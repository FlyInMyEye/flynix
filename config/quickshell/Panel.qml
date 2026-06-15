import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
PanelWindow {
  Colors { id: colors }
  id: island
  anchors { top: true; left: true; right: true }
  margins.top: 5
  exclusiveZone: 40
  height: screen ? screen.height : 1080
  mask: Region {
    item: launcherPanel

    Region { item: dragSurface }
    Region { item: leftWorkspaceGroup }
    Region { item: trayGroup }
    Region { item: rightWorkspaceGroup }
    Region { item: megaPanel }
    Region { item: volumeSlider }
  }

  color: "transparent"

  property string shortTimeStr: ""
  property string fullTimeStr: ""
  property string dateStr: ""
  property string dayStr: ""
  property var leftWorkspaces: [1, 2, 3, 4, 5]
  property var rightWorkspaces: [6, 7, 8, 9, 10]
  property int workspaceButtonWidth: 30
  property int workspaceButtonHeight: 30
  property int workspaceButtonSpacing: 2
  property int megaWorkspaceSpacing: 6
  property int blockTopMargin: 3
  property int topMenuHeight: 182
  property int dragThreshold: 56
  property real dragResistance: 0.18
  property int focusedWorkspaceId: -1
  property real leftIndicatorX: 12
  property real rightIndicatorX: 12
  property real leftIndicatorOpacity: 0
  property real rightIndicatorOpacity: 0
  property bool leftIndicatorAnimate: true
  property bool rightIndicatorAnimate: true
  property real sideInfoWidth: Math.max(dayTextMetrics.width, dateTextMetrics.width)
  property var occupiedWorkspaces: ({})
  property var activeTrayItem: null
  property bool trayExpanded: activeTrayItem !== null
  property bool menuExpanded: false
  property bool dragActive: false
  property real dragStartGlobalY: 0
  property real dragBaseOffset: 0
  property real dragDistance: 0
  property real megaPanelWidth: sideInfoWidth * 2 + Math.max(fullTimeMetrics.width, shortTimeMetrics.width) + 140
  property int megaWorkspacePanelWidth: 44
  property real revealOffset: dragActive ? dragOffset(dragDistance) : (menuExpanded ? topMenuHeight : 0)
  property real revealProgress: Math.max(0, Math.min(1, revealOffset / topMenuHeight))
  property real mergeProgress: revealProgress
  property real pillYOffset: revealOffset > 1 ? revealOffset + 12 : 0
  property real topRowFade: Math.max(0, 1 - mergeProgress * 2)
  property string mediaStatus: ""
  property string mediaPlayer: ""
  property string mediaTitle: ""
  property string mediaArtist: ""
  property string mediaArtUrl: ""

  function lerp(a, b, t) {
    return a + (b - a) * t
  }

  function dragToOffset(distance) {
    var d = Math.max(0, distance)
    if (d <= dragThreshold) return d * dragResistance
    var extra = d - dragThreshold
    return Math.min(topMenuHeight, dragThreshold * dragResistance + extra * 0.45 + extra * extra * 0.06)
  }

  function dragOffset(distance) {
    if (dragBaseOffset >= topMenuHeight * 0.5) {
      return Math.max(0, Math.min(topMenuHeight, distance))
    }

    return dragToOffset(distance)
  }

  function workspaceIsActive(id) {
    return Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === id
  }

  function workspaceIsOccupied(id) {
    return occupiedWorkspaces[id] === true
  }

  function isLeftWorkspace(id) {
    return id >= 1 && id <= 5
  }

  function isRightWorkspace(id) {
    return id >= 6 && id <= 10
  }

  function leftWorkspaceIndex() {
    if (!Hyprland.focusedWorkspace) return -1
    var id = Hyprland.focusedWorkspace.id
    return id >= 1 && id <= 5 ? id - 1 : -1
  }

  function rightWorkspaceIndex() {
    if (!Hyprland.focusedWorkspace) return -1
    var id = Hyprland.focusedWorkspace.id
    return id >= 6 && id <= 10 ? id - 6 : -1
  }

  function rightMergedWorkspaceIndex() {
    var index = rightWorkspaceIndex()
    return index >= 0 ? 4 - index : -1
  }

  function workspaceIndicatorX(index) {
    return 12 + index * (workspaceButtonWidth + workspaceButtonSpacing)
  }

  function syncWorkspaceIndicators() {
    var next = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    var prev = focusedWorkspaceId

    focusedWorkspaceId = next

    if (isLeftWorkspace(next)) {
      var leftTarget = workspaceIndicatorX(next - 1)

      if (isRightWorkspace(prev)) {
        leftIndicatorAnimate = false
        leftIndicatorX = leftTarget
        leftIndicatorOpacity = 0
        Qt.callLater(function() {
          leftIndicatorAnimate = true
          leftIndicatorOpacity = 1
        })
      } else {
        leftIndicatorAnimate = true
        leftIndicatorOpacity = 1
        leftIndicatorX = leftTarget
      }

      rightIndicatorOpacity = 0
    } else if (isRightWorkspace(next)) {
      var rightTarget = workspaceIndicatorX(next - 6)

      if (isLeftWorkspace(prev)) {
        rightIndicatorAnimate = false
        rightIndicatorX = rightTarget
        rightIndicatorOpacity = 0
        Qt.callLater(function() {
          rightIndicatorAnimate = true
          rightIndicatorOpacity = 1
        })
      } else {
        rightIndicatorAnimate = true
        rightIndicatorOpacity = 1
        rightIndicatorX = rightTarget
      }

      leftIndicatorOpacity = 0
    } else {
      leftIndicatorOpacity = 0
      rightIndicatorOpacity = 0
    }
  }

  function activateWorkspace(id) {
    Hyprland.dispatch("workspace " + id)
  }

  function openTrayMenu(item, button) {
    activeTrayItem = item
  }

  function closeTrayMenu() {
    activeTrayItem = null
  }

  Behavior on revealOffset {
    NumberAnimation {
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  Component.onCompleted: syncWorkspaceIndicators()

  Connections {
    target: Hyprland

    function onFocusedWorkspaceChanged() {
      island.syncWorkspaceIndicators()
    }
  }

  Process {
    id: workspaceStateProc
    command: ["hyprctl", "workspaces", "-j"]

    stdout: StdioCollector {
      onStreamFinished: {
        var nextOccupied = {}

        try {
          var workspaces = JSON.parse(this.text)
          for (var i = 0; i < workspaces.length; i++) {
            var workspace = workspaces[i]
            if (workspace.id >= 1 && workspace.id <= 10) {
              nextOccupied[workspace.id] = (workspace.windows || 0) > 0
            }
          }
        } catch (error) {
          return
        }

        island.occupiedWorkspaces = nextOccupied
      }
    }
  }

  Process {
    id: nowPlayingProc
    command: [
      "sh",
      "-c",
      "status=$(playerctl status 2>/dev/null || true); if [ -n \"$status\" ]; then printf '%s\n' \"$status\"; playerctl metadata --format '{{playerName}}\n{{title}}\n{{artist}}\n{{mpris:artUrl}}' 2>/dev/null; fi"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.split("\n")
        island.mediaStatus = lines[0] || ""
        island.mediaPlayer = lines[1] || ""
        island.mediaTitle = lines[2] || ""
        island.mediaArtist = lines[3] || ""
        island.mediaArtUrl = lines[4] || ""
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var now = new Date()
      var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
      dayStr = days[now.getDay()]
      dateStr = now.getDate().toString().padStart(2, '0')
        + "/" + (now.getMonth() + 1).toString().padStart(2, '0')
      shortTimeStr = now.getHours().toString().padStart(2, '0')
        + ":" + now.getMinutes().toString().padStart(2, '0')
      fullTimeStr = now.getHours().toString().padStart(2, '0')
        + ":" + now.getMinutes().toString().padStart(2, '0')
        + ":" + now.getSeconds().toString().padStart(2, '0')

      workspaceStateProc.running = true
      nowPlayingProc.running = true
    }
  }

  TextMetrics {
    id: dayTextMetrics
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
    text: island.dayStr
  }

  TextMetrics {
    id: dateTextMetrics
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
    text: island.dateStr
  }

  TextMetrics {
    id: shortTimeMetrics
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
    text: island.shortTimeStr
  }

  TextMetrics {
    id: fullTimeMetrics
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
    text: island.fullTimeStr
  }

  MegaPanel {
    id: megaPanel
    blockTopMargin: island.blockTopMargin
    topMenuHeight: island.topMenuHeight
    revealOffset: island.revealOffset
    revealProgress: island.revealProgress
    megaPanelWidth: island.megaPanelWidth
    mediaStatus: island.mediaStatus
    mediaPlayer: island.mediaPlayer
    mediaTitle: island.mediaTitle
    mediaArtist: island.mediaArtist
    mediaArtUrl: island.mediaArtUrl
    dayStr: island.dayStr
    fullTimeStr: island.fullTimeStr
    dateStr: island.dateStr
  }

  LauncherPanel {
    id: launcherPanel
    blockTopMargin: island.blockTopMargin
  }

  Pill {
    id: pill
    blockTopMargin: island.blockTopMargin
    pillYOffset: island.pillYOffset
    menuExpanded: island.menuExpanded
    dragActive: island.dragActive
    sideInfoWidth: island.sideInfoWidth
    dayStr: island.dayStr
    fullTimeStr: island.fullTimeStr
    shortTimeStr: island.shortTimeStr
    dateStr: island.dateStr
  }

  Item {
    id: dragSurface
    x: island.dragActive ? 0 : pill.x
    y: island.dragActive ? 0 : pill.y
    width: island.dragActive ? parent.width : pill.width
    height: island.dragActive && screen ? screen.height : pill.height
    z: 5

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.OpenHandCursor

      onPressed: function(mouse) {
        if (!island.dragActive) {
          var insidePillX = mouse.x >= 0 && mouse.x <= dragSurface.width
          var insidePillY = mouse.y >= 0 && mouse.y <= dragSurface.height
          if (!insidePillX || !insidePillY) {
            mouse.accepted = false
            return
          }
        }

        island.dragStartGlobalY = mouse.y + dragSurface.y
        island.dragActive = true
        island.dragBaseOffset = island.menuExpanded ? island.topMenuHeight : 0
        island.dragDistance = island.dragBaseOffset
        mouse.accepted = true
      }

      onPositionChanged: function(mouse) {
        if (!pressed || !island.dragActive) {
          mouse.accepted = false
          return
        }
        island.dragDistance = island.dragBaseOffset + (mouse.y + dragSurface.y) - island.dragStartGlobalY
      }

      onReleased: {
        if (!island.dragActive) return
        island.dragActive = false
        island.menuExpanded = island.revealOffset > island.topMenuHeight * 0.45
      }

      onCanceled: {
        island.dragActive = false
        island.menuExpanded = false
      }
    }
  }

  Rectangle {
    id: leftWorkspaceGroup
    x: island.lerp(pill.x - (leftRow.width + 24) - 6, megaPanel.x - island.megaWorkspacePanelWidth + 1, island.mergeProgress)
    y: island.lerp(island.blockTopMargin, megaPanel.y, island.mergeProgress)
    width: island.lerp(leftRow.width + 24, island.megaWorkspacePanelWidth, island.mergeProgress)
    height: island.lerp(44, island.topMenuHeight, island.mergeProgress)
    color: colors.altBg
    radius: 10
    topRightRadius: 10 * (1 - island.mergeProgress)
    bottomRightRadius: 10 * (1 - island.mergeProgress)
    z: 3
    clip: true

    Rectangle {
      x: island.mergeProgress > 0
        ? island.lerp(
        ((leftWorkspaceGroup.width - leftRow.width) / 2)
          + Math.max(0, island.leftWorkspaceIndex()) * (island.workspaceButtonWidth + island.workspaceButtonSpacing),
        (leftWorkspaceGroup.width - island.workspaceButtonWidth) / 2,
        island.mergeProgress
      )
        : island.leftIndicatorX
      y: island.mergeProgress > 0
        ? island.lerp(
        (leftWorkspaceGroup.height - island.workspaceButtonHeight) / 2,
        (leftWorkspaceGroup.height - (5 * island.workspaceButtonHeight + 4 * island.megaWorkspaceSpacing)) / 2
          + Math.max(0, island.leftWorkspaceIndex()) * (island.workspaceButtonHeight + island.megaWorkspaceSpacing),
        island.mergeProgress
      )
        : (leftWorkspaceGroup.height - island.workspaceButtonHeight) / 2
      width: island.workspaceButtonWidth
      height: island.workspaceButtonHeight
      radius: 8
      color: colors.accent
      opacity: island.leftIndicatorOpacity

      Behavior on x {
        enabled: island.leftIndicatorAnimate
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Behavior on y {
        enabled: island.leftIndicatorAnimate
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }
    }

    Row {
      id: leftRow
      anchors.centerIn: parent
      spacing: island.workspaceButtonSpacing
      visible: island.mergeProgress < 0.999
      opacity: 1 - island.mergeProgress

      Repeater {
        model: island.leftWorkspaces

        delegate: Rectangle {
          required property int modelData

          width: island.workspaceButtonWidth
          height: island.workspaceButtonHeight
          radius: 8
          color: "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.modelData
            color: island.workspaceIsActive(parent.modelData)
              ? colors.bg
              : (island.workspaceIsOccupied(parent.modelData) ? colors.fg : colors.muted)
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: island.activateWorkspace(parent.modelData)
          }
        }
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: island.megaWorkspaceSpacing
      visible: island.mergeProgress > 0.001
      opacity: island.mergeProgress

      Repeater {
        model: island.leftWorkspaces

        delegate: Rectangle {
          required property int modelData

          width: island.workspaceButtonWidth
          height: island.workspaceButtonHeight
          radius: 8
          color: "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.modelData
            color: island.workspaceIsActive(parent.modelData)
              ? colors.bg
              : (island.workspaceIsOccupied(parent.modelData) ? colors.fg : colors.muted)
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: island.activateWorkspace(parent.modelData)
          }
        }
      }
    }
  }

  TrayGroup {
    id: trayGroup
    trayExpanded: island.trayExpanded
    activeTrayItem: island.activeTrayItem
    onOpenTrayMenu: island.openTrayMenu(item, ctxButton)
    onCloseTrayMenu: island.closeTrayMenu()
  }

  Rectangle {
    id: rightWorkspaceGroup
    x: island.lerp(pill.x + pill.width + 6, megaPanel.x + megaPanel.width - 1, island.mergeProgress)
    y: island.lerp(island.blockTopMargin, megaPanel.y, island.mergeProgress)
    width: island.lerp(rightRow.width + 24, island.megaWorkspacePanelWidth, island.mergeProgress)
    height: island.lerp(44, island.topMenuHeight, island.mergeProgress)
    color: colors.altBg
    radius: 10
    topLeftRadius: 10 * (1 - island.mergeProgress)
    bottomLeftRadius: 10 * (1 - island.mergeProgress)
    z: 3
    clip: true

    Rectangle {
      x: island.mergeProgress > 0
        ? island.lerp(
        ((rightWorkspaceGroup.width - rightRow.width) / 2)
          + Math.max(0, island.rightWorkspaceIndex()) * (island.workspaceButtonWidth + island.workspaceButtonSpacing),
        (rightWorkspaceGroup.width - island.workspaceButtonWidth) / 2,
        island.mergeProgress
      )
        : island.rightIndicatorX
      y: island.mergeProgress > 0
        ? island.lerp(
        (rightWorkspaceGroup.height - island.workspaceButtonHeight) / 2,
        (rightWorkspaceGroup.height - (5 * island.workspaceButtonHeight + 4 * island.megaWorkspaceSpacing)) / 2
          + Math.max(0, island.rightMergedWorkspaceIndex()) * (island.workspaceButtonHeight + island.megaWorkspaceSpacing),
        island.mergeProgress
      )
        : (rightWorkspaceGroup.height - island.workspaceButtonHeight) / 2
      width: island.workspaceButtonWidth
      height: island.workspaceButtonHeight
      radius: 8
      color: colors.accent
      opacity: island.rightIndicatorOpacity

      Behavior on x {
        enabled: island.rightIndicatorAnimate
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Behavior on y {
        enabled: island.rightIndicatorAnimate
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }
    }

    Row {
      id: rightRow
      anchors.centerIn: parent
      spacing: island.workspaceButtonSpacing
      visible: island.mergeProgress < 0.999
      opacity: 1 - island.mergeProgress

      Repeater {
        model: island.rightWorkspaces

        delegate: Rectangle {
          required property int modelData

          width: island.workspaceButtonWidth
          height: island.workspaceButtonHeight
          radius: 8
          color: "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.modelData
            color: island.workspaceIsActive(parent.modelData)
              ? colors.bg
              : (island.workspaceIsOccupied(parent.modelData) ? colors.fg : colors.muted)
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: island.activateWorkspace(parent.modelData)
          }
        }
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: island.megaWorkspaceSpacing
      visible: island.mergeProgress > 0.001
      opacity: island.mergeProgress

      Repeater {
        model: [10, 9, 8, 7, 6]

        delegate: Rectangle {
          required property int modelData

          width: island.workspaceButtonWidth
          height: island.workspaceButtonHeight
          radius: 8
          color: "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.modelData
            color: island.workspaceIsActive(parent.modelData)
              ? colors.bg
              : (island.workspaceIsOccupied(parent.modelData) ? colors.fg : colors.muted)
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: island.activateWorkspace(parent.modelData)
          }
        }
      }
    }
  }

  VolumeSlider {
    id: volumeSlider
  }
}
