import { readdir, readFile, lstat } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { safeCount } from './codex.mjs';
import { modelRows } from './models.mjs';
import { activitySummary } from './activity.mjs';

export function geminiMessages(text) {
  try {
    const doc = JSON.parse(text);
    if (Array.isArray(doc.messages)) return doc.messages;
  } catch { /* Current Gemini CLI records append-only JSONL. */ }
  let messages = new Map();
  for (const line of text.split('\n')) {
    let row;
    try { row = JSON.parse(line); } catch { continue; }
    if (Array.isArray(row.$set?.messages)) {
      messages = new Map(row.$set.messages.map((m) => [m.id, m]));
    } else if (row.$rewindTo) {
      let after = false;
      for (const id of messages.keys()) {
        if (after) messages.delete(id);
        if (id === row.$rewindTo) after = true;
      }
    } else if (row.$patch?.removeIds) {
      for (const id of row.$patch.removeIds) messages.delete(id);
    } else if (row.type === 'gemini' && typeof row.id === 'string') {
      messages.set(row.id, row);
    }
  }
  return [...messages.values()];
}

export async function readGemini(root = join(homedir(), '.gemini', 'tmp'), now = new Date()) {
  const files = [];
  let truncated = false;
  async function walk(dir, depth = 0) {
    if (depth > 4) return;
    let entries;
    try { entries = await readdir(dir, { withFileTypes: true }); }
    catch (e) { if (e.code !== 'ENOENT') truncated = true; return; }
    for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
      if (files.length >= 500) { truncated = true; break; }
      if (entry.isSymbolicLink()) continue;
      const path = join(dir, entry.name);
      if (entry.isDirectory()) await walk(path, depth + 1);
      else if (entry.isFile() && /^session-.*\.jsonl?$/.test(entry.name)) files.push(path);
    }
  }
  await walk(root);
  let tokens = 0, known = 0, observed = null;
  const records = [];
  const seen = new Set();
  for (const file of files) {
    try {
      const stat = await lstat(file);
      if (!stat.isFile() || stat.size > 8 * 1024 * 1024) { truncated = true; continue; }
      for (const row of geminiMessages(await readFile(file, 'utf8'))) {
        const date = Date.parse(row.timestamp), amount = safeCount(row.tokens?.total);
        if (row.type !== 'gemini' || typeof row.id !== 'string' || amount === null ||
            !Number.isFinite(date) || date > +now || +now - date > 30 * 86400000) continue;
        // Session files can be copied/resumed; do not count the same message twice.
        if (seen.has(row.id)) continue;
        seen.add(row.id);
        if (!Number.isSafeInteger(tokens + amount)) { truncated = true; continue; }
        tokens += amount; known++;
        records.push({ model: row.model, input: row.tokens.input, output: row.tokens.output, total: amount,
          timestamp: row.timestamp, session: file, task: row.id, purpose: 'other',
          cached: safeCount(row.tokens.cached), reasoning: safeCount(row.tokens.thoughts), cacheWrite: null });
        observed = Math.max(observed ?? 0, date);
      }
    } catch { truncated = true; }
  }
  return { id: 'google', status: known ? 'ready' : 'setup', plan: null,
    source: 'Gemini CLI · lịch sử 30 ngày',
    coverage: `${truncated ? 'Một phần lịch sử. ' : ''}Chỉ phiên CLI lưu trên máy; chưa đọc quota/hoá đơn AI Pro hay usage website.`,
    observedAt: observed == null ? null : new Date(observed).toISOString(),
    totalTokens: known ? tokens : null, contextTokens: null, windows: [],
    activity: activitySummary(records, now, truncated), models: modelRows(records), modelsCoverage: 'Lịch sử Gemini CLI trên máy, 30 ngày; không xác minh cùng owner với Google login.',
    estimatedCostMicros: null, subscriptionFeeMicros: null, billedCostMicros: null };
}
