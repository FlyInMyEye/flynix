import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property var settings
    // A separate three-anchor surface reserves a constant strip. The animated
    // island uses four anchors and cannot itself create an exclusive zone.
    // Keep it on every output so hopping never rearranges the user's windows.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Math.max(1, root.settings.reservedHeight)
            exclusiveZone: root.settings.reservedHeight
            visible: root.settings.reservedHeight > 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.namespace: "island-reserved"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        }
    }
}
