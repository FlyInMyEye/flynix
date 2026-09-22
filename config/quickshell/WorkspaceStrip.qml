import QtQuick

Item {
    id: root
    required property var theme
    required property var workspaces
    property bool presented: false
    readonly property int activeId: workspaces.activeId
    readonly property var ids: workspaces.ids
    readonly property real step: 18
    implicitWidth: ids.length * step + 20
    implicitHeight: 40
    readonly property real leftEdge: 10
    property real head: 19
    property real tail: 19
    property real destination: 19
    property int previousId: 0
    property bool animateMove: false

    function retarget() {
        if (activeId <= 0 || !ids.includes(activeId))
            return;
        var next = leftEdge + ids.indexOf(activeId) * step + step / 2;
        if (previousId === activeId && destination === next)
            return;
        animateMove = previousId > 0;
        previousId = activeId;
        destination = next;
        head = next;
        tail = next;
    }
    onActiveIdChanged: retarget()
    onIdsChanged: Qt.callLater(retarget)
    Component.onCompleted: retarget()
    // The nose leads, the tail catches up. Retarget from the current shape when
    // keys repeat; revealing/resizing the capsule never restarts this motion.
    Behavior on head {
        enabled: root.animateMove
        NumberAnimation {
            duration: Motion.ms(360)
            easing.type: Easing.OutBack
            easing.overshoot: 0.55
        }
    }
    Behavior on tail {
        enabled: root.animateMove
        NumberAnimation {
            duration: Motion.ms(460)
            easing.type: Easing.InOutCubic
        }
    }
    Repeater {
        model: root.ids
        Item {
            id: dot
            required property int modelData
            required property int index
            readonly property bool occupied: root.workspaces.occupied.includes(modelData)
            x: root.leftEdge + index * root.step
            width: root.step
            height: root.height
            Rectangle {
                anchors.centerIn: parent
                width: dot.occupied ? 4 : 3
                height: width
                radius: width / 2
                color: root.theme.fg
                opacity: root.activeId === dot.modelData ? 0 : dot.occupied ? 0.65 : 0.22
                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.ms(180)
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaces.activate(dot.modelData)
            }
        }
    }
    Canvas {
        id: bead
        objectName: "workspaceMarker"
        anchors.fill: parent
        visible: root.activeId > 0
        antialiasing: true
        readonly property real lead: root.head
        readonly property real lag: root.head + Math.max(-24, Math.min(24, root.tail - root.head))
        readonly property real stretch: Math.abs(lead - lag)
        readonly property color ink: root.theme.accent
        readonly property color centerColor: root.theme.bg
        onLeadChanged: requestPaint()
        onLagChanged: requestPaint()
        onInkChanged: requestPaint()
        onCenterColorChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var y = height / 2;
            var left = Math.min(lead, lag), right = Math.max(lead, lag);
            var tension = Math.min(1, stretch / 18);
            var nose = 4.5 - tension * 0.6, heel = 4.5 - tension * 2;
            var lr = lead < lag ? nose : heel, rr = lead < lag ? heel : nose;
            var mid = (left + right) / 2;
            ctx.fillStyle = ink;
            ctx.beginPath();
            ctx.moveTo(left, y - lr);
            ctx.bezierCurveTo(mid, y - lr * (1 - tension * 0.55), mid, y - rr * (1 - tension * 0.55), right, y - rr);
            ctx.bezierCurveTo(right + rr * 1.33, y - rr, right + rr * 1.33, y + rr, right, y + rr);
            ctx.bezierCurveTo(mid, y + rr * (1 - tension * 0.55), mid, y + lr * (1 - tension * 0.55), left, y + lr);
            ctx.bezierCurveTo(left - lr * 1.33, y + lr, left - lr * 1.33, y - lr, left, y - lr);
            ctx.closePath();
            ctx.fill();
            // A quiet ring at rest; it fills while stretched and reforms on arrival.
            ctx.globalAlpha = 1 - Math.min(1, stretch / 5);
            ctx.fillStyle = centerColor;
            ctx.beginPath();
            ctx.arc(lead, y, 2.2, 0, Math.PI * 2);
            ctx.fill();
        }
    }
}
