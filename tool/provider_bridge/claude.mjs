import { readFile, mkdir, writeFile, rename } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { safeCount } from './codex.mjs';

export const stateDir = join(homedir(), '.local', 'share', 'tokenledger');

export function sanitizeClaude(raw, now = new Date()) {
  const windows = ['five_hour', 'seven_day'].flatMap((key) => {
    const w = raw.rate_limits?.[key];
    if (!w || !Number.isFinite(w.used_percentage) || w.used_percentage < 0 ||
        w.used_percentage > 100 || !Number.isFinite(w.resets_at)) return [];
    return [{ label: key === 'five_hour' ? '5 giờ' : '7 ngày',
      usedPercent: w.used_percentage, resetsAt: new Date(w.resets_at * 1000).toISOString() }];
  });
  const usd = raw.cost?.total_cost_usd;
  return {
    id: 'claude', status: windows.length || safeCount(raw.context_window?.total_input_tokens) != null ||
      (typeof usd === 'number' && Number.isFinite(usd) && usd >= 0) ? 'ready' : 'setup', source: 'Claude Code status line',
    coverage: 'Context hiện tại và ước tính phiên Code; không phải tổng usage website.',
    observedAt: now.toISOString(), plan: null, windows,
    totalTokens: null,
    contextTokens: safeCount(raw.context_window?.total_input_tokens),
    estimatedCostMicros: typeof usd === 'number' && usd >= 0 &&
      Number.isSafeInteger(Math.round(usd * 1e6)) ? Math.round(usd * 1e6) : null,
    subscriptionFeeMicros: null, billedCostMicros: null,
  };
}

export async function readClaude(dir = stateDir) {
  try {
    const raw = JSON.parse(await readFile(join(dir, 'claude-metrics.json'), 'utf8'));
    // Re-allowlist even our own file; never return arbitrary file properties.
    return sanitizeClaude({ rate_limits: Object.fromEntries(
      (raw.windows ?? []).map((w) => [w.label === '7 ngày' ? 'seven_day' : 'five_hour', {
        used_percentage: w.usedPercent, resets_at: Date.parse(w.resetsAt) / 1000,
      }])), cost: { total_cost_usd: raw.estimatedCostMicros == null ? null : raw.estimatedCostMicros / 1e6 },
      context_window: { total_input_tokens: raw.contextTokens } }, new Date(raw.observedAt));
  } catch {
    return { id: 'claude', status: 'setup', source: 'Claude Code status line',
      coverage: 'Chưa có status line. Xem hướng dẫn kết nối Claude Code.',
      observedAt: null, plan: null, windows: [], totalTokens: null,
      contextTokens: null, estimatedCostMicros: null, subscriptionFeeMicros: null, billedCostMicros: null };
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  let input = '';
  for await (const chunk of process.stdin) {
    input += chunk;
    if (input.length > 1024 * 1024) process.exit(1);
  }
  try {
    const result = sanitizeClaude(JSON.parse(input));
    await mkdir(stateDir, { recursive: true, mode: 0o700 });
    const temp = join(stateDir, `claude-${randomUUID()}.tmp`);
    await writeFile(temp, JSON.stringify(result), { mode: 0o600 });
    await rename(temp, join(stateDir, 'claude-metrics.json'));
    process.stdout.write('TokenLedger · Claude metrics connected\n');
  } catch { process.exitCode = 1; }
}
