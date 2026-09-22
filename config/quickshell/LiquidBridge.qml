import QtQuick

Canvas {
    id: root
    required property var bubble
    required property var capsule
    required property var theme
    readonly property real amount: bubble.merge
    readonly property real centerX: bubble.x + 18
    readonly property real centerY: bubble.y + 18
    readonly property real edge: bubble.kind === "wifi" ? capsule.x : capsule.x + capsule.width
    readonly property real direction: bubble.kind === "wifi" ? 1 : -1
    x: Math.min(centerX - 20, edge - 20)
    y: centerY - 24
    width: Math.abs(centerX - edge) + 40
    height: 48
    z: 4
    opacity: Math.min(1, amount * 3) * bubble.opacity
    visible: amount > 0.001 && bubble.visible
    onAmountChanged: requestPaint()
    onCenterXChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        var c = getContext("2d"); c.reset();
        if (!visible) return;
        // Two opposing concave curves thicken into a liquid neck. The fill
        // overlaps both bodies so their outlines don't leave a seam inside it.
        var cx = centerX - x, cy = 24, side = direction;
        var a = cx + side * (12 - amount * 5);
        var b = edge - x + side * 12;
        var tip = 10 + amount * 7;
        var neck = 1 + amount * 13;
        var mid = (a + b) / 2;
        c.fillStyle = theme.bg;
        c.beginPath(); c.moveTo(a, cy - tip);
        c.bezierCurveTo(mid, cy - neck, mid, cy - neck, b, cy - tip);
        c.lineTo(b, cy + tip);
        c.bezierCurveTo(mid, cy + neck, mid, cy + neck, a, cy + tip);
        c.closePath(); c.fill();
        c.strokeStyle = Qt.alpha(theme.accent, 0.22 * (1 - amount));
        c.lineWidth = 1;
        c.beginPath(); c.moveTo(a, cy - tip);
        c.bezierCurveTo(mid, cy - neck, mid, cy - neck, b, cy - tip);
        c.moveTo(a, cy + tip);
        c.bezierCurveTo(mid, cy + neck, mid, cy + neck, b, cy + tip);
        c.stroke();
    }
}
