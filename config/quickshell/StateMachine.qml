import QtQuick
import Quickshell
import "logic/State.js" as Logic

Scope {
    id: root
    property var data: Logic.initial()
    property int revision: 0
    property double now: Date.now()
    readonly property string state: {
        revision;
        return Logic.state(data, now);
    }
    readonly property bool locked: {
        revision;
        return data.locked;
    }
    readonly property bool captured: {
        revision;
        return data.launcher || data.tray || data.clipboard || data.stats || data.wifi || data.bluetooth || data.dragging || data.pointerCapture;
    }
    readonly property bool dragging: {
        revision;
        return data.dragging;
    }
    readonly property var current: {
        revision;
        return data.current ? Object.assign({}, data.current) : null;
    }
    property string hardwareKind: "volume"
    property real hardwareValue: 0
    property bool hardwareMuted: false
    property bool hovered: false
    property double previousTick: Date.now()
    signal screenshot

    function settleTime() {
        var time = Date.now();
        Logic.tick(data, Math.max(0, time - previousTick), now);
        previousTick = time;
        now = time;
    }

    function setFlag(name, value) {
        if (locked)
            return;
        if (data[name] === value)
            return;
        settleTime();
        data[name] = value;
        revision++;
    }
    function toggle(name) {
        if (locked)
            return;
        settleTime();
        var next = !data[name];
        Logic.dismiss(data);
        data[name] = next;
        data.hover = hovered;
        revision++;
    }
    function open(name) {
        if (!locked && !data[name])
            toggle(name);
    }
    function finishClipboardPull(open) {
        if (locked)
            return;
        settleTime();
        if (open) {
            Logic.dismiss(data);
            data.clipboard = true;
            data.hover = hovered;
        }
        data.pointerCapture = false;
        revision++;
    }
    function dismiss() {
        if (!locked) {
            settleTime();
            Logic.dismiss(data);
            data.hover = hovered;
            revision++;
        }
    }
    function beginLock() {
        Logic.dismiss(data);
        data.workspace = false;
        data.workspaceUntil = 0;
        data.locked = true;
        data.current = null;
        data.queue = [];
        revision++;
    }
    // This only restores normal UI; compositor unlock belongs exclusively to PAM.
    function lockClientSucceeded() {
        data.locked = false;
        revision++;
    }
    function workspaceChanged() {
        if (locked)
            return;
        settleTime();
        data.workspaceUntil = Date.now() + 850;
        revision++;
    }
    function notify(text, kind, critical, key) {
        if (locked)
            return;
        settleTime();
        Logic.enqueue(data, text, kind, critical, key);
        revision++;
    }
    function hardware(kind, value, muted) {
        if (locked)
            return;
        hardwareKind = kind;
        hardwareValue = Math.max(0, Math.min(1, value));
        hardwareMuted = !!muted;
        data.hardwareUntil = Date.now() + 2000;
        revision++;
    }
    function hover(value) {
        if (locked || hovered === value)
            return;
        hovered = value;
        setFlag("hover", value);
    }
    Timer {
        interval: 50
        repeat: true
        running: !root.locked
        onTriggered: {
            var time = Date.now();
            Logic.tick(root.data, time - root.previousTick, time);
            root.previousTick = time;
            root.now = time;
            root.revision++;
        }
    }
}
