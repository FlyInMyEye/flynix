import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Wayland
import "logic/State.js" as Logic

Scope {
    id: root
    required property var machine
    required property var settings
    property bool enabled: true
    property alias radios: radioService
    RadioService {
        id: radioService
        machine: root.machine
    }
    property alias workspaces: workspaceModel
    WorkspaceModel {
        id: workspaceModel
        onSwitched: root.machine.workspaceChanged()
    }
    readonly property string helper: Quickshell.shellPath("scripts/island.py")
    property var history: []
    property var previews: ({})
    property var previewQueue: []
    property var shelf: []
    property alias shelfModel: shelfItems
    ListModel {
        id: shelfItems
    }
    property var fileResults: []
    property bool fileSearchBusy: false
    property string fileSearchError: ""
    property var appUsage: ({})
    property var usageQueue: []
    function launchApp(app) {
        if (machine.locked || !app)
            return;
        app.execute();
        if (app.id) {
            var usage = Object.assign({}, appUsage);
            usage[app.id] = {
                count: ((usage[app.id] || {}).count || 0) + 1,
                last: Date.now()
            };
            appUsage = usage;
            usageQueue = usageQueue.concat([
                {
                    id: app.id
                }
            ]);
            drainUsage();
        }
        machine.dismiss();
    }
    function drainUsage() {
        if (!enabled || usageProcess.running || !usageQueue.length)
            return;
        usageProcess.batch = usageQueue.slice(0, 100);
        usageQueue = usageQueue.slice(100);
        usageProcess.running = true;
    }
    Process {
        id: usageProcess
        property var batch: []
        command: ["python3", root.helper, "usage"]
        stdinEnabled: true
        onStarted: write(JSON.stringify(batch) + "\n")
        Component.onCompleted: {
            if (root.enabled)
                running = true;
        }
        stdout: SplitParser {
            onRead: line => {
                try {
                    var result = JSON.parse(line);
                    if (result.type !== "usage")
                        return;
                    var usage = result.entries;
                    for (var event of root.usageQueue) {
                        usage[event.id] = {
                            count: ((usage[event.id] || {}).count || 0) + 1,
                            last: (root.appUsage[event.id] || {}).last || Date.now()
                        };
                    }
                    root.appUsage = usage;
                } catch (_) {}
            }
        }
        onExited: Qt.callLater(root.drainUsage)
    }
    property var messages: []
    property string chatError: ""
    readonly property bool chatBusy: chatProcess.running
    property string cpu: "—"
    property string ram: "—"
    property string gpu: "—"
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    function appendSample(history, value) {
        return history.concat([typeof value === "number" && isFinite(value) ? Math.max(0, Math.min(100, value)) : null]).slice(-30);
    }
    property string cursorScreen: ""
    property bool recording: false
    property double recordingSince: 0
    property int recordingOverride: -1
    property real amplitude: 0
    property int idleFrame: 0
    property string lastHash: ""
    property double lastCopy: 0
    property int combo: 0
    property string comboKey: ""
    property double lastCpuAlert: 0
    property bool batteryWarned: false
    property var hardwareQueue: []
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Paused) || Mpris.players.values[0] || null
    property bool mediaPlaying: player !== null && player.isPlaying
    property bool mediaAvailable: mediaTimeline.available
    property real mediaProgress: mediaTimeline.progress
    readonly property alias mediaStatus: mediaTimeline
    MediaProgress {
        id: mediaTimeline
        player: root.player
        enabled: root.enabled && !root.machine.locked
    }
    property string lastTrack: ""
    property bool mediaInitialized: false
    property string restoredHash: ""
    property double restoredAt: 0
    property int highCpuSamples: 0

    function ingest(event) {
        if (machine.locked)
            return;
        switch (event.type) {
        case "stats":
            cpu = event.cpu + "%";
            ram = event.ram + "%";
            cpuHistory = appendSample(cpuHistory, event.cpu);
            ramHistory = appendSample(ramHistory, event.ram);
            var rec = recordingOverride < 0 ? event.recording : recordingOverride === 1;
            if (rec && !recording)
                recordingSince = Date.now();
            recording = rec;
            highCpuSamples = event.cpu > 90 ? highCpuSamples + 1 : 0;
            if (highCpuSamples >= 3 && Date.now() - lastCpuAlert > 60000) {
                machine.notify("CPU over 90%", "warning", true, "cpu");
                lastCpuAlert = Date.now();
            }
            break;
        case "screen":
            cursorScreen = event.name;
            break;
        case "gpu":
            gpu = event.value === null ? "—" : event.value + "%";
            gpuHistory = appendSample(gpuHistory, event.value);
            break;
        case "history":
            history = event.entries;
            break;
        case "preview":
            if (machine.state !== "CLIPBOARD" || !history.some(entry => entry.id === event.id))
                break;
            var images = Object.assign({}, previews);
            if (Object.keys(images).length >= 8)
                delete images[Object.keys(images)[0]];
            images[event.id] = event.url;
            previews = images;
            break;
        case "hardware":
            machine.hardware(event.kind, event.value, event.muted);
            break;
        case "restoring":
            restoredHash = event.digest;
            restoredAt = Date.now();
            break;
        case "copy":
            if (event.digest === restoredHash && Date.now() - restoredAt < 5000) {
                restoredHash = "";
                break;
            }
            if (restoreProcess.running)
                break;
            combo = event.digest === lastHash && Date.now() - lastCopy < 1500 ? combo + 1 : 1;
            if (combo === 1)
                comboKey = "copy-" + Date.now();
            lastHash = event.digest;
            lastCopy = Date.now();
            machine.notify(combo > 1 ? "Copied ×" + combo : "Copied", "copy", false, comboKey);
            comboTimer.restart();
            break;
        case "greeting":
            var hour = new Date().getHours();
            var name = Quickshell.env("USER") || "friend";
            machine.notify(hour >= 1 && hour < 4 ? "3am session?" : hour >= 4 && hour < 7 ? "Early start, " + name : hour < 12 ? "Good morning, " + name : hour < 18 ? "Good afternoon, " + name : "Good evening, " + name, "greeting", false, "greeting");
            break;
        case "error":
            machine.notify(event.message, "warning", false, "helper-error");
            break;
        }
    }
    function parse(line) {
        try {
            ingest(JSON.parse(line));
        } catch (e) {
            console.warn("Island: invalid helper response");
        }
    }
    function adjust(kind, direction) {
        if (machine.locked)
            return;
        hardwareQueue = hardwareQueue.concat([
            {
                kind: kind,
                direction: direction
            }
        ]).slice(-20);
        drainHardware();
    }
    function drainHardware() {
        if (machine.locked || hardwareProcess.running || !hardwareQueue.length)
            return;
        var item = hardwareQueue[0];
        hardwareQueue = hardwareQueue.slice(1);
        hardwareProcess.command = ["python3", helper, "hardware", item.kind, item.direction];
        hardwareProcess.running = true;
    }
    function pin(urls) {
        if (machine.locked)
            return;
        var fresh = Logic.localFiles(urls).filter(url => !shelf.includes(url));
        for (var url of fresh)
            shelfItems.append({
                fileUrl: url
            });
        shelf = shelf.concat(fresh);
        machine.open("clipboard");
    }
    function consume(url) {
        for (var i = shelfItems.count - 1; i >= 0; --i)
            if (shelfItems.get(i).fileUrl === url)
                shelfItems.remove(i);
        shelf = shelf.filter(item => item !== url);
    }
    function restore(id) {
        if (machine.locked || restoreProcess.running)
            return;
        restoreProcess.command = ["python3", helper, "restore", String(id)];
        restoreProcess.running = true;
        machine.dismiss();
    }
    function requestPreview(id) {
        if (!enabled || machine.locked || machine.state !== "CLIPBOARD" || !/^\d+$/.test(id) || previews[id] !== undefined || previewQueue.includes(id) || previewProcess.entryId === id && previewProcess.running)
            return;
        if (previewQueue.length >= 8)
            return;
        previewQueue = previewQueue.concat([id]);
        drainPreviews();
    }
    function drainPreviews() {
        if (!enabled || machine.locked || machine.state !== "CLIPBOARD" || previewProcess.running || !previewQueue.length)
            return;
        previewProcess.entryId = previewQueue[0];
        previewQueue = previewQueue.slice(1);
        previewProcess.running = true;
    }
    function clearPreviews() {
        previewProcess.running = false;
        previewQueue = [];
        previews = ({});
    }
    function searchFiles(query) {
        if (machine.locked)
            return;
        pendingQuery = query;
        fileResults = [];
        fileSearchError = "";
        fileSearchBusy = query.trim().length >= 2;
        if (query.trim().length < 2) {
            fileDebounce.stop();
            fileResults = [];
            fileProcess.running = false;
            return;
        }
        fileDebounce.restart();
    }
    property string pendingQuery: ""
    function sendChat(text) {
        if (machine.locked || chatBusy || !text.trim())
            return;
        messages = messages.concat([
            {
                role: "user",
                content: text.trim()
            }
        ]);
        chatError = "";
        chatProcess.running = true;
    }
    function openUrl(url) {
        if (machine.locked || !/^(file:\/\/|https?:\/\/)/.test(url))
            return;
        Qt.openUrlExternally(url);
        machine.dismiss();
    }
    Timer {
        id: comboTimer
        interval: 1500
        onTriggered: {
            if (root.combo > 1)
                root.machine.notify("+" + (root.combo * root.combo * 100), "score", false, root.comboKey);
            root.combo = 0;
            root.lastHash = "";
        }
    }
    Timer {
        id: fileDebounce
        interval: 180
        onTriggered: {
            if (!root.machine.locked && root.pendingQuery.trim().length >= 2 && !fileProcess.running) {
                fileProcess.query = root.pendingQuery;
                fileProcess.running = true;
            }
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.enabled && !root.machine.locked
        onTriggered: {
            if (root.player) {
                var track = root.player.trackTitle + " · " + root.player.trackArtist;
                if (root.player.trackTitle && track !== root.lastTrack && root.mediaInitialized)
                    root.machine.notify(track, "media", false, "media");
                root.lastTrack = track;
            } else {
                root.lastTrack = "";
            }
            root.mediaInitialized = true;
            var battery = UPower.displayDevice;
            if (battery && battery.isLaptopBattery && !UPower.onBattery)
                root.batteryWarned = false;
            if (battery && UPower.onBattery && battery.percentage <= 0.10 && !root.batteryWarned) {
                root.batteryWarned = true;
                root.machine.notify("Battery critical", "warning", true, "battery");
            }
        }
    }
    IdleMonitor {
        id: idle
        timeout: root.settings.idleSeconds
        enabled: root.enabled && !root.machine.locked
        onIsIdleChanged: {
            root.idleFrame = 0;
            if (isIdle && root.machine.state === "IDLE")
                blink.restart();
            else
                blink.stop();
        }
    }
    Timer {
        id: blink
        interval: 900
        repeat: true
        onTriggered: {
            root.idleFrame++;
            if (root.idleFrame > 5) {
                stop();
                root.idleFrame = 0;
            }
        }
    }
    Timer {
        id: audioDecay
        interval: 100
        repeat: true
        running: root.amplitude > 0.001
        onTriggered: root.amplitude *= 0.7
    }
    Connections {
        target: root.machine
        function onStateChanged() {
            if (root.machine.state !== "CLIPBOARD")
                root.clearPreviews();
            if (root.machine.state !== "IDLE") {
                blink.stop();
                root.idleFrame = 0;
            }
        }
        function onLockedChanged() {
            if (root.machine.locked) {
                root.hardwareQueue = [];
                hardwareProcess.running = false;
                restoreProcess.running = false;
                fileProcess.running = false;
                chatProcess.running = false;
                root.messages = [];
                root.chatError = "";
                root.history = [];
                root.fileResults = [];
                root.fileSearchBusy = false;
                root.fileSearchError = "";
                comboTimer.stop();
                fileDebounce.stop();
                root.lastHash = "";
                root.combo = 0;
                root.amplitude = 0;
            }
        }
    }
    Process {
        command: ["python3", root.helper, "monitor"]
        running: root.enabled && !root.machine.locked
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
    Process {
        command: ["python3", root.helper, "greeting"]
        running: root.enabled && root.settings.greeting
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.enabled && root.machine.state === "STATS"
        onTriggered: {
            if (!gpuProcess.running)
                gpuProcess.running = true;
        }
    }
    Process {
        id: gpuProcess
        command: ["python3", root.helper, "gpu"]
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
    Process {
        command: ["python3", root.helper, "audio"]
        running: root.enabled && !root.machine.locked && root.player !== null && root.player.isPlaying
        stdout: SplitParser {
            onRead: line => {
                if (root.machine.locked)
                    return;
                var bins = line.split(";").slice(0, 3).map(Number);
                if (bins.length === 3 && bins.every(Number.isFinite)) {
                    var sample = Math.max(0, Math.min(1, (bins[0] + bins[1] + bins[2]) / 300));
                    root.amplitude += (sample - root.amplitude) * (sample > root.amplitude ? 0.6 : 0.2);
                }
            }
        }
    }
    Process {
        id: hardwareProcess
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
        onExited: Qt.callLater(root.drainHardware)
    }
    Process {
        id: restoreProcess
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
    Process {
        id: previewProcess
        property string entryId: ""
        command: ["python3", root.helper, "preview", entryId]
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
        onExited: Qt.callLater(root.drainPreviews)
    }
    Process {
        id: fileProcess
        property string query: ""
        command: ["python3", root.helper, "files", query]
        stdout: SplitParser {
            onRead: line => {
                try {
                    var e = JSON.parse(line);
                    if (!root.machine.locked && fileProcess.query === root.pendingQuery && e.type === "files") {
                        root.fileResults = e.entries;
                        root.fileSearchBusy = false;
                    }
                } catch (_) {}
            }
        }
        onExited: (code, status) => {
            if (root.machine.locked)
                return;
            if (query !== root.pendingQuery && root.pendingQuery.trim().length >= 2)
                fileDebounce.restart();
            else if (query === root.pendingQuery) {
                root.fileSearchBusy = false;
                if (code !== 0 || status !== 0)
                    root.fileSearchError = "Could not search files";
            }
        }
    }
    Process {
        id: chatProcess
        command: ["python3", root.helper, "chat"]
        stdinEnabled: true
        onStarted: write(JSON.stringify({
            endpoint: root.settings.aiEndpoint,
            model: root.settings.aiModel,
            messages: root.messages
        }) + "\n")
        stdout: SplitParser {
            onRead: line => {
                if (root.machine.locked)
                    return;
                try {
                    var e = JSON.parse(line);
                    if (e.type === "chat")
                        root.messages = root.messages.concat([
                            {
                                role: "assistant",
                                content: e.text
                            }
                        ]);
                    else if (e.type === "error")
                        root.chatError = e.message;
                } catch (_) {
                    root.chatError = "Invalid response";
                }
            }
        }
    }
    NotificationServer {
        id: notifications
        bodySupported: true
        bodyMarkupSupported: false
        onNotification: notification => {
            if (root.machine.locked) {
                notification.dismiss();
                return;
            }
            notification.tracked = true;
            var text = notification.summary || notification.body;
            root.machine.notify(text, "notice", notification.urgency === NotificationUrgency.Critical, "notification-" + notification.id);
            if (/screenshot|hyprshot|grim/i.test(notification.appName + " " + text))
                root.machine.screenshot();
        }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            var live = root.machine.data.queue.map(item => item.key);
            if (root.machine.current)
                live.push(root.machine.current.key);
            for (var notification of notifications.trackedNotifications.values) {
                if (root.machine.locked)
                    notification.dismiss();
                else if (!live.includes("notification-" + notification.id))
                    notification.expire();
            }
        }
    }
}
