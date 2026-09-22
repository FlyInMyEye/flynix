import QtQuick

// Presentation is independent of arbitration: input can reach the launcher
// during flight, and a new intent always replaces the pending destination.
Item {
    id: motion
    required property real targetWidth
    required property real targetHeight
    required property real topMargin
    required property real screenHeight
    required property string scene
    property bool direct: false
    property bool suspended: false
    property string phase: "rest"
    property string previousScene: "IDLE"
    property bool ready: false
    property real bodyWidth: 100
    property real bodyHeight: 40
    property real centerY: topMargin + 20
    property real reveal: 1
    property real collapseY: topMargin + 20
    property int collapseDuration: 180
    property bool pullRelease: false
    property real flightStart: 0
    property real flightEnd: 0
    readonly property real flightFraction: Math.abs(flightEnd - flightStart) < 1 ? 0 : Math.max(0, Math.min(1, (centerY - flightStart) / (flightEnd - flightStart)))
    property real stretch: phase === "travel" ? Math.sin(flightFraction * Math.PI) * 0.65 : 0
    Behavior on stretch {
        // Retargeting flight must not snap an elongated dot back to a circle.
        NumberAnimation {
            duration: Motion.ms(80)
            easing.type: Easing.OutCubic
        }
    }
    readonly property bool centered: scene === "LAUNCHER"
    readonly property real destinationY: centered ? screenHeight / 2 : topMargin + targetHeight / 2
    readonly property bool busy: phase !== "rest"
    readonly property bool contentReady: phase === "rest" || phase === "expand"

    function stop() {
        shrink.stop();
        hold.stop();
        flight.stop();
        bloom.stop();
        resize.stop();
        fade.stop();
    }
    function settle() {
        if (!ready || suspended)
            return;
        if (direct) {
            stop();
            phase = "rest";
            reveal = 1;
            pullRelease = true;
            bodyWidth = targetWidth;
            bodyHeight = targetHeight;
            centerY = destinationY;
        } else if (phase === "rest") {
            resize.restart();
        }
    }
    function request() {
        if (!ready)
            return;
        var old = previousScene;
        previousScene = scene;
        if (suspended) {
            stop();
            phase = "rest";
            reveal = 0;
            bodyWidth = 100;
            bodyHeight = 40;
            centerY = topMargin + 20;
            return;
        }
        if (direct) {
            settle();
            return;
        }
        var panels = ["LAUNCHER", "CLIPBOARD", "TRAY", "STATS", "WIFI", "BLUETOOTH"];
        if (scene === old || (!panels.includes(old) && !panels.includes(scene))) {
            settle();
            return;
        }
        // During the empty phase, simply steer the same dot to the new target.
        if (phase === "collapse" || phase === "dot")
            return;
        if (phase === "travel") {
            fly();
            return;
        }
        collapseY = old === "LAUNCHER" ? centerY : topMargin + 20;
        // Large panels need time to visibly contract, rather than vanishing
        // most of their width in one or two frames at the middle of the curve.
        collapseDuration = Math.round(180 + 160 * Math.max(0, Math.min(1, (Math.max(bodyWidth, bodyHeight) - 100) / 860)));
        pullRelease = false;
        stop();
        phase = "collapse";
        fade.to = 0;
        fade.duration = Motion.ms(80);
        fade.start();
        shrink.start();
    }
    function fly() {
        flight.stop();
        hold.stop();
        var landing = centered ? screenHeight / 2 : topMargin + 20;
        if (Math.abs(centerY - landing) < 1) {
            expand();
            return;
        }
        phase = "travel";
        flightStart = centerY;
        flightEnd = landing;
        flight.to = landing;
        flight.start();
    }
    function expand() {
        phase = "expand";
        bloom.restart();
        fade.to = 1;
        fade.duration = Motion.ms(240);
        fade.start();
    }
    onSceneChanged: request()
    onSuspendedChanged: {
        if (suspended)
            request();
        else {
            reveal = 1;
            Qt.callLater(settle);
        }
    }
    onDirectChanged: Qt.callLater(settle)
    onTargetWidthChanged: Qt.callLater(settle)
    onTargetHeightChanged: Qt.callLater(settle)
    onScreenHeightChanged: {
        if (phase === "travel")
            fly();
        else
            Qt.callLater(settle);
    }
    Component.onCompleted: {
        previousScene = scene;
        bodyWidth = targetWidth;
        bodyHeight = targetHeight;
        centerY = destinationY;
        ready = true;
    }
    NumberAnimation {
        id: fade
        target: motion
        property: "reveal"
        easing.type: Easing.OutCubic
    }
    ParallelAnimation {
        id: shrink
        NumberAnimation {
            target: motion
            property: "bodyWidth"
            to: 18
            duration: Motion.ms(motion.collapseDuration)
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: motion
            property: "bodyHeight"
            to: 18
            duration: Motion.ms(motion.collapseDuration)
            easing.type: Easing.InOutCubic
        }
        // Collapse a top drawer toward its header; a launcher toward its center.
        NumberAnimation {
            target: motion
            property: "centerY"
            to: motion.collapseY
            duration: Motion.ms(motion.collapseDuration)
            easing.type: Easing.InOutCubic
        }
        onFinished: {
            motion.phase = "dot";
            hold.start();
        }
    }
    Timer {
        id: hold
        interval: Motion.ms(45)
        onTriggered: motion.fly()
    }
    NumberAnimation {
        id: flight
        target: motion
        property: "centerY"
        duration: Motion.ms(350)
        easing.type: Easing.InOutQuint
        onFinished: motion.expand()
    }
    ParallelAnimation {
        id: bloom
        NumberAnimation {
            target: motion
            property: "bodyWidth"
            to: motion.targetWidth
            duration: Motion.ms(460)
            easing.type: Easing.OutBack
            easing.overshoot: 0.65
        }
        NumberAnimation {
            target: motion
            property: "bodyHeight"
            to: motion.targetHeight
            duration: Motion.ms(500)
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: motion
            property: "centerY"
            to: motion.destinationY
            duration: Motion.ms(500)
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        onFinished: {
            motion.phase = "rest";
            motion.settle();
        }
    }
    ParallelAnimation {
        id: resize
        NumberAnimation {
            target: motion
            property: "bodyWidth"
            to: motion.targetWidth
            duration: Motion.ms(380)
            easing.type: motion.pullRelease ? Easing.OutQuint : Easing.OutBack
            easing.overshoot: 0.4
        }
        // Pull releases retain a monotonic trajectory into the drawer.
        NumberAnimation {
            target: motion
            property: "bodyHeight"
            to: motion.targetHeight
            duration: Motion.ms(380)
            easing.type: Easing.OutQuint
        }
        NumberAnimation {
            target: motion
            property: "centerY"
            to: motion.destinationY
            duration: Motion.ms(380)
            easing.type: Easing.OutQuint
        }
    }
}
