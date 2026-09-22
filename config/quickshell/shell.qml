import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    Theme {
        id: islandTheme
    }
    Settings {
        id: islandSettings
    }
    StateMachine {
        id: stateMachine
    }
    Services {
        id: systemServices
        machine: stateMachine
        settings: islandSettings
    }
    Shortcuts {
        machine: stateMachine
        services: systemServices
        onLockRequested: root.lock()
    }
    Island {
        machine: stateMachine
        services: systemServices
        theme: islandTheme
        settings: islandSettings
    }
    ReservedSpace {
        settings: islandSettings
    }

    function lock() {
        if (stateMachine.locked || locker.running || lockPreflight.running)
            return;
        stateMachine.beginLock();
        lockPreflight.running = true;
    }
    Component.onCompleted: Quickshell.watchFiles = true
    Connections {
        target: stateMachine
        function onLockedChanged() {
            Quickshell.watchFiles = !stateMachine.locked;
        }
    }
    Process {
        id: lockPreflight
        command: ["test", "-r", "/etc/pam.d/" + islandSettings.pamService]
        onExited: (code, status) => {
            if (code === 0 && status === 0)
                locker.running = true;
            else {
                // No protocol request has been made: restore normal UI and
                // report the missing service rather than create an unusable lock.
                stateMachine.lockClientSucceeded();
                stateMachine.notify("Lock service is not installed", "warning", true, "lock-setup");
            }
        }
    }
    LockProcess {
        id: locker
        onExited: (code, status) => {
            if (code === 0 && status === 0)
                stateMachine.lockClientSucceeded();
            else
                console.error("Island lock client stopped. If locked, use the documented TTY recovery procedure.");
        }
    }
}
