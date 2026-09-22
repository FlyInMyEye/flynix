import QtQuick
import Quickshell

Item {
    id: root
    required property var machine
    required property var services
    required property var theme
    property bool showClock: false
    property var lastNotice: null
    Connections {
        target: root.machine
        function onCurrentChanged() {
            if (root.machine.current)
                root.lastNotice = root.machine.current;
        }
    }
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    readonly property string elapsed: {
        var seconds = Math.floor((clock.date.getTime() - services.recordingSince) / 1000);
        return String(Math.max(0, Math.floor(seconds / 60))).padStart(2, "0") + ":" + String(Math.max(0, seconds % 60)).padStart(2, "0");
    }
    MotionSlot {
        anchors.fill: parent
        active: root.showClock || ["IDLE", "HOVER_TIME"].includes(root.machine.state)
        enterDelay: 0
        property real extension: root.machine.state === "HOVER_TIME" && !root.showClock ? 1 : 0
        Behavior on extension {
            NumberAnimation {
                duration: Motion.ms(300)
                easing.type: Easing.OutCubic
            }
        }
        Item {
            id: timeGroup
            objectName: "clockGroup"
            anchors.centerIn: parent
            width: minutes.implicitWidth + secondsClip.width
            height: 40
            Text {
                id: minutes
                anchors.verticalCenter: parent.verticalCenter
                text: root.services.recording ? root.elapsed : root.services.idleFrame && !root.showClock ? (root.services.idleFrame % 2 ? "-_-" : "°_°") : Qt.formatDateTime(clock.date, "hh:mm")
                color: root.theme.fg
                font {
                    pixelSize: 13
                    family: root.theme.mono
                    weight: Font.Medium
                    letterSpacing: 0.3
                }
            }
            Item {
                id: secondsClip
                anchors {
                    left: minutes.right
                    verticalCenter: parent.verticalCenter
                }
                width: root.services.recording ? 0 : secondText.implicitWidth * parent.parent.extension
                height: 40
                clip: true
                opacity: parent.parent.extension
                Text {
                    id: secondText
                    anchors.verticalCenter: parent.verticalCenter
                    text: ":" + Qt.formatDateTime(clock.date, "ss")
                    color: root.theme.muted
                    font {
                        pixelSize: 13
                        family: root.theme.mono
                        weight: Font.Medium
                        letterSpacing: 0.3
                    }
                }
            }
        }
        Item {
            anchors.centerIn: parent
            width: 270
            height: 40
            opacity: parent.extension
            Text {
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd")
                color: root.theme.muted
                font {
                    pixelSize: 12
                    family: root.theme.font
                }
            }
            Text {
                anchors {
                    right: parent.right
                    rightMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: Qt.formatDateTime(clock.date, "d MMM")
                color: root.theme.muted
                font {
                    pixelSize: 12
                    family: root.theme.font
                }
            }
        }
        Repeater {
            model: root.services.shelf.length && !root.showClock ? 2 : 0
            Rectangle {
                required property int index
                width: 3
                height: 3
                radius: 2
                color: root.theme.accent
                x: parent.width / 2 + (index ? 42 : -45)
                anchors.verticalCenter: parent.verticalCenter
                opacity: 1 - parent.extension
            }
        }
    }
    MotionSlot {
        anchors.fill: parent
        active: root.machine.state === "WORKSPACES"
        WorkspaceStrip {
            anchors.centerIn: parent
            width: implicitWidth
            height: 40
            theme: root.theme
            workspaces: root.services.workspaces
            presented: parent.revealed
        }
    }
    MotionSlot {
        anchors.fill: parent
        active: root.machine.state === "HARDWARE"
        Row {
            anchors.centerIn: parent
            spacing: 12
            Text {
                text: root.machine.hardwareKind === "brightness" ? "󰃠" : root.machine.hardwareMuted ? "󰝟" : "󰕾"
                color: root.theme.muted
                font {
                    family: root.theme.icons
                    pixelSize: 16
                }
            }
            Rectangle {
                width: 100
                height: 3
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.theme.altBg
                Rectangle {
                    width: parent.width * (root.machine.hardwareMuted ? 0 : root.machine.hardwareValue)
                    height: 3
                    radius: 2
                    color: root.theme.accent
                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.ms(180)
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            Text {
                text: Math.round(root.machine.hardwareValue * 100)
                color: root.theme.fg
                font {
                    pixelSize: 11
                    family: root.theme.mono
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    MotionSlot {
        anchors.fill: parent
        active: root.machine.state === "TRANSIENT"
        Text {
            id: notice
            objectName: "noticeText"
            anchors {
                fill: parent
                leftMargin: 22
                rightMargin: 22
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.lastNotice ? (root.lastNotice.kind === "media" ? "♫  " : root.lastNotice.critical ? "!  " : "") + root.lastNotice.text : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: root.lastNotice && root.lastNotice.critical ? root.theme.red : root.theme.fg
            font {
                pixelSize: root.lastNotice && root.lastNotice.kind === "score" ? 18 : 12
                family: root.theme.font
                weight: Font.Medium
            }
            onTextChanged: appear.restart()
            NumberAnimation {
                id: appear
                target: notice
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.ms(200)
            }
        }
    }
}
