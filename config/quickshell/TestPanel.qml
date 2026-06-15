import QtQuick
import Quickshell

PanelWindow {
  anchors { top: true; left: true; right: true }
  height: 50
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: "#323844"
    radius: 10
    Text {
      anchors.centerIn: parent
      text: "Quickshell Test - working!"
      color: "#dcdfe1"
      font.pixelSize: 18
      font.bold: true
    }
  }
}
