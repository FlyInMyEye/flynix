import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "colors.qml" as Theme

Rectangle {
  Colors { id: colors }
  id: trayGroup
  anchors.right: parent.right
  anchors.rightMargin: 6
  anchors.top: parent.top
  anchors.topMargin: 3
  width: trayExpanded ? Math.max(trayRow.width + 12, trayMenuColumn.childrenRect.width + 24) : trayRow.width + 12
  height: trayExpanded ? 44 + trayMenuColumn.childrenRect.height + 10 : 44
  color: colors.altBg
  radius: 10
  clip: true
  z: 3

  property bool trayExpanded: false
  property var activeTrayItem: null
  signal openTrayMenu(var item, var ctxButton)
  signal closeTrayMenu()

  Behavior on width {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Row {
    id: trayRow
    anchors.top: parent.top
    anchors.topMargin: 11
    anchors.right: parent.right
    anchors.rightMargin: 6
    spacing: 4

    Repeater {
      model: SystemTray.items

      delegate: Rectangle {
        id: trayButton
        required property var modelData

        width: 22
        height: 22
        radius: 8
        color: "transparent"

        IconImage {
          anchors.centerIn: parent
          implicitSize: 16
          source: modelData.icon
        }

        HoverHandler {
          id: trayButtonHover

          onHoveredChanged: {
            if (hovered && modelData.hasMenu) {
              trayGroup.openTrayMenu(modelData, trayButton)
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor

          onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
              if (modelData.onlyMenu && modelData.hasMenu) {
                trayGroup.openTrayMenu(modelData, trayButton)
              } else {
                trayGroup.closeTrayMenu()
                modelData.activate()
              }
            } else if (mouse.button === Qt.MiddleButton) {
              trayGroup.closeTrayMenu()
              modelData.secondaryActivate()
            }
          }
        }
      }
    }
  }

  HoverHandler {
    id: trayGroupHover

    onHoveredChanged: {
      if (!hovered) trayGroup.closeTrayMenu()
    }
  }

  QsMenuOpener {
    id: trayMenuOpener
    menu: trayGroup.activeTrayItem ? trayGroup.activeTrayItem.menu : null
  }

  Column {
    id: trayMenuColumn
    anchors.top: trayRow.bottom
    anchors.topMargin: 4
    anchors.right: parent.right
    anchors.rightMargin: 6
    spacing: 2
    visible: trayExpanded

    Repeater {
      model: trayMenuOpener.children

      delegate: Item {
        required property var modelData

        width: trayMenuEntry.implicitWidth
        height: modelData.isSeparator ? 9 : 30
        implicitWidth: trayMenuEntry.implicitWidth

        Rectangle {
          id: trayMenuEntry
          anchors.verticalCenter: parent.verticalCenter
          width: trayMenuRow.implicitWidth + 20
          height: modelData.isSeparator ? 1 : parent.height
          radius: modelData.isSeparator ? 0 : 8
          color: modelData.isSeparator ? colors.muted : (trayEntryHover.containsMouse ? colors.bg : "transparent")
          opacity: modelData.isSeparator ? 0.4 : 1
          implicitWidth: width

          Row {
            id: trayMenuRow
            visible: !modelData.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 8

            IconImage {
              anchors.verticalCenter: parent.verticalCenter
              implicitSize: 14
              source: modelData.icon
              visible: modelData.icon !== ""
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.text
              color: modelData.enabled ? colors.fg : colors.muted
              font.family: "CaskaydiaCove NF"
              font.pixelSize: 13
              font.bold: true
            }

            Item {
              width: modelData.hasChildren ? 12 : 0
              height: 1
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.hasChildren ? ">" : ""
              color: colors.muted
              font.family: "CaskaydiaCove NF"
              font.pixelSize: 13
              font.bold: true
            }
          }

          MouseArea {
            id: trayEntryHover
            visible: !modelData.isSeparator
            anchors.fill: parent
            hoverEnabled: true
            enabled: !modelData.isSeparator && modelData.enabled
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              if (modelData.hasChildren) {
                modelData.display(trayGroup, trayGroup.width - 12, 44)
              } else {
                modelData.triggered()
                trayGroup.closeTrayMenu()
              }
            }
          }
        }
      }
    }
  }
}
