import QtQuick
import ".."

QtObject {
    id: root
    required property var controller
    property real progress: 0
    readonly property bool authorized: controller.secure && controller.phase === "UNLOCKING"
    signal readyForUnlock

    // One shared timeline for every output. Animation completion alone cannot unlock.
    property Connections authentication: Connections {
        target: root.controller
        function onAuthenticated() {
            if (root.authorized && !outro.running && root.progress === 0)
                outro.start();
        }
    }
    onAuthorizedChanged: {
        if (!authorized) {
            outro.stop();
            progress = 0;
        }
    }
    property NumberAnimation outro: NumberAnimation {
        id: outro
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Motion.ms(900)
        onFinished: {
            if (root.authorized && root.progress === 1)
                root.readyForUnlock();
        }
    }
}
