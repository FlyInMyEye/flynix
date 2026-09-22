#!/usr/bin/env python3
"""Small, argv-only adapters for Linux tools. No shell evaluation of user data."""
import base64
import ctypes
import hashlib
import fcntl
import json
import os
import re
from pathlib import Path
import selectors
import shutil
import signal
import socket
import subprocess
import sys
import time
import tempfile
import urllib.parse
import urllib.request


def emit(kind, **data):
    print(json.dumps({"type": kind, **data}), flush=True)


def run(args, data=None, timeout=2):
    return subprocess.run(args, input=data, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, timeout=timeout, check=True).stdout


def optional(args, default=b"", **kwargs):
    try:
        return run(args, **kwargs)
    except (OSError, subprocess.SubprocessError):
        return default


def cpu_sample():
    values = list(map(int, Path("/proc/stat").read_text().splitlines()[0].split()[1:9]))
    return sum(values), values[3] + values[4]


def cpu_percent(old, new):
    total, idle = new[0] - old[0], new[1] - old[1]
    return round(100 * (1 - idle / total)) if total > 0 else 0


def memory_percent(text):
    fields = {line.split(":")[0]: int(line.split()[1]) for line in text.splitlines()}
    return round(100 * (1 - fields["MemAvailable"] / fields["MemTotal"]))


def gpu_percent():
    for path in Path("/sys/class/drm").glob("card*/device/gpu_busy_percent"):
        try:
            return int(path.read_text())
        except (OSError, ValueError):
            pass
    if shutil.which("nvidia-smi"):
        value = optional(["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"])
        try:
            return max(map(int, value.splitlines()))
        except ValueError:
            pass
    return None


def history():
    data = optional(["cliphist", "list"], default=None)
    if data is None:
        return None
    lines = data.decode(errors="replace").splitlines()[:40]
    result = []
    for line in lines:
        ident, sep, preview = line.partition("\t")
        if sep and ident.isdecimal():
            image = preview.startswith("[[ binary data") and re.search(r"\b(png|jpe?g|gif|webp|bmp|tiff)\b", preview, re.I) is not None
            result.append({"id": ident, "preview": preview, "image": image})
    return result


def recording():
    # An open OBS window is not evidence of recording. OBS integrations use IPC.
    return bool(optional(["pgrep", "-u", str(os.getuid()), "-f", r"(^|/)(wf-recorder|gpu-screen-recorder)( |$)"]))


def hypr_query(command):
    """Read Hyprland IPC without spawning hyprctl for every cursor sample.

    Protocol: https://wiki.hypr.land/IPC/ (JSON flag: j/command).
    """
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not signature or not runtime:
        return None
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(0.3)
            connection.connect(str(Path(runtime) / "hypr" / signature / ".socket.sock"))
            connection.sendall(("j/" + command).encode())
            response = bytearray()
            while chunk := connection.recv(8192):
                response.extend(chunk)
                if len(response) > 1024 * 1024:
                    return None
        return json.loads(response)
    except (OSError, ValueError):
        return None


class ClipboardObserver:
    """Suppress the initial selection replay, not the first real copy."""
    def __init__(self, baseline):
        self.baseline = baseline
        self.first = True

    def accepts(self, event):
        if event.get("state") in ("nil", "clear", "sensitive"):
            return False
        initial_replay = self.first and event.get("digest") == self.baseline
        self.first = False
        return not initial_replay


def bind_parent_lifetime(parent_pid):
    """Quickshell may SIGKILL helpers on reload; finally blocks cannot handle it."""
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(1, signal.SIGTERM, 0, 0, 0) != 0:  # PR_SET_PDEATHSIG
        raise OSError(ctypes.get_errno(), "Could not bind watcher lifetime")
    # Close the race where the parent exited before prctl was installed.
    if os.getppid() != parent_pid:
        raise SystemExit(0)


