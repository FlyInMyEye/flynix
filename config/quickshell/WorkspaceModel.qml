import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root
    // Keep the last confirmed workspace through focus handovers, special
    // workspaces and temporary nulls from Hyprland. Never invent workspace 1.
    property int activeId: 0
    property bool initialized: false
    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int candidate: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
    readonly property var occupied: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)
    readonly property var ids: {
        var values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        for (var id of occupied.concat([activeId]))
            if (id > 10 && !values.includes(id))
                values.push(id);
        return values.sort((a, b) => a - b);
    }
    signal switched
    function observe(id) {
        if (id <= 0 || id === activeId)
            return;
        var wasInitialized = initialized;
        activeId = id;
        initialized = true;
        if (wasInitialized)
            switched();
    }
    onCandidateChanged: observe(candidate)
    Component.onCompleted: observe(candidate)
    function activate(id) {
        if (id > 0)
            Hyprland.dispatch("workspace " + id);
    }
}
