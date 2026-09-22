import QtQuick
import Quickshell
import "logic/State.js" as Logic

Item {
    id: root
    required property var machine
    required property var services
    required property var theme
    required property var settings
    required property var hostWindow
    property real hopWidth: 1
    property real hopY: 0
    property bool hopping: false
    readonly property bool modal: machine.state === "LAUNCHER"
    readonly property bool cardOpen: machine.state === "CLIPBOARD" || machine.state === "TRAY"
    readonly property bool radioOpen: machine.state === "WIFI" || machine.state === "BLUETOOTH"
    readonly property bool radioInteracting: wifiBubble.interacting || bluetoothBubble.interacting || radioMerge.running
    readonly property bool bubblesAllowed: !machine.locked && !modal && !radioOpen && !hopping && !pulling && !motion.busy && width >= 320
    property real radioMergeProgress: 0
    property string pendingRadio: ""
    property string radioOrigin: ""
    function openRadio(kind) {
        if (!bubblesAllowed || radioMerge.running) return;
        machine.hover(false);
        radioOrigin = machine.state;
        pendingRadio = kind;
        radioMerge.restart();
    }
    NumberAnimation {
        id: radioMerge
        target: root; property: "radioMergeProgress"
        from: 0; to: 1
        duration: Motion.ms(460)
        easing.type: Easing.InOutCubic
        onFinished: {
            if (!root.machine.locked && root.pendingRadio && root.machine.state === root.radioOrigin)
                root.machine.open(root.pendingRadio);
            root.pendingRadio = "";
            root.radioMergeProgress = 0;
        }
    }
    Connections {
        target: root.machine
        function onStateChanged() {
            if (radioMerge.running && root.machine.state !== root.radioOrigin) {
                radioMerge.stop(); root.pendingRadio = ""; root.radioMergeProgress = 0;
            }
        }
    }
    property alias wifiBubbleItem: wifiBubble
    property alias bluetoothBubbleItem: bluetoothBubble
    readonly property bool transitioning: motion.busy
    readonly property string motionPhase: motion.phase
    readonly property bool interacting: motion.busy || gestures.pressed || relayProxy.Drag.active || machine.dragging || radioInteracting
    readonly property bool clipboardOpen: machine.state === "CLIPBOARD"
    readonly property real cardWidth: Math.min(340, Math.max(80, width - 24))
    readonly property real cardHeight: Math.max(80, Math.min(height - settings.topMargin - 12, 72 + Math.max(32, services.history.slice(0, 5).reduce((sum, entry) => sum + (entry.image ? 76 : 36), 0)) + (services.shelf.length ? 61 : 0)))
    readonly property real launcherWidth: Math.min(960, Math.max(80, width - 64))
    readonly property real launcherHeight: Math.min(640, Math.max(80, height - 80))
    property alias capsuleItem: capsule
    property alias dragProxy: relayProxy
    property real pull: 0
    property bool pulling: false
    property real pullStartWidth: 100
    property real pullStartHeight: 40
    property real flashOpacity: 0
    property real recordingOpacity: 0.4
    IslandMotion {
        id: motion
        targetWidth: capsule.targetWidth
        targetHeight: capsule.targetHeight
        topMargin: root.settings.topMargin
        screenHeight: root.height
        scene: root.machine.state
        direct: root.pulling || root.machine.dragging
        suspended: root.machine.locked
    }
    RadioBubble {
        id: wifiBubble
        kind: "wifi"
        theme: root.theme
        mergeProgress: root.radioMergeProgress
        merging: radioMerge.running
        homeX: Math.max(8, capsule.x - 48)
        homeY: root.settings.topMargin + 2 + root.hopY
        allowed: root.bubblesAllowed
        powered: root.services.radios.wifiEnabled
        connected: root.services.radios.currentNetwork !== null
        status: root.services.radios.wifiStatus
        onClicked: kind => root.openRadio(kind)
    }
    RadioBubble {
        id: bluetoothBubble
        kind: "bluetooth"
        theme: root.theme
        mergeProgress: root.radioMergeProgress
        merging: radioMerge.running
        homeX: Math.min(root.width - 44, capsule.x + capsule.width + 12)
        homeY: root.settings.topMargin + 2 + root.hopY
        allowed: root.bubblesAllowed
        powered: root.services.radios.bluetoothEnabled
        connected: root.services.radios.connectedDevices.length > 0
        status: root.services.radios.bluetoothStatus
        onClicked: kind => root.openRadio(kind)
    }
    LiquidBridge { bubble: wifiBubble; capsule: capsule; theme: root.theme }
    LiquidBridge { bubble: bluetoothBubble; capsule: capsule; theme: root.theme }
    Timer {
        objectName: "panelTimeout"
        interval: root.clipboardOpen ? root.settings.clipboardTimeout : root.settings.trayTimeout
        running: root.cardOpen && !motion.busy && interval > 0 && !hover.hovered && !root.interacting && !root.pulling
        onTriggered: root.machine.dismiss()
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#55090b12"
        opacity: root.modal ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.ms(250)
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.modal
            onClicked: root.machine.dismiss()
        }
    }
    Rectangle {
        id: capsule
        objectName: "capsule"
        readonly property real baseWidth: {
            switch (root.machine.state) {
            case "LAUNCHER":
                return root.launcherWidth;
            case "CLIPBOARD":
                return root.cardWidth;
            case "TRAY":
                return tray.desiredWidth;
            case "STATS":
                return Math.min(480, root.width - 24);
            case "WIFI":
            case "BLUETOOTH":
                return Math.min(380, root.width - 120);
            case "WORKSPACES":
                return root.services.workspaces.ids.length * 18 + 36;
            case "TRANSIENT":
                return Math.max(160, Math.min(480, messageMetrics.width + 52));
            case "HARDWARE":
                return 210;
            case "HOVER_TIME":
                return 270;
            default:
                return root.services.shelf.length ? 112 : 100;
            }
        }
        readonly property real targetWidth: Math.min(Math.max(80, root.width - 24), root.pulling ? root.pullStartWidth + root.pull * (root.cardWidth - root.pullStartWidth) : baseWidth)
        readonly property real targetHeight: root.pulling ? root.pullStartHeight + root.pull * (root.cardHeight - root.pullStartHeight) : root.modal ? root.launcherHeight : root.clipboardOpen ? root.cardHeight : root.radioOpen ? Math.min(370, root.height - root.settings.topMargin - 16) : root.machine.state === "TRAY" ? 40 + tray.desiredHeight : root.machine.state === "STATS" ? 218 : 40
        width: motion.bodyWidth * root.hopWidth / (1 + motion.stretch * 0.4)
        height: motion.bodyHeight * (1 + motion.stretch)
        x: (root.width - width) / 2
        y: motion.centerY - height / 2 + root.hopY
        property real cornerRadius: root.modal || root.clipboardOpen || root.radioOpen || root.pulling || root.machine.state === "STATS" ? 28 : 20
        radius: Math.min(width / 2, height / 2, cornerRadius)
        Behavior on cornerRadius {
            NumberAnimation {
                duration: Motion.ms(260)
                easing.type: Easing.OutCubic
            }
        }
        color: root.theme.bg
        border.color: root.services.recording ? Qt.alpha(root.theme.red, root.recordingOpacity) : Qt.alpha(root.theme.accent, 0.22)
        border.width: root.services.recording ? 1.5 : root.radioOpen ? 1 : 0
        clip: true
        transform: Scale {
            origin.x: capsule.width / 2
            origin.y: 20
            xScale: gestures.pressed && !root.pulling ? 0.96 : 1 + (root.cardOpen || root.modal || motion.busy ? 0 : root.services.amplitude * 0.025)
            yScale: gestures.pressed && !root.pulling ? 0.94 : 1
            Behavior on yScale {
                NumberAnimation {
                    duration: Motion.ms(200)
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.8
                }
            }
            Behavior on xScale {
                NumberAnimation {
                    duration: Motion.ms(100)
                    easing.type: Easing.OutCubic
                }
            }
        }
        HoverHandler {
            id: hover
            onHoveredChanged: {
                leaveDelay.stop();
                if (hovered && !root.radioInteracting)
                    root.machine.hover(true);
                else
                    leaveDelay.start();
            }
        }
        Timer {
            id: leaveDelay
            interval: 160
            onTriggered: root.machine.hover(false)
        }
        Item {
            id: header
            objectName: "islandHeader"
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(270, capsule.targetWidth)
            height: 40
            opacity: (motion.contentReady ? motion.reveal : 0) * (root.modal ? 0 : root.hopping ? Math.max(0, (root.hopWidth - 0.5) * 2) : 1)
            MouseArea {
                id: gestures
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                enabled: !root.modal && motion.contentReady
                property real startY: 0
                property bool moved: false
                onPressed: mouse => {
                    startY = mapToItem(root, mouse.x, mouse.y).y;
                    moved = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed || pressedButtons !== Qt.LeftButton || root.cardOpen || root.radioOpen)
                        return;
                    var delta = mapToItem(root, mouse.x, mouse.y).y - startY;
                    if (delta > 6 || root.pulling) {
                        moved = true;
                        if (!root.pulling) {
                            root.pullStartWidth = capsule.width;
                            root.pullStartHeight = capsule.height;
                            root.pull = 0;
                            root.pulling = true;
                            root.machine.setFlag("pointerCapture", true);
                        }
                        root.pull = Math.max(0, Math.min(1, delta / 170));
                    }
                }
                onReleased: {
                    if (root.pulling) {
                        var open = root.pull > 0.18;
                        // Commit the destination before releasing gesture geometry.
                        // The drawer never passes through an idle target or hides.
                        root.machine.finishClipboardPull(open);
                        root.pulling = false;
                        root.pull = 0;
                    }
                }
                onCanceled: {
                    root.pulling = false;
                    root.pull = 0;
                    root.machine.setFlag("pointerCapture", false);
                }
                onClicked: mouse => {
                    if (moved)
                        return;
                    if (mouse.button === Qt.RightButton)
                        root.machine.toggle("stats");
                    else if (mouse.button === Qt.MiddleButton)
                        root.machine.toggle("clipboard");
                    else if (root.cardOpen || root.radioOpen)
                        root.machine.dismiss();
                    else
                        root.machine.toggle("tray");
                }
                onWheel: wheel => {
                    root.services.adjust(wheel.modifiers & Qt.ShiftModifier ? "brightness" : "volume", wheel.angleDelta.y > 0 ? "up" : "down");
                    wheel.accepted = true;
                }
            }
            CapsuleContent {
                anchors.fill: parent
                machine: root.machine
                services: root.services
                theme: root.theme
                showClock: root.cardOpen || root.radioOpen || root.pulling || root.machine.state === "STATS"
            }
        }
        MotionSlot {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: Math.min(380, root.width - 120)
            height: Math.min(330, root.height - root.settings.topMargin - 56)
            active: root.radioOpen && motion.contentReady
            opacity: (revealed ? 1 : 0) * motion.reveal
            RadioPanel {
                anchors.fill: parent
                radios: root.services.radios
                theme: root.theme
                machine: root.machine
                active: root.radioOpen && !root.machine.locked
            }
        }
        MotionSlot {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: Math.min(480, root.width - 24)
            height: 178
            active: root.machine.state === "STATS" && motion.contentReady
            opacity: (revealed ? 1 : 0) * motion.reveal
            StatsCard {
                objectName: "statsCard"
                anchors.fill: parent
                services: root.services
                theme: root.theme
            }
        }
        Text {
            anchors.centerIn: parent
            visible: root.hopWidth < 0.3
            text: "•"
            color: root.theme.fg
            font.family: root.theme.font
        }
        MotionSlot {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: Math.min(root.width - 24, tray.desiredWidth)
            height: tray.desiredHeight
            active: root.machine.state === "TRAY" && motion.contentReady
            opacity: (revealed ? 1 : 0) * motion.reveal
            TrayDrawer {
                id: tray
                objectName: "trayDrawer"
                anchors.fill: parent
                machine: root.machine
                theme: root.theme
                window: root.hostWindow
                active: root.machine.state === "TRAY"
                maximumHeight: Math.max(60, root.height - root.settings.topMargin - 56)
            }
        }
        MotionSlot {
            objectName: "clipboardReveal"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: root.cardWidth
            height: root.cardHeight - 40
            active: (root.clipboardOpen || root.pulling) && motion.contentReady
            opacity: (revealed ? 1 : 0) * motion.reveal
            enterDelay: 100
            ClipboardCard {
                anchors.fill: parent
                machine: root.machine
                services: root.services
                theme: root.theme
                dragProxy: relayProxy
            }
        }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.launcherWidth
            height: root.launcherHeight
            // Remains in the focus tree during the empty/flight phases.
            visible: root.modal
            opacity: motion.contentReady ? motion.reveal : 0
            Launcher {
                anchors.fill: parent
                active: root.modal
                pointerReady: motion.contentReady
                machine: root.machine
                services: root.services
                theme: root.theme
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "white"
            opacity: root.flashOpacity
        }
        ProgressBorder {
            objectName: "mediaProgressBorder"
            anchors.fill: parent
            readonly property bool mediaNotice: root.machine.state === "TRANSIENT" && root.machine.current !== null && root.machine.current.kind === "media"
            visible: root.services.mediaAvailable && (root.settings.mediaProgressIdle || mediaNotice)
            // The outline belongs to the physical capsule, not its contents.
            // Keep it attached through collapse, the empty dot and flight.
            opacity: mediaNotice ? 1 : 0.45
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.ms(180)
                    easing.type: Easing.OutCubic
                }
            }
            progress: root.services.mediaProgress
            lineWidth: root.services.mediaPlaying ? 4 : 1.5
            Behavior on lineWidth {
                NumberAnimation {
                    duration: Motion.ms(220)
                    easing.type: Easing.OutCubic
                }
            }
            stroke: root.theme.accent
            radius: capsule.radius
        }
        DropArea {
            id: drop
            anchors.fill: parent
            onEntered: drag => {
                if (root.machine.locked || !drag.hasUrls || !Logic.localFiles(drag.urls).length) {
                    drag.accepted = false;
                    return;
                }
                if (relayProxy.Drag.active) {
                    relayProxy.inside = true;
                    return;
                }
                root.machine.open("clipboard");
                root.machine.setFlag("dragging", true);
            }
            onExited: {
                if (relayProxy.Drag.active && relayProxy.inside) {
                    root.services.consume(relayProxy.url);
                    relayProxy.inside = false;
                }
                root.machine.setFlag("dragging", false);
            }
            onDropped: event => {
                if (!relayProxy.Drag.active)
                    root.services.pin(event.urls);
                root.machine.setFlag("dragging", false);
                event.acceptProposedAction();
            }
        }
        Rectangle {
            anchors.fill: parent
            visible: root.machine.dragging
            color: Qt.alpha(root.theme.altBg, 0.94)
            radius: parent.radius
            Text {
                anchors.centerIn: parent
                text: "↓"
                color: root.theme.accent
                font {
                    family: root.theme.font
                    pixelSize: 26
                }
            }
        }
    }
    Item {
        id: relayProxy
        property string url: ""
        property bool inside: false
        width: 1
        height: 1
        // Keep the source alive while the chip is removed; copy semantics never
        // delete the real file, even when the one-use shelf chip is consumed.
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: ({
                "text/uri-list": url + "\r\n"
            })
        Drag.source: relayProxy
        Drag.onDragStarted: {
            inside = true;
            root.machine.setFlag("pointerCapture", true);
        }
        Drag.onDragFinished: {
            Drag.active = false;
            root.machine.setFlag("pointerCapture", false);
            inside = false;
        }
    }
    TextMetrics {
        id: messageMetrics
        font {
            family: root.theme.font
            pixelSize: 12
        }
        text: root.machine.current ? root.machine.current.text : ""
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.modal || root.cardOpen || root.radioOpen
        onActivated: root.machine.dismiss()
    }
    Connections {
        target: root.machine
        function onScreenshot() {
            flash.restart();
        }
    }
    SequentialAnimation {
        id: flash
        PropertyAction {
            target: root
            property: "flashOpacity"
            value: 0.85
        }
        NumberAnimation {
            target: root
            property: "flashOpacity"
            to: 0
            duration: Motion.ms(500)
            easing.type: Easing.OutCubic
        }
    }
    SequentialAnimation on recordingOpacity {
        running: root.services.recording
        loops: Animation.Infinite
        NumberAnimation {
            from: 0.35
            to: 1
            duration: Motion.ms(900)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: 1
            to: 0.35
            duration: Motion.ms(900)
            easing.type: Easing.InOutSine
        }
    }
}
