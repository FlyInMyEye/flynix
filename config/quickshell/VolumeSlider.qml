import QtQuick
import Quickshell
import Quickshell.Io

Item {
  Colors { id: colors }
  id: root
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  width: Math.max(56, Math.min(root.visibleCount, root.maxCount) * root.sliderWidth)
  height: 340
  z: 10
  clip: true

  property real volume: 0.75
  property bool muted: false

  property real sliderWidth: 48
  property real visibleCount: 0
  property real maxCount: 1 + Math.min(audioStreams.length, 5)
  property var audioStreams: []
  property real globalH: 340

  onAudioStreamsChanged: {
    if (visibleCount > maxCount) visibleCount = maxCount
  }

  property bool dragging: false
  property real pressX: 0

  function snapVisible(v) {
    if (v < 0.4) return 0
    var base = Math.floor(v)
    var frac = v - base
    return frac < 0.5 ? Math.max(1, base) : Math.min(maxCount, base + 1)
  }

  Behavior on width {
    enabled: !root.dragging
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  Rectangle {
    id: panelBg
    x: root.width - Math.min(root.visibleCount, root.maxCount) * root.sliderWidth
    width: Math.min(root.visibleCount, root.maxCount) * root.sliderWidth
    height: parent.height
    color: colors.altBg
    radius: 10
    clip: true

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Row {
      id: sliderRow
      width: Math.min(root.visibleCount, root.maxCount) * root.sliderWidth
      height: parent.height
      layoutDirection: Qt.LeftToRight
      clip: true

      Rectangle {
        id: globalSlider
        width: 48
        height: sliderRow.height
        color: "transparent"

        Rectangle {
          id: iconBg
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 8
          width: 26
          height: 26
          radius: 7
          color: colors.bg

          Text {
            anchors.centerIn: parent
            text: root.muted ? "" : root.volume > 0.5 ? "" : root.volume > 0.1 ? "" : ""
            color: root.muted ? colors.muted : colors.accent
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
          }
        }

        Rectangle {
          id: trackBg
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: iconBg.bottom
          anchors.topMargin: 10
          anchors.bottom: percentLabel.top
          anchors.bottomMargin: 6
          width: 8
          radius: 4
          color: colors.bg
          opacity: 0.5

          Rectangle {
            id: trackFill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * root.volume
            radius: 4
            color: root.muted ? colors.muted : colors.accent
          }

          MouseArea {
            id: trackArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            onPressed: function(mouse) {
              root.dragging = true
              var ratio = 1.0 - Math.max(0, Math.min(1, mouseY / trackBg.height))
              root.volume = ratio
              root.setVolume(ratio)
              autoHideTimer.restart()
            }

            onPositionChanged: function(mouse) {
              if (!pressed) return
              var ratio = 1.0 - Math.max(0, Math.min(1, mouseY / trackBg.height))
              root.volume = ratio
              root.setVolume(ratio)
            }

            onReleased: {
              root.dragging = false
            }

            onWheel: function(wheel) {
              var delta = wheel.angleDelta.y / 120 * 0.05
              root.volume = Math.max(0, Math.min(1, root.volume + delta))
              root.setVolume(root.volume)
              autoHideTimer.restart()
            }
          }
        }

        Text {
          id: percentLabel
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 4
          text: Math.round(root.volume * 100) + "%"
          color: root.muted ? colors.muted : colors.fg
          font.family: "CaskaydiaCove NF"
          font.pixelSize: 11
          font.bold: true
        }
      }

      Repeater {
        model: root.audioStreams

        delegate: Rectangle {
          required property var modelData

          width: 48
          height: sliderRow.height
          color: "transparent"

          Rectangle {
            id: strIconBg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: 26
            height: 26
            radius: 7
            color: colors.bg

            Image {
              id: strAppIcon
              anchors.centerIn: parent
              width: 18
              height: 18
              sourceSize.width: 18
              sourceSize.height: 18
              asynchronous: true
              visible: status === Image.Ready

              property int _tryIdx: 0
              property var _tryList: []

              Component.onCompleted: {
                var name = modelData.icon || modelData.appid || modelData.name || ""
                if (!name) return
                var lname = name.toLowerCase()
                _tryList = [
                  "file:///usr/share/icons/hicolor/scalable/apps/" + name + ".svg",
                  "file:///usr/share/icons/hicolor/scalable/apps/" + lname + ".svg",
                  "file:///usr/share/icons/hicolor/32x32/apps/" + name + ".png",
                  "file:///usr/share/icons/hicolor/32x32/apps/" + lname + ".png",
                  "file:///usr/share/icons/hicolor/48x48/apps/" + name + ".png",
                  "file:///usr/share/icons/hicolor/48x48/apps/" + lname + ".png",
                  "file:///usr/share/icons/hicolor/64x64/apps/" + name + ".png",
                  "file:///usr/share/icons/hicolor/64x64/apps/" + lname + ".png",
                ]
                source = _tryList[0]
              }

              onStatusChanged: {
                if (status === Image.Error && _tryIdx < _tryList.length - 1) {
                  _tryIdx++
                  source = _tryList[_tryIdx]
                }
              }
            }

            Text {
              anchors.centerIn: parent
              text: {
                var icon = modelData.icon || modelData.appid || modelData.name || "?"
                return icon ? icon.charAt(0).toUpperCase() : "?"
              }
              color: modelData.mute ? colors.muted : colors.accent
              font.family: "CaskaydiaCove NF"
              font.pixelSize: 14
              font.bold: true
              visible: strAppIcon.status !== Image.Ready
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleStreamMute(modelData.id, !modelData.mute)
            }
          }

          Rectangle {
            id: strTrackBg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: strIconBg.bottom
            anchors.topMargin: 10
            anchors.bottom: strPct.top
            anchors.bottomMargin: 6
            width: 8
            radius: 4
            color: colors.bg
            opacity: 0.5

            Rectangle {
              id: strTrackFill
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              width: parent.width
              height: parent.height * (modelData.vol || 0)
              radius: 4
              color: modelData.mute ? colors.muted : colors.accent
            }

            MouseArea {
              id: strTrackArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              preventStealing: true

              onPressed: function(mouse) {
                root.dragging = true
                var v = 1.0 - Math.max(0, Math.min(1, mouseY / strTrackBg.height))
                modelData.vol = v
                root.setStreamVolume(modelData.id, v)
                strTrackFill.height = parent.height * v
                strPct.text = Math.round(v * 100) + "%"
                autoHideTimer.restart()
              }

              onPositionChanged: function(mouse) {
                if (!pressed) return
                var v = 1.0 - Math.max(0, Math.min(1, mouseY / strTrackBg.height))
                modelData.vol = v
                root.setStreamVolume(modelData.id, v)
                strTrackFill.height = parent.height * v
                strPct.text = Math.round(v * 100) + "%"
              }

              onReleased: {
                root.dragging = false
              }

              onWheel: function(wheel) {
                var v = (modelData.vol || 0) + wheel.angleDelta.y / 120 * 0.05
                v = Math.max(0, Math.min(1, v))
                modelData.vol = v
                root.setStreamVolume(modelData.id, v)
                strTrackFill.height = parent.height * v
                strPct.text = Math.round(v * 100) + "%"
                autoHideTimer.restart()
              }
            }
          }

          Text {
            id: strPct
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: Math.round((modelData.vol || 0) * 100) + "%"
            color: modelData.mute ? colors.muted : colors.fg
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 11
            font.bold: true
          }
        }
      }
    }
  }

  MouseArea {
    id: grabZone
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 8
    enabled: root.visibleCount < 0.1
    cursorShape: Qt.PointingHandCursor

    property real pressX: 0

    onPressed: function(mouse) {
      root.dragging = true
      pressX = mouse.x
    }

    onPositionChanged: function(mouse) {
      if (!pressed) return
      var dx = pressX - mouse.x
      root.visibleCount = Math.max(0, Math.min(root.maxCount, dx / root.sliderWidth))
    }

    onReleased: {
      root.dragging = false
      root.visibleCount = root.snapVisible(root.visibleCount)
      if (root.visibleCount > 0) autoHideTimer.restart()
    }
  }

  function setVolume(value) {
    var cmd = Math.round(value * 100) / 100
    volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", cmd.toString()]
    volumeSetProc.startDetached()
  }

  function toggleMute() {
    root.muted = !root.muted
    muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"]
    muteProc.startDetached()
  }

  function setStreamVolume(id, vol) {
    vol = Math.max(0, Math.min(1, vol))
    streamVolSetProc.command = [
      "pw-cli", "set-param", id.toString(), "Props",
      "{ volume: " + vol.toFixed(4) + " }"
    ]
    streamVolSetProc.startDetached()

    if (root.dragging) return

    for (var i = 0; i < root.audioStreams.length; i++) {
      if (root.audioStreams[i].id === id) {
        var updated = root.audioStreams.slice()
        updated[i] = Object.assign({}, updated[i])
        updated[i].vol = vol
        root.audioStreams = updated
        break
      }
    }
  }

  function toggleStreamMute(id, mute) {
    streamMuteProc.command = [
      "pw-cli", "set-param", id.toString(), "Props",
      "{ mute: " + (mute ? "true" : "false") + " }"
    ]
    streamMuteProc.startDetached()

    for (var i = 0; i < root.audioStreams.length; i++) {
      if (root.audioStreams[i].id === id) {
        var updated = root.audioStreams.slice()
        updated[i] = Object.assign({}, updated[i])
        updated[i].mute = mute
        root.audioStreams = updated
        break
      }
    }
  }

  Process { id: volumeSetProc }
  Process { id: muteProc }
  Process { id: streamVolSetProc }
  Process { id: streamMuteProc }

  Process {
    id: volumeGetProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

    stdout: StdioCollector {
      onStreamFinished: {
        var text = this.text.trim()
        var match = text.match(/Volume:\s*([\d.]+)/)
        if (match) root.volume = parseFloat(match[1])
        root.muted = text.includes("[MUTED]")
      }
    }
  }

  Process {
    id: streamListProc
    command: [
      "sh", "-c",
      "pw-dump 2>/dev/null | jq -c '.[] | select(.type == \"PipeWire:Interface:Node\") | select((.info.props.\"media.class\" // \"\") | startswith(\"Stream/Output/Audio\")) | {id: .id, name: (.info.props.\"application.name\" // .info.props.\"node.name\" // \"Unknown\"), icon: (.info.props.\"application.icon.name\" // \"\"), appid: (.info.props.\"application.id\" // \"\"), vol: ((.info.params.Props[0].volume // .info.params.Props[0].channelVolumes[0]) // 1.0), mute: (.info.params.Props[0].mute // false)}' 2>/dev/null"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split("\n")
        var streams = []
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].trim()) continue
          try {
            var obj = JSON.parse(lines[i])
            if (obj && obj.id) streams.push(obj)
          } catch (_) {}
        }
        root.audioStreams = streams
      }
    }
  }

  Timer {
    id: autoHideTimer
    interval: 3000
    onTriggered: {
      root.visibleCount = 0
    }
  }

  Timer {
    interval: 3000
    running: root.visibleCount > 0.5 && !root.dragging
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      volumeGetProc.running = true
      streamListProc.running = true
    }
  }

  Component.onCompleted: {
    volumeGetProc.running = true
    streamListProc.running = true
  }
}
