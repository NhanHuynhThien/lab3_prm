import { readFile, writeFile, mkdir, chmod } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { randomBytes } from 'node:crypto';
import { stateDir } from './claude.mjs';

// Run from the Flutter project. No provider keys, OAuth tokens or passwords.
await mkdir(stateDir, { recursive: true, mode: 0o700 });
const tokenFile = join(stateDir, 'bridge-token');
let token;
try { token = (await readFile(tokenFile, 'utf8')).trim(); } catch { /* first pairing */ }
if (!/^[a-f0-9]{64}$/.test(token ?? '')) {
  token = randomBytes(32).toString('hex');
  await writeFile(tokenFile, token, { mode: 0o600 });
}
await chmod(tokenFile, 0o600);
let env = {};
try { env = JSON.parse(await readFile('.env', 'utf8')); }
catch (e) { if (e.code !== 'ENOENT') throw new Error('Existing .env is not valid JSON; left unchanged.'); }
if (!env || Array.isArray(env) || typeof env !== 'object') throw new Error('Invalid env object');
await writeFile('.env', `${JSON.stringify({ ...env, PROVIDER_BRIDGE_TOKEN: token }, null, 2)}\n`, { mode: 0o600 });
await chmod('.env', 0o600);
const shellQuote = (value) => `'${value.replaceAll("'", "'\\''")}'`;
await writeFile(join(stateDir, 'claude-statusline-settings.json'), JSON.stringify({
  statusLine: { type: 'command', command: `node ${shellQuote(resolve('tool/provider_bridge/claude.mjs'))}` },
}, null, 2), { mode: 0o600 });
console.log('Local pairing configured in ignored .env. Nhập pairing token trong màn Nguồn AI khi kết nối local; không nhúng credential vào APK.');
console.log('Claude statusLine snippet prepared in ~/.local/share/tokenledger/claude-statusline-settings.json; merge with existing settings, do not overwrite them.');
