pragma Singleton
import QtQml

QtObject {
    readonly property real speed: 2
    function ms(milliseconds) {
        return Math.max(0, Math.round(milliseconds / speed));
    }
}
