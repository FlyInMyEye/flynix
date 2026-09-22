// Pure arbitration/queue logic, shared by QML and the regression tests.
function initial() {
    return { locked: false, launcher: false, workspace: false, stats: false,
        tray: false, clipboard: false, wifi: false, bluetooth: false, hover: false, dragging: false, pointerCapture: false,
        hardwareUntil: 0, workspaceUntil: 0, queue: [], current: null, serial: 0 };
}

function state(s, now) {
    if (s.locked) return "LOCKING";
    if (s.launcher) return "LAUNCHER";
    if (s.workspace || (s.workspaceUntil > now && !s.clipboard && !s.tray && !s.wifi && !s.bluetooth)) return "WORKSPACES";
    if (s.wifi) return "WIFI";
    if (s.bluetooth) return "BLUETOOTH";
    if (s.stats) return "STATS";
    if (s.pointerCapture) return s.clipboard || s.dragging ? "CLIPBOARD" : "IDLE";
    // Critical alerts preempt tray/clipboard, but never a lock, launcher,
    // workspace hold or stats. Normal alerts respect active user capture.
    if (s.current && s.current.critical && !s.dragging) return "TRANSIENT";
    if (s.tray) return "TRAY";
    if (s.clipboard || s.dragging) return "CLIPBOARD";
    if (s.current) return "TRANSIENT";
    if (s.hardwareUntil > now) return "HARDWARE";
    return s.hover ? "HOVER_TIME" : "IDLE";
}

function enqueue(s, text, kind, critical, key) {
    // Coalesce repeated producers (clipboard combos, changing notification).
    if (key && s.current && s.current.key === key) {
        s.current.text = text;
        s.current.kind = kind || "notice";
        s.current.critical = !!critical;
        s.current.remaining = 3000;
        return;
    }
    var match = key ? s.queue.findIndex(function(n) { return n.key === key; }) : -1;
    if (match >= 0 && !critical) { s.queue[match].text = text; s.queue[match].kind = kind || "notice"; return; }
    if (match >= 0) s.queue.splice(match, 1);
    var item = { id: ++s.serial, text: text, kind: kind || "notice",
        critical: !!critical, key: key || "", remaining: 3000 };
    if (critical) {
        if (s.current) s.queue.unshift(s.current);
        s.current = item;
    } else if (!s.current) s.current = item;
    else s.queue.push(item);
    // Bound memory for noisy applications; retain the current item.
    if (s.queue.length > 100) s.queue.pop();
}

function tick(s, elapsed, now) {
    if (state(s, now) !== "TRANSIENT" || !s.current) return;
    s.current.remaining -= elapsed;
    if (s.current.remaining <= 0) s.current = s.queue.shift() || null;
}

function dismiss(s) {
    s.launcher = s.stats = s.tray = s.clipboard = s.wifi = s.bluetooth = s.dragging = s.pointerCapture = s.hover = false;
}

function localFiles(urls) {
    return urls.map(String).filter(function(url) {
        return /^file:\/\/(\/|localhost\/)/.test(url) && !/[\r\n\0]/.test(url);
    }).filter(function(url, index, all) { return all.indexOf(url) === index; });
}

if (typeof module !== "undefined") module.exports = { initial, state, enqueue, tick, dismiss, localFiles };
