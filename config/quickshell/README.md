# Island

A single Quickshell capsule for Hyprland. Requires Quickshell 0.3.x. Start with:

```sh
qs --no-duplicate --path /etc/nixos/config/quickshell
```

The host's NixOS Quickshell module installs Python, clipboard and hardware tools,
CAVA, fonts, and the dedicated `quickshell-island` PAM service.
The Hyprland configuration routes Super+Space to the launcher and both Super
keys to the workspace strip. Desktop workspace changes use a short slide.
These Nix changes take effect on a system rebuild; editing the QML reloads the
running UI directly. Existing unrelated changes in the repository are untouched.

`ReservedSpace.qml` creates a transparent, input-free 56-pixel top reservation on
every output. Tiled/maximized windows stay below the clock. This stays constant
while the island hops or expands, so opening a drawer does not resize windows.
The actual island remains an overlay for expanded drawers and the launcher.
The reservation uses the three-anchor
[`PanelWindow.exclusiveZone`](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/)
surface required by layer-shell; `reservedHeight` controls its size.

## Interaction

| Input | Result |
| --- | --- |
| Hover the clock | The same clock expands to centered `hh:mm:ss`, with day/date at its sides |
| Left-click the clock | Open/close the tray drawer |
| Hover a tray icon | Reveal its actual menu actions inside the island; click a submenu to enter it |
| Pull the clock downward, or middle-click | Open clipboard history and the file shelf |
| Click the clock above an open drawer | Collapse the drawer |
| Right-click the clock | Toggle diagnostics; they stay open until dismissed or another view is opened |
| Click the left / right bubble | Both bubbles merge into the island, then Wi-Fi / Bluetooth controls open |
| Scroll / Shift+scroll over the clock | Volume / brightness |
| Hold either Super key | All ten workspace positions; occupied dots are brighter |
| Change workspace | A bead stretches toward the destination and settles into a ring |
| Super+Space | Launcher; Enter opens a result, Escape closes |
| Super+Shift+L | Native island lock, including when the normal shell is unavailable |
| Launcher Alt+1…9 | Open one of the first nine results directly |
| Launcher `/name` / `?query` | Search files under home / search the web |
| Drop local files on the capsule | Pin them to the shelf |
| Drag a shelf chip into another application | Transfer its file URI and consume the shelf chip on exit |

Clipboard and tray drawers are **nonmodal**. Only the rounded capsule receives
pointer input, and they do not request exclusive keyboard focus. Other windows
remain usable while a drawer is open. Escape closes a drawer when it has keyboard
focus; clicking its clock works without keyboard focus. After the pointer leaves,
clipboard closes after eight seconds and tray after five. Hovering, pulling or
dragging keeps a drawer open and resets the delay. Expansion finishes before the
inactivity countdown starts. Workspace holds suspend it.
Set `clipboardTimeout` / `trayTimeout` in `Settings.qml` (milliseconds); zero
disables automatic dismissal. Timing out never removes pinned files.

The Wi-Fi and Bluetooth bubbles are clickable, with live power and connection
indicators. A shared animation pulls both into the island through liquid bridges
before expanding the selected connection panel. Click the clock or press Escape
to close it and bring the bubbles back. These panels are nonmodal and have no
inactivity timeout. Wi-Fi offers radio power, network selection and WPA/WPA2/WPA3
personal passwords; network settings opens `nmtui-connect` for other security
types. Bluetooth offers power and paired-device connections; Pair a device opens
Blueman for discovery and pairing. Wi-Fi scanning is enabled while its panel is
open, and password input clears on submission, panel changes and locking.

All visual transitions run at twice the original speed, controlled centrally by
`Motion.speed` in `Motion.qml`. Service polling, hover intent and dismissal
timeouts retain their original timing. Diagnostics now expand into three compact
cards: CPU/GPU history graphs and a segmented RAM gauge. History keeps the latest
30 samples; unavailable readings show an em dash.

Clicking between interactive views compresses the island into an empty 18-pixel
dot before it blooms into its destination. The launcher first flies to the screen
center; closing reverses the journey. The moving dot stretches with its flight,
expansion overshoots and settles, and pressing the header gives a small squash.
New requests steer from the current shape/position. Keyboard focus is ready as
soon as the launcher is requested, so typing or pressing Enter during flight works.
The empty phase hides all content. During expansion the clock returns to the header. Content uses
stable geometry: the capsule reveals it as it grows instead of squeezing and
reflowing each frame. Workspace geometry is independent of capsule width, and
temporary null/special-workspace focus reports preserve the last confirmed
workspace. No workspace-1 fallback animation is used.

Pulling starts from the capsule's current size, including an expanded hover
clock. Releasing past the threshold commits directly to the open card and
continues the expansion; a short pull returns to the clock. The workspace bead
has independently animated leading/trailing edges and retargets from its current
shape when workspace changes reverse rapidly.

