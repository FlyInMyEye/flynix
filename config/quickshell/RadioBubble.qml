import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    required property var theme
    required property string kind
    required property real homeX
    required property real homeY
    property bool connected: false
    property bool powered: false
    property string status: ""
    property bool allowed: true
    property real mergeProgress: 0
    property bool merging: false
    readonly property real direction: kind === "wifi" ? 1 : -1
    readonly property real offsetX: direction * 36 * mergeProgress
    readonly property real merge: Math.max(0, Math.min(1, (Math.abs(offsetX) - 2) / 28))
    readonly property bool interacting: mouse.pressed
    signal clicked(string kind)
    objectName: kind + "Bubble"
    x: homeX + offsetX
    y: homeY
    width: 36
    height: 36
    radius: 18
    color: theme.bg
    border.width: 1
    border.color: Qt.alpha(theme.accent, (mouse.containsMouse ? 0.65 : 0.22) * (1 - merge))
    scale: mouse.pressed ? 0.94 : mouse.containsMouse && !merging ? 1.04 : 1
    enabled: allowed && !merging
    opacity: allowed ? 1 - Math.max(0, (mergeProgress - 0.65) / 0.35) : 0
    visible: opacity > 0.001
    z: 5
    Behavior on opacity { enabled: !root.merging; NumberAnimation { duration: Motion.ms(160) } }
    Behavior on scale { NumberAnimation { duration: Motion.ms(240); easing.type: Easing.OutBack } }
    Canvas {
        anchors.centerIn: parent
        width: 22; height: 22
        property color ink: root.powered ? root.theme.accent : root.theme.muted
        onInkChanged: requestPaint()
        onPaint: {
            var c = getContext("2d"); c.reset(); c.strokeStyle = ink; c.fillStyle = ink; c.lineWidth = 1.65; c.lineCap = "round"; c.lineJoin = "round";
            if (root.kind === "wifi") {
                for (var r of [7, 12]) { c.beginPath(); c.arc(11, 18, r, -Math.PI * 0.76, -Math.PI * 0.24); c.stroke(); }
                c.beginPath(); c.arc(11, 18, 1.3, 0, Math.PI * 2); c.fill();
            } else {
                c.beginPath(); c.moveTo(7, 6); c.lineTo(16, 15); c.lineTo(11, 20); c.lineTo(11, 2); c.lineTo(16, 7); c.lineTo(7, 16); c.stroke();
            }
        }
    }
    Rectangle {
        x: 26; y: 25; width: 4; height: 4; radius: 2
        color: root.theme.green
        visible: root.connected
    }
    ToolTip.visible: mouse.containsMouse && !mouse.pressed
    ToolTip.delay: 600
    ToolTip.text: status + " · click to configure"
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root.kind)
    }
}
