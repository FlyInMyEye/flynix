import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var machine
    required property var theme
    required property var window
    property bool active: false
    property real maximumHeight: 360
    property var items: SystemTray.items.values
    readonly property int count: items.length
    readonly property real contentWidth: count * 32 + Math.max(0, count - 1) * 14
    property var selectedItem: null
    property var pendingItem: null
    readonly property int menuDepth: submenuPath.count
    readonly property var currentEntries: menuDepth && branches.count === menuDepth && branches.itemAt(branches.count - 1) ? branches.itemAt(branches.count - 1).entries.values : opener.children.values
    property var menuEntries: currentEntries
    readonly property real desiredHeight: selectedItem ? 78 + (menuDepth ? 26 : 0) + Math.max(32, menuList.naturalHeight) : 60
    readonly property real desiredWidth: Math.max(280, Math.min(350, contentWidth + 36), selectedItem ? menuList.columnCount * 240 + 28 : 0)
    ListModel {
        id: submenuPath
    }

    function select(item) {
        hoverIntent.stop();
        if (!active || selectedItem === item)
            return;
        submenuPath.clear();
        selectedItem = item;
    }
    function reset() {
        hoverIntent.stop();
        pendingItem = null;
        submenuPath.clear();
        selectedItem = null;
    }
    function choose(entry) {
        if (!entry.enabled || entry.isSeparator)
            return;
        if (entry.hasChildren)
            submenuPath.append({
                handle: entry
            });
        else {
            var keepOpen = entry.buttonType !== QsMenuButtonType.None;
            entry.triggered();
            if (!keepOpen)
                machine.dismiss();
        }
    }
    onActiveChanged: {
        if (!active)
            reset();
    }
    onItemsChanged: {
        if (selectedItem && !items.includes(selectedItem))
            reset();
    }
    Timer {
        id: hoverIntent
        interval: 140
        onTriggered: root.select(root.pendingItem)
    }
    QsMenuOpener {
        id: opener
        menu: root.selectedItem && root.selectedItem.hasMenu ? root.selectedItem.menu : null
    }
    // Keep every ancestor open while navigating a submenu: its child handles
    // remain alive even if the application's menu changes over D-Bus.
    Repeater {
        id: branches
        model: submenuPath
        Item {
            id: branchOwner
            required property var handle
            property alias entries: branch.children
            visible: false
            QsMenuOpener {
                id: branch
                menu: branchOwner.handle
            }
        }
    }
    Flickable {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 14
            topMargin: 5
        }
        height: 40
        clip: true
        contentWidth: Math.max(width, iconRow.width)
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: iconRow
            x: Math.max(0, (parent.width - width) / 2)
            spacing: 14
            Repeater {
                model: root.items
                Item {
                    id: icon
                    required property var modelData
                    objectName: "trayIcon:" + modelData.id
                    width: 32
                    height: 38
                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 30
                        radius: 10
                        color: root.theme.altBg
                        opacity: root.selectedItem === icon.modelData ? 1 : iconMouse.containsMouse ? 0.5 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.ms(140)
                            }
                        }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 21
                        height: 21
                        source: icon.modelData.icon
                        sourceSize: Qt.size(24, 24)
                        scale: iconMouse.containsMouse ? 1.12 : 1
                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.ms(220)
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.6
                            }
                        }
                    }
                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onEntered: {
                            root.pendingItem = icon.modelData;
                            hoverIntent.restart();
                        }
                        onExited: {
                            if (root.pendingItem === icon.modelData)
                                hoverIntent.stop();
                        }
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || icon.modelData.onlyMenu)
                                root.select(icon.modelData);
                            else {
                                if (mouse.button === Qt.MiddleButton)
                                    icon.modelData.secondaryActivate();
                                else
                                    icon.modelData.activate();
                                root.machine.dismiss();
                            }
                        }
                        onWheel: wheel => icon.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
    Column {
        x: 14
        y: 48
        width: parent.width - 28
        spacing: 4
        visible: !!root.selectedItem
        Text {
            width: parent.width
            height: 18
            text: root.selectedItem ? root.selectedItem.tooltipTitle || root.selectedItem.title || root.selectedItem.id : ""
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: root.theme.muted
            font {
                family: root.theme.font
                pixelSize: 10
            }
        }
        Rectangle {
            visible: root.menuDepth > 0
            width: parent.width
            height: 22
            radius: 7
            color: backMouse.containsMouse ? root.theme.altBg : "transparent"
            Text {
                anchors.centerIn: parent
                text: "‹"
                color: root.theme.fg
                font {
                    family: root.theme.font
                    pixelSize: 18
                }
            }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: submenuPath.remove(submenuPath.count - 1)
            }
        }
        TrayMenu {
            id: menuList
            objectName: "trayMenu"
            width: parent.width
            height: Math.max(0, root.height - 78 - (root.menuDepth ? 26 : 0))
            theme: root.theme
            entries: root.selectedItem ? root.menuEntries : []
            maximumColumnHeight: Math.max(32, root.maximumHeight - 78 - (root.menuDepth ? 26 : 0))
            onChosen: entry => root.choose(entry)
            Text {
                anchors.centerIn: parent
                visible: !menuList.entries.length
                text: root.selectedItem && !root.selectedItem.hasMenu ? "Open" : "···"
                color: root.theme.muted
                font {
                    family: root.theme.font
                    pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !!root.selectedItem && !root.selectedItem.hasMenu
                    onClicked: {
                        root.selectedItem.activate();
                        root.machine.dismiss();
                    }
                }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: !root.count
        text: "···"
        color: root.theme.muted
        font {
            family: root.theme.font
            pixelSize: 11
        }
    }
}