Tray hover waits 140 ms before opening the app's menu through
[`QsMenuOpener`](https://quickshell.org/docs/v0.3.0/types/Quickshell/QsMenuOpener/).
The menu stays selected as the pointer moves down to its actions. Disabled items,
separators, checkboxes, radio buttons and nested menus retain their app-provided
behavior. Toggles stay open; ordinary actions dismiss the drawer. Right-click
selects the menu immediately. Apps without menus offer their primary Open action.
Menus grow to show every action, with no scrolling. Menus taller than the available
screen height continue in additional columns, ordered down then across.

Clipboard history uses the existing `wl-paste --watch cliphist store` autostart.
Text and binary/image entries can be restored. PNG, JPEG, GIF and WebP entries show
image previews loaded on demand, with an 8 MiB / two-second decode limit and up to
eight images retained in memory. No preview files are written, and previews clear
when the card closes or the session locks. Unsupported/oversized images use a
placeholder and can still be restored. The island's separate watcher only produces
copy feedback. It ignores the initial selection replay and sensitive/empty
selection events. Its watcher exits with the helper even if a reload kills the
helper abruptly, so repeated reloads do not accumulate background watchers. Reading history and restoring a selection do not produce copy
combos. Shelf removal never deletes or moves the underlying file. Shelf pins are
ephemeral and are cleared by a shell restart/reload.

The launcher grows to 960 × 640 pixels with screen margins on smaller displays.
It has one search view: type an app name, `/filename` to search home, or `?query`
to search the web. File queries need at least two characters after `/`; results
show the containing folder in the preview. Pinned files remain in the clipboard
shelf. The empty search field shows the search prefixes.
A moving selection highlight and app preview follow keyboard or pointer selection;
the preview disappears on narrow screens. Arrow navigation keeps the selected
result visible; a stationary mouse cannot steal selection as rows scroll beneath
it. Moving the pointer resumes hover selection. Search matches names and keywords, with
exact/prefix matches ahead of metadata matches. Within equally good matches,
frequency and recency rank apps; old habits gradually decay. With no history,
ordering is alphabetical. There is no arbitrary 40-result cutoff.

Launches made through the island are remembered by desktop-entry ID in
`$XDG_STATE_HOME/quickshell/island-launcher.json` (default
`~/.local/state/quickshell/island-launcher.json`). Updates are locked and atomic,
and the data file is private. Search queries, files and chat are not stored there.
The history counts launch requests, not foreground-window time or launches made
through other tools.

## Services and configuration

`Theme.qml` reads Stylix's `colors.json` and uses your JetBrainsMono Nerd Font settings. Muted text
is derived from the foreground to retain contrast across themes. `Settings.qml`
sets timing and optional features. The session greeting is off by default.

Notifications retain their protocol objects until their visible three-second
slot expires. Normal alerts wait during user capture; critical alerts can lead
the queue but cannot interrupt a lock, launcher, workspace hold, diagnostics or
file gesture. Holds/capture pause remaining display time. CPU alerts require
three consecutive high samples. GPU utilization is queried only while diagnostics
are visible; unsupported GPUs show `—`.

MPRIS supplies track changes and progress. The initial track snapshot is silent.
The progress border follows every island view, including stats, tray, clipboard,
workspaces and launcher. It is 4 px while playing and stays visible at 1.5 px when
paused. Length changes interpolate smoothly, including forward/backward seeks.
A lightweight position query once per second corrects players that omit seek
signals; local interpolation keeps movement smooth between replies. Unknown
track lengths, stopped players and disconnected players have no progress border.
The capsule and border remain continuous through collapse, the empty dot, flight
and expansion; only interior content fades. Flight reversals preserve the current
stretched shape, and corner radii interpolate between views.
Disable `mediaProgressIdle` in `Settings.qml` to limit it to track notifications.
CAVA supplies a subtle pulse while a player is playing, and quietly disables
itself when unavailable. Recording detection covers `wf-recorder` and
`gpu-screen-recorder`; an open OBS process alone is not treated as a recording.
OBS integrations can call the explicit recording IPC hook below.

Optional integration commands:

```sh
qs ipc -p /etc/nixos/config/quickshell call island status
qs ipc -p /etc/nixos/config/quickshell call island launcher
qs ipc -p /etc/nixos/config/quickshell call island clipboard
qs ipc -p /etc/nixos/config/quickshell call island stats
qs ipc -p /etc/nixos/config/quickshell call island screenshot
qs ipc -p /etc/nixos/config/quickshell call island notify 'Build finished' false
qs ipc -p /etc/nixos/config/quickshell call island recording true
qs ipc -p /etc/nixos/config/quickshell call island recording false
```

Screenshot notifications from common screenshot tools also trigger the flash.
Run only one notification daemon; another owner of
`org.freedesktop.Notifications` prevents the island receiving those events.

## Native lock and recovery

The lock lives in **a separate Quickshell process**, `lock.qml`, using
[`WlSessionLock` and `WlSessionLockSurface`](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlSessionLock/).
It has no IPC handler, no reload watcher, and exactly one assignment releasing
the compositor lock, after a shared outro authorized by explicit PAM success. Every output is
covered by the protocol-managed surface component, including hot-plugged outputs.
Input is disabled until `secure` confirms acquisition; password buffers are
cleared after submission and completion. The ordinary shell suspends its controls
and sensitive producers when locking starts. A missing PAM service is reported
before attempting acquisition.

The lock uses the astronaut wallpaper, a large clock and an animated floating
password capsule. The wallpaper fades in after loading, typing gently pulses the
masked field and capsule, and successful authentication folds the capsule into a
dot that travels back to the top while the scene fades out. The compositor stays
locked throughout this shared animation; animation completion without PAM success
cannot release it. `lockWallpaper` in `hosts/hp-laptop/theme.nix` controls the
background; Nix installs it at `/etc/quickshell/lock-wallpaper`. `desktopWallpaper`
in the same file controls the Hyprpaper desktop background, Stylix palette source
and login background. The lock image defaults to the desktop image and can be
overridden independently. Rebuild and switch to apply wallpaper changes. Authentication
failures shake the capsule; PAM errors and exhausted attempts require an explicit
retry. Escape clears the password without unlocking.

The Nix configuration routes Super+Shift+L and Hypridle through `island-lock`.
This wrapper requests the native lock from a running island, ignores repeated
requests while locking, and starts the native lock directly if the island is unavailable.
Hypridle's `inhibit_sleep = 3` waits for the compositor's lock notification before
releasing its sleep inhibitor. These integrations take effect after rebuilding;
they have not been activated or tested against a live session here. Complete the
live acceptance checks below before relying on the native locker.

To test the native client in a disposable graphical session with the PAM service installed:

```sh
qs ipc -p /etc/nixos/config/quickshell call island lock
```

**Orphaned-lock recovery:** save work before destructive lock testing. If a lock
client dies after acquisition, a conforming compositor keeps the session locked.
Do not assume a replacement locker can reclaim it. Switch to a TTY with
Ctrl+Alt+F3, authenticate there, and use `loginctl list-sessions` followed by
`loginctl show-session ID -p Name -p Type -p Desktop` to identify the affected
graphical session. Run `loginctl terminate-session ID` for that session, then log
in to a fresh graphical session. This terminates its applications and loses
unsaved work; it never exposes the existing locked desktop. There is deliberately
no administrative IPC unlock command.

## Verification

```sh
node --test config/quickshell/tests/*.test.cjs
python3 -m unittest discover -s config/quickshell/tests -v
python3 config/quickshell/tests/smoke.py --qs qs
```

The UI test runner uses the **unmodified production UI components** in an
offscreen window, with synthetic mouse/keyboard events. It checks clock centering,
click-through outside the clipboard card, drag-following expansion, null focus
reports, actual workspace interpolation, interrupted morphs, visible copy-combo
updates, paused notifications, stable shelf delegates, launcher input/Escape and
normal-service suspension on lock, both Super keys, and silent clipboard restores.
It also samples the pull-release animation frame by frame, checks cancelled pulls
from the hover clock, workspace deformation/reversal, tray hover intent, action
dispatch, disabled items, toggle persistence and disappearing tray applications.
Tray interaction tests use fixture entries; real application D-Bus menus still
need a session-level check.
Additional checks cover drawer inactivity/hover/drag, long menus fitting into
columns, rendering and clearing image previews, idle media decoration, empty-dot
geometry, flight redirection, overshoot bounds, early typing/launching, lock
interruption, app ranking, and concurrent/restarted usage-history writes.
The stats tests check bounded history and missing readings. Lock UI/controller
tests cover masked input, immediate password clearing, retry/error handling,
rejected pre-acquisition and duplicate success signals, and Escape remaining
locked. Their PAM fixture never authenticates a real user.
When `cliphist` is on PATH, the helper tests also store/decode a fixture image in
an isolated temporary database and verify restoration without calling `wl-copy`.
Screenshots and logs go to
`/tmp/island-smoke-artifacts`. It also starts the real lock entrypoint through
the production `LockProcess` component in an isolated offscreen process. This
checks CLI path resolution and startup without acquiring a lock; the test refuses
to run that step with a live Wayland display. No live compositor, user's clipboard
or chat provider is contacted.

Offscreen tests cannot certify Wayland behavior. Before deploying the native lock,
verify these in a disposable real Hyprland session:

- Correct, wrong and empty passwords; repeated submissions; PAM service errors.
- Repeated lock shortcuts while acquisition/authentication is pending.
- All attached outputs covered before input becomes active; hot-plug while locked.
- Kill the **lock client** with SIGTERM and SIGKILL; the compositor must stay locked.
- Restart/crash the **normal shell** while locked; no desktop must become accessible.
- QML/render/GPU failure and attempted reload during locking.
- Suspend/resume during lock, including acquisition-before-sleep ordering.
- Orphaned-lock recovery by terminating the graphical session from a TTY.

Also check the compositor-specific UI paths: input reaching real windows outside
the drawer, the fixed top reservation on each output, tray context menus,
external file drag in/out, cursor hopping across
mixed-scale monitors, output removal during a hop, and hardware media keys.
