import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
  Colors { id: colors }
  id: launcherPanel
  anchors.left: parent.left
  anchors.leftMargin: 6
  anchors.top: parent.top
  anchors.topMargin: blockTopMargin
  width: launcherHover.containsMouse ? launcherRow.width + 12 : 44
  height: 44
  color: colors.altBg
  radius: 10
  clip: true
  z: 3

  property int blockTopMargin: 3

  Process {
    id: lockScreen
    command: ["hyprlock"]
  }

  Process {
    id: powerMenu
    command: ["wlogout", "-b", "5", "-r", "1"]
  }

  Behavior on width {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Row {
    id: launcherRow
    anchors.left: parent.left
    anchors.leftMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    Rectangle {
      width: 32
      height: 32
      radius: 8
      color: "transparent"

      Text {
        anchors.centerIn: parent
        text: ""
        color: "#5178C4"
        font.family: "CaskaydiaCove NF"
        font.pixelSize: 18
        font.bold: true

        rotation: launcherHover.containsMouse ? 180 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
          }
        }
      }
    }

    Rectangle {
      width: 52
      height: 32
      radius: 8
      color: colors.bg
      visible: launcherHover.containsMouse

      Text {
        anchors.centerIn: parent
        text: "Lock"
        color: colors.fg
        font.family: "CaskaydiaCove NF"
        font.pixelSize: 13
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: lockScreen.startDetached()
      }
    }

    Rectangle {
      width: 58
      height: 32
      radius: 8
      color: colors.bg
      visible: launcherHover.containsMouse

      Text {
        anchors.centerIn: parent
        text: "Power"
        color: colors.red
        font.family: "CaskaydiaCove NF"
        font.pixelSize: 13
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: powerMenu.startDetached()
      }
    }
  }

  MouseArea {
    id: launcherHover
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
