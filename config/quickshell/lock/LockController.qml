import QtQml
import Quickshell.Services.Pam

QtObject {
    id: root
    required property var pam
    required property bool secure
    property string phase: "LOCK_REQUESTED"
    property string feedback: ""
    property bool error: false
    property int failures: 0
    readonly property bool accepting: secure && pam.active && pam.responseRequired && phase === "AUTHENTICATING"
    readonly property bool busy: secure && pam.active && !pam.responseRequired
    readonly property string prompt: pam.responseRequired && pam.responseVisible ? pam.message : "Password"
    signal clearSecrets
    signal authenticated
    function retry() {
        if (!secure || pam.active || phase === "UNLOCKING")
            return;
        phase = "AUTHENTICATING";
        if (!pam.start()) {
            phase = "LOCK_ACQUIRED";
            error = true;
            feedback = "Authentication unavailable · click ↵ to retry";
        }
    }
    function submit(response) {
        if (!accepting) {
            clearSecrets();
            return;
        }
        error = false;
        feedback = "";
        pam.respond(response);
        clearSecrets();
    }
    onSecureChanged: {
        if (secure && phase === "LOCK_REQUESTED") {
            phase = "LOCK_ACQUIRED";
            retry();
        } else if (!secure)
            clearSecrets();
    }
    Component.onCompleted: {
        if (secure)
            retry();
    }
    property Connections pamSignals: Connections {
        target: root.pam
        function onPamMessage() {
            if (root.pam.responseRequired && root.pam.responseVisible)
                root.feedback = root.pam.message;
        }
        function onError() {
            root.clearSecrets();
            root.error = true;
            root.feedback = "Authentication unavailable · click ↵ to retry";
        }
        function onCompleted(result) {
            root.clearSecrets();
            if (!root.secure || root.phase !== "AUTHENTICATING")
                return;
            if (result === PamResult.Success) {
                root.phase = "UNLOCKING";
                root.authenticated();
            } else {
                root.phase = "LOCK_ACQUIRED";
                root.error = true;
                root.failures++;
                root.feedback = result === PamResult.Error ? "Authentication unavailable · click ↵ to retry" : "Not accepted · try again";
                if (result === PamResult.Failed)
                    Qt.callLater(root.retry);
            }
        }
    }
}
