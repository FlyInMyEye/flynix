import QtQml

QtObject {
    readonly property int focusDelay: 125
    readonly property int idleSeconds: 120
    readonly property int topMargin: 8
    readonly property int reservedHeight: topMargin + 40 + 8
    // Inactivity after leaving a drawer; zero disables automatic dismissal.
    readonly property int clipboardTimeout: 8000
    readonly property int trayTimeout: 5000
    readonly property bool mediaProgressIdle: true
    readonly property string pamService: "quickshell-island"
    // Nix installs the image selected in hosts/hp-laptop/theme.nix here.
    readonly property url lockWallpaper: "file:///etc/quickshell/lock-wallpaper"
    readonly property bool greeting: false
    // OpenAI-compatible endpoint. Empty disables network chat until configured.
    // Credentials are read only by the helper from ISLAND_AI_KEY_FILE.
    readonly property string aiEndpoint: ""
    readonly property string aiModel: ""
}
