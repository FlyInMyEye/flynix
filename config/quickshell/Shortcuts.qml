import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root
    required property var machine
    required property var services
    signal lockRequested
    property bool leftHeld: false
    property bool rightHeld: false
    function updateHold() {
        machine.setFlag("workspace", leftHeld || rightHeld);
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "super-held"
        onPressed: {
            root.leftHeld = true;
            root.updateHold();
        }
        onReleased: {
            root.leftHeld = false;
            root.updateHold();
        }
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "super-right"
        onPressed: {
            root.rightHeld = true;
            root.updateHold();
        }
        onReleased: {
            root.rightHeld = false;
            root.updateHold();
        }
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        onPressed: root.machine.toggle("launcher")
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        onPressed: root.lockRequested()
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "volume-up"
        onPressed: root.services.adjust("volume", "up")
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "volume-down"
        onPressed: root.services.adjust("volume", "down")
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "volume-mute"
        onPressed: root.services.adjust("volume", "mute")
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "brightness-up"
        onPressed: root.services.adjust("brightness", "up")
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "brightness-down"
        onPressed: root.services.adjust("brightness", "down")
    }
    IpcHandler {
        target: "island"
        function status(): string {
            return root.machine.state;
        }
        function launcher(): void {
            root.machine.toggle("launcher");
        }
        function clipboard(): void {
            root.machine.toggle("clipboard");
        }
        function stats(): void {
            root.machine.toggle("stats");
        }
        function lock(): void {
            root.lockRequested();
        }
        function screenshot(): void {
            if (!root.machine.locked) {
                root.machine.screenshot();
                root.machine.notify("Screenshot saved", "notice", false, "screenshot");
            }
        }
        function notify(text: string, critical: bool): void {
            root.machine.notify(text, "notice", critical, "");
        }
        function recording(active: bool): void {
            if (!root.machine.locked) {
                root.services.recordingOverride = active ? 1 : 0;
                if (active && !root.services.recording)
                    root.services.recordingSince = Date.now();
                root.services.recording = active;
            }
        }
        function audio(value: real): void {
            if (!root.machine.locked && root.services.player && root.services.player.isPlaying)
                root.services.amplitude = Math.max(0, Math.min(1, value));
        }
    }
}
