import QtQuick
import Quickshell

Item {
    id: root
    required property var theme
    property var entries: []
    signal chosen(var entry)
    property real maximumColumnHeight: 600
    readonly property var layout: {
        var placed = [], column = 0, y = 0;
        for (var entry of entries) {
            var h = entry.isSeparator ? 9 : 32;
            if (y && y + h > maximumColumnHeight) {
                column++;
                y = 0;
            }
            placed.push({
                entry: entry,
                column: column,
                offset: y,
                rowHeight: h
            });
            y += h;
        }
        return placed;
    }
    readonly property int columnCount: layout.length ? layout[layout.length - 1].column + 1 : 1
    readonly property real naturalHeight: layout.reduce((height, row) => Math.max(height, row.offset + row.rowHeight), 0)
    Repeater {
        model: root.layout
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property var entry: modelData.entry
            objectName: "trayAction:" + (entry.isSeparator ? "separator" : entry.text)
            x: modelData.column * root.width / root.columnCount
            y: modelData.offset
            width: root.width / root.columnCount - (root.columnCount > 1 ? 8 : 0)
            height: entry.isSeparator ? 9 : 32
            radius: 9
            color: mouse.containsMouse && !entry.isSeparator && entry.enabled ? root.theme.altBg : "transparent"
            opacity: entry.isSeparator || entry.enabled ? 1 : 0.38
            Behavior on color {
                ColorAnimation {
                    duration: Motion.ms(100)
                }
            }
            Rectangle {
                visible: row.entry.isSeparator
                anchors.centerIn: parent
                width: parent.width - 16
                height: 1
                color: Qt.alpha(root.theme.fg, 0.12)
            }
            Item {
                anchors.fill: parent
                visible: !row.entry.isSeparator
                Text {
                    x: 9
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.entry.buttonType === QsMenuButtonType.RadioButton ? (row.entry.checkState === Qt.Checked ? "●" : "○") : row.entry.buttonType === QsMenuButtonType.CheckBox ? (row.entry.checkState === Qt.Checked ? "✓" : "□") : ""
                    color: root.theme.accent
                    font {
                        family: root.theme.font
                        pixelSize: 12
                    }
                }
                Image {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    visible: row.entry.buttonType === QsMenuButtonType.None && !!row.entry.icon
                    source: visible ? row.entry.icon : ""
                }
                Text {
                    x: 31
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 55
                    text: (row.entry.text || "").replace(/&&/g, "\u0001").replace(/&/g, "").replace(/\u0001/g, "&")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.theme.fg
                    font {
                        family: root.theme.font
                        pixelSize: 11
                    }
                }
                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.entry.hasChildren ? "›" : ""
                    color: root.theme.muted
                    font {
                        family: root.theme.font
                        pixelSize: 16
                    }
                }
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                enabled: !row.entry.isSeparator && row.entry.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(row.entry)
            }
        }
    }
}
