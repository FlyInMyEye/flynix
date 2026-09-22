import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pam
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."
import "../lock"
import "../logic/State.js" as Logic

ShellRoot {
    id: testRoot
    Theme {
        id: palette
    }
    Settings {
        id: preferences
    }
    StateMachine {
        id: stateMachine
    }
    Services {
        id: backend
        machine: stateMachine
        settings: preferences
        enabled: false
    }
    QtObject {
        id: fixtureNetwork
        property string name: "Test Wi-Fi"
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property real signalStrength: 0.85
        property int security: WifiSecurityType.Wpa2Psk
        property int requests: 0
        signal connectionFailed(int reason)
        function connectWithPsk(secret) { requests++; }
        function connect() { requests++; }
        function disconnect() { connected = false; }
    }
    QtObject {
        id: fixtureWifi
        property int type: DeviceType.Wifi
        property bool connected: false
        property bool scannerEnabled: false
        property var networks: ({values: [fixtureNetwork]})
    }
    QtObject {
        id: fixtureNetworking
        property bool wifiEnabled: true
        property bool wifiHardwareEnabled: true
        property var devices: ({values: [fixtureWifi]})
    }
    QtObject {
        id: fixtureHeadphones
        property string name: "Headphones"
        property bool connected: false
        property bool paired: true
    }
    QtObject {
        id: fixtureAdapter
        property bool enabled: true
        property var devices: ({values: [fixtureHeadphones]})
    }
    QtObject {
        id: fixtureBluetooth
        property var defaultAdapter: fixtureAdapter
    }
    QtObject {
        id: fakePlayer
        property real position: 60
        property real length: 300
        property bool positionSupported: true
        property bool lengthSupported: true
        property int playbackState: MprisPlaybackState.Playing
        readonly property bool isPlaying: playbackState === MprisPlaybackState.Playing
        property real rate: 1
        property int uniqueId: 1
        property string dbusName: "org.mpris.MediaPlayer2.fixture"
        signal postTrackChanged
    }
    MediaProgress {
        id: mediaFixture
        player: fakePlayer
        enabled: false
        pollEnabled: false
    }
    QtObject {
        id: fakePam
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property int starts: 0
        property int responses: 0
        property bool startWorks: true
        signal completed(int result)
        signal pamMessage
        signal error(int error)
        function start() {
            starts++;
            active = startWorks;
            responseRequired = startWorks;
            return startWorks;
        }
        function respond(value) {
            responses++;
            responseRequired = false;
        }
    }
    LockController {
        id: authenticationFixture
        secure: false
        pam: fakePam
        onAuthenticated: suite.unlocks++
    }
    LockExit {
        id: exitFixture
        controller: authenticationFixture
        onReadyForUnlock: suite.releases++
    }
    LockProcess {
        id: lockLaunchProbe
        property string output: ""
        onOutputLine: line => output += line + "\n"
    }
    Shortcuts {
        id: shortcuts
        machine: stateMachine
        services: backend
    }
    Component.onCompleted: Quickshell.watchFiles = false
    FloatingWindow {
        id: testWindow
        implicitWidth: 1000
        implicitHeight: 700
        visible: true
        color: "#30343f"
        Rectangle {
            anchors.fill: parent
            color: "#30343f"
            MouseArea {
                anchors.fill: parent
                onClicked: suite.outsideClicks++
            }
        }
        IslandSurface {
            id: surface
            anchors.fill: parent
            machine: stateMachine
            services: backend
            settings: preferences
            theme: palette
            hostWindow: testWindow
        }
        LockView {
            id: lockPreview
            anchors.fill: parent
            visible: suite.previewLock
            theme: palette
            wallpaper: Quickshell.env("ISLAND_TEST_WALLPAPER")
            controller: authenticationFixture
            exitProgress: exitFixture.progress
            userName: "archbtw"
        }
        TestCase {
            id: suite
            name: "IslandInteractions"
            when: false
            property int outsideClicks: 0
            property int launched: 0
            property int unlocks: 0
            property int releases: 0
            property bool previewLock: false
            function check(condition, message) {
                if (!condition)
                    console.error("ASSERTION: " + message);
                verify(condition, message);
            }
            function init() {
                var selectedTest = Quickshell.env("ISLAND_SMOKE_TEST");
                if (selectedTest && selectedTest !== qtest_results.functionName)
                    skip("Not selected");
                mouseMove(surface, 10, 650);
                wait(180);
                stateMachine.data = Logic.initial();
                stateMachine.hovered = false;
                stateMachine.previousTick = Date.now();
                stateMachine.now = Date.now();
                stateMachine.revision++;
                backend.history = [];
                backend.lastHash = "";
                backend.combo = 0;
                backend.shelf.slice().forEach(url => backend.consume(url));
                backend.appUsage = ({});
                backend.usageQueue = [];
                launched = 0;
                var launcher = findChild(surface, "launcher");
                launcher.availableApps = [
                    {
                        id: "browser",
                        name: "Firefox",
                        genericName: "Web browser",
                        icon: "firefox",
                        keywords: ["internet"],
                        execute: () => launched++
                    },
                    {
                        id: "terminal",
                        name: "Kitty",
                        genericName: "Terminal",
                        icon: "utilities-terminal",
                        keywords: ["shell"],
                        execute: () => launched++
                    },
                    {
                        id: "editor",
                        name: "Visual Studio Code",
                        genericName: "Code editor",
                        icon: "code",
                        keywords: ["text"],
                        execute: () => launched++
                    }
                ];
                settled();
                wait(420);
            }
            function settled() {
                tryVerify(() => !surface.transitioning, 1800, "The latest transition settles");
            }
            function cleanup() {
                backend.radios.networkBackend = Networking;
                backend.radios.bluetoothBackend = Bluetooth;
                lockLaunchProbe.running = false;
                console.log("CASE", qtest_results.functionName, qtest_results.failed ? "FAIL" : "PASS");
                var timeout = findChild(surface, "panelTimeout");
                timeout.interval = Qt.binding(() => surface.clipboardOpen ? preferences.clipboardTimeout : preferences.trayTimeout);
                backend.mediaPlaying = Qt.binding(() => backend.player !== null && backend.player.isPlaying);
                backend.mediaAvailable = Qt.binding(() => backend.mediaStatus.available);
                backend.mediaProgress = Qt.binding(() => backend.mediaStatus.progress);
                mediaFixture.enabled = false;
                mediaFixture.player = fakePlayer;
                previewLock = false;
                authenticationFixture.secure = false;
                fakePam.active = false;
                fakePam.responseRequired = false;
                fakePam.startWorks = true;
                authenticationFixture.phase = "LOCK_REQUESTED";
                authenticationFixture.error = false;
                unlocks = 0;
                releases = 0;
            }
            function shot(name, target) {
                var done = false;
                (target || surface.capsuleItem).grabToImage(result => {
                    result.saveToFile(Quickshell.env("ISLAND_SMOKE_ARTIFACTS") + "/" + name + ".png");
                    done = true;
                });
                tryVerify(() => done, 2000);
            }
            function test_01_clock_center() {
                var group = findChild(surface, "clockGroup");
                var capsule = surface.capsuleItem;
                stateMachine.hover(true);
                wait(450);
                var p = group.mapToItem(capsule, group.width / 2, group.height / 2);
                check(Math.abs(p.x - capsule.width / 2) < 0.5, "Full hh:mm:ss must be centered");
                check(group.width > 60, "Seconds must expand the same clock group");
                shot("clock-expanded");
            }
            function test_02_clipboard_is_nonmodal() {
                var clock = findChild(surface, "clockGroup");
                stateMachine.open("clipboard");
                settled();
                check(!surface.modal && surface.cardOpen, "Clipboard must not be modal");
                check(findChild(surface, "clockGroup") === clock, "Drawer preserves the original clock object");
                var p = clock.mapToItem(surface.capsuleItem, 0, 20);
                check(Math.abs(p.y - 20) < 0.5, "Clock stays at the top during expansion");
                var before = outsideClicks;
                mouseClick(surface, 40, 500);
                compare(outsideClicks, before + 1, "Outside click must reach the underlying window content");
                compare(stateMachine.state, "CLIPBOARD");
                shot("clipboard");
                mouseClick(findChild(surface, "islandHeader"), 170, 20);
                check(!surface.cardOpen, "Clicking the clock closes its drawer");
            }
            function test_03_pull_is_continuous() {
                var header = findChild(surface, "islandHeader");
                mousePress(header, header.width / 2, 20, Qt.LeftButton);
                mouseMove(surface, 500, 95, 30, Qt.LeftButton);
                wait(30);
                check(surface.pulling, "Downward pointer movement must start a pull");
                check(surface.capsuleItem.height > 40 && surface.capsuleItem.height < surface.cardHeight, "Pull reveals an intermediate shape before release");
                shot("clipboard-pull");
                var previousHeight = surface.capsuleItem.height;
                var previousWidth = surface.capsuleItem.width;
                mouseRelease(surface, 500, 95, Qt.LeftButton);
                check(surface.capsuleItem.height < surface.cardHeight - 1, "Release must animate from the pulled size rather than snap open");
                for (var frame = 0; frame < 30; ++frame) {
                    check(surface.capsuleItem.height >= previousHeight - 0.5, "Release must never collapse the drawn height");
                    check(surface.capsuleItem.width >= previousWidth - 0.5, "Release must never collapse the drawn width");
                    previousHeight = surface.capsuleItem.height;
                    previousWidth = surface.capsuleItem.width;
                    wait(16);
                }
                compare(stateMachine.state, "CLIPBOARD");
                compare(Math.round(surface.capsuleItem.height), Math.round(surface.cardHeight));
            }
            function test_04_workspace_focus_nulls() {
                backend.workspaces.observe(7);
                stateMachine.setFlag("workspace", true);
                wait(450);
                var marker = findChild(surface, "workspaceMarker");
                var x = marker.lead;
                backend.workspaces.observe(0);
                backend.workspaces.observe(-99);
                wait(100);
                compare(backend.workspaces.activeId, 7);
                compare(marker.lead, x, "Null focus must not move to workspace 1");
                backend.workspaces.observe(2);
                wait(60);
                check(marker.lead < x && marker.lead > 37, "Indicator must interpolate between actual workspaces");
                check(marker.stretch > 1, "Moving bead must stretch, not just translate a rigid shape");
                shot("workspace-stretch");
                wait(500);
                compare(marker.lead, 37);
                check(marker.stretch < 0.1, "Bead settles back to a ring");
                compare(backend.workspaces.ids.length, 10);
                shot("workspaces");
            }
            function test_05_morph_interruptions() {
                for (var name of ["clipboard", "launcher", "tray", "stats", "clipboard"]) {
                    stateMachine.toggle(name);
                    wait(70);
                    check(surface.capsuleItem.width >= 17 && surface.capsuleItem.width < surface.width, "Interrupted width remains bounded");
                    check(surface.capsuleItem.height >= 17 && surface.capsuleItem.height < surface.height, "Interrupted height remains bounded");
                }
                stateMachine.dismiss();
                settled();
                wait(420);
                compare(Math.round(surface.capsuleItem.height), 40);
                compare(Math.round(surface.capsuleItem.width), 100);
            }
            function test_06_combo_updates_visible_text() {
                backend.ingest({
                    type: "copy",
                    digest: "a"
                });
                backend.ingest({
                    type: "copy",
                    digest: "a"
                });
                backend.ingest({
                    type: "copy",
                    digest: "a"
                });
                wait(250);
                compare(findChild(surface, "noticeText").text, "Copied ×3");
                stateMachine.open("clipboard");
                var remaining = stateMachine.current.remaining;
                wait(200);
                check(Math.abs(stateMachine.current.remaining - remaining) < 60, "Captured notification timer stays paused");
            }
            function test_07_relay_removal_preserves_other_chips() {
                backend.pin(["file:///tmp/one.pdf", "file:///tmp/two.png", "file:///tmp/three.txt"]);
                wait(450);
                var first = findChild(surface, "shelfChip:file:///tmp/one.pdf");
                check(first !== null, "First chip exists");
                backend.consume("file:///tmp/two.png");
                wait(250);
                compare(backend.shelfModel.count, 2);
                check(findChild(surface, "shelfChip:file:///tmp/one.pdf") === first, "Removing a chip must not rebuild the shelf");
                shot("relay");
            }
            function test_08_launcher_focus_and_escape() {
                stateMachine.open("launcher");
                wait(500);
                check(surface.modal, "Launcher owns modal input");
                var search = findChild(surface, "launcherSearch");
                check(search.activeFocus, "Launcher search receives keyboard focus");
                settled();
                shot("launcher");
                keyClick(Qt.Key_A);
                compare(search.text, "a");
                keyClick(Qt.Key_Escape);
                wait(450);
                check(!surface.modal, "Escape releases modal input");
            }
            function test_09_lock_suspends_normal_services() {
                stateMachine.open("launcher");
                stateMachine.beginLock();
                backend.ingest({
                    type: "copy",
                    digest: "secret"
                });
                stateMachine.toggle("clipboard");
                stateMachine.notify("Must not display", "notice", true, "test");
                compare(stateMachine.state, "LOCKING");
                compare(stateMachine.current, null);
                compare(stateMachine.data.queue.length, 0);
                var component = Qt.createComponent(Qt.resolvedUrl("../lock.qml"));
                check(component.status === Component.Ready, component.errorString());
            }
            function test_10_restore_is_silent_but_new_copy_is_not() {
                backend.ingest({
                    type: "restoring",
                    digest: "restored"
                });
                backend.ingest({
                    type: "copy",
                    digest: "restored"
                });
                compare(stateMachine.current, null);
                backend.ingest({
                    type: "copy",
                    digest: "new"
                });
                compare(stateMachine.current.text, "Copied");
                compare(backend.combo, 1);
            }
            function test_11_both_super_keys_preserve_hold() {
                shortcuts.leftHeld = true;
                shortcuts.updateHold();
                shortcuts.rightHeld = true;
                shortcuts.updateHold();
                shortcuts.leftHeld = false;
                shortcuts.updateHold();
                compare(stateMachine.state, "WORKSPACES");
                shortcuts.rightHeld = false;
                shortcuts.updateHold();
                check(stateMachine.state !== "WORKSPACES", "Last Super release must end the hold");
            }
            function test_12_recording_clock_has_no_wall_seconds() {
                backend.recordingSince = Date.now() - 72000;
                backend.recording = true;
                stateMachine.hover(true);
                wait(450);
                var group = findChild(surface, "clockGroup");
                compare(group.children[1].width, 0, "Recording elapsed time cannot append wall-clock seconds");
                backend.recording = false;
            }
            function test_13_hovered_clock_pull_and_cancel() {
                var header = findChild(surface, "islandHeader");
                mouseMove(header, header.width / 2, 20);
                wait(450);
                var before = surface.capsuleItem.width;
                check(before > 200, "Begin from the expanded hover clock");
                mousePress(header, header.width / 2, 20, Qt.LeftButton);
                mouseMove(surface, 500, 43, 30, Qt.LeftButton);
                check(surface.capsuleItem.width >= before - 0.5, "Starting a pull must preserve current width");
                mouseRelease(surface, 500, 43, Qt.LeftButton);
                wait(500);
                check(!surface.pulling && !surface.cardOpen, "A short pull cancels without opening a drawer");
                check(!stateMachine.data.pointerCapture, "Cancelled pulls release capture");
                compare(Math.round(surface.capsuleItem.height), 40);
            }
            function test_14_workspace_reversal_keeps_current_shape() {
                stateMachine.setFlag("workspace", true);
                backend.workspaces.observe(2);
                wait(500);
                var marker = findChild(surface, "workspaceMarker");
                backend.workspaces.observe(9);
                wait(85);
                var before = marker.lead;
                backend.workspaces.observe(4);
                check(Math.abs(marker.lead - before) < 0.5, "A reversal must start from the current position");
                wait(520);
                compare(marker.lead, 73);
                check(marker.stretch < 0.1, "Rapid changes cannot leave a stretched marker behind");
            }
            function test_15_tray_hover_actions_and_disabled_entries() {
                var tray = findChild(surface, "trayDrawer");
                var originalItems = tray.items;
                var invoked = 0;
                var item = {
                    id: "fixture",
                    title: "Player",
                    tooltipTitle: "Player",
                    icon: "",
                    hasMenu: false,
                    onlyMenu: false,
                    activate: () => {},
                    secondaryActivate: () => {}
                };
                tray.items = [item];
                tray.menuEntries = [
                    {
                        text: "Unavailable",
                        enabled: false,
                        isSeparator: false,
                        buttonType: 0,
                        icon: "",
                        hasChildren: false,
                        triggered: () => invoked += 100
                    },
                    {
                        text: "Repeat",
                        enabled: true,
                        isSeparator: false,
                        buttonType: 1,
                        checkState: Qt.Checked,
                        icon: "",
                        hasChildren: false,
                        triggered: () => invoked++
                    },
                    {
                        text: "Quit",
                        enabled: true,
                        isSeparator: false,
                        buttonType: 0,
                        icon: "",
                        hasChildren: false,
                        triggered: () => invoked++
                    }
                ];
                stateMachine.open("tray");
                settled();
                var icon = findChild(surface, "trayIcon:fixture");
                mouseMove(icon, 16, 19);
                wait(180);
                compare(tray.selectedItem, item, "Hover must select the tray menu");
                wait(450);
                check(surface.capsuleItem.height > 170, "Tray grows to reveal its actions");
                var disabled = findChild(surface, "trayAction:Unavailable");
                mouseClick(disabled, 80, 16);
                compare(invoked, 0);
                mouseClick(findChild(surface, "trayAction:Repeat"), 80, 16);
                compare(invoked, 1);
                compare(stateMachine.state, "TRAY", "Toggles keep the menu open");
                shot("tray-actions");
                mouseClick(findChild(surface, "trayAction:Quit"), 80, 16);
                compare(invoked, 2);
                check(stateMachine.state !== "TRAY", "Normal actions close the drawer");
                tray.items = originalItems;
                tray.menuEntries = Qt.binding(() => tray.currentEntries);
            }
            function test_16_tray_hover_intent_and_item_removal() {
                var tray = findChild(surface, "trayDrawer");
                var originalItems = tray.items;
                var first = {
                    id: "one",
                    title: "One",
                    icon: "",
                    hasMenu: false
                };
                var second = {
                    id: "two",
                    title: "Two",
                    icon: "",
                    hasMenu: false
                };
                tray.items = [first, second];
                stateMachine.open("tray");
                settled();
                var icon = findChild(surface, "trayIcon:one");
                var x = icon.mapToItem(surface, 0, 0).x;
                mouseMove(icon, 16, 19);
                wait(40);
                mouseMove(findChild(surface, "trayIcon:two"), 16, 19);
                wait(180);
                compare(tray.selectedItem, second, "Passing over one icon must not open its menu later");
                wait(400);
                compare(icon.mapToItem(surface, 0, 0).x, x, "Menu expansion must not move the icon row");
                tray.items = [first];
                compare(tray.selectedItem, null, "Removed applications must release their menu");
                tray.items = originalItems;
            }
            function test_17_drawer_timeouts_respect_hover_and_drag() {
                var timeout = findChild(surface, "panelTimeout");
                timeout.interval = 120;
                for (var name of ["clipboard", "tray"]) {
                    stateMachine.open(name);
                    settled();
                    wait(220);
                    check(!surface.cardOpen, name + " closes after inactivity outside");
                }
                stateMachine.open("clipboard");
                mouseMove(surface, 500, 28);
                settled();
                wait(250);
                compare(stateMachine.state, "CLIPBOARD", "Hover keeps history open");
                stateMachine.setFlag("dragging", true);
                mouseMove(surface, 20, 600);
                wait(250);
                compare(stateMachine.state, "CLIPBOARD", "Dragging keeps history open outside its bounds");
                stateMachine.setFlag("dragging", false);
                wait(220);
                check(!surface.cardOpen, "Finishing a drag starts a fresh timeout");
            }
            function test_18_timeout_does_not_dismiss_workspace_hold() {
                var timeout = findChild(surface, "panelTimeout");
                timeout.interval = 120;
                stateMachine.open("tray");
                stateMachine.setFlag("workspace", true);
                wait(240);
                compare(stateMachine.state, "WORKSPACES");
                check(stateMachine.data.tray, "Hidden drawer is retained during a modifier hold");
                stateMachine.setFlag("workspace", false);
                compare(stateMachine.state, "TRAY");
                settled();
                wait(220);
                check(!surface.cardOpen);
                timeout.interval = 0;
                stateMachine.open("clipboard");
                wait(250);
                compare(stateMachine.state, "CLIPBOARD", "Zero disables dismissal");
            }
            function test_19_tray_expands_all_actions_into_columns() {
                var tray = findChild(surface, "trayDrawer");
                var originalItems = tray.items;
                var item = {
                    id: "long-menu",
                    title: "Long menu",
                    icon: "",
                    hasMenu: false
                };
                var entries = [];
                for (var i = 0; i < 40; ++i)
                    entries.push({
                        text: "Action " + i,
                        enabled: true,
                        isSeparator: false,
                        buttonType: 0,
                        icon: "",
                        hasChildren: false,
                        triggered: () => {}
                    });
                tray.items = [item];
                tray.menuEntries = entries;
                stateMachine.open("tray");
                tray.select(item);
                wait(500);
                var menu = findChild(surface, "trayMenu");
                check(menu.columnCount > 1, "Tall menus use columns rather than a scroll area");
                check(menu.contentY === undefined, "The menu is not a Flickable");
                for (var j = 0; j < entries.length; ++j) {
                    var row = findChild(surface, "trayAction:Action " + j);
                    check(row !== null, "Every action is instantiated");
                    var position = row.mapToItem(surface, 0, 0);
                    check(position.y >= 0 && position.y + row.height <= surface.height, "Every action fits vertically on screen");
                    check(position.x >= 0 && position.x + row.width <= surface.width, "Every column fits horizontally on screen");
                }
                shot("tray-full-menu");
                tray.items = originalItems;
                tray.menuEntries = Qt.binding(() => tray.currentEntries);
            }
            function test_20_image_previews_render_and_clear() {
                backend.history = [
                    {
                        id: "9",
                        image: true,
                        preview: "binary image"
                    }
                ];
                stateMachine.open("clipboard");
                var url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFElEQVR4nGNYuuVP2/s1DEAMZAEAPYgI7bYffO4AAAAASUVORK5CYII=";
                backend.ingest({
                    type: "preview",
                    id: "9",
                    url: url
                });
                wait(500);
                var preview = findChild(surface, "clipboardImage:9");
                check(preview !== null, "Image entries contain a preview");
                tryCompare(preview, "status", Image.Ready, 2000);
                shot("clipboard-image");
                stateMachine.dismiss();
                compare(Object.keys(backend.previews).length, 0, "Closing history clears decoded images");
                backend.ingest({
                    type: "preview",
                    id: "9",
                    url: url
                });
                compare(Object.keys(backend.previews).length, 0, "Late replies cannot repopulate a closed card");
                stateMachine.open("clipboard");
                backend.ingest({
                    type: "preview",
                    id: "9",
                    url: url
                });
                stateMachine.beginLock();
                compare(Object.keys(backend.previews).length, 0, "Locking clears image previews");
            }
            function test_21_media_border_follows_all_views() {
                var border = findChild(surface, "mediaProgressBorder");
                backend.mediaPlaying = true;
                backend.mediaAvailable = true;
                backend.mediaProgress = 0.4;
                wait(260);
                check(border.visible, "Playing media has a progress border on the idle clock");
                compare(border.lineWidth, 4);
                shot("idle-media");
                backend.mediaProgress = 0.85;
                wait(60);
                check(border.progress > 0.4 && border.progress < 0.85, "A forward seek interpolates instead of jumping");
                wait(200);
                compare(border.progress, 0.85);
                backend.mediaProgress = 0.2;
                wait(60);
                check(border.progress > 0.2 && border.progress < 0.85, "A backward seek also interpolates");
                stateMachine.open("clipboard");
                check(border.visible, "Clipboard retains media progress");
                for (var panel of ["stats", "tray", "launcher"]) {
                    stateMachine.open(panel);
                    settled();
                    check(border.visible && border.opacity > 0, panel + " retains the progress border");
                    compare(Math.round(border.width), Math.round(surface.capsuleItem.width), "The border follows the capsule shape");
                }
                stateMachine.dismiss();
                stateMachine.setFlag("workspace", true);
                settled();
                compare(stateMachine.state, "WORKSPACES");
                check(border.visible, "Workspaces retain media progress");
                stateMachine.setFlag("workspace", false);
                backend.recording = true;
                check(border.visible, "Media progress remains visible during recording");
                backend.recording = false;
                backend.mediaPlaying = false;
                settled();
                wait(260);
                check(border.visible, "Paused playback retains the progress border");
                compare(border.lineWidth, 1.5, "Pause returns to the original thin stroke");
                shot("paused-media");
                backend.mediaAvailable = false;
                check(!border.visible, "Closing or stopping the player hides the idle border");
            }
            function test_27_media_seeks_pause_and_silent_position_refresh() {
                fakePlayer.playbackState = MprisPlaybackState.Playing;
                fakePlayer.length = 300;
                fakePlayer.position = 60;
                mediaFixture.enabled = true;
                fakePlayer.position = 90;
                check(Math.abs(mediaFixture.progress - 0.3) < 0.001, "Seek events update the timeline immediately");
                wait(240);
                check(mediaFixture.progress > 0.3, "Playback advances between remote position samples");
                fakePlayer.playbackState = MprisPlaybackState.Paused;
                fakePlayer.position = 30;
                compare(mediaFixture.progress, 0.1);
                check(mediaFixture.available, "A paused track still has a progress indicator");
                wait(250);
                compare(mediaFixture.progress, 0.1, "Paused position remains frozen");
                mediaFixture.acceptPosition("x 120000000", mediaFixture.snapshot());
                compare(mediaFixture.progress, 0.4, "Polling catches seeks that emit no signal, including while paused");
                fakePlayer.playbackState = MprisPlaybackState.Playing;
                wait(120);
                fakePlayer.playbackState = MprisPlaybackState.Paused;
                check(mediaFixture.progress >= 0.4 && mediaFixture.progress < 0.402, "Pause/resume retains the corrected position instead of the stale player cache");
                var stale = mediaFixture.snapshot();
                fakePlayer.position = 15;
                mediaFixture.acceptPosition("x 200000000", stale);
                compare(mediaFixture.progress, 0.05, "An old query cannot overwrite a newer seek");
                stale = mediaFixture.snapshot();
                fakePlayer.uniqueId++;
                mediaFixture.acceptPosition("x 200000000", stale);
                compare(mediaFixture.progress, 0.05, "Old-track replies are discarded");
                mediaFixture.acceptPosition("bad reply", mediaFixture.snapshot());
                compare(mediaFixture.progress, 0.05, "Failed queries preserve the last valid sample");
                fakePlayer.playbackState = MprisPlaybackState.Stopped;
                check(!mediaFixture.available);
                compare(mediaFixture.progress, 0);
                fakePlayer.playbackState = MprisPlaybackState.Playing;
                check(mediaFixture.available);
                mediaFixture.player = null;
                compare(mediaFixture.progress, 0);
            }
            function test_28_outline_is_continuous_through_morphs() {
                backend.mediaAvailable = true;
                backend.mediaPlaying = true;
                backend.mediaProgress = 0.6;
                wait(260);
                var capsule = surface.capsuleItem;
                var border = findChild(surface, "mediaProgressBorder");
                var phases = ({});
                for (var destination of ["stats", "tray", "clipboard", "launcher", "idle"]) {
                    if (destination === "idle")
                        stateMachine.dismiss();
                    else
                        stateMachine.open(destination);
                    var previousWidth = capsule.width;
                    var previousHeight = capsule.height;
                    for (var frame = 0; frame < 75; ++frame) {
                        phases[surface.motionPhase] = true;
                        check(capsule === surface.capsuleItem && border === findChild(surface, "mediaProgressBorder"), "The capsule and outline keep their identity");
                        check(border.visible && border.opacity >= 0.44 && capsule.opacity === 1, "No frame fades or replaces the capsule outline");
                        compare(border.width, capsule.width);
                        compare(border.height, capsule.height);
                        compare(border.radius, capsule.radius);
                        check(Math.abs(capsule.width - previousWidth) < 400 && Math.abs(capsule.height - previousHeight) < 300, "Geometry flows continuously: " + destination + "/" + surface.motionPhase + " " + previousWidth + "×" + previousHeight + " -> " + capsule.width + "×" + capsule.height);
                        previousWidth = capsule.width;
                        previousHeight = capsule.height;
                        if (!surface.transitioning)
                            break;
                        wait(16);
                    }
                    settled();
                }
                check(phases.collapse && phases.dot && phases.travel && phases.expand, "All morph phases were observed with the outline intact");
                stateMachine.open("launcher");
                wait(Motion.ms(200));
                shot("media-morph-dot");
                wait(Motion.ms(170));
                compare(surface.motionPhase, "travel");
                var widthBefore = capsule.width;
                var heightBefore = capsule.height;
                stateMachine.open("clipboard");
                check(Math.abs(capsule.width - widthBefore) < 0.5 && Math.abs(capsule.height - heightBefore) < 0.5, "Reversing a flight preserves the stretched shape");
                settled();
            }
            function test_29_keyboard_scroll_ignores_stationary_mouse() {
                var launcher = findChild(surface, "launcher");
                var apps = [];
                for (var i = 0; i < 40; ++i)
                    apps.push({
                        id: "fixture-" + i,
                        name: "App " + String(i).padStart(2, "0"),
                        keywords: [],
                        icon: "",
                        execute: () => launched++
                    });
                launcher.availableApps = apps;
                stateMachine.open("launcher");
                settled();
                var list = findChild(surface, "launcherResults");
                mouseMove(list, 100, 95);
                wait(80);
                compare(list.currentIndex, 1, "Moving the mouse selects a row");
                for (var expected = 2; expected < 25; ++expected) {
                    keyClick(Qt.Key_Down);
                    wait(35);
                    compare(list.currentIndex, expected, "Scrolling cannot give selection back to the stationary pointer");
                }
                wait(250);
                compare(list.currentIndex, 24);
                check(list.contentY > 500, "Arrow navigation scrolls beyond the first screen");
                check(list.currentItem.y >= list.contentY && list.currentItem.y + list.currentItem.height <= list.contentY + list.height + 1, "Selected result remains fully visible");
                for (var expected = 23; expected >= 0; --expected) {
                    keyClick(Qt.Key_Up);
                    wait(25);
                    compare(list.currentIndex, expected, "Reverse scrolling also preserves keyboard selection");
                }
                wait(250);
                compare(list.currentIndex, 0);
                mouseMove(list, 102, 160);
                wait(80);
                compare(list.currentIndex, 2, "Actual mouse movement resumes pointer selection");
            }
            function test_30_stats_graphs_and_bounded_samples() {
                for (var i = 0; i < 45; ++i) {
                    backend.ingest({
                        type: "stats",
                        cpu: 20 + i % 9 * 5,
                        ram: 62,
                        recording: false
                    });
                    backend.ingest({
                        type: "gpu",
                        value: 8 + i % 6 * 9
                    });
                }
                compare(backend.cpuHistory.length, 30);
                compare(backend.ramHistory.length, 30);
                compare(backend.gpuHistory.length, 30);
                stateMachine.open("stats");
                settled();
                wait(150);
                compare(Math.round(surface.capsuleItem.height), 218);
                check(findChild(surface, "stat:CPU") !== null && findChild(surface, "stat:GPU") !== null);
                shot("stats");
                backend.ingest({
                    type: "gpu",
                    value: null
                });
                compare(backend.gpu, "—");
                check(isNaN(findChild(surface, "stat:GPU").value), "Unknown GPU data is not a fabricated zero");
            }
            function test_31_lock_authentication_and_secret_lifetime() {
                previewLock = true;
                var password = findChild(lockPreview, "lockPassword");
                check(!password.enabled, "No password input before compositor acquisition");
                fakePam.completed(PamResult.Success);
                compare(unlocks, 0, "Unsolicited pre-acquisition success cannot unlock");
                authenticationFixture.secure = true;
                tryVerify(() => password.enabled && password.activeFocus, 500);
                keyClick(Qt.Key_A);
                compare(password.echoMode, TextInput.Password);
                keyClick(Qt.Key_Return);
                compare(password.text, "", "Submission clears the field immediately");
                check(authenticationFixture.busy);
                fakePam.active = false;
                fakePam.completed(PamResult.Failed);
                wait(30);
                compare(unlocks, 0, "Wrong passwords keep the compositor locked");
                check(authenticationFixture.error && password.enabled, "Retry accepts new typing without an extra Enter");
                keyClick(Qt.Key_B);
                authenticationFixture.clearSecrets();
                compare(password.text, "");
                fakePam.active = false;
                fakePam.completed(PamResult.Error);
                wait(30);
                var starts = fakePam.starts;
                wait(80);
                compare(fakePam.starts, starts, "PAM errors do not create an automatic retry loop");
                compare(unlocks, 0);
                authenticationFixture.retry();
                fakePam.active = false;
                fakePam.completed(PamResult.MaxTries);
                starts = fakePam.starts;
                wait(80);
                compare(fakePam.starts, starts, "Exhausted PAM attempts require an explicit retry");
                compare(unlocks, 0);
                authenticationFixture.retry();
                keyClick(Qt.Key_C);
                keyClick(Qt.Key_Return);
                fakePam.active = false;
                fakePam.completed(PamResult.Success);
                compare(unlocks, 1, "Only explicit PAM success authorizes unlock");
                compare(password.text, "");
                fakePam.completed(PamResult.Success);
                compare(unlocks, 1, "Duplicate completions cannot unlock twice");
            }
            function test_32_lock_visual_and_escape_is_not_unlock() {
                previewLock = true;
                authenticationFixture.secure = true;
                wait(450);
                var password = findChild(lockPreview, "lockPassword");
                password.forceActiveFocus();
                keyClick(Qt.Key_A);
                keyClick(Qt.Key_Escape);
                compare(password.text, "");
                compare(unlocks, 0);
                check(authenticationFixture.secure);
                shot("lock-screen", lockPreview);
            }
            function test_33_lock_process_launches_real_entrypoint() {
                // Never request a compositor lock in the developer's live session.
                if (Quickshell.env("QT_QPA_PLATFORM") !== "offscreen" || Quickshell.env("WAYLAND_DISPLAY")) {
                    fail("Lock process test requires the isolated offscreen runner");
                    return;
                }
                check(lockLaunchProbe.command[3].startsWith("/"), "CLI receives a filesystem path, not a qs: URL");
                lockLaunchProbe.output = "";
                lockLaunchProbe.running = true;
                tryVerify(() => lockLaunchProbe.output.includes("Configuration Loaded"), 5000, "Actual lock entrypoint starts: " + lockLaunchProbe.output);
                check(lockLaunchProbe.output.includes("Cannot start session lock"), "Offscreen compositor cannot acquire a lock");
                check(!lockLaunchProbe.output.includes("Failed to load configuration"));
                lockLaunchProbe.running = false;
            }
            function test_34_lock_motion_and_authorized_outro() {
                previewLock = true;
                authenticationFixture.secure = true;
                var wallpaper = findChild(lockPreview, "lockWallpaper");
                var password = findChild(lockPreview, "lockPassword");
                var capsule = findChild(lockPreview, "lockCapsule");
                tryVerify(() => wallpaper.reveal > 0, 1500);
                check(wallpaper.reveal < 1, "Wallpaper fades after the image has loaded");
                tryVerify(() => wallpaper.reveal === 1, 1500);
                password.forceActiveFocus();
                keyClick(Qt.Key_A);
                check(lockPreview.typingPulse > 0, "Typing animates the capsule and masked text");
                tryVerify(() => lockPreview.typingPulse === 0, 1000);
                authenticationFixture.authenticated();
                wait(50);
                compare(exitFixture.progress, 0, "An unauthorized animation request cannot start the outro");
                compare(releases, 0);
                keyClick(Qt.Key_Return);
                fakePam.active = false;
                fakePam.completed(PamResult.Success);
                compare(releases, 0, "PAM success keeps the compositor locked during the outro");
                wait(Motion.ms(450));
                check(exitFixture.progress > 0 && exitFixture.progress < 1);
                check(capsule.width < 300 && wallpaper.opacity < 0.68, "Capsule morphs and wallpaper fades during the shared outro");
                check(authenticationFixture.secure && !password.enabled);
                shot("lock-outro", lockPreview);
                tryCompare(suite, "releases", 1, 1500);
                fakePam.completed(PamResult.Success);
                wait(30);
                compare(releases, 1, "Duplicate completion cannot release twice");
            }
            function test_35_stats_remain_open_without_hover() {
                stateMachine.open("stats");
                settled();
                stateMachine.hover(false);
                wait(3300);
                compare(stateMachine.state, "STATS", "Stats stay open beyond the former leave timeout");
                stateMachine.toggle("stats");
                settled();
                check(stateMachine.state !== "STATS");
            }
            function test_36_radio_bubbles_click_merge_and_cancel() {
                var wifi = findChild(surface, "wifiBubble");
                var bluetooth = findChild(surface, "bluetoothBubble");
                var capsule = surface.capsuleItem;
                check(wifi.x + wifi.width < capsule.x && bluetooth.x > capsule.x + capsule.width, "Radio bubbles flank the island");
                shot("radio-bubbles", surface);
                mousePress(wifi, 18, 18, Qt.LeftButton);
                mouseMove(surface, 250, 130, 30, Qt.LeftButton);
                compare(wifi.x, wifi.homeX, "Bubbles cannot be dragged");
                compare(wifi.y, wifi.homeY);
                mouseRelease(surface, 250, 130, Qt.LeftButton);
                check(!surface.radioOpen);
                mouseClick(wifi, 18, 18, Qt.LeftButton);
                wait(Motion.ms(220));
                check(wifi.offsetX > 0 && bluetooth.offsetX < 0, "One click draws BOTH bubbles inward");
                compare(wifi.mergeProgress, bluetooth.mergeProgress, "Both sides share the same merge timeline");
                check(!surface.radioOpen, "Menu opens after the merge");
                shot("radio-liquid-neck", surface);
                tryCompare(stateMachine, "state", "WIFI", 1000);
                settled();
                check(surface.radioOpen && !surface.modal);
                check(!wifi.visible && !bluetooth.visible, "Merged bubbles stay inside the open island");
                shot("wifi-panel", surface);
                var header = findChild(surface, "islandHeader");
                mouseClick(header, header.width / 2, 20, Qt.LeftButton);
                mouseMove(surface, 10, 650);
                settled();
                wait(250);
                mouseClick(bluetooth, 18, 18, Qt.LeftButton);
                tryCompare(stateMachine, "state", "BLUETOOTH", 1000);
                settled();
                shot("bluetooth-panel", surface);
                stateMachine.dismiss();
                settled();
                wait(200);
                mouseClick(wifi, 18, 18, Qt.LeftButton);
                stateMachine.beginLock();
                wait(400);
                compare(stateMachine.state, "LOCKING", "Locking cancels a pending radio menu");
                check(!wifi.enabled && !bluetooth.enabled);
                compare(surface.radioMergeProgress, 0);
            }
            function test_37_radio_controls_and_password_lifetime() {
                backend.radios.networkBackend = fixtureNetworking;
                backend.radios.bluetoothBackend = fixtureBluetooth;
                stateMachine.open("wifi");
                settled();
                wait(100);
                check(fixtureWifi.scannerEnabled, "Scan only while the Wi-Fi card is open");
                var list = findChild(surface, "radioDevices");
                tryCompare(list, "count", 1, 500);
                mouseClick(list, 100, 20, Qt.LeftButton);
                var password = findChild(surface, "wifiPassword");
                check(password.visible && password.activeFocus);
                keyClick(Qt.Key_A);
                keyClick(Qt.Key_Return);
                compare(fixtureNetwork.requests, 1);
                compare(password.text, "", "Wi-Fi credentials clear immediately after submission");
                fixtureNetwork.connectionFailed(ConnectionFailReason.NoSecrets);
                check(backend.radios.error.length > 0);
                mouseClick(list, 100, 20, Qt.LeftButton);
                check(password.visible, "Failed credentials can be replaced");
                keyClick(Qt.Key_B);
                stateMachine.open("bluetooth");
                settled();
                compare(password.text, "", "Switching cards clears sensitive input");
                check(!fixtureWifi.scannerEnabled, "Closing the card restores scanning state");
                mouseClick(list, 100, 20, Qt.LeftButton);
                check(fixtureHeadphones.connected);
                shot("bluetooth-connected", surface);
                var power = findChild(surface, "radioPower");
                mouseClick(power, 22, 13, Qt.LeftButton);
                check(!fixtureAdapter.enabled);
                stateMachine.beginLock();
                backend.radios.toggleBluetooth();
                backend.radios.toggleWifi();
                check(!fixtureAdapter.enabled && fixtureNetworking.wifiEnabled, "Locked sessions reject radio actions");
            }
            function test_22_launcher_dot_flight_and_early_typing() {
                var capsule = surface.capsuleItem;
                stateMachine.open("launcher");
                wait(Motion.ms(25));
                var search = findChild(surface, "launcherSearch");
                check(search.activeFocus, "Typing is captured before the flight completes");
                keyClick(Qt.Key_F);
                wait(Motion.ms(175));
                check(capsule.width <= 19 && capsule.height <= 19, "The middle state is an empty circle");
                check(findChild(surface, "islandHeader").opacity < 0.01, "The dot contains no clock or panel content");
                shot("empty-dot");
                wait(Motion.ms(140));
                compare(surface.motionPhase, "travel");
                check(capsule.y > 28 && capsule.y < surface.height / 2, "The dot flies toward the center before expansion");
                check(capsule.width <= 19, "Flight does not expand the dot early");
                var peak = 0;
                for (var frame = 0; frame < 50; ++frame) {
                    peak = Math.max(peak, capsule.width);
                    check(capsule.x >= 0 && capsule.x + capsule.width <= surface.width, "Overshoot remains on screen");
                    wait(16);
                }
                check(peak > surface.launcherWidth + 2, "Expansion has a visible overshoot");
                settled();
                compare(search.text, "f", "Opening animation preserves early input");
                check(capsule.width > 900 && capsule.height > 600, "Launcher uses the larger adaptive layout");
                compare(Math.round(capsule.y + capsule.height / 2), surface.height / 2);
                search.clear();
                shot("launcher");
            }
            function test_23_flight_redirects_to_latest_intent() {
                stateMachine.open("launcher");
                wait(Motion.ms(330));
                compare(surface.motionPhase, "travel");
                var before = surface.capsuleItem.y;
                stateMachine.open("clipboard");
                check(Math.abs(surface.capsuleItem.y - before) < 1, "Redirecting flight preserves position");
                settled();
                compare(stateMachine.state, "CLIPBOARD");
                compare(Math.round(surface.capsuleItem.width), Math.round(surface.cardWidth));
                compare(Math.round(surface.capsuleItem.y), preferences.topMargin);
                check(!surface.modal, "Redirecting out of the launcher releases keyboard capture");
            }
            function test_24_launch_during_flight_records_usage_once() {
                stateMachine.open("launcher");
                wait(30);
                keyClick(Qt.Key_K);
                keyClick(Qt.Key_Return);
                compare(launched, 1);
                compare(backend.appUsage.terminal.count, 1);
                check(!surface.modal, "Launching before arrival dismisses the launcher");
                settled();
                stateMachine.open("launcher");
                wait(30);
                var launcher = findChild(surface, "launcher");
                compare(findChild(surface, "launcherSearch").text, "");
                compare(launcher.results[0].id, "terminal", "A used app rises above alphabetical order");
                keyClick(Qt.Key_Escape);
                settled();
                compare(launched, 1, "Escape never launches a selection");
            }
            function test_25_lock_aborts_motion() {
                stateMachine.open("launcher");
                wait(Motion.ms(330));
                stateMachine.beginLock();
                check(!surface.transitioning, "Locking cancels all presentation animation");
                check(!surface.modal);
                wait(600);
                compare(Math.round(surface.capsuleItem.width), 100, "No stale completion expands a hidden launcher");
            }
            function test_26_launcher_single_search_modes() {
                stateMachine.open("launcher");
                wait(30);
                var launcher = findChild(surface, "launcher");
                var search = findChild(surface, "launcherSearch");
                check(findChild(surface, "launcherPins") === null);
                check(findChild(surface, "launcherChat") === null);
                search.text = "/island-file-fixture";
                check(launcher.fileMode && !launcher.webMode);
                compare(backend.pendingQuery, "island-file-fixture");
                tryVerify(() => !backend.fileSearchBusy, 5000);
                compare(backend.fileSearchError, "");
                compare(launcher.results.length, 2, "Real helper searches the isolated home directory");
                check(launcher.selected.url.startsWith("file://"));
                keyClick(Qt.Key_Down);
                compare(findChild(surface, "launcherResults").currentIndex, 1);
                shot("launcher-files");
                search.text = "?quickshell";
                check(launcher.webMode && !launcher.fileMode);
                compare(backend.fileResults.length, 0, "Switching modes clears file results");
                compare(launcher.results.length, 1);
                search.text = "kitty";
                check(!launcher.webMode && !launcher.fileMode);
                compare(launcher.results[0].id, "terminal");
                keyClick(Qt.Key_Escape);
                settled();
            }
            function cleanupTestCase() {
                console.log("UI RESULT", qtest_results.failCount, "failures");
                Qt.quit();
            }
        }
    }
    // QtTest is embedded in qs because Quickshell's static plugins cannot be
    // loaded by standalone qmltestrunner. Explicitly start its normal test run.
    Timer {
        interval: 400
        running: true
        onTriggered: {
            suite.when = true;
            suite.qtest_run();
        }
    }
}
