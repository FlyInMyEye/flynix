const {test} = require('node:test');
const assert = require('node:assert/strict');
const S = require('../logic/State.js');

test('lock is absolute, including during capture and critical alerts', () => {
    const s = S.initial();
    Object.assign(s, {locked: true, launcher: true, workspace: true, stats: true, dragging: true});
    S.enqueue(s, 'urgent', 'warning', true);
    assert.equal(S.state(s, 0), 'LOCKING');
});
test('launcher, modifier, diagnostics preserve their priority', () => {
    const s = S.initial();
    Object.assign(s, {launcher: true, workspace: true, stats: true});
    S.enqueue(s, 'urgent', 'warning', true);
    for (const [flag, state] of [['launcher', 'LAUNCHER'], ['workspace', 'WORKSPACES'], ['stats', 'STATS']]) {
        assert.equal(S.state(s, 0), state); s[flag] = false;
    }
    assert.equal(S.state(s, 0), 'TRANSIENT');
});
for (const capture of ['launcher', 'clipboard', 'tray', 'stats', 'wifi', 'bluetooth', 'dragging']) {
    test(`normal notifications wait throughout ${capture}`, () => {
        const s = S.initial(); s[capture] = true;
        S.enqueue(s, 'first'); S.enqueue(s, 'second');
        S.tick(s, 10000, 10000);
        assert.equal(s.current.remaining, 3000);
        s[capture] = false;
        S.tick(s, 2999, 12999); assert.equal(s.current.text, 'first');
        S.tick(s, 1, 13000); assert.equal(s.current.text, 'second');
        S.tick(s, 3000, 16000); assert.equal(S.state(s, 16000), 'IDLE');
    });
}
test('workspace holds resume exactly the remaining notification time', () => {
    const s = S.initial(); S.enqueue(s, 'first');
    S.tick(s, 1234, 1234); s.workspace = true;
    S.tick(s, 5000, 6234); assert.equal(s.current.remaining, 1766);
    s.workspace = false; S.tick(s, 1765, 7999); assert.ok(s.current);
    S.tick(s, 1, 8000); assert.equal(s.current, null);
});
test('critical alerts displace and then resume the current item', () => {
    const s = S.initial(); S.enqueue(s, 'normal'); S.tick(s, 1000, 1000);
    s.clipboard = true; S.enqueue(s, 'urgent', 'warning', true);
    assert.equal(S.state(s, 1000), 'TRANSIENT');
    S.tick(s, 3000, 4000); assert.equal(s.current.text, 'normal');
    assert.equal(s.current.remaining, 2000); assert.equal(S.state(s, 4000), 'CLIPBOARD');
});
test('critical alerts never interrupt a file drag', () => {
    const s = S.initial(); s.dragging = true; S.enqueue(s, 'urgent', 'warning', true);
    assert.equal(S.state(s, 0), 'CLIPBOARD');
});
test('hardware overlays expire two seconds after the latest input', () => {
    const s = S.initial(); s.hardwareUntil = 2000;
    assert.equal(S.state(s, 1999), 'HARDWARE'); assert.equal(S.state(s, 2000), 'IDLE');
    s.hardwareUntil = 3500; assert.equal(S.state(s, 3499), 'HARDWARE');
});
test('automatic workspace previews do not hide an open clipboard or tray', () => {
    for (const capture of ['clipboard', 'tray']) {
        const s = S.initial(); s[capture] = true; s.workspaceUntil = 850;
        assert.equal(S.state(s, 0), capture.toUpperCase());
        s.workspace = true;
        assert.equal(S.state(s, 0), 'WORKSPACES');
        s.workspace = false;
        assert.equal(S.state(s, 0), capture.toUpperCase());
    }
});
test('pointer capture defers critical alerts until the gesture finishes', () => {
    const s = S.initial(); s.pointerCapture = true;
    S.enqueue(s, 'urgent', 'warning', true);
    S.tick(s, 2000, 2000);
    assert.equal(S.state(s, 2000), 'IDLE');
    assert.equal(s.current.remaining, 3000);
    s.pointerCapture = false;
    assert.equal(S.state(s, 2000), 'TRANSIENT');
});
test('copy combos update their existing slot, including while queued', () => {
    const s = S.initial(); S.enqueue(s, 'other');
    S.enqueue(s, 'Copied', 'copy', false, 'copy');
    S.enqueue(s, 'Copied ×3', 'copy', false, 'copy');
    assert.equal(s.queue.length, 1); S.tick(s, 3000, 3000);
    assert.equal(s.current.text, 'Copied ×3');
    S.enqueue(s, '+900', 'score', false, 'copy');
    assert.equal(s.current.text, '+900'); assert.equal(s.queue.length, 0);
});
test('file relay accepts only local URI lists and preserves escaped filenames', () => {
    assert.deepEqual(S.localFiles(['file:///tmp/a%20b.pdf', 'https://example.com/file', 'file://evil/tmp/a', 'file:///tmp/a%20b.pdf', 'file://localhost/tmp/c', 'file:///tmp/a\nfile:///tmp/b']), ['file:///tmp/a%20b.pdf', 'file://localhost/tmp/c']);
});
test('untrusted event floods are bounded', () => {
    const s = S.initial(); for (let i = 0; i < 1000; i++) S.enqueue(s, `${i}`);
    assert.equal(s.queue.length, 100); assert.equal(s.current.text, '0');
});
