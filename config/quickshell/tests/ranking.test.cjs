const {test} = require('node:test');
const assert = require('node:assert/strict');
const R = require('../logic/Ranking.js');
const now = 1800000000000;
const day = 86400000;
const apps = [
  {id: 'a', name: 'Alpha', genericName: 'Web browser', keywords: ['internet']},
  {id: 'b', name: 'Beta', genericName: 'Editor', keywords: ['text']},
  {id: 'c', name: 'Gamma', genericName: 'Terminal', keywords: []},
];
const order = (query, usage = {}, source = apps) => R.rank(source, query, usage, now).map(a => a.id);
test('recent and frequent launches precede unused applications', () => {
  assert.deepEqual(order('', {c: {count: 1, last: now}}), ['c', 'a', 'b']);
  assert.deepEqual(order('', {b: {count: 20, last: now}, c: {count: 1, last: now}}), ['b', 'c', 'a']);
});
test('old habits decay so yesterday’s one-off can beat a stale favorite', () => {
  assert.deepEqual(order('', {b: {count: 100, last: now - 180 * day}, c: {count: 1, last: now - day}}), ['c', 'b', 'a']);
});
test('exact names and prefixes beat heavily used keyword matches', () => {
  const source = apps.concat({id: 'd', name: 'Al', keywords: []}, {id: 'e', name: 'Other', keywords: ['alpha']});
  assert.deepEqual(order('al', {e: {count: 9999, last: now}}, source), ['d', 'a', 'e', 'c']);
});
test('multiple words match across names and metadata without depending on order', () => {
  assert.deepEqual(order('internet web'), ['a']);
  assert.deepEqual(order('EDITOR be'), ['b']);
  assert.deepEqual(order('nonexistent'), []);
});
test('hidden entries never surface and equal names retain distinct desktop IDs', () => {
  assert.deepEqual(order('', {b: {count: 2, last: now}}, [
    {id: 'a', name: 'Same'}, {id: 'b', name: 'Same'}, {id: 'c', name: 'Hidden', noDisplay: true}
  ]), ['b', 'a']);
});
