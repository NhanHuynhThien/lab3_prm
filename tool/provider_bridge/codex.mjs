import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

// Deliberately exposes no login/token/turn/write RPCs.
export async function readCodex({ binary = 'codex', timeout = 8000, spawnImpl = spawn } = {}) {
  const child = spawnImpl(binary, ['app-server'], { stdio: ['pipe', 'pipe', 'ignore'] });
  const pending = new Map();
  let next = 0;
  const lines = createInterface({ input: child.stdout });
  const fail = () => {
    for (const task of pending.values()) task.reject(new Error('Codex unavailable'));
    pending.clear();
  };
  child.on('error', fail);
  child.stdin.on('error', fail);
  child.on('exit', fail);
  lines.on('line', (line) => {
    let msg;
    try { msg = JSON.parse(line); } catch { return; }
    const task = pending.get(msg.id);
    if (!task) return;
    pending.delete(msg.id);
    msg.error ? task.reject(new Error('Codex RPC unavailable')) : task.resolve(msg.result);
  });
  function call(method, params) {
    return new Promise((resolve, reject) => {
      const id = ++next;
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error('Codex timeout'));
      }, timeout);
      pending.set(id, {
        resolve: (v) => { clearTimeout(timer); resolve(v); },
        reject: (e) => { clearTimeout(timer); reject(e); },
      });
      child.stdin.write(`${JSON.stringify({ id, method, params })}\n`, (e) => {
        if (e) { pending.get(id)?.reject(e); pending.delete(id); }
      });
    });
  }
  try {
    await call('initialize', { clientInfo: { name: 'tokenledger', version: '0.1.0' } });
    child.stdin.write('{"method":"initialized","params":{}}\n');
    const identity = await call('account/read', { refreshToken: false });
    if (!identity.account || identity.account.type !== 'chatgpt') {
      return { status: 'setup', plan: null, windows: [], totalTokens: null };
    }
    const quota = await call('account/rateLimits/read');
    // Older CLI versions may not expose usage/read. Quota remains usable.
    const usage = await call('account/usage/read').catch(() => null);
    return {
      status: 'ready',
      plan: typeof identity.account.planType === 'string' ? identity.account.planType : null,
      windows: codexWindows(quota),
      totalTokens: safeCount(usage?.summary?.lifetimeTokens),
    };
  } finally {
    fail();
    lines.close();
    child.stdin.end();
    child.kill();
  }
}

export function safeCount(value) {
  return Number.isSafeInteger(value) && value >= 0 ? value : null;
}

export function codexWindows(quota) {
  const buckets = quota?.rateLimitsByLimitId ?? { codex: quota?.rateLimits };
  return Object.entries(buckets).flatMap(([id, bucket]) =>
    ['primary', 'secondary'].flatMap((key) => {
      const w = bucket?.[key];
      if (!w || !Number.isFinite(w.usedPercent) || w.usedPercent < 0 ||
          w.usedPercent > 100 || !Number.isFinite(w.resetsAt)) return [];
      return [{ label: `${id} · ${w.windowDurationMins ?? '?'} phút`,
        usedPercent: w.usedPercent, resetsAt: new Date(w.resetsAt * 1000).toISOString() }];
    }));
}
