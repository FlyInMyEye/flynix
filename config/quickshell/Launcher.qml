import QtQuick
import QtQuick.Controls
import Quickshell
import "logic/Ranking.js" as Ranking

Item {
    id: root
    required property var machine
    required property var services
    required property var theme
    objectName: "launcher"
    property bool active: false
    property bool pointerReady: true
    property var availableApps: DesktopEntries.applications.values
    property double rankingTime: Date.now()
    property point lastPointerScene: Qt.point(-1, -1)
    property int pointerRevision: 0
    HoverHandler {
        id: launcherHover
        onPointChanged: {
            var p = point.scenePosition;
            if (Math.abs(p.x - root.lastPointerScene.x) < 0.5 && Math.abs(p.y - root.lastPointerScene.y) < 0.5)
                return;
            root.lastPointerScene = p;
            var revision = ++root.pointerRevision;
            Qt.callLater(() => {
                if (revision !== root.pointerRevision || !hovered || !root.active || !root.pointerReady)
                    return;
                var view = resultsList;
                var local = view.mapFromItem(null, p.x, p.y);
                if (local.x < 0 || local.x >= view.width || local.y < 0 || local.y >= view.height)
                    return;
                var index = view.indexAt(local.x + view.contentX, local.y + view.contentY);
                if (index >= 0)
                    view.currentIndex = index;
            });
        }
    }
    readonly property string query: search.text.trim()
    onQueryChanged: services.searchFiles(query.startsWith("/") ? query.slice(1).trim() : "")
    function moveSelection(delta) {
        // Window coordinates distinguish a real mouse move from rows scrolling
        // beneath it. Cancel any hover selection queued before this key event.
        pointerRevision++;
        lastPointerScene = launcherHover.point.scenePosition;
        var view = resultsList;
        view.currentIndex = Math.max(0, Math.min(view.count - 1, view.currentIndex + delta));
        view.positionViewAtIndex(view.currentIndex, ListView.Contain);
    }
    readonly property bool fileMode: query.startsWith("/")
    readonly property bool webMode: query.startsWith("?") || /^https?:\/\//.test(query)
    readonly property var apps: Ranking.rank(availableApps, query, services.appUsage, rankingTime)
    readonly property var selected: results[resultsList.currentIndex] || null
    onResultsChanged: resultsList.currentIndex = Math.max(0, Math.min(resultsList.currentIndex, results.length - 1))

    readonly property var results: webMode ? [
        {
            name: "Search the web for “" + query.replace(/^\?\s*/, "") + "”",
            web: true
        }
    ] : fileMode ? services.fileResults : apps
    function activate(item) {
        if (!item || machine.locked)
            return;
        if (item.web)
            services.openUrl(/^https?:\/\//.test(query) ? query : "https://duckduckgo.com/?q=" + encodeURIComponent(query.replace(/^\?\s*/, "")));
        else if (item.url)
            services.openUrl(item.url);
        else {
            services.launchApp(item);
        }
    }
    onActiveChanged: {
        if (active) {
            rankingTime = Date.now();
            search.clear();
            Qt.callLater(() => {
                if (root.active)
                    search.forceActiveFocus();
            });
        } else {
            search.clear();
        }
    }
    Column {
        anchors {
            fill: parent
            margins: 32
        }
        spacing: 16
        Row {
            width: parent.width
            spacing: 12
            Text {
                font.family: root.theme.font
                text: "⌕"
                color: root.theme.accent
                font.pixelSize: 28
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: search
                font.family: root.theme.font
                objectName: "launcherSearch"
                width: parent.width - 100
                height: 52
                placeholderText: "Apps · /files · ?web"
                placeholderTextColor: root.theme.muted
                color: root.theme.fg
                font.pixelSize: 24
                selectByMouse: true
                background: null
                onTextChanged: {
                    resultsList.currentIndex = 0;
                }
                onAccepted: {
                    if (root.results.length)
                        root.activate(root.results[resultsList.currentIndex]);
                }
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onEscapePressed: root.machine.dismiss()
                Keys.onPressed: event => {
                    if (event.modifiers & Qt.AltModifier && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        root.activate(root.results[event.key - Qt.Key_1]);
                        event.accepted = true;
                    }
                }
            }
            Rectangle {
                width: 36
                height: 36
                radius: 18
                anchors.verticalCenter: parent.verticalCenter
                color: closeMouse.containsMouse ? root.theme.altBg : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: root.theme.muted
                    font.pixelSize: 22
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.pointerReady
                    onClicked: root.machine.dismiss()
                }
            }
        }
        Item {
            width: parent.width
            height: parent.height - 68
            Item {
                anchors.fill: parent
                ListView {
                    id: resultsList
                    objectName: "launcherResults"
                    width: preview.visible ? parent.width * 0.62 - 20 : parent.width
                    height: parent.height
                    clip: true
                    spacing: 6
                    model: root.results
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Motion.ms(180)
                    highlightResizeDuration: Motion.ms(180)
                    highlight: Rectangle {
                        radius: 16
                        color: root.theme.altBg
                        border.color: Qt.alpha(root.theme.accent, 0.16)
                        Rectangle {
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 18
                            radius: 2
                            color: root.theme.accent
                        }
                    }
                    delegate: Item {
                        id: result
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === resultsList.currentIndex
                        width: ListView.view.width
                        height: 62
                        scale: resultMouse.pressed ? 0.97 : 1
                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.ms(180)
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.2
                            }
                        }
                        Image {
                            id: resultIcon
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            visible: status === Image.Ready
                            source: result.modelData.icon ? Quickshell.iconPath(result.modelData.icon, true) : ""
                            sourceSize: Qt.size(68, 68)
                        }
                        Text {
                            x: 20
                            anchors.verticalCenter: parent.verticalCenter
                            visible: resultIcon.status !== Image.Ready
                            text: result.modelData.web ? "↗" : result.modelData.url ? "▤" : result.modelData.name.charAt(0).toUpperCase()
                            color: root.theme.accent
                            font {
                                family: root.theme.font
                                pixelSize: 24
                            }
                        }
                        Text {
                            x: 66
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 108
                            text: result.modelData.name
                            color: result.selected ? root.theme.fg : Qt.alpha(root.theme.fg, 0.75)
                            font {
                                family: root.theme.font
                                pixelSize: 15
                            }
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.ms(160)
                                }
                            }
                        }
                        Text {
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                            text: result.selected ? "↵" : result.index < 9 ? String(result.index + 1) : ""
                            color: result.selected ? root.theme.accent : Qt.alpha(root.theme.muted, 0.4)
                            font {
                                family: root.theme.mono
                                pixelSize: 12
                            }
                        }
                        MouseArea {
                            id: resultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.pointerReady
                            onClicked: root.activate(result.modelData)
                        }
                    }
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
                Item {
                    id: preview
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: parent.width * 0.38
                    visible: parent.width > 620 && root.results.length > 0
                    Rectangle {
                        width: 1
                        height: parent.height - 32
                        y: 16
                        color: Qt.alpha(root.theme.muted, 0.12)
                    }
                    Column {
                        id: previewContent
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: parent.width - 48
                        spacing: 20
                        Item {
                            width: 132
                            height: 132
                            anchors.horizontalCenter: parent.horizontalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: 38
                                color: Qt.alpha(root.theme.accent, 0.06)
                                rotation: -8
                            }
                            Image {
                                id: previewIcon
                                anchors.centerIn: parent
                                width: 88
                                height: 88
                                sourceSize: Qt.size(176, 176)
                                source: root.selected && root.selected.icon ? Quickshell.iconPath(root.selected.icon, true) : ""
                                visible: status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: previewIcon.status !== Image.Ready
                                text: root.webMode ? "↗" : root.fileMode ? "▤" : root.selected ? root.selected.name.charAt(0).toUpperCase() : ""
                                color: root.theme.accent
                                font {
                                    family: root.theme.font
                                    pixelSize: 54
                                }
                            }
                        }
                        Text {
                            width: parent.width
                            text: root.selected ? root.selected.name : ""
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: root.theme.fg
                            font {
                                family: root.theme.font
                                pixelSize: 19
                            }
                        }
                        Text {
                            width: parent.width
                            text: root.selected ? root.selected.genericName || "" : ""
                            visible: text.length > 0
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: root.theme.muted
                            font {
                                family: root.theme.font
                                pixelSize: 12
                            }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56
                            height: 40
                            radius: 20
                            color: openMouse.containsMouse ? root.theme.accent : root.theme.altBg
                            scale: openMouse.pressed ? 0.9 : 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.ms(140)
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Motion.ms(180)
                                    easing.type: Easing.OutBack
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "↵"
                                color: openMouse.containsMouse ? root.theme.bg : root.theme.accent
                                font.pixelSize: 22
                            }
                            MouseArea {
                                id: openMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.pointerReady
                                onClicked: root.activate(root.selected)
                            }
                        }
                    }
                    Connections {
                        target: root
                        function onSelectedChanged() {
                            previewEntrance.restart();
                        }
                    }
                    ParallelAnimation {
                        id: previewEntrance
                        NumberAnimation {
                            target: previewContent
                            property: "opacity"
                            from: 0.35
                            to: 1
                            duration: Motion.ms(200)
                        }
                        NumberAnimation {
                            target: previewContent
                            property: "scale"
                            from: 0.94
                            to: 1
                            duration: Motion.ms(320)
                            easing.type: Easing.OutBack
                            easing.overshoot: 1
                        }
                    }
                    Text {
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: 12
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: "↑ ↓   ↵     alt 1–9"
                        color: Qt.alpha(root.theme.muted, 0.6)
                        font {
                            family: root.theme.mono
                            pixelSize: 10
                        }
                    }
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !root.results.length
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "⌕"
                        color: root.theme.muted
                        font.pixelSize: 36
                    }
                    Text {
                        text: root.fileMode ? root.services.fileSearchBusy ? "Searching…" : root.services.fileSearchError || (root.query.replace(/^\//, "").trim().length < 2 ? "Type at least two characters" : "No files found") : "No matches"
                        color: root.theme.muted
                        font {
                            family: root.theme.font
                            pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
