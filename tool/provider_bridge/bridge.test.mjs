import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { PassThrough } from 'node:stream';
import { mkdtemp, writeFile, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { readCodex, codexWindows } from './codex.mjs';
import { sanitizeClaude, readClaude } from './claude.mjs';
import { geminiMessages, readGemini } from './gemini.mjs';
import { bridgeServer, withLocalUsage } from './server.mjs';
import { request as httpRequest } from 'node:http';
import { codexModelRecords, claudeModelRecords, modelRows } from './models.mjs';

function fakeCodex({ usageError = false, hang = false } = {}) {
  const methods = [];
  const child = new EventEmitter();
  child.stdin = new PassThrough(); child.stdout = new PassThrough();
  child.kill = () => { child.killed = true; };
  child.stdin.on('data', (buffer) => {
    for (const line of String(buffer).trim().split('\n')) {
      const msg = JSON.parse(line); methods.push(msg.method);
      if (!msg.id || hang) continue;
      let result = {};
      if (msg.method === 'account/read') result = { account: { type: 'chatgpt', planType: 'business', email: 'private@example.test' } };
      if (msg.method === 'account/rateLimits/read') result = { rateLimits: {
        primary: { usedPercent: 12, windowDurationMins: 300, resetsAt: 1800000000 } } };
      if (msg.method === 'account/usage/read') result = { summary: { lifetimeTokens: 1000 } };
      queueMicrotask(() => child.stdout.write(`${JSON.stringify(
        usageError && msg.method === 'account/usage/read'
          ? { id: msg.id, error: { message: 'private SDK error' } }
          : { id: msg.id, result })}\n`));
    }
  });
  return { methods, child, spawnImpl: () => child };
}

test('Codex only reads allowed RPCs; discards identity secrets', async () => {
  const fake = fakeCodex();
  const value = await readCodex(fake);
  assert.deepEqual(fake.methods, ['initialize', 'initialized', 'account/read', 'account/rateLimits/read', 'account/usage/read']);
  assert.equal(value.plan, 'business'); assert.equal(value.totalTokens, 1000);
  assert.equal(value.windows.length, 1); assert.equal(fake.child.killed, true);
  assert.ok(!JSON.stringify(value).includes('private'));
});
test('Codex old usage RPC does not erase valid quota', async () => {
  const value = await readCodex(fakeCodex({ usageError: true }));
  assert.equal(value.totalTokens, null); assert.equal(value.windows.length, 1);
});
test('Codex timeout closes process', async () => {
  const fake = fakeCodex({ hang: true });
  await assert.rejects(readCodex({ ...fake, timeout: 10 }));
  assert.equal(fake.child.killed, true);
});
test('Codex multi-bucket response never counts legacy copy twice', () => {
  const bucket = { primary: { usedPercent: 20, resetsAt: 1800000000 } };
  assert.equal(codexWindows({ rateLimits: bucket, rateLimitsByLimitId: { codex: bucket } }).length, 1);
  assert.equal(codexWindows({ rateLimits: { primary: { usedPercent: 200 } } }).length, 0);
});
test('Claude never treats context count or estimated cost as billed usage', () => {
  const result = sanitizeClaude({ session_id: 'secret', access_token: 'secret',
    cost: { total_cost_usd: .123456 }, context_window: { total_input_tokens: 1234 },
    rate_limits: { seven_day: { used_percentage: 0, resets_at: 1800000000 } } });
  assert.equal(result.totalTokens, null); assert.equal(result.contextTokens, 1234);
  assert.equal(result.estimatedCostMicros, 123456); assert.equal(result.billedCostMicros, null);
  assert.equal(result.windows[0].usedPercent, 0); assert.ok(!JSON.stringify(result).includes('secret'));
});
test('Claude only-weekly window survives persistence without relabeling', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'tl-claude-'));
  try {
    await writeFile(join(dir, 'claude-metrics.json'), JSON.stringify(sanitizeClaude({
      rate_limits: { seven_day: { used_percentage: 30, resets_at: 1800000000 } } })));
    assert.equal((await readClaude(dir)).windows[0].label, '7 ngày');
  } finally { await rm(dir, { recursive: true, force: true }); }
});
test('Gemini JSONL updates/dedupes and honors rewind/removal', () => {
  const a = { id: 'a', type: 'gemini', tokens: { total: 10 } };
  const b = { id: 'b', type: 'gemini', tokens: { total: 20 } };
  const text = [a, a, b, { $rewindTo: 'a' }].map(JSON.stringify).join('\n');
  assert.equal(geminiMessages(text).length, 1);
  assert.equal(geminiMessages(`${text}\n{"$patch":{"removeIds":["a"]}}`).length, 0);
});
test('Gemini sums only recent known metrics and excludes prompts, duplicates, symlinks', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'tl-gemini-'));
  try {
    const now = new Date('2026-10-21T10:00:00Z');
    const doc = { messages: [{ id: 'known', type: 'gemini', timestamp: now.toISOString(), tokens: { total: 120 }, content: 'SECRET PROMPT' },
      { id: 'old', type: 'gemini', timestamp: '2025-01-01T00:00:00Z', tokens: { total: 400 } }] };
    await writeFile(join(dir, 'session-a.json'), JSON.stringify(doc));
    await writeFile(join(dir, 'session-copy.json'), JSON.stringify(doc));
    await symlink(join(dir, 'session-a.json'), join(dir, 'session-link.json'));
    const result = await readGemini(dir, now);
    assert.equal(result.totalTokens, 120); assert.equal(result.plan, null);
    assert.ok(!JSON.stringify(result).includes('SECRET'));
  } finally { await rm(dir, { recursive: true, force: true }); }
});
test('missing sources are unknown, not measured zero', async () => {
  assert.equal((await readClaude('/nonexistent-tokenledger')).status, 'setup');
  assert.equal((await readGemini('/nonexistent-tokenledger')).totalTokens, null);
});
test('bridge auth/origin/host boundaries and concurrent refresh coalescing', async () => {
  let calls = 0;
  const token = 'a'.repeat(64);
  const server = bridgeServer({ token, collect: async () => {
    calls++; await new Promise((r) => setTimeout(r, 10)); return { safe: true };
  } });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const url = `http://127.0.0.1:${server.address().port}/v1/snapshot`;
  const request = (headers = {}, method = 'GET') => new Promise((resolve, reject) => {
    const req = httpRequest(url, { method, headers }, (res) => {
      res.resume();
      res.on('end', () => resolve({ status: res.statusCode,
        headers: { get: (key) => res.headers[key.toLowerCase()] } }));
    });
    req.on('error', reject); req.end();
  });
  try {
    assert.equal((await request()).status, 401);
    assert.equal((await request({ Host: 'evil.test' })).status, 403);
    assert.equal((await request({ Origin: 'https://evil.test', Authorization: `Bearer ${token}` })).status, 403);
    assert.equal(calls, 0);
    const headers = { Origin: 'http://localhost:4183', Authorization: `Bearer ${token}` };
    const results = await Promise.all([request(headers), request(headers)]);
    assert.equal(calls, 1); assert.equal(results[0].status, 200);
    assert.equal(results[0].headers.get('Access-Control-Allow-Origin'), 'http://localhost:4183');
    assert.equal((await request(headers, 'POST')).status, 405);
    assert.equal((await request({ Origin: 'http://localhost:4183' }, 'OPTIONS')).status, 204);
  } finally { await new Promise((r) => server.close(r)); }
});

