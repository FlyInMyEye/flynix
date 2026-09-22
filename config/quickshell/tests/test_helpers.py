import importlib.util
import base64
import json
from concurrent.futures import ThreadPoolExecutor
import os
import shutil
import subprocess
import sys
import tempfile
import time
import signal
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("island", Path(__file__).parents[1] / "scripts/island.py")
island = importlib.util.module_from_spec(spec)
spec.loader.exec_module(island)


class Helpers(unittest.TestCase):
    def test_watcher_exits_even_when_parent_is_killed(self):
        helper_dir = str(Path(island.__file__).parent)
        child_code = ('import sys,os,time; sys.path.insert(0,sys.argv[1]); '
                      'import island; island.bind_parent_lifetime(int(sys.argv[2])); '
                      'print("ready",flush=True); time.sleep(30)')
        parent_code = ('import sys,os,subprocess; '
                       'child=subprocess.Popen([sys.executable,"-c",sys.argv[1],sys.argv[2],str(os.getpid())],stdout=subprocess.PIPE); '
                       'child.stdout.readline(); print(child.pid,flush=True); sys.stdin.read()')
        parent = subprocess.Popen([sys.executable, '-c', parent_code, child_code, helper_dir],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        child_pid = None
        try:
            child_pid = int(parent.stdout.readline())
            parent.kill()
            parent.wait(timeout=2)
            deadline = time.monotonic() + 2
            while time.monotonic() < deadline:
                try:
                    state = Path(f'/proc/{child_pid}/stat').read_text().split()[2]
                    if state == 'Z': break
                except FileNotFoundError:
                    break
                time.sleep(0.02)
            else:
                self.fail('Watcher survived its parent')
        finally:
            if child_pid:
                try: os.kill(child_pid, signal.SIGTERM)
                except ProcessLookupError: pass
            if parent.poll() is None: parent.kill()
            parent.wait(timeout=2)
            parent.stdin.close()
            parent.stdout.close()

    def test_usage_survives_restarts_and_concurrent_updates(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, XDG_STATE_HOME=directory):
            self.assertEqual(island.launcher_usage([]), {})
            with ThreadPoolExecutor(max_workers=4) as pool:
                list(pool.map(lambda _: island.launcher_usage([{'id': 'firefox.desktop'}]), range(12)))
            self.assertEqual(island.launcher_usage([])['firefox.desktop']['count'], 12)
            path = Path(directory) / 'quickshell/island-launcher.json'
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(json.loads(path.read_text())['firefox.desktop']['count'], 12)

    def test_usage_recovers_from_corrupt_and_invalid_entries(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, XDG_STATE_HOME=directory):
            island.launcher_usage([])
            path = Path(directory) / 'quickshell/island-launcher.json'
            for bad in ['{broken', '[]', '{"bad":{"count":"oops","last":0}}']:
                path.write_text(bad)
                self.assertEqual(set(island.launcher_usage([{'id': 'ok'}])), {'ok'})

    def test_initial_clipboard_replay_is_silent(self):
        copies = island.ClipboardObserver('existing')
        self.assertFalse(copies.accepts({'digest': 'existing', 'state': 'data'}))
        self.assertTrue(copies.accepts({'digest': 'existing', 'state': 'data'}))

    def test_empty_clipboard_does_not_swallow_first_real_copy(self):
        copies = island.ClipboardObserver(None)
        self.assertFalse(copies.accepts({'state': 'nil'}))
        self.assertTrue(copies.accepts({'digest': 'new', 'state': 'data'}))

    def test_copy_during_watcher_startup_is_not_mistaken_for_replay(self):
        copies = island.ClipboardObserver('old')
        self.assertTrue(copies.accepts({'digest': 'new', 'state': 'data'}))

    def test_sensitive_and_cleared_clipboard_produce_no_copy_alert(self):
        copies = island.ClipboardObserver(None)
        self.assertFalse(copies.accepts({'digest': 'secret', 'state': 'sensitive'}))
        self.assertFalse(copies.accepts({'state': 'clear'}))

    def test_cpu_uses_deltas_and_handles_zero(self):
        self.assertEqual(island.cpu_percent((1000, 800), (1200, 850)), 75)
        self.assertEqual(island.cpu_percent((1000, 800), (1000, 800)), 0)

    def test_memory_uses_available_not_free(self):
        self.assertEqual(island.memory_percent("MemTotal: 1000 kB\nMemAvailable: 600 kB\nMemFree: 50 kB"), 40)

    def test_restore_never_interpolates_clipboard_into_shell(self):
        with patch.object(island, 'run', side_effect=[b'$(touch /tmp/should-not-exist)\x00', b'']) as run, patch.object(island, 'emit'):
            island.restore('12')
            self.assertEqual(run.call_args_list[0].args, (["cliphist", "decode"], b'12\t\n'))
            self.assertEqual(run.call_args_list[1].args, (["wl-copy"], b'$(touch /tmp/should-not-exist)\x00'))
        with self.assertRaises(ValueError): island.restore('12; rm -rf ~')

    def test_hardware_arguments_are_bounded(self):
        with patch.object(island, 'run', side_effect=[b'', b'Volume: 0.55 [MUTED]']), patch.object(island, 'emit') as emit:
            island.hardware('volume', 'up')
            emit.assert_called_once_with('hardware', kind='volume', value=0.55, muted=True)

    def test_history_preserves_tabs_and_binary_entries(self):
        with patch.object(island, 'optional', return_value=b'2\ttext\twith tabs\n1\t[[ binary data 1 KiB png 100x100 ]]\nbad entry\n'):
            entries = island.history()
            self.assertEqual(entries[0]['preview'], 'text\twith tabs')
            self.assertTrue(entries[1]['image'])

    def test_failed_history_read_is_distinct_from_empty_history(self):
        with patch.object(island, 'optional', return_value=None):
            self.assertIsNone(island.history())
        with patch.object(island, 'optional', return_value=b''):
            self.assertEqual(island.history(), [])

    def test_hypr_query_handles_fragmented_ipc_response(self):
        with patch.dict(island.os.environ, {'XDG_RUNTIME_DIR': '/tmp/test-runtime', 'HYPRLAND_INSTANCE_SIGNATURE': 'test-session'}), patch.object(island.socket, 'socket') as socket:
            connection = socket.return_value.__enter__.return_value
            connection.recv.side_effect = [b'{"x":10,', b'"y":20}', b'']
            self.assertEqual(island.hypr_query('cursorpos'), {'x': 10, 'y': 20})
            connection.connect.assert_called_once_with('/tmp/test-runtime/hypr/test-session/.socket.sock')
            connection.sendall.assert_called_once_with(b'j/cursorpos')

    def test_hypr_query_tolerates_compositor_disconnect(self):
        with patch.dict(island.os.environ, {'XDG_RUNTIME_DIR': '/tmp/test-runtime', 'HYPRLAND_INSTANCE_SIGNATURE': 'test-session'}), patch.object(island.socket, 'socket') as socket:
            socket.return_value.__enter__.return_value.recv.side_effect = OSError('disconnected')
            self.assertIsNone(island.hypr_query('cursorpos'))

    def test_preview_accepts_raster_images_only(self):
        data = b'\x89PNG\r\n\x1a\nexample'
        self.assertEqual(island.image_url(data), 'data:image/png;base64,' + base64.b64encode(data).decode())
        self.assertEqual(island.image_url(b'<svg><image href="https://example.com"/></svg>'), '')
        self.assertEqual(island.image_url(None), '')

    def test_preview_is_read_only_and_rejects_invalid_ids(self):
        with patch.object(island, 'read_preview', return_value=b'\xff\xd8\xffdata') as decode, patch.object(island, 'emit') as emit:
            island.preview('42')
            decode.assert_called_once_with('42')
            self.assertTrue(emit.call_args.kwargs['url'].startswith('data:image/jpeg;base64,'))
        with self.assertRaises(ValueError): island.preview('42; malicious')

    def test_preview_decoder_bounds_real_pipe_output(self):
        with tempfile.TemporaryDirectory() as directory:
            command = Path(directory) / 'cliphist'
            command.write_text('#!' + sys.executable + '\nimport sys\nsys.stdin.readline()\nsys.stdout.buffer.write(b"x" * 4096)\n')
            command.chmod(0o700)
            with patch.dict(os.environ, {'PATH': directory}):
                self.assertEqual(island.read_preview('12', limit=4096), b'x' * 4096)
                self.assertIsNone(island.read_preview('12', limit=32))

    @unittest.skipUnless(shutil.which('cliphist'), 'cliphist is not installed')
    def test_real_cliphist_image_history_and_decode(self):
        data = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFElEQVR4nGNYuuVP2/s1DEAMZAEAPYgI7bYffO4AAAAASUVORK5CYII=')
        with tempfile.TemporaryDirectory(prefix='island-cliphist-test-') as directory:
            with patch.dict(os.environ, {'XDG_CACHE_HOME': directory + '/cache', 'XDG_CONFIG_HOME': directory + '/config', 'CLIPHIST_DB_PATH': directory + '/history.db', 'CLIPBOARD_STATE': 'data'}):
                subprocess.run(['cliphist', 'store'], input=data, check=True, capture_output=True)
                entries = island.history()
                self.assertEqual(len(entries), 1)
                self.assertTrue(entries[0]['image'], entries[0]['preview'])
                self.assertEqual(island.read_preview(entries[0]['id']), data)
                self.assertEqual(island.history(), entries, 'Decoding a preview must not mutate history')
                actual_run = island.run
                copied = []
                def restore_adapter(args, payload=None, **kwargs):
                    if args == ['wl-copy']:
                        copied.append(payload)
                        return b''
                    return actual_run(args, payload, **kwargs)
                with patch.object(island, 'run', side_effect=restore_adapter), patch.object(island, 'emit'):
                    island.restore(entries[0]['id'])
                self.assertEqual(copied, [data], 'Restoration must decode the actual stored image bytes')


if __name__ == '__main__': unittest.main()
