import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var radios
    required property var theme
    required property var machine
    property bool bluetooth: machine.state === "BLUETOOTH"
    property bool active: false
    property var passwordNetwork: null
    readonly property bool powered: bluetooth ? radios.bluetoothEnabled : radios.wifiEnabled
    onActiveChanged: { password.clear(); passwordNetwork = null; }
    onBluetoothChanged: { password.clear(); passwordNetwork = null; }
    Column {
        anchors { fill: parent; margins: 20; topMargin: 8 }
        spacing: 12
        Row {
            width: parent.width
            spacing: 8
            Column {
                width: parent.width - 52
                spacing: 5
                Text { text: root.bluetooth ? "Bluetooth" : "Wi-Fi"; color: root.theme.fg; font.family: root.theme.font; font.pixelSize: 18 }
                Text {
                    width: parent.width
                    text: root.bluetooth ? root.radios.bluetoothStatus : root.radios.wifiStatus
                    textFormat: Text.PlainText; elide: Text.ElideRight
                    color: root.theme.muted; font.family: root.theme.font; font.pixelSize: 11
                }
            }
            Rectangle {
                objectName: "radioPower"
                width: 44; height: 26; radius: 13
                color: root.powered ? root.theme.accent : root.theme.altBg
                opacity: (root.bluetooth ? root.radios.bluetoothAvailable : root.radios.wifiAvailable) ? 1 : 0.3
                Rectangle {
                    width: 18; height: 18; radius: 9; y: 4; x: root.powered ? 22 : 4
                    color: root.powered ? root.theme.bg : root.theme.muted
                    Behavior on x { NumberAnimation { duration: Motion.ms(220); easing.type: Easing.OutCubic } }
                }
                MouseArea { anchors.fill: parent; onClicked: root.bluetooth ? root.radios.toggleBluetooth() : root.radios.toggleWifi() }
            }
        }
        ListView {
            id: list
            objectName: "radioDevices"
            width: parent.width
            height: Math.max(50, root.height - 154)
            clip: true; spacing: 4
            model: root.powered ? root.bluetooth ? root.radios.devices : root.radios.networks : []
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width; height: 44; radius: 12
                color: rowMouse.containsMouse || modelData.connected ? root.theme.altBg : "transparent"
                Text {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80
                    text: parent.modelData.name || "Hidden network"
                    textFormat: Text.PlainText; elide: Text.ElideRight
                    color: parent.modelData.connected ? root.theme.accent : root.theme.fg
                    font.family: root.theme.font; font.pixelSize: 12
                }
                Text {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: parent.modelData.connected ? "✓" : root.bluetooth ? "+" : Math.round(parent.modelData.signalStrength * 100) + "%"
                    color: root.theme.muted; font.family: root.theme.mono; font.pixelSize: 11
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (root.bluetooth) root.radios.toggleDevice(parent.modelData);
                        else if (!parent.modelData.connected && root.radios.needsPassword(parent.modelData)) {
                            root.passwordNetwork = parent.modelData;
                            password.clear(); password.forceActiveFocus();
                        } else root.radios.connectWifi(parent.modelData, "");
                    }
                }
            }
            Text {
                anchors.centerIn: parent; visible: list.count === 0
                text: !root.powered ? "Turn on to connect" : root.bluetooth ? "No paired devices" : "Looking for networks…"
                color: root.theme.muted; font.family: root.theme.font; font.pixelSize: 12
            }
            ScrollBar.vertical: ScrollBar {}
        }
        TextField {
            id: password
            objectName: "wifiPassword"
            width: parent.width; height: visible ? 36 : 0
            visible: root.passwordNetwork !== null
            placeholderText: "Password · Enter to connect"
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            color: root.theme.fg; font.family: root.theme.font; font.pixelSize: 12
            background: Rectangle { color: root.theme.altBg; radius: 10 }
            onAccepted: { root.radios.connectWifi(root.passwordNetwork, text); clear(); root.passwordNetwork = null; }
        }
        Text {
            width: parent.width; visible: !password.visible
            text: root.radios.error || (root.bluetooth ? "Pair a device ↗" : "Network settings ↗")
            textFormat: Text.PlainText; elide: Text.ElideRight
            color: root.radios.error ? root.theme.red : root.theme.accent
            font.family: root.theme.font; font.pixelSize: 11
            MouseArea { anchors.fill: parent; onClicked: root.radios.manage(root.bluetooth) }
        }
    }
}
