import { readdir, lstat, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { safeCount } from './codex.mjs';
import { activitySummary, classifyPurpose } from './activity.mjs';

const validModel = (model) => typeof model === 'string' && /^[a-zA-Z0-9._:/-]{1,128}$/.test(model);
const inPeriod = (date, now) => Number.isFinite(Date.parse(date)) &&
  Date.parse(date) <= +now && +now - Date.parse(date) <= 30 * 86400000;

export function modelRows(records) {
  const result = new Map();
  for (const r of records) {
    if (!validModel(r.model) || safeCount(r.total) == null) continue;
    const value = result.get(r.model) ?? { model: r.model, inputTokens: 0, outputTokens: 0,
      totalTokens: 0, estimatedCostMicros: null, billedCostMicros: null };
    for (const [key, raw] of [['inputTokens', r.input], ['outputTokens', r.output], ['totalTokens', r.total]]) {
      value[key] = value[key] == null || safeCount(raw) == null ||
        !Number.isSafeInteger(value[key] + raw) ? null : value[key] + raw;
    }
    result.set(r.model, value);
  }
  return [...result.values()].filter((v) => v.totalTokens != null)
    .sort((a, b) => b.totalTokens - a.totalTokens).slice(0, 100);
}

export function codexModelRecords(text, now = new Date()) {
  let model = null, session = null, task = 0, purpose = 'other', startedAt = null;
  let previous = { input_tokens: 0, output_tokens: 0, total_tokens: 0, cached_input_tokens: 0, reasoning_output_tokens: 0 };
  const records = [], responses = new Map();
  for (const line of text.split('\n')) {
    let row;
    try { row = JSON.parse(line); } catch { continue; }
    if (row.type === 'session_meta') session = row.payload?.id;
    if (row.type === 'turn_context') model = row.payload?.model;
    if (row.type === 'event_msg' && row.payload?.type === 'user_message') {
      task++; purpose = classifyPurpose(row.payload.message); startedAt = row.timestamp;
    }
    if (row.type === 'response_item' && row.payload?.type === 'message' && row.payload.role === 'user') {
      const p = row.payload, meta = p.internal_chat_message_metadata_passthrough;
      const kinds = meta?.content_item_kinds;
      const parts = (p.content ?? []).filter((c, i) => (c.type === 'input_text' || c.type === 'text') &&
        (!Array.isArray(kinds) || kinds[i] === 'user.text'));
      const content = parts.map((c) => c.text ?? '').join(' ').trim();
      if (content) { task++; purpose = classifyPurpose(content); startedAt = row.timestamp; }
    }
    if (row.type === 'token_usage_record') {
      const p = row.payload, u = p?.usage;
      if (p?.thread_id === session && typeof p.response_id === 'string' &&
          safeCount(u?.total_tokens) != null && inPeriod(row.timestamp, now)) {
        responses.set(p.response_id, { id: p.response_id, model, session, task: p.turn_id ?? task,
          purpose, startedAt, timestamp: row.timestamp, input: safeCount(u.input_tokens),
          output: safeCount(u.output_tokens), total: u.total_tokens,
          cached: safeCount(u.cached_input_tokens), cacheWrite: safeCount(u.cache_write_input_tokens),
          reasoning: safeCount(u.reasoning_output_tokens) });
      }
    }
    if (row.type !== 'event_msg' || row.payload?.type !== 'token_count') continue;
    const total = row.payload.info?.total_token_usage;
    if (safeCount(total?.total_tokens) == null) continue;
    const diff = (key) => safeCount(total[key]) != null && safeCount(previous[key]) != null
      ? Math.max(0, total[key] - previous[key]) : null;
    const record = { model, session, task, purpose, startedAt, timestamp: row.timestamp,
      input: diff('input_tokens'), output: diff('output_tokens'), total: diff('total_tokens'),
      cached: diff('cached_input_tokens'), reasoning: diff('reasoning_output_tokens'), cacheWrite: null };
    previous = total;
    if (record.total > 0 && inPeriod(row.timestamp, now)) records.push(record);
  }
  // New schema has per-response usage; never add its cumulative mirror again.
  return responses.size ? [...responses.values()] : records;
}

export function claudeModelRecords(text, now = new Date()) {
  const messages = new Map();
  let task = 0, purpose = 'other', startedAt = null;
  for (const line of text.split('\n')) {
    let row;
    try { row = JSON.parse(line); } catch { continue; }
    const msg = row.message;
    if (row.type === 'user') {
      const content = typeof msg?.content === 'string' ? msg.content : Array.isArray(msg?.content)
        ? msg.content.filter((c) => c.type === 'text').map((c) => c.text).join(' ') : '';
      if (content) { task++; purpose = classifyPurpose(content); startedAt = row.timestamp; }
    }
    if (row.type !== 'assistant' || typeof msg?.id !== 'string' || !validModel(msg.model) ||
        !msg.usage || !inPeriod(row.timestamp, now)) continue;
    const key = `${msg.id}:${msg.model}`;
    const old = messages.get(key)?.usage ?? {};
    const usage = { ...old };
    for (const field of ['input_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens', 'output_tokens']) {
      if (safeCount(msg.usage[field]) != null) usage[field] = Math.max(old[field] ?? 0, msg.usage[field]);
    }
    messages.set(key, { model: msg.model, usage, session: row.sessionId, task, purpose,
      startedAt, timestamp: row.timestamp });
  }
  return [...messages.entries()].flatMap(([id, { model, usage: u, ...meta }]) => {
    if (safeCount(u.input_tokens) == null || safeCount(u.output_tokens) == null) return [];
    const input = u.input_tokens + (u.cache_creation_input_tokens ?? 0) + (u.cache_read_input_tokens ?? 0);
    return [{ id, model, ...meta, input, output: u.output_tokens, total: input + u.output_tokens,
      cached: safeCount(u.cache_read_input_tokens), cacheWrite: safeCount(u.cache_creation_input_tokens), reasoning: null }];
  });
}

export async function localModelUsage(provider, root, now = new Date()) {
  root ??= join(homedir(), provider === 'codex' ? '.codex/sessions' : '.claude/projects');
  const records = [], files = [];
  let partial = false;
  async function walk(dir, depth = 0) {
    if (depth > 7) { partial = true; return; }
    let entries;
    try { entries = await readdir(dir, { withFileTypes: true }); }
    catch (e) { if (e.code !== 'ENOENT') partial = true; return; }
    for (const e of entries.sort((a, b) => b.name.localeCompare(a.name))) {
      if (files.length >= 500) { partial = true; break; }
      if (e.isSymbolicLink()) continue;
      const path = join(dir, e.name);
      if (e.isDirectory()) await walk(path, depth + 1);
      else if (e.isFile() && e.name.endsWith('.jsonl')) files.push(path);
    }
  }
  await walk(root);
  const seenSessions = new Set();
  for (const path of files) {
    try {
      const stat = await lstat(path);
      if (stat.mtimeMs < +now - 30 * 86400000) continue;
      if (!stat.isFile() || stat.size > 16 * 1024 * 1024) { partial = true; continue; }
      const text = await readFile(path, 'utf8');
      // Rollout copies have the same session_meta ID; do not count them twice.
      if (provider === 'codex') {
        let session;
        try { const first = JSON.parse(text.split('\n', 1)[0]); session = first.type === 'session_meta' ? first.payload?.id : null; } catch { /* malformed */ }
        if (!session) { partial = true; continue; }
        if (seenSessions.has(session)) continue;
        seenSessions.add(session);
      }
      records.push(...(provider === 'codex' ? codexModelRecords(text, now) : claudeModelRecords(text, now)));
    } catch { partial = true; }
  }
  const unique = [...new Map(records.map((r, i) => [r.id ?? `legacy:${i}`, r])).values()];
  return { activity: activitySummary(unique, now, partial), models: modelRows(unique), modelsCoverage: `${partial ? 'Một phần dữ liệu. ' : ''}Lịch sử model trên máy trong 30 ngày; có thể gồm nhiều tài khoản, không phải tổng website.` };
}
