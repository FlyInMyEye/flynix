import QtQuick

Rectangle {
  Colors { id: colors }
  id: pill
  x: (parent.width - width) / 2
  y: blockTopMargin + pillYOffset
  width: (pillHover.hovered || menuExpanded || dragActive)
    ? sideInfoWidth * 2 + timeText.width + leftBullet.width + rightBullet.width + 64
    : timeText.width + 24
  height: 44
  color: colors.altBg
  radius: 10
  clip: true
  z: 4

  property int blockTopMargin: 3
  property real pillYOffset: 0
  property bool menuExpanded: false
  property bool dragActive: false
  property real sideInfoWidth: 0
  property string dayStr: ""
  property string fullTimeStr: ""
  property string shortTimeStr: ""
  property string dateStr: ""

  Behavior on width {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Text {
    id: dayLabel
    anchors.right: leftBullet.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    width: sideInfoWidth
    horizontalAlignment: Text.AlignLeft
    visible: pillHover.hovered || menuExpanded || dragActive
    text: dayStr
    color: colors.muted
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
  }

  Text {
    id: leftBullet
    anchors.right: timeText.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: pillHover.hovered || menuExpanded || dragActive
    text: "•"
    color: colors.muted
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
  }

  Text {
    id: timeText
    anchors.centerIn: parent
    text: (pillHover.hovered || menuExpanded || dragActive) ? fullTimeStr : shortTimeStr
    color: colors.fg
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
  }

  Text {
    id: rightBullet
    anchors.left: timeText.right
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: pillHover.hovered || menuExpanded || dragActive
    text: "•"
    color: colors.muted
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
  }

  Text {
    id: dateLabel
    anchors.left: rightBullet.right
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    width: sideInfoWidth
    horizontalAlignment: Text.AlignRight
    visible: pillHover.hovered || menuExpanded || dragActive
    text: dateStr
    color: colors.fg
    font.family: "CaskaydiaCove NF"
    font.pixelSize: 14
    font.bold: true
  }

  HoverHandler {
    id: pillHover
  }
}
