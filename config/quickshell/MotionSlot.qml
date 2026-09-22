import QtQuick

Item {
    id: root
    property bool active: false
    property int enterDelay: 80
    property bool revealed: false
    onActiveChanged: {
        revealDelay.stop();
        if (active)
            revealDelay.restart();
        else
            revealed = false;
    }
    Component.onCompleted: {
        if (active)
            revealDelay.start();
    }
    Timer {
        id: revealDelay
        interval: Motion.ms(root.enterDelay)
        onTriggered: root.revealed = root.active
    }
    opacity: revealed ? 1 : 0
    visible: opacity > 0.001
    enabled: active
    transform: Translate {
        y: root.revealed ? 0 : 4
        Behavior on y {
            NumberAnimation {
                duration: Motion.ms(260)
                easing.type: Easing.OutCubic
            }
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Motion.ms(160)
            easing.type: Easing.OutCubic
        }
    }
}
