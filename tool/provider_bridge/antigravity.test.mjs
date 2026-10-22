import test from 'node:test';
import assert from 'node:assert/strict';
import { parseAntigravityUsage, readAntigravity } from './antigravity.mjs';

const envelope = (fraction = .2) => ({ status: 'SUCCESS', num_turns: 0, command: { name: 'usage', data: { groups: [{name: 'Gemini', buckets: [{id: 'five-hour', name: '5h', remaining_fraction: fraction, reset_time: '2026-10-22T18:00:00Z'}]}] } }, email: 'private@example.test', access_token: 'secret', response: 'sensitive text' });
test('official quota envelope is allowlisted and fraction becomes percent', () => {
  const result = parseAntigravityUsage(envelope(), new Date('2026-10-22T12:00:00Z'));
  assert.equal(result.windows[0].usedPercent, 80);
  assert.equal(result.totalTokens, null);
  assert.equal(result.status, 'ready');
  assert.ok(!JSON.stringify(result).includes('secret'));
  assert.ok(!JSON.stringify(result).includes('private@example'));
});
test('zero and fully remaining quotas are valid; invalid data cannot become ready', () => {
  assert.equal(parseAntigravityUsage(envelope(0)).windows[0].usedPercent, 100);
  assert.equal(parseAntigravityUsage(envelope(1)).windows[0].usedPercent, 0);
  for (const x of [-1, 1.1, null, '0.5']) assert.throws(() => parseAntigravityUsage(envelope(x)));
  assert.throws(() => parseAntigravityUsage({...envelope(), num_turns: 1}));
});
test('reader invokes only the read-only slash command and never an agent prompt', async () => {
  const result = await readAntigravity({binary: '/official/agy', execute: async (binary, args, options) => {
    assert.equal(binary, '/official/agy');
    assert.deepEqual(args, ['--print', '/usage', '--output-format', 'json']);
    assert.equal(options.timeout, 18000);
    return {stdout: JSON.stringify(envelope())};
  }});
  assert.equal(result.status, 'ready');
});
test('missing or unauthenticated CLI remains unknown and exposes no process output', async () => {
  const result = await readAntigravity({execute: async () => {throw Object.assign(new Error('secret token'), {code: 'ENOENT'});}});
  assert.equal(result.status, 'setup'); assert.equal(result.windows.length, 0);
  assert.equal(result.totalTokens, null); assert.ok(!JSON.stringify(result).includes('secret token'));
});
test('model group and supported window keys survive without exposing other fields', () => {
  const raw = envelope(); raw.command.data.groups[0].buckets[0].window = '5h';
  const result = parseAntigravityUsage(raw);
  assert.equal(result.windows[0].group, 'Gemini');
  assert.equal(result.windows[0].window, '5h');
});
