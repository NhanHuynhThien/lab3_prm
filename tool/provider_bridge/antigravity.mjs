import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { homedir } from 'node:os';
import { join } from 'node:path';

const exec = promisify(execFile);
const empty = (status = 'setup') => ({
  id: 'antigravity', status, source: 'Antigravity · /usage chính thức',
  coverage: 'Đăng nhập Antigravity CLI (agy) trên Mac để đọc quota. Lịch sử token IDE chưa được cung cấp.',
  observedAt: null, plan: null, windows: [], models: [], totalTokens: null,
  contextTokens: null, estimatedCostMicros: null,
  modelsCoverage: 'Quota tài khoản và token từng model là hai chỉ số khác nhau.',
});

/** Only a read-only CLI command is accepted; never sends an agent prompt. */
export function parseAntigravityUsage(raw, now = new Date()) {
  if (raw?.status !== 'SUCCESS' || raw?.command?.name !== 'usage' ||
      raw.num_turns !== 0 || !Array.isArray(raw.command.data?.groups)) {
    throw new Error('Unsupported Antigravity usage envelope');
  }
  const windows = [], seen = new Set();
  for (const group of raw.command.data.groups) {
    for (const bucket of Array.isArray(group.buckets) ? group.buckets : []) {
      const fraction = bucket.remaining_fraction;
      const reset = Date.parse(bucket.reset_time);
      if (typeof bucket.id !== 'string' || seen.has(bucket.id) ||
          typeof fraction !== 'number' || !Number.isFinite(fraction) ||
          fraction < 0 || fraction > 1 || !Number.isFinite(reset)) continue;
      const label = [group.name, bucket.name, bucket.window]
        .filter((v) => typeof v === 'string' && v.length > 0).join(' · ');
      if (!label || label.length > 100 || /[\x00-\x1f]/.test(label)) continue;
      seen.add(bucket.id);
      windows.push({ label, group: typeof group.name === 'string' && group.name.length <= 100 ? group.name : undefined,
        window: ['5h', 'weekly'].includes(bucket.window) ? bucket.window : undefined,
        usedPercent: (1 - fraction) * 100, resetsAt: new Date(reset).toISOString() });
      if (windows.length === 20) break;
    }
    if (windows.length === 20) break;
  }
  if (!windows.length) throw new Error('No supported quota buckets');
  return { ...empty('ready'), observedAt: now.toISOString(), windows,
    coverage: 'Quota tài khoản từ Antigravity CLI chính thức. Không suy token IDE hoặc quota Gemini web từ các phần trăm này.' };
}

export async function readAntigravity({
  binary = process.env.TOKENLEDGER_AGY_BIN || join(homedir(), '.local', 'bin', 'agy'),
  execute = exec,
  now = new Date(),
} = {}) {
  try {
    const { stdout } = await execute(binary, ['--print', '/usage', '--output-format', 'json'], {
      timeout: 18000, maxBuffer: 256 * 1024, windowsHide: true,
    });
    return parseAntigravityUsage(JSON.parse(stdout), now);
  } catch (error) {
    return empty(error.code === 'ENOENT' ? 'setup' : 'error');
  }
}
