// OS-specific parts of the background companion: where the Google session is
// kept and how the sync loop starts at login. Everything else is portable.
import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { execFile, spawn } from 'node:child_process';
import { promisify } from 'node:util';
import { homedir, userInfo } from 'node:os';
import { join, dirname } from 'node:path';
import { stateDir } from './claude.mjs';

const exec = promisify(execFile);
const SERVICE = 'tokenledger-companion';
const LABEL = 'com.tokenledger.companion';
const TASK = 'TokenLedgerCompanion';
export const logFile = join(stateDir, 'companion.log');
const plainFile = join(stateDir, 'cloud-refresh-token');
const dpapiFile = join(stateDir, 'cloud-refresh-token.dpapi');
const plistPath = join(homedir(), 'Library/LaunchAgents', `${LABEL}.plist`);
const unitPath = join(homedir(), '.config/systemd/user', `${SERVICE}.service`);

// Feed secrets through stdin so they never show up in the process list.
function pipe(cmd, args, input, env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['pipe', 'ignore', 'ignore'], env: { ...process.env, ...env } });
    child.on('error', reject);
    child.on('exit', (code) => (code === 0 ? resolve() : reject(new Error(`${cmd} exited ${code}`))));
    child.stdin.end(input);
  });
}
const ps = (script, env) => ['powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', script], env];

export async function saveSecret(value, platform = process.platform) {
  // Refresh tokens are URL-safe; anything else is rejected before reaching a shell.
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{20,4096}$/.test(value)) {
    throw new Error('Phiên đăng nhập không hợp lệ.');
  }
  await mkdir(stateDir, { recursive: true, mode: 0o700 });
  if (platform === 'darwin') {
    await pipe('security', ['-i'], `add-generic-password -U -a ${SERVICE} -s ${SERVICE} -w "${value}"\n`);
  } else if (platform === 'win32') {
    // DPAPI (CurrentUser): only this Windows user on this machine can decrypt.
    const [cmd, args, env] = ps('[Console]::In.ReadToEnd().Trim() | ConvertTo-SecureString -AsPlainText -Force | '
      + 'ConvertFrom-SecureString | Set-Content -NoNewline -Path $env:TL_FILE', { TL_FILE: dpapiFile });
    await pipe(cmd, args, value, env);
  } else {
    try { await pipe('secret-tool', ['store', '--label=TokenLedger companion', 'service', SERVICE], value); }
    catch { await writeFile(plainFile, value, { mode: 0o600 }); } // no keyring (headless): user-only file
  }
  if ((await loadSecret(platform)) !== value) throw new Error('Không lưu được phiên đăng nhập.');
}

export async function loadSecret(platform = process.platform) {
  try {
    if (platform === 'darwin') {
      return (await exec('security', ['find-generic-password', '-a', SERVICE, '-s', SERVICE, '-w'])).stdout.trim();
    }
    if (platform === 'win32') {
      const [cmd, args, env] = ps('$s = ConvertTo-SecureString ((Get-Content -Raw -Path $env:TL_FILE).Trim()); '
        + '[Net.NetworkCredential]::new("", $s).Password', { TL_FILE: dpapiFile });
      return (await exec(cmd, args, { env: { ...process.env, ...env } })).stdout.trim() || null;
    }
    const keyring = await exec('secret-tool', ['lookup', 'service', SERVICE]).then((r) => r.stdout.trim(), () => '');
    return keyring || (await readFile(plainFile, 'utf8')).trim();
  } catch { return null; }
}

export async function deleteSecret(platform = process.platform) {
  if (platform === 'darwin') await exec('security', ['delete-generic-password', '-a', SERVICE, '-s', SERVICE]).catch(() => {});
  if (platform === 'linux') await exec('secret-tool', ['clear', 'service', SERVICE]).catch(() => {});
  await rm(plainFile, { force: true });
  await rm(dpapiFile, { force: true });
}

const xml = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
export function launchAgentPlist({ node, script, log }) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key><array><string>${xml(node)}</string><string>${xml(script)}</string><string>sync</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${xml(log)}</string>
  <key>StandardErrorPath</key><string>${xml(log)}</string>
</dict></plist>
`;
}

const sd = (s) => `"${s.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
export function systemdUnit({ node, script }) {
  return `[Unit]
Description=TokenLedger companion (token sync)
After=network-online.target

[Service]
ExecStart=${sd(node)} ${sd(script)} sync
Restart=always
RestartSec=30

[Install]
WantedBy=default.target
`;
}

// Paths reach PowerShell through env vars; '' escapes a quote inside '...'.
export function windowsTaskScript() {
  return `$q = { param($p) $p.Replace("'", "''") }
$arg = "-NoProfile -WindowStyle Hidden -Command & '$(& $q $env:TL_NODE)' '$(& $q $env:TL_SCRIPT)' sync *>> '$(& $q $env:TL_LOG)'"
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName '${TASK}' -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName '${TASK}'`;
}

export async function installBackground({ node, script }, platform = process.platform) {
  await mkdir(stateDir, { recursive: true, mode: 0o700 });
  if (platform === 'darwin') {
    await mkdir(dirname(plistPath), { recursive: true });
    await writeFile(plistPath, launchAgentPlist({ node, script, log: logFile }));
    const domain = `gui/${userInfo().uid}`;
    await exec('launchctl', ['bootout', domain, plistPath]).catch(() => {});
    await exec('launchctl', ['bootstrap', domain, plistPath]);
    return `LaunchAgent ${LABEL}. Log: ${logFile}`;
  }
  if (platform === 'win32') {
    const [cmd, args, env] = ps(windowsTaskScript(), { TL_NODE: node, TL_SCRIPT: script, TL_LOG: logFile });
    await exec(cmd, args, { env: { ...process.env, ...env } });
    return `Task Scheduler "${TASK}" (chạy khi đăng nhập Windows). Log: ${logFile}`;
  }
  await mkdir(dirname(unitPath), { recursive: true });
  await writeFile(unitPath, systemdUnit({ node, script }));
  await exec('systemctl', ['--user', 'daemon-reload']);
  await exec('systemctl', ['--user', 'enable', '--now', `${SERVICE}.service`]);
  return `systemd user service ${SERVICE}. Log: journalctl --user -u ${SERVICE}`;
}

export async function uninstallBackground(platform = process.platform) {
  if (platform === 'darwin') {
    await exec('launchctl', ['bootout', `gui/${userInfo().uid}`, plistPath]).catch(() => {});
    await rm(plistPath, { force: true });
  } else if (platform === 'win32') {
    const [cmd, args] = ps(`Unregister-ScheduledTask -TaskName '${TASK}' -Confirm:$false -ErrorAction SilentlyContinue`);
    await exec(cmd, args).catch(() => {});
  } else {
    await exec('systemctl', ['--user', 'disable', '--now', `${SERVICE}.service`]).catch(() => {});
    await rm(unitPath, { force: true });
    await exec('systemctl', ['--user', 'daemon-reload']).catch(() => {});
  }
}
