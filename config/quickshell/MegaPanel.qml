import QtQuick
import Quickshell.Io

Rectangle {
  Colors { id: colors }
  id: megaPanel
  anchors.horizontalCenter: parent.horizontalCenter
  y: blockTopMargin - topMenuHeight + revealOffset
  width: megaPanelWidth
  height: topMenuHeight
  color: colors.altBg
  radius: 0
  opacity: revealProgress
  clip: true
  z: 1

  property int blockTopMargin: 3
  property int topMenuHeight: 182
  property real revealOffset: 0
  property real revealProgress: 0
  property real megaPanelWidth: 200
  property string mediaStatus: ""
  property string mediaPlayer: ""
  property string mediaTitle: ""
  property string mediaArtist: ""
  property string mediaArtUrl: ""
  property string dayStr: ""
  property string fullTimeStr: ""
  property string dateStr: ""

  Process {
    id: mediaControlPrev
    command: ["playerctl", "previous"]
  }

  Process {
    id: mediaControlToggle
    command: ["playerctl", "play-pause"]
  }

  Process {
    id: mediaControlNext
    command: ["playerctl", "next"]
  }

  Rectangle {
    anchors.fill: parent
    anchors.top: parent.top
    anchors.topMargin: 12
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    color: colors.bg
    opacity: 0.55
    radius: 14

    Column {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      Item {
        id: mediaTitleViewport
        width: parent.width
        height: 28
        clip: true

        property string displayText: megaPanel.mediaTitle || (megaPanel.dayStr + "  " + megaPanel.fullTimeStr)
        property real overflow: Math.max(0, mediaTitleText.implicitWidth - width)
        property real marqueeOffset: 0

        Text {
          id: mediaTitleText
          x: mediaTitleViewport.overflow > 0
            ? mediaTitleViewport.marqueeOffset
            : (mediaTitleViewport.width - implicitWidth) / 2
          anchors.verticalCenter: parent.verticalCenter
          text: mediaTitleViewport.displayText
          color: colors.fg
          font.family: "CaskaydiaCove NF"
          font.pixelSize: 18
          font.bold: true
        }

        SequentialAnimation on marqueeOffset {
          running: mediaTitleViewport.overflow > 0 && megaPanel.revealProgress > 0.9
          loops: Animation.Infinite

          PauseAnimation { duration: 700 }
          NumberAnimation {
            from: 0
            to: -mediaTitleViewport.overflow
            duration: Math.max(3200, mediaTitleViewport.overflow * 40)
            easing.type: Easing.Linear
          }
          PauseAnimation { duration: 500 }
          NumberAnimation {
            from: -mediaTitleViewport.overflow
            to: 0
            duration: 1
          }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 20
          visible: mediaTitleViewport.overflow > 0
          color: "transparent"
          opacity: 0.55

          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: colors.bg }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 20
          visible: mediaTitleViewport.overflow > 0
          color: "transparent"
          opacity: 0.55

          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: colors.bg }
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Rectangle {
          width: 92
          height: 92
          radius: 12
          color: colors.altBg
          clip: true

          Image {
            anchors.fill: parent
            source: megaPanel.mediaArtUrl
            fillMode: Image.PreserveAspectCrop
            visible: megaPanel.mediaArtUrl !== ""
          }

          Text {
            anchors.centerIn: parent
            text: megaPanel.mediaPlayer ? megaPanel.mediaPlayer.charAt(0).toUpperCase() : "♪"
            color: colors.fg
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 32
            font.bold: true
            visible: megaPanel.mediaArtUrl === ""
          }
        }

        Column {
          width: 120
          spacing: 8

          Text {
            width: parent.width
            text: megaPanel.mediaArtist || megaPanel.dateStr
            color: colors.muted
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
          }

          Rectangle {
            width: parent.width
            height: 30
            radius: 8
            color: colors.altBg

            Text {
              anchors.centerIn: parent
              text: megaPanel.mediaStatus === "Playing" ? "⏮  ⏸  ⏭" : "⏮  ▶  ⏭"
              color: colors.fg
              font.pixelSize: 16
              font.bold: true
            }

            Row {
              anchors.fill: parent

              MouseArea {
                width: parent.width / 3
                height: parent.height
                enabled: megaPanel.mediaPlayer !== ""
                onClicked: mediaControlPrev.startDetached()
              }

              MouseArea {
                width: parent.width / 3
                height: parent.height
                enabled: megaPanel.mediaPlayer !== ""
                onClicked: mediaControlToggle.startDetached()
              }

              MouseArea {
                width: parent.width / 3
                height: parent.height
                enabled: megaPanel.mediaPlayer !== ""
                onClicked: mediaControlNext.startDetached()
              }
            }
          }

          Text {
            width: parent.width
            text: megaPanel.mediaPlayer ? (megaPanel.mediaPlayer + (megaPanel.mediaStatus ? "  " + megaPanel.mediaStatus : "")) : "No active player"
            color: colors.muted
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
