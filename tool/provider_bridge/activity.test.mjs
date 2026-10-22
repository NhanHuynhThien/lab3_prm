import { test } from 'node:test';
import assert from 'node:assert/strict';
import { activitySummary, classifyPurpose } from './activity.mjs';
import { codexModelRecords, claudeModelRecords } from './models.mjs';
const now = new Date('2026-10-22T10:00:00Z');
const base = { session: 'PRIVATE_SESSION', task: 1, purpose: 'code', model: 'test-model',
  timestamp: '2026-10-22T09:05:00Z', startedAt: '2026-10-22T09:00:00Z',
  input: 100, output: 20, total: 120, cached: 60, reasoning: 5 };
test('purpose classifier is conservative and supports Vietnamese', () => {
  assert.equal(classifyPurpose('redesign giao diện'), 'design');
  assert.equal(classifyPurpose('kiểm thử testing test'), 'test');
  assert.equal(classifyPurpose('fix crash bug'), 'debug');
  assert.equal(classifyPurpose('test code'), 'other');
  assert.equal(classifyPurpose(undefined), 'other');
});
test('activity totals include all records; cache/reasoning are not added twice', () => {
  const a = activitySummary([base, { ...base, task: 2, purpose: 'test' }], now);
  assert.equal(a.totalTokens, 240); assert.equal(a.cachedInputTokens, 120);
  assert.equal(a.cacheWriteTokens, null); assert.equal(a.reasoningTokens, 10);
  assert.equal(a.sessionCount, 1); assert.equal(a.taskCount, 2);
  assert.equal(a.tasks[0].elapsedSeconds, 300); assert.equal(a.billedCostMicros, null);
  assert.equal(a.daily[0].totalTokens, 240);
  assert.equal(a.purposes.reduce((n, p) => n + p.totalTokens, 0), 240);
  assert.ok(!JSON.stringify(a).includes('PRIVATE'));
});
test('unknown breakdown stays unknown, zero cache is measured zero', () => {
  const a = activitySummary([base, { ...base, input: undefined, cached: 0 }], now);
  assert.equal(a.inputTokens, null); assert.equal(a.cachedInputTokens, 60);
  assert.equal(activitySummary([{ ...base, cached: 0 }], now).cachedInputTokens, 0);
});
test('30 day boundary/future/invalid excluded; missing start has no invented duration', () => {
  const a = activitySummary([{ ...base, startedAt: undefined },
    { ...base, timestamp: '2026-10-23T10:00:00Z' },
    { ...base, timestamp: '2026-09-01T10:00:00Z' }], now, true);
  assert.equal(a.totalTokens, 120); assert.equal(a.tasks[0].elapsedSeconds, null);
  assert.equal(a.partial, true); assert.equal(activitySummary([], now), null);
});
test('task payload is bounded but total accounting is complete', () => {
  const a = activitySummary(Array.from({ length: 80 }, (_, task) => ({ ...base, task })), now);
  assert.equal(a.tasks.length, 60); assert.equal(a.omittedTasks, 20);
  assert.equal(a.totalTokens, 9600); assert.equal(a.taskCount, 80);
});
test('Codex attaches purpose/time/cache and omits prompt contents', () => {
  const text = [
    { type: 'session_meta', payload: { id: 'PRIVATE_SESSION' } },
    { type: 'turn_context', payload: { model: 'test-model' } },
    { type: 'event_msg', timestamp: base.startedAt, payload: { type: 'user_message', message: 'fix crash PRIVATE' } },
    { type: 'event_msg', timestamp: base.timestamp, payload: { type: 'token_count', info: {
      total_token_usage: { input_tokens: 100, cached_input_tokens: 60, output_tokens: 20, reasoning_output_tokens: 5, total_tokens: 120 } } } },
  ].map(JSON.stringify).join('\n');
  const a = activitySummary(codexModelRecords(text, now), now);
  assert.equal(a.tasks[0].purpose, 'debug'); assert.equal(a.cachedInputTokens, 60);
  assert.equal(a.tasks[0].elapsedSeconds, 300); assert.ok(!JSON.stringify(a).includes('PRIVATE'));
});
test('Claude streaming usage retains task attribution and distinct cache writes', () => {
  const text = [
    { type: 'user', timestamp: base.startedAt, message: { content: 'review review PRIVATE' } },
    ...[1, 20].map((output) => ({ type: 'assistant', sessionId: 'PRIVATE_SESSION', timestamp: base.timestamp,
      message: { id: 'msg1', model: 'test-model', usage: { input_tokens: 40,
        cache_read_input_tokens: 60, cache_creation_input_tokens: 10, output_tokens: output } } })),
  ].map(JSON.stringify).join('\n');
  const a = activitySummary(claudeModelRecords(text, now), now);
  assert.equal(a.totalTokens, 130); assert.equal(a.inputTokens, 110);
  assert.equal(a.tasks[0].purpose, 'review'); assert.equal(a.cacheWriteTokens, 10);
  assert.ok(!JSON.stringify(a).includes('PRIVATE'));
});
test('Codex response_item user metadata ignores environment-only content', () => {
  const text = [
    { type: 'session_meta', payload: { id: 'session' } },
    { type: 'turn_context', payload: { model: 'test-model' } },
    { type: 'response_item', timestamp: base.startedAt, payload: { type: 'message', role: 'user',
      internal_chat_message_metadata_passthrough: { content_item_kinds: ['environments.environment_context', 'user.text'] },
      content: [{ type: 'input_text', text: 'design design' }, { type: 'input_text', text: 'fix crash' }] } },
    { type: 'event_msg', timestamp: base.timestamp, payload: { type: 'token_count', info: {
      total_token_usage: { input_tokens: 100, output_tokens: 20, total_tokens: 120 } } } },
  ].map(JSON.stringify).join('\n');
  const a = activitySummary(codexModelRecords(text, now), now);
  assert.equal(a.tasks[0].purpose, 'debug'); assert.equal(a.tasks[0].elapsedSeconds, 300);
});
test('Codex per-response usage excludes inherited thread and cumulative mirror', () => {
  const text = [
    { type: 'session_meta', payload: { id: 'session' } },
    { type: 'turn_context', payload: { model: 'test-model' } },
    ...['parent', 'session', 'session'].map((thread_id) => ({ type: 'token_usage_record', timestamp: base.timestamp,
      payload: { thread_id, response_id: 'response', turn_id: 'turn', usage: {
        input_tokens: 100, output_tokens: 20, total_tokens: 120, cached_input_tokens: 60, cache_write_input_tokens: 0 } } })),
    { type: 'event_msg', timestamp: base.timestamp, payload: { type: 'token_count', info: {
      total_token_usage: { input_tokens: 1000, output_tokens: 200, total_tokens: 1200 } } } },
  ].map(JSON.stringify).join('\n');
  const records = codexModelRecords(text, now);
  assert.equal(records.length, 1); assert.equal(records[0].total, 120);
  assert.equal(records[0].cacheWrite, 0);
});
