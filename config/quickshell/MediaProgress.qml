import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root
    required property var player
    property bool enabled: true
    property bool pollEnabled: true
    readonly property bool available: player !== null && player.positionSupported && player.lengthSupported && player.length > 0 && player.playbackState !== MprisPlaybackState.Stopped
    property real progress: 0
    property real anchor: 0
    property double sampledAt: Date.now()
    property int revision: 0
    property bool advancing: false
    property real speed: 1

    function currentPosition() {
        return anchor + (advancing ? (Date.now() - sampledAt) / 1000 * speed : 0);
    }

    function update() {
        // playerChanged can run before the derived `available` binding catches
        // up when an MPRIS service disappears.
        var current = player;
        progress = current && current.positionSupported && current.lengthSupported && current.length > 0 && current.playbackState !== MprisPlaybackState.Stopped ? Math.max(0, Math.min(1, currentPosition() / current.length)) : 0;
    }
    function sample(position) {
        revision++;
        anchor = Math.max(0, position);
        sampledAt = Date.now();
        advancing = player !== null && player.isPlaying;
        speed = player ? player.rate : 1;
        update();
    }
    function sync() {
        sample(player ? player.position : 0);
    }
    function snapshot() {
        return {
            player: player,
            track: player ? player.uniqueId : -1,
            revision: revision
        };
    }
    function acceptPosition(text, request) {
        // A response from before a seek, track change or player switch is stale.
        if (!enabled || !player || !available || request.player !== player || request.track !== player.uniqueId || request.revision !== revision)
            return;
        var match = /^x\s+(\d+)\s*$/.exec(text);
        if (match)
            sample(Number(match[1]) / 1000000);
    }
    function refresh() {
        if (!enabled || !pollEnabled || !player || !available || positionQuery.running)
            return;
        positionQuery.request = snapshot();
        positionQuery.command = ["busctl", "--user", "--timeout=1s", "get-property", player.dbusName, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Position"];
        positionQuery.running = true;
    }
    onPlayerChanged: {
        sync();
        Qt.callLater(refresh);
    }
    onEnabledChanged: {
        if (enabled) {
            sync();
            Qt.callLater(refresh);
        } else
            positionQuery.running = false;
    }
    onAvailableChanged: {
        update();
        Qt.callLater(refresh);
    }
    Component.onCompleted: {
        sync();
        Qt.callLater(refresh);
    }
    Connections {
        target: root.player
        function onPositionChanged() {
            root.sync();
        }
        function onPlaybackStateChanged() {
            // Preserve a position corrected by polling when the player's
            // cached position was stale before pause/resume.
            root.sample(root.currentPosition());
            Qt.callLater(root.refresh);
        }
        function onRateChanged() {
            root.sample(root.currentPosition());
        }
        function onLengthChanged() {
            root.update();
        }
        function onPostTrackChanged() {
            root.sync();
            Qt.callLater(root.refresh);
        }
    }
    Timer {
        interval: 100
        repeat: true
        running: root.enabled && root.available && root.player.isPlaying
        onTriggered: root.update()
    }
    // Query even while paused: dragging a paused player's slider may emit no
    // Seeked signal. Reading the cached QML position cannot detect that change.
    Timer {
        interval: 1000
        repeat: true
        running: root.enabled && root.pollEnabled && root.available
        onTriggered: root.refresh()
    }
    Process {
        id: positionQuery
        property var request: ({})
        stdout: StdioCollector {
            onStreamFinished: root.acceptPosition(text, positionQuery.request)
        }
    }
}
