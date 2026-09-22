import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property color bg: "#10131b"
    property color fg: "#e5e9f0"
    property color altBg: "#202635"
    property color muted: Qt.alpha(fg, 0.58)
    property color accent: "#a5b4fc"
    property color red: "#fb7185"
    property color green: "#86efac"
    property string font: "JetBrainsMono Nerd Font" 
    property string mono: "JetBrainsMono Nerd Font Mono"
    property string icons: "JetBrainsMono Nerd Font"
    FileView {
        path: Qt.resolvedUrl("colors.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var c = JSON.parse(text());
                for (var key of ["bg", "fg", "altBg", "accent", "red", "green"])
                    if (c[key])
                        root[key] = c[key];
            } catch (e) {
                console.warn("Island: invalid theme JSON");
            }
        }
    }
}
