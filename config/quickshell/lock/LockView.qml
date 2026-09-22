import QtQuick
import QtQuick.Controls
import Quickshell
import ".."

Item {
    id: root
    required property var theme
    required property var controller
    required property url wallpaper
    property string userName: Quickshell.env("USER") || ""
    property real entrance: 0
    property real shake: 0
    property real exitProgress: 0
    property real typingPulse: 0
    readonly property bool departing: controller.phase === "UNLOCKING"
    readonly property real collapse: easeOut((exitProgress - 0.15) / 0.5)
    readonly property real flight: easeInOut((exitProgress - 0.35) / 0.65)
    function clamp(value) { return Math.max(0, Math.min(1, value)); }
    function easeOut(value) { return 1 - Math.pow(1 - clamp(value), 3); }
    function easeInOut(value) { var t = clamp(value); return t * t * (3 - 2 * t); }
    function enter() {
        entrance = 0;
        entranceMotion.restart();
        if (backdrop.status === Image.Ready)
            wallpaperFade.restart();
    }
    Component.onCompleted: { if (visible) enter(); }
    onVisibleChanged: { if (visible) enter(); }
    NumberAnimation {
        id: entranceMotion
        target: root
        property: "entrance"
        to: 1
        duration: Motion.ms(700)
        easing.type: Easing.OutQuint
    }
    Rectangle {
        anchors.fill: parent
        color: root.theme.bg
    }
    Image {
        id: backdrop
        objectName: "lockWallpaper"
        property real reveal: 0
        anchors.fill: parent
        source: root.wallpaper
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width * 1.1, root.height * 1.1)
        scale: 1.035 + (1 - reveal) * 0.04 + root.exitProgress * 0.025
        opacity: 0.68 * reveal * (1 - root.easeInOut(root.exitProgress))
        onStatusChanged: {
            if (status === Image.Ready && root.visible)
                wallpaperFade.restart();
        }
        NumberAnimation {
            id: wallpaperFade
            target: backdrop
            property: "reveal"
            from: 0
            to: 1
            duration: Motion.ms(800)
            easing.type: Easing.InOutCubic
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#5510131b"
            }
            GradientStop {
                position: 0.48
                color: "#1010131b"
            }
            GradientStop {
                position: 1
                color: "#e610131b"
            }
        }
    }
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    Column {
        x: root.width < 700 ? (root.width - width) / 2 : 64
        y: Math.max(42, root.height * 0.14) - (1 - root.entrance) * 18 - root.exitProgress * 24
        spacing: 8
        opacity: root.entrance * (1 - root.easeOut(root.exitProgress / 0.8))
        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: root.theme.fg
            font {
                family: root.theme.mono
                pixelSize: root.width < 700 ? 64 : 96
                weight: Font.Light
                letterSpacing: -5
            }
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.alpha(root.theme.fg, 0.65)
            font {
                family: root.theme.font
                pixelSize: 13
                letterSpacing: 1
            }
        }
    }
    Rectangle {
        id: capsule
        objectName: "lockCapsule"
        x: (root.width - width) / 2 + root.shake
        y: 8 + root.entrance * (Math.max(120, root.height * 0.72) - 8) * (1 - root.flight)
        property real restingWidth: Math.min(root.width - 40, root.controller.accepting && password.activeFocus ? 400 : 370)
        width: restingWidth * (1 - root.collapse) + 18 * root.collapse
        height: 64 - 46 * root.collapse
        radius: height / 2
        scale: 1 + root.typingPulse * 0.012
        opacity: 1 - root.clamp((root.exitProgress - 0.87) / 0.13)
        clip: true
        color: Qt.alpha(root.theme.bg, 0.96)
        border.width: 1
        border.color: root.departing ? root.theme.green : root.controller.error ? root.theme.red : Qt.alpha(root.theme.accent, 0.5 + root.typingPulse * 0.45)
        Behavior on restingWidth {
            enabled: !root.departing
            NumberAnimation {
                duration: Motion.ms(220)
                easing.type: Easing.OutBack
                easing.overshoot: 0.5
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Motion.ms(220)
            }
        }
        Canvas {
            opacity: 1 - root.clamp(root.exitProgress / 0.3)
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 26
            property color ink: root.controller.error ? root.theme.red : root.theme.accent
            onInkChanged: requestPaint()
            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.strokeStyle = ink;
                c.lineWidth = 1.8;
                c.lineCap = "round";
                c.beginPath();
                c.arc(11, 9, 5, Math.PI, 2 * Math.PI);
                c.lineTo(16, 12);
                c.moveTo(6, 9);
                c.lineTo(6, 12);
                c.stroke();
                c.strokeRect(3, 12, 16, 11);
                c.beginPath();
                c.moveTo(11, 16);
                c.lineTo(11, 19);
                c.stroke();
            }
        }
        TextField {
            id: password
            objectName: "lockPassword"
            anchors {
                left: parent.left
                right: action.left
                verticalCenter: parent.verticalCenter
                leftMargin: 58
                rightMargin: 10
            }
            height: 50
            opacity: 1 - root.clamp(root.exitProgress / 0.2)
            scale: 1 + root.typingPulse * 0.035
            transformOrigin: Item.Left
            enabled: root.controller.accepting
            echoMode: TextInput.Password
            passwordCharacter: "•"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            placeholderText: root.controller.busy ? "Verifying…" : root.controller.secure ? root.controller.prompt : "Securing session…"
            placeholderTextColor: root.theme.muted
            color: root.theme.fg
            font {
                family: root.theme.font
                pixelSize: 14
                letterSpacing: 1
            }
            background: null
            selectByMouse: false
            onTextEdited: {
                root.typingPulse = 1;
                keystroke.restart();
            }
            focus: enabled
            onEnabledChanged: {
                if (enabled)
                    forceActiveFocus();
                else
                    clear();
            }
            onAccepted: {
                root.controller.submit(text);
                clear();
            }
            Keys.onEscapePressed: clear()
            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && [Qt.Key_C, Qt.Key_V, Qt.Key_X, Qt.Key_Insert].includes(event.key))
                    event.accepted = true;
                if ((event.modifiers & Qt.ShiftModifier) && [Qt.Key_Insert, Qt.Key_Delete, Qt.Key_F10].includes(event.key))
                    event.accepted = true;
                if (event.key === Qt.Key_Menu)
                    event.accepted = true;
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.MiddleButton
            }
        }
        Rectangle {
            id: action
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: 40
            height: 40
            radius: 20
            color: actionMouse.containsMouse ? root.theme.accent : root.theme.altBg
            opacity: (root.controller.secure ? 1 : 0.3) * (1 - root.clamp(root.exitProgress / 0.4))
            Text {
                id: actionGlyph
                anchors.centerIn: parent
                text: root.departing ? "✓" : root.controller.busy ? "·" : "↵"
                color: root.departing ? root.theme.green : actionMouse.containsMouse ? root.theme.bg : root.theme.accent
                font {
                    family: root.theme.font
                    pixelSize: 22
                }
                SequentialAnimation on opacity {
                    running: root.controller.busy
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.25
                        duration: Motion.ms(650)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1
                        duration: Motion.ms(650)
                        easing.type: Easing.InOutSine
                    }
                    onStopped: actionGlyph.opacity = 1
                }
            }
            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.controller.secure && !root.controller.busy && !root.departing
                onClicked: {
                    if (root.controller.accepting)
                        root.controller.submit(password.text);
                    else
                        root.controller.retry();
                    password.clear();
                }
            }
        }
    }
    Text {
        opacity: root.entrance * (1 - root.clamp(root.exitProgress / 0.25))
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: capsule.bottom
            topMargin: 17
        }
        width: Math.max(100, root.width - 64)
        text: root.controller.error ? root.controller.feedback : root.userName
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: root.controller.error ? root.theme.red : Qt.alpha(root.theme.fg, 0.5)
        font {
            family: root.theme.font
            pixelSize: 12
        }
    }
    Connections {
        target: root.controller
        function onClearSecrets() {
            password.clear();
        }
        function onFailuresChanged() {
            rejection.restart();
        }
    }
    NumberAnimation {
        id: keystroke
        target: root
        property: "typingPulse"
        to: 0
        duration: Motion.ms(380)
        easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: rejection
        NumberAnimation {
            target: root
            property: "shake"
            to: -9
            duration: Motion.ms(60)
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 7
            duration: Motion.ms(90)
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -4
            duration: Motion.ms(80)
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: Motion.ms(100)
            easing.type: Easing.OutCubic
        }
    }
}
