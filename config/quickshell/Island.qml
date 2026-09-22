import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property var machine
    required property var services
    required property var theme
    required property var settings
    property var destination: null
    property real hopWidth: 1
    property real hopY: 0
    readonly property bool canHop: !machine.locked && !machine.captured && !surface.interacting && machine.state !== "WORKSPACES"
    readonly property string candidate: services.cursorScreen || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: !machine.locked
    WlrLayershell.namespace: "island"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only the launcher is modal. Cards consume input within their actual
    // rounded bounds; clicks and keyboard focus elsewhere belong to windows.
    WlrLayershell.keyboardFocus: surface.modal ? WlrKeyboardFocus.Exclusive : surface.cardOpen || surface.radioOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region {
        item: surface.modal ? surface : surface.capsuleItem
        radius: surface.modal ? 0 : surface.capsuleItem.radius
        Region {
            item: surface.wifiBubbleItem.visible ? surface.wifiBubbleItem : null
            radius: 18
        }
        Region {
            item: surface.bluetoothBubbleItem.visible ? surface.bluetoothBubbleItem : null
            radius: 18
        }
    }
    IslandSurface {
        id: surface
        anchors.fill: parent
        machine: root.machine
        services: root.services
        theme: root.theme
        settings: root.settings
        hostWindow: root
        hopWidth: root.hopWidth
        hopY: root.hopY
        hopping: hop.running
    }
    onCandidateChanged: focusDelay.restart()
    onCanHopChanged: {
        if (canHop)
            focusDelay.restart();
    }
    Component.onCompleted: focusDelay.start()
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (!root.screen || !Quickshell.screens.some(s => s.name === root.screen.name)) {
                hop.stop();
                root.hopWidth = 1;
                root.hopY = 0;
                root.machine.dismiss();
                if (Quickshell.screens.length)
                    root.screen = Quickshell.screens[0];
            }
            focusDelay.restart();
        }
    }
    Timer {
        id: focusDelay
        interval: root.settings.focusDelay
        onTriggered: {
            if (!root.canHop || hop.running)
                return;
            var target = Quickshell.screens.find(s => s.name === root.candidate) || Quickshell.screens[0];
            if (!target || (root.screen && root.screen.name === target.name))
                return;
            root.destination = target;
            hop.start();
        }
    }
    SequentialAnimation {
        id: hop
        onStopped: focusDelay.restart()
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "hopWidth"
                to: 0.16
                duration: Motion.ms(110)
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: root
                property: "hopY"
                to: 8
                duration: Motion.ms(110)
                easing.type: Easing.OutCubic
            }
        }
        NumberAnimation {
            target: root
            property: "hopY"
            to: -65
            duration: Motion.ms(110)
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                var target = Quickshell.screens.includes(root.destination) ? root.destination : Quickshell.screens[0];
                if (target)
                    root.screen = target;
            }
        }
        NumberAnimation {
            target: root
            property: "hopY"
            to: 0
            duration: Motion.ms(320)
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
        NumberAnimation {
            target: root
            property: "hopWidth"
            to: 1
            duration: Motion.ms(220)
            easing.type: Easing.OutCubic
        }
    }
}
