import QtQuick

Item {
    id: root
    required property var services
    required property var theme
    Row {
        anchors {
            fill: parent
            margins: 20
            topMargin: 8
            bottomMargin: 20
        }
        spacing: 14
        Repeater {
            model: ["CPU", "RAM", "GPU"]
            Rectangle {
                id: metric
                required property string modelData
                required property int index
                objectName: "stat:" + modelData
                readonly property var metricInfo: ({
                        name: modelData,
                        value: index === 0 ? root.services.cpu : index === 1 ? root.services.ram : root.services.gpu,
                        samples: index === 0 ? root.services.cpuHistory : index === 1 ? root.services.ramHistory : root.services.gpuHistory,
                        color: index === 0 ? root.theme.accent : index === 1 ? root.theme.green : root.theme.fg
                    })
                width: (parent.width - 28) / 3
                height: parent.height
                radius: 18
                color: Qt.alpha(root.theme.altBg, 0.65)
                readonly property real value: parseFloat(metricInfo.value)
                Text {
                    x: 14
                    y: 13
                    text: metric.metricInfo.name
                    color: root.theme.muted
                    font {
                        family: root.theme.font
                        pixelSize: 10
                        letterSpacing: 1.5
                    }
                }
                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 16
                        top: parent.top
                        topMargin: 18
                    }
                    width: 4
                    height: 4
                    radius: 2
                    color: metric.value >= 85 ? root.theme.red : metric.metricInfo.color
                    opacity: isNaN(metric.value) ? 0.15 : 0.85
                }
                Row {
                    x: 14
                    y: 36
                    spacing: 3
                    Text {
                        text: isNaN(metric.value) ? "—" : Math.round(metric.value)
                        color: root.theme.fg
                        font {
                            family: root.theme.mono
                            pixelSize: 30
                            weight: Font.Medium
                        }
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        text: isNaN(metric.value) ? "" : "%"
                        color: root.theme.muted
                        font {
                            family: root.theme.mono
                            pixelSize: 12
                        }
                    }
                }
                Canvas {
                    id: graph
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 14
                    }
                    height: 48
                    property var samples: metric.metricInfo.samples
                    property real reveal: 1
                    onSamplesChanged: {
                        reveal = 0;
                        settle.restart();
                        requestPaint();
                    }
                    onRevealChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onVisibleChanged: requestPaint()
                    NumberAnimation {
                        id: settle
                        target: graph
                        property: "reveal"
                        to: 1
                        duration: Motion.ms(260)
                        easing.type: Easing.OutCubic
                    }
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        if (!width || !height)
                            return;
                        ctx.strokeStyle = Qt.alpha(root.theme.fg, 0.08);
                        ctx.lineWidth = 1;
                        for (var row = 0; row < 3; ++row) {
                            var y = 4 + row * (height - 8) / 2;
                            ctx.beginPath();
                            ctx.moveTo(0, y);
                            ctx.lineTo(width, y);
                            ctx.stroke();
                        }
                        if (metric.index === 1 && !isNaN(metric.value)) {
                            var bars = Math.max(4, Math.floor(width / 7));
                            for (var i = 0; i < bars; ++i) {
                                ctx.fillStyle = i / bars < metric.value / 100 ? Qt.alpha(metric.metricInfo.color, 0.8) : Qt.alpha(root.theme.fg, 0.08);
                                ctx.fillRect(i * width / bars, 12, 3, height - 24);
                            }
                            return;
                        }
                        var values = samples.filter(v => v !== null && isFinite(v));
                        if (!values.length)
                            return;
                        if (values.length === 1)
                            values = [values[0], values[0]];
                        ctx.beginPath();
                        for (var i = 0; i < values.length; ++i) {
                            var v = values[i];
                            if (i === values.length - 1)
                                v = values[i - 1] + (v - values[i - 1]) * reveal;
                            var x = i * width / (values.length - 1);
                            var y = height - 3 - Math.max(0, Math.min(100, v)) / 100 * (height - 6);
                            if (!i)
                                ctx.moveTo(x, y);
                            else
                                ctx.lineTo(x, y);
                        }
                        ctx.strokeStyle = metric.metricInfo.color;
                        ctx.lineWidth = 2;
                        ctx.lineJoin = "round";
                        ctx.stroke();
                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height);
                        ctx.closePath();
                        var fill = ctx.createLinearGradient(0, 0, 0, height);
                        fill.addColorStop(0, Qt.alpha(metric.metricInfo.color, 0.2));
                        fill.addColorStop(1, "transparent");
                        ctx.fillStyle = fill;
                        ctx.fill();
                    }
                }
            }
        }
    }
}
