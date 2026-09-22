import QtQuick
import Quickshell.Io

QtObject {
  id: colors

  property string bg: "#2e3440"
  property string fg: "#e5e9f0"
  property string altBg: "#3b4252"
  property string muted: "#4c566a"
  property string accent: "#81a1c1"
  property string red: "#bf616a"
  property string green: "#a3be8c"
  property string yellow: "#ebcb8b"
  property string blue: "#81a1c1"
  property string cyan: "#88c0d0"
  property string magenta: "#b48ead"
  property bool hibernationEnabled: true

  property string _lastJson: ""

  function updateColors(json) {
    try {
      var o = JSON.parse(json);
      if (o.bg) colors.bg = o.bg;
      if (o.fg) colors.fg = o.fg;
      if (o.altBg) colors.altBg = o.altBg;
      if (o.muted) colors.muted = o.muted;
      if (o.accent) colors.accent = o.accent;
      if (o.red) colors.red = o.red;
      if (o.green) colors.green = o.green;
      if (o.blue) colors.blue = o.blue;
      if (o.cyan) colors.cyan = o.cyan;
      if (o.magenta) colors.magenta = o.magenta;
      if (typeof o.hibernationEnabled === "boolean") colors.hibernationEnabled = o.hibernationEnabled;
    } catch (_) {}
  }

  Component.onCompleted: {
    var reader = Qt.createQmlObject(
      'import Quickshell.Io; import QtQml; Process { id: _p; property QtObject target: null; command: ["sh", "-c", "cat ${HOME:-/home/archbtw}/.config/quickshell/colors.json"]; stdout: StdioCollector { onStreamFinished: { if (this.text !== _p.target._lastJson) { _p.target._lastJson = this.text; _p.target.updateColors(this.text); } } } }',
      colors, "colorReader"
    );
    reader.target = colors;
    Qt.createQmlObject(
      'import QtQuick; Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: parent.running = true }',
      reader, "colorTimer"
    );
  }
}