def monitor():
    selector = selectors.DefaultSelector()
    watcher = None
    baseline = optional(["wl-paste", "--no-newline"], default=None)
    copies = ClipboardObserver(hashlib.sha256(baseline).hexdigest() if baseline is not None else None)
    baseline = None
    if shutil.which("wl-paste"):
        watcher = subprocess.Popen([sys.executable, __file__, "watch", str(os.getpid())],
                                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, start_new_session=True, bufsize=0)
        selector.register(watcher.stdout, selectors.EVENT_READ)
    stopped = False

    def stop(*_):
        nonlocal stopped
        stopped = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    previous = cpu_sample()
    next_slow = 0
    last_history = None
    last_screen = None
    monitors = []
    try:
        while not stopped:
            for key, _ in selector.select(timeout=0.10):
                line = key.fileobj.readline()
                if line:
                    try:
                        event = json.loads(line)
                        if copies.accepts(event):
                            sys.stdout.buffer.write(line)
                            sys.stdout.flush()
                    except ValueError:
                        pass
                else:
                    selector.unregister(key.fileobj)
            now = time.monotonic()
            if now >= next_slow:
                current = cpu_sample()
                emit("stats", cpu=cpu_percent(previous, current),
                     ram=memory_percent(Path("/proc/meminfo").read_text()), recording=recording())
                previous = current
                entries = history()
                if entries is not None and entries != last_history:
                    emit("history", entries=entries)
                    last_history = entries
                monitors = hypr_query("monitors") or []
                next_slow = now + 2
            if monitors:
                try:
                    pos = hypr_query("cursorpos")
                    if not pos:
                        continue
                    for screen in monitors:
                        w, h = screen["width"], screen["height"]
                        if screen.get("transform", 0) % 2:
                            w, h = h, w
                        scale = screen.get("scale", 1)
                        if screen["x"] <= pos["x"] < screen["x"] + w / scale and screen["y"] <= pos["y"] < screen["y"] + h / scale:
                            if screen["name"] != last_screen:
                                emit("screen", name=screen["name"])
                                last_screen = screen["name"]
                            break
                except (ValueError, KeyError, TypeError, ZeroDivisionError):
                    pass
    finally:
        if watcher:
            try:
                os.killpg(watcher.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            watcher.wait(timeout=3)
        selector.close()


def hardware(kind, direction):
    if kind == "volume":
        if direction == "mute":
            run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        else:
            run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+" if direction == "up" else "5%-"])
        value = run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]).decode()
        emit("hardware", kind=kind, value=float(value.split()[1]), muted="MUTED" in value)
    elif kind == "brightness":
        run(["brightnessctl", "-q", "set", "+5%" if direction == "up" else "5%-"])
        emit("hardware", kind=kind, value=int(run(["brightnessctl", "get"])) / int(run(["brightnessctl", "max"])), muted=False)


def restore(ident):
    if not ident.isdecimal():
        raise ValueError("Invalid clipboard entry")
    # Older cliphist versions split at the first tab without trimming newlines.
    data = run(["cliphist", "decode"], (ident + "\t\n").encode())
    emit("restoring", digest=hashlib.sha256(data).hexdigest())
    run(["wl-copy"], data)


def read_preview(ident, limit=8 * 1024 * 1024):
    """Decode a bounded image without changing the clipboard or writing a cache."""
    with subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as process:
        try:
            process.stdin.write((ident + "\t\n").encode())
            process.stdin.close()
            data = bytearray()
            deadline = time.monotonic() + 2
            with selectors.DefaultSelector() as selector:
                selector.register(process.stdout, selectors.EVENT_READ)
                while True:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0 or not selector.select(remaining):
                        return None
                    chunk = os.read(process.stdout.fileno(), min(65536, limit + 1 - len(data)))
                    if not chunk:
                        return bytes(data) if process.wait(timeout=0.2) == 0 else None
                    data.extend(chunk)
                    if len(data) > limit:
                        return None
        finally:
            if process.poll() is None:
                process.kill()


def image_url(data):
    if not data:
        return ""
    mime = ""
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        mime = "image/png"
    elif data.startswith(b"\xff\xd8\xff"):
        mime = "image/jpeg"
    elif data.startswith((b"GIF87a", b"GIF89a")):
        mime = "image/gif"
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        mime = "image/webp"
    if not mime:
        return ""
    return "data:" + mime + ";base64," + base64.b64encode(data).decode("ascii")


def preview(ident):
    if not ident.isdecimal():
        raise ValueError("Invalid clipboard entry")
    try:
        url = image_url(read_preview(ident))
    except (OSError, subprocess.SubprocessError):
        url = ""
    emit("preview", id=ident, url=url)


def files(query):
    query = query.casefold().strip()
    result = []
    if len(query) >= 2:
        count = 0
        for folder, dirs, names in os.walk(Path.home()):
            dirs[:] = sorted(d for d in dirs if not d.startswith(".") and d not in ("node_modules", "target", "vendor"))
            for name in names:
                count += 1
                if query in name.casefold():
                    path = Path(folder, name)
                    result.append({"name": name, "url": path.as_uri(),
                                   "genericName": "~/" + str(path.parent.relative_to(Path.home()))})
                if len(result) >= 30 or count >= 50000:
                    emit("files", entries=result)
                    return
    emit("files", entries=result)


