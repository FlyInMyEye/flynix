import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var machine
    required property var services
    required property var theme
    required property var dragProxy
    function label(url) {
        try {
            return decodeURIComponent(url.split("/").pop());
        } catch (_) {
            return url.split("/").pop();
        }
    }
    Column {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 10
        Flickable {
            visible: root.services.shelf.length > 0
            width: parent.width
            height: 40
            contentWidth: Math.max(width, chips.width)
            clip: true
            Row {
                id: chips
                x: Math.max(0, (parent.width - width) / 2)
                Behavior on x {
                    NumberAnimation {
                        duration: Motion.ms(220)
                        easing.type: Easing.OutCubic
                    }
                }
                spacing: 8
                move: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: Motion.ms(180)
                        easing.type: Easing.OutCubic
                    }
                }
                Repeater {
                    model: root.services.shelfModel
                    Rectangle {
                        id: chip
                        required property string fileUrl
                        objectName: "shelfChip:" + fileUrl
                        width: Math.min(160, chipText.implicitWidth + 28)
                        height: 34
                        radius: 12
                        color: root.theme.altBg
                        border.color: root.theme.accent
                        Text {
                            id: chipText
                            font.family: root.theme.font
                            anchors.centerIn: parent
                            width: parent.width - 20
                            text: "✦ " + root.label(chip.fileUrl)
                            color: root.theme.fg
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                        }
                        MouseArea {
                            anchors.fill: parent
                            drag.target: root.dragProxy
                            onPressed: {
                                root.dragProxy.url = chip.fileUrl;
                                root.dragProxy.inside = true;
                                var p = mapToItem(root.dragProxy.parent, width / 2, height / 2);
                                root.dragProxy.x = p.x;
                                root.dragProxy.y = p.y;
                            }
                            onPositionChanged: {
                                if (drag.active && !root.dragProxy.Drag.active)
                                    root.dragProxy.Drag.active = true;
                            }
                            // Native drag owns completion, including when the
                            // source chip disappears on leaving the island.
                        }
                    }
                }
            }
            Text {
                font.family: root.theme.font
                anchors.centerIn: parent
                visible: !root.services.shelf.length
                text: "+"
                color: root.theme.muted
                font.pixelSize: 18
            }
        }
        Rectangle {
            visible: root.services.shelf.length > 0
            width: parent.width
            height: 1
            color: Qt.alpha(root.theme.fg, 0.12)
        }
        ListView {
            width: parent.width
            height: Math.max(0, root.height - 32 - (root.services.shelf.length ? 61 : 0))
            clip: true
            spacing: 4
            model: root.services.history
            delegate: Rectangle {
                id: entry
                required property var modelData
                objectName: "clipboardEntry:" + modelData.id
                width: ListView.view.width
                height: modelData.image ? 72 : 32
                radius: 9
                color: historyMouse.containsMouse ? root.theme.altBg : "transparent"
                function loadPreview() {
                    if (modelData.image)
                        root.services.requestPreview(modelData.id);
                }
                Component.onCompleted: loadPreview()
                Connections {
                    target: root.machine
                    function onStateChanged() {
                        if (root.machine.state === "CLIPBOARD")
                            entry.loadPreview();
                    }
                }
                Image {
                    id: previewImage
                    objectName: "clipboardImage:" + entry.modelData.id
                    x: 8
                    y: 8
                    width: 84
                    height: 56
                    visible: entry.modelData.image
                    source: root.services.previews[entry.modelData.id] || ""
                    sourceSize: Qt.size(168, 112)
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    Text {
                        anchors.centerIn: parent
                        visible: previewImage.status !== Image.Ready
                        text: "▧"
                        color: root.theme.muted
                        font {
                            family: root.theme.font
                            pixelSize: 22
                        }
                    }
                }
                Text {
                    font.family: root.theme.font
                    anchors {
                        fill: parent
                        margins: 8
                        leftMargin: entry.modelData.image ? 104 : 8
                    }
                    text: entry.modelData.image ? "Image" : entry.modelData.preview
                    verticalAlignment: Text.AlignVCenter
                    color: root.theme.fg
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                MouseArea {
                    id: historyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: entry.loadPreview()
                    onClicked: root.services.restore(entry.modelData.id)
                }
            }
            Text {
                font.family: root.theme.font
                anchors.centerIn: parent
                visible: !root.services.history.length
                text: "···"
                color: root.theme.muted
                font.pixelSize: 11
            }
            ScrollBar.vertical: ScrollBar {}
        }
    }
}
