import { createServer } from 'node:http';
import { timingSafeEqual, randomBytes } from 'node:crypto';
import { readFile, writeFile, mkdir, chmod } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { readCodex } from './codex.mjs';
import { readClaude, stateDir } from './claude.mjs';
import { readGemini } from './gemini.mjs';
import { localModelUsage } from './models.mjs';

export function bridgeServer({ token, collect, port = 8787, origins = ['http://localhost:4183'] }) {
  let cache, cacheAt = 0, pending;
  const secret = Buffer.from(`Bearer ${token}`);
  const server = createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    const finish = (status, data) => { res.writeHead(status); res.end(JSON.stringify(data)); };
    const listenPort = server.address()?.port ?? port;
    if (![`127.0.0.1:${listenPort}`, `localhost:${listenPort}`].includes(req.headers.host)) return finish(403, {});
    const origin = req.headers.origin;
    if (origin && !origins.includes(origin)) return finish(403, {});
    if (origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    }
    if (req.url !== '/v1/snapshot') return finish(404, {});
    if (req.method === 'OPTIONS') {
      res.setHeader('Access-Control-Allow-Methods', 'GET');
      res.setHeader('Access-Control-Allow-Headers', 'Authorization');
      res.setHeader('Access-Control-Max-Age', '300');
      res.writeHead(204); return res.end();
    }
    if (req.method !== 'GET') return finish(405, {});
    const supplied = Buffer.from(req.headers.authorization ?? '');
    if (supplied.length !== secret.length || !timingSafeEqual(supplied, secret)) return finish(401, {});
    try {
      if (!cache || Date.now() - cacheAt > 55000) {
        pending ??= collect().then((value) => { cache = value; cacheAt = Date.now(); })
          .finally(() => { pending = null; });
        await pending;
      }
      finish(200, cache);
    } catch { finish(503, { error: 'Nguồn đồng bộ tạm thời chưa sẵn sàng.' }); }
  });
  return server;
}

export async function collectSnapshot() {
  const now = new Date();
  const codex = await readCodex({ binary: process.env.TOKENLEDGER_CODEX_BIN || 'codex' })
    .then((result) => ({ id: 'codex', source: 'Codex App Server',
      coverage: 'Quota tài khoản CLI hiện tại; token lifetime nếu CLI hỗ trợ. Không phải phí đã charge.',
      observedAt: now.toISOString(), contextTokens: null, estimatedCostMicros: null,
      billedCostMicros: null, subscriptionFeeMicros: null, ...result }))
    .catch(() => ({ id: 'codex', status: 'error', plan: null, windows: [],
      source: 'Codex App Server', coverage: 'Cần Codex CLI đã đăng nhập; cập nhật CLI nếu RPC chưa hỗ trợ.',
      observedAt: null, totalTokens: null, contextTokens: null, estimatedCostMicros: null,
      subscriptionFeeMicros: null, billedCostMicros: null }));
  const [claude, google, codexModels, claudeModels] = await Promise.all([
    readClaude(), readGemini(), localModelUsage('codex'), localModelUsage('claude')]);
  return { schemaVersion: 1, collectedAt: new Date().toISOString(), providers: [
    { ...codex, ...codexModels }, { ...claude, ...claudeModels }, google] };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await mkdir(stateDir, { recursive: true, mode: 0o700 });
  const file = join(stateDir, 'bridge-token');
  let token;
  try { token = (await readFile(file, 'utf8')).trim(); } catch { /* first pairing */ }
  if (!/^[a-f0-9]{64}$/.test(token ?? '')) {
    token = randomBytes(32).toString('hex');
    await writeFile(file, token, { mode: 0o600 });
  }
  await chmod(file, 0o600);
  const server = bridgeServer({ token, collect: collectSnapshot });
  server.listen(8787, '127.0.0.1', () => {
    console.log('TokenLedger bridge: http://127.0.0.1:8787 (local only)');
    console.log('Pairing token saved in ~/.local/share/tokenledger/bridge-token; never commit it.');
  });
  server.on('error', () => { console.error('Bridge port unavailable.'); process.exitCode = 1; });
}