def chat():
    # Request and history arrive on stdin, never in process arguments.
    config = json.loads(sys.stdin.readline())
    endpoint = config.get("endpoint") or os.environ.get("ISLAND_AI_ENDPOINT", "")
    model = config.get("model") or os.environ.get("ISLAND_AI_MODEL", "")
    parsed = urllib.parse.urlsplit(endpoint)
    if not model or not (parsed.scheme == "https" or (parsed.scheme == "http" and parsed.hostname in ("localhost", "127.0.0.1", "::1"))):
        raise ValueError("Set an AI model and HTTPS endpoint (or local HTTP endpoint) in Settings.qml or ISLAND_AI_*.")
    headers = {"Content-Type": "application/json"}
    key_file = os.environ.get("ISLAND_AI_KEY_FILE")
    if key_file:
        headers["Authorization"] = "Bearer " + Path(key_file).read_text().strip()
    payload = json.dumps({"model": model, "messages": config["messages"], "stream": False}).encode()
    request = urllib.request.Request(endpoint, payload, headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        data = json.load(response)
    emit("chat", text=data["choices"][0]["message"]["content"])


def greeting():
    # Atomic marker survives shell restarts within this compositor session.
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    session = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") or os.environ.get("XDG_SESSION_ID", "unknown")
    marker = runtime / ("island-greeting-" + hashlib.sha256(session.encode()).hexdigest()[:20])
    try:
        fd = os.open(marker, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(fd)
        emit("greeting")
    except FileExistsError:
        pass


def launcher_usage(events):
    """Serialize updates across shell instances; never leave a partial JSON file."""
    directory = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "quickshell"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = directory / "island-launcher.json"
    with (directory / "island-launcher.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            data = json.loads(path.read_text())
        except (OSError, ValueError):
            data = {}
        if not isinstance(data, dict):
            data = {}
        data = {key: value for key, value in data.items()
                if isinstance(value, dict) and isinstance(value.get("count"), int)
                and 0 < value["count"] <= 1000000
                and isinstance(value.get("last"), (int, float))
                and 0 <= value["last"] <= time.time() * 1000 + 86400000}
        for event in events[:100]:
            key = event.get("id")
            if not isinstance(key, str) or not key or len(key) > 1024:
                continue
            data[key] = {"count": min(1000000, data.get(key, {}).get("count", 0) + 1),
                         "last": time.time() * 1000}
        data = dict(sorted(data.items(), key=lambda pair: pair[1]["last"], reverse=True)[:1000])
        if events:
            temp = None
            try:
                with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as stream:
                    temp = stream.name
                    json.dump(data, stream)
                    stream.flush()
                    os.fsync(stream.fileno())
                os.replace(temp, path)
            finally:
                if temp and os.path.exists(temp):
                    os.unlink(temp)
        return data


def main():
    action = sys.argv[1]
    if action == "monitor": monitor()
    elif action == "watch":
        bind_parent_lifetime(int(sys.argv[2]))
        os.execvp("wl-paste", ["wl-paste", "--watch", sys.executable, __file__, "copy-event"])
    elif action == "hardware": hardware(*sys.argv[2:4])
    elif action == "restore": restore(sys.argv[2])
    elif action == "preview": preview(sys.argv[2])
    elif action == "files": files(sys.argv[2])
    elif action == "chat": chat()
    elif action == "greeting": greeting()
    elif action == "usage": emit("usage", entries=launcher_usage(json.loads(sys.stdin.readline())))
    elif action == "gpu": emit("gpu", value=gpu_percent())
    elif action == "audio":
        cava = shutil.which("cava")
        if cava:
            os.execv(cava, [cava, "-p", str(Path(__file__).resolve().parents[1] / "cava.conf")])
    elif action == "copy-event":
        digest = hashlib.sha256()
        for chunk in iter(lambda: sys.stdin.buffer.read(65536), b""): digest.update(chunk)
        emit("copy", digest=digest.hexdigest(), state=os.environ.get("CLIPBOARD_STATE", "data"))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never include request headers, clipboard contents or credentials.
        emit("error", message=str(error) if isinstance(error, ValueError) else "System helper failed: " + type(error).__name__)
        sys.exit(1)