test('Codex model counters use cumulative deltas, dedupe repeats and retain model switches', () => {
  const now = new Date('2026-10-21T12:00:00Z');
  const event = (input, output) => ({ type: 'event_msg', timestamp: now.toISOString(), payload: {
    type: 'token_count', info: { total_token_usage: { input_tokens: input, output_tokens: output, total_tokens: input + output } } } });
  const text = [{ type: 'turn_context', payload: { model: 'gpt-model-a' } }, event(100, 20), event(100, 20),
    { type: 'turn_context', payload: { model: 'gpt-model-b' } }, event(130, 30)].map(JSON.stringify).join('\n');
  const rows = modelRows(codexModelRecords(text, now));
  assert.equal(rows[0].totalTokens, 120); assert.equal(rows[1].totalTokens, 40);
  assert.equal(rows[0].estimatedCostMicros, null);
});
test('Claude model streaming messages dedupe and count cache input once', () => {
  const now = new Date('2026-10-21T12:00:00Z');
  const event = (output) => ({ type: 'assistant', timestamp: now.toISOString(), message: {
    id: 'same', model: 'claude-test', content: 'PRIVATE',
    usage: { input_tokens: 100, output_tokens: output, cache_read_input_tokens: 200 } } });
  const rows = modelRows(claudeModelRecords([event(1), event(10)].map(JSON.stringify).join('\n'), now));
  assert.equal(rows[0].totalTokens, 310); assert.equal(rows[0].inputTokens, 300);
  assert.ok(!JSON.stringify(rows).includes('PRIVATE'));
});

test('local session tokens make a source ready when quota is unavailable', () => {
  const now = new Date('2026-11-04T00:00:00Z');
  const usage = { models: [{ model: 'm', totalTokens: 5 }], activity: { totalTokens: 5 }, modelsCoverage: 'Local.' };
  const row = withLocalUsage({ id: 'codex', status: 'error', windows: [], totalTokens: null }, usage, now);
  assert.equal(row.status, 'ready');
  assert.equal(row.totalTokens, 5);
  assert.equal(row.observedAt, now.toISOString());
  assert.equal(withLocalUsage({ id: 'codex', status: 'setup' }, { models: [], activity: null }).status, 'setup');
  assert.equal(withLocalUsage({ id: 'codex', status: 'ready', totalTokens: 9 }, usage).totalTokens, 9);
});
