import Quickshell
import Quickshell.Io

Process {
    id: root
    // Qt.resolvedUrl is a qs: URL inside Quickshell, not a CLI filesystem path.
    command: ["qs", "--no-duplicate", "--path", Quickshell.shellPath("lock.qml")]
    signal outputLine(string line)
    stdout: SplitParser {
        onRead: data => root.outputLine(data)
    }
    stderr: SplitParser {
        onRead: data => {
            console.error("Island lock:", data);
            root.outputLine(data);
        }
    }
}
