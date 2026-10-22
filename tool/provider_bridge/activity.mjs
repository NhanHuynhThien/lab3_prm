import { createHash } from 'node:crypto';
import { safeCount } from './codex.mjs';

// No prompt, title, path, account identity or raw session ID leaves the bridge.
export const opaqueId = (value) => createHash('sha256').update(String(value)).digest('hex').slice(0, 16);
export function classifyPurpose(text) {
  if (typeof text !== 'string') return 'other';
  const value = text.slice(0, 32000).normalize('NFD').replace(/\p{Diacritic}/gu, '').replace(/[đĐ]/g, 'd').toLowerCase();
  const rules = {
    debug: /\b(debug|bug|fix|error|crash|loi|sua loi|lag)\b/g,
    test: /\b(test|testing|verify|kiem thu|kiem tra)\b/g,
    review: /\b(review|audit|danh gia|ra soat)\b/g,
    design: /\b(design|redesign|css|layout|ui|ux|thiet ke|giao dien)\b/g,
    research: /\b(research|search|investigate|nghien cuu|tim hieu)\b/g,
    write: /\b(write|document|draft|viet|tai lieu|bao cao)\b/g,
    learn: /\b(explain|learn|teach|giai thich|hoc)\b/g,
    code: /\b(code|implement|build|refactor|function|lap trinh|tich hop)\b/g,
  };
  const scores = Object.entries(rules).map(([id, rule]) => [id, [...value.matchAll(rule)].length])
    .sort((a, b) => b[1] - a[1]);
  return scores[0][1] > 0 && scores[0][1] !== scores[1][1] ? scores[0][0] : 'other';
}

export function activitySummary(records, now = new Date(), partial = false) {
  const start = +now - 30 * 86400000;
  const rows = records.filter((r) => safeCount(r.total) != null && r.total > 0 &&
    Number.isFinite(Date.parse(r.timestamp)) && Date.parse(r.timestamp) >= start && Date.parse(r.timestamp) <= +now);
  if (!rows.length) return null;
  const totals = { totalTokens: 0, inputTokens: 0, outputTokens: 0, cachedInputTokens: 0,
    cacheWriteTokens: 0, reasoningTokens: 0, eventCount: 0 };
  const tasks = new Map(), days = new Map(), purposes = new Map();
  const fields = { totalTokens: 'total', inputTokens: 'input', outputTokens: 'output',
    cachedInputTokens: 'cached', cacheWriteTokens: 'cacheWrite', reasoningTokens: 'reasoning' };
  function add(target, r) {
    target.eventCount = (target.eventCount ?? 0) + 1;
    for (const [key, field] of Object.entries(fields)) {
      const v = safeCount(r[field]);
      target[key] = target[key] === null || v === null || !Number.isSafeInteger((target[key] ?? 0) + v)
        ? null : (target[key] ?? 0) + v;
    }
  }
  const sessions = new Set();
  for (const r of rows) {
    add(totals, r);
    const purpose = Object.hasOwn({ code: 1, debug: 1, test: 1, review: 1, design: 1,
      research: 1, write: 1, learn: 1 }, r.purpose) ? r.purpose : 'other';
    const day = new Date(r.timestamp).toISOString().slice(0, 10);
    const d = days.get(day) ?? { day }; add(d, r); days.set(day, d);
    const p = purposes.get(purpose) ?? { purpose }; add(p, r); purposes.set(purpose, p);
    if (!r.session) continue;
    sessions.add(r.session);
    const id = opaqueId(`${r.session}:${r.task ?? 0}`);
    const t = tasks.get(id) ?? { id, sessionId: opaqueId(r.session), purpose, models: new Set(),
      startedAt: null, endedAt: r.timestamp };
    if (/^[a-zA-Z0-9._:/-]{1,128}$/.test(r.model ?? '')) t.models.add(r.model);
    const began = Date.parse(r.startedAt);
    if (Number.isFinite(began) && began >= start && began <= Date.parse(r.timestamp)) {
      if (!t.startedAt || began < Date.parse(t.startedAt)) t.startedAt = new Date(began).toISOString();
    }
    if (Date.parse(r.timestamp) > Date.parse(t.endedAt)) t.endedAt = r.timestamp;
    add(t, r); tasks.set(id, t);
  }
  const sorted = [...tasks.values()].sort((a, b) => Date.parse(b.endedAt) - Date.parse(a.endedAt));
  return { periodStart: new Date(start).toISOString(), periodEnd: now.toISOString(), partial,
    ...totals, sessionCount: sessions.size, taskCount: tasks.size,
    activeDays: days.size, daily: [...days.values()].sort((a, b) => a.day.localeCompare(b.day)),
    purposes: [...purposes.values()].sort((a, b) => b.totalTokens - a.totalTokens),
    tasks: sorted.slice(0, 60).map((t) => ({ ...t, models: [...t.models].sort().slice(0, 100),
      elapsedSeconds: t.startedAt ? Math.floor((Date.parse(t.endedAt) - Date.parse(t.startedAt)) / 1000) : null })),
    omittedTasks: Math.max(0, sorted.length - 60), billedCostMicros: null,
    method: 'Mục đích suy luận bằng từ khóa của yêu cầu; nhãn Khác khi thiếu hoặc mơ hồ. Thời lượng từ yêu cầu đến token cuối, gồm chờ/nghỉ; không phải thời gian GPU. Cache là phần của input; reasoning là phần của output. Không có hóa đơn hay đơn giá đã xác nhận.' };
}
