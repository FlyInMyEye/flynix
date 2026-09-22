import QtQuick

Canvas {
    id: root
    property real progress: 0
    property real radius: 20
    property color stroke: "white"
    property real lineWidth: 1.5
    Behavior on progress {
        NumberAnimation {
            duration: Motion.ms(200)
            easing.type: Easing.OutCubic
        }
    }
    onLineWidthChanged: requestPaint()
    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var inset = Math.max(3, lineWidth / 2 + 1), w = width - 2 * inset, h = height - 2 * inset;
        var r = Math.min(radius - inset, h / 2, w / 2);
        if (r <= 0)
            return;
        // Sample the rounded rectangle clockwise from 12 o'clock, then draw
        // the requested fraction by arc length (uniform through the corners).
        var points = [], steps = 240;
        var perimeter = 2 * (w + h - 4 * r) + 2 * Math.PI * r;
        var segments = [[w / 2 - r, t => [width / 2 + t, inset]], [Math.PI * r / 2, t => [inset + w - r + r * Math.cos(-Math.PI / 2 + t / r), inset + r + r * Math.sin(-Math.PI / 2 + t / r)]], [h - 2 * r, t => [inset + w, inset + r + t]], [Math.PI * r / 2, t => [inset + w - r + r * Math.cos(t / r), inset + h - r + r * Math.sin(t / r)]], [w - 2 * r, t => [inset + w - r - t, inset + h]], [Math.PI * r / 2, t => [inset + r + r * Math.cos(Math.PI / 2 + t / r), inset + h - r + r * Math.sin(Math.PI / 2 + t / r)]], [h - 2 * r, t => [inset, inset + h - r - t]], [Math.PI * r / 2, t => [inset + r + r * Math.cos(Math.PI + t / r), inset + r + r * Math.sin(Math.PI + t / r)]], [w / 2 - r, t => [inset + r + t, inset]]];
        ctx.beginPath();
        ctx.moveTo(width / 2, inset);
        for (var i = 1; i <= steps; ++i) {
            var distance = perimeter * Math.min(1, Math.max(0, progress)) * i / steps;
            for (var segment of segments) {
                if (distance <= segment[0]) {
                    var p = segment[1](distance);
                    ctx.lineTo(p[0], p[1]);
                    break;
                }
                distance -= segment[0];
            }
        }
        ctx.strokeStyle = stroke;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.stroke();
    }
}
