import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import ".."

ShellRoot {
    id: root
    Theme {
        id: lockTheme
    }
    Settings {
        id: settings
    }
    Component.onCompleted: {
        Quickshell.watchFiles = false;
        sessionLock.locked = true;
    }
    PamContext {
        id: pam
        config: settings.pamService
    }
    LockController {
        id: authentication
        pam: pam
        secure: sessionLock.secure
    }
    LockExit {
        id: departure
        controller: authentication
        onReadyForUnlock: {
            if (!sessionLock.secure || authentication.phase !== "UNLOCKING" || progress !== 1)
                return;
            sessionLock.locked = false; // PAM-authorized release after the shared outro.
            Qt.quit();
        }
    }
    WlSessionLock {
        id: sessionLock
        WlSessionLockSurface {
            color: lockTheme.bg
            LockView {
                anchors.fill: parent
                theme: lockTheme
                controller: authentication
                exitProgress: departure.progress
                wallpaper: settings.lockWallpaper
            }
        }
    }
}
