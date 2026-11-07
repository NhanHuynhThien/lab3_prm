// Background companion: signs in once with the user's Google account, then
// writes the sanitised snapshot to users/{uid}/provider_snapshots/latest.
// The phone only reads Firestore, so no pairing key exists or is shared.
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { readFile, writeFile, mkdir, rm } from "node:fs/promises";
import { spawn } from "node:child_process";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { collectSnapshot } from "./server.mjs";
import { stateDir } from "./claude.mjs";
import {
  saveSecret,
  loadSecret,
  deleteSecret,
  installBackground,
  uninstallBackground,
} from "./platform.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const accountFile = join(stateDir, "cloud-account.json"); // uid + email, not secret
const INTERVAL_MS = 5 * 60_000;

export async function loadFirebaseConfig() {
  return JSON.parse(await readFile(join(here, "firebase-config.json"), "utf8"));
}

export async function readAccount() {
  try {
    const value = JSON.parse(await readFile(accountFile, "utf8"));
    if (typeof value.uid !== "string" || !value.uid || value.uid.length > 128)
      return null;
    return {
      uid: value.uid,
      email: typeof value.email === "string" ? value.email.slice(0, 254) : null,
    };
  } catch {
    return null;
  }
}

export async function logout() {
  await deleteSecret();
  await rm(accountFile, { force: true });
}

export function firebaseWebConfig(dart) {
  const block =
    dart.match(
      /static const FirebaseOptions web = FirebaseOptions\(([\s\S]*?)\);/,
    )?.[1] ?? "";
  const pick = (key) => block.match(new RegExp(`${key}: '([^']+)'`))?.[1];
  const cfg = {
    apiKey: pick("apiKey"),
    authDomain: pick("authDomain"),
    projectId: pick("projectId"),
    appId: pick("appId"),
  };
  if (Object.values(cfg).some((v) => !v))
    throw new Error(
      "Không thấy Firebase web config trong lib/firebase_options.dart.",
    );
  return cfg;
}

export async function exchange(apiKey, refreshToken, fetchImpl = fetch) {
  const res = await fetchImpl(
    `https://securetoken.googleapis.com/v1/token?key=${apiKey}`,
    {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(30000),
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: refreshToken,
      }),
    },
  );
  if (!res.ok)
    throw new Error(
      `Phiên đăng nhập hết hạn (${res.status}). Chạy lại: node tool/provider_bridge/cloud.mjs login`,
    );
  const body = await res.json();
  return {
    idToken: body.id_token,
    uid: body.user_id,
    refreshToken: body.refresh_token,
  };
}

export function snapshotWrite(projectId, uid, snapshot) {
  const name = `projects/${projectId}/databases/(default)/documents/users/${uid}/provider_snapshots/latest`;
  return {
    writes: [
      {
        update: {
          name,
          fields: {
            ownerId: { stringValue: uid },
            json: { stringValue: JSON.stringify(snapshot) },
          },
        },
        // Firestore rules require savedAt == request.time.
        updateTransforms: [
          { fieldPath: "savedAt", setToServerValue: "REQUEST_TIME" },
        ],
      },
    ],
  };
}

export async function syncOnce(
  cfg,
  {
    fetchImpl = fetch,
    collect = collectSnapshot,
    load = loadSecret,
    save = saveSecret,
    expectedUid,
    shouldWrite = () => true,
  } = {},
) {
  const stored = await load();
  if (!stored)
    throw new Error(
      "Chưa đăng nhập. Chạy: node tool/provider_bridge/cloud.mjs login",
    );
  const session = await exchange(cfg.apiKey, stored, fetchImpl);
  if (expectedUid && session.uid !== expectedUid)
    throw new Error("Tài khoản đồng bộ đã thay đổi. Hãy đăng nhập lại.");
  if (session.refreshToken && session.refreshToken !== stored)
    await save(session.refreshToken);
  const snapshot = await collect();
  const ready = snapshot.providers
    .filter((provider) => provider.status === "ready")
    .map((provider) => provider.id);
  if (!shouldWrite(snapshot)) return ready;
  const res = await fetchImpl(
    `https://firestore.googleapis.com/v1/projects/${cfg.projectId}/databases/(default)/documents:commit`,
    {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(30000),
      headers: {
        Authorization: `Bearer ${session.idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(snapshotWrite(cfg.projectId, session.uid, snapshot)),
    },
  );
  if (!res.ok) throw new Error(`Firestore từ chối ghi (${res.status}).`);
  return ready;
}

function loginPage(cfg, state) {
  const v = "10.12.2";
  return `<!doctype html><meta charset="utf-8"><title>TokenLedger companion</title>
<body style="font:16px system-ui;max-width:520px;margin:64px auto;padding:0 16px">
<h2>TokenLedger companion</h2>
<p>Đăng nhập đúng tài khoản Google bạn dùng trong app. Companion sẽ ghi số liệu token của máy này vào tài khoản đó.</p>
<button id="go" style="font:inherit;padding:12px 20px">Đăng nhập Google</button><p id="msg"></p>
<script type="module">
import { initializeApp } from 'https://www.gstatic.com/firebasejs/${v}/firebase-app.js';
import { getAuth, setPersistence, inMemoryPersistence, GoogleAuthProvider, signInWithPopup } from 'https://www.gstatic.com/firebasejs/${v}/firebase-auth.js';
const auth = getAuth(initializeApp(${JSON.stringify(cfg)}));
const msg = document.getElementById('msg');
document.getElementById('go').onclick = async () => {
  try {
    await setPersistence(auth, inMemoryPersistence);
    const { user } = await signInWithPopup(auth, new GoogleAuthProvider());
    const res = await fetch('/session', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({
      state: ${JSON.stringify(state)}, uid: user.uid, email: user.email, refreshToken: user.refreshToken }) });
    msg.textContent = res.ok ? 'Xong. ' + user.email + ' đã được kết nối, có thể đóng tab này.' : 'Không lưu được phiên.';
  } catch (e) { msg.textContent = 'Đăng nhập chưa hoàn tất: ' + e.code; }
};
</script>`;
}

export async function login(
  cfg,
  {
    open = (url) => {
      const [cmd, args] =
        process.platform === "darwin"
          ? ["open", [url]]
          : process.platform === "win32"
            ? ["cmd", ["/c", "start", "", url]]
            : ["xdg-open", [url]];
      spawn(cmd, args, { stdio: "ignore" }).on("error", () => {});
    },
    signal,
    timeoutMs = 180000,
    exchangeToken = exchange,
    save = saveSecret,
    saveAccount = (value) =>
      writeFile(accountFile, JSON.stringify(value), { mode: 0o600 }),
    onUrl = () => {},
  } = {},
) {
  if (signal?.aborted) throw new Error("Đã hủy đăng nhập.");
  await mkdir(stateDir, { recursive: true, mode: 0o700 });
  const state = randomBytes(32).toString("hex");
  return new Promise((resolve, reject) => {
    let finished = false,
      accepting = false;
    const finish = (error, value) => {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      signal?.removeEventListener("abort", abort);
      server.close();
      server.closeAllConnections();
      error ? reject(error) : resolve(value);
    };
    const abort = () => finish(new Error("Đã hủy đăng nhập."));
    const server = createServer((req, res) => {
      const authority = `localhost:${server.address().port}`;
      const origin = `http://${authority}`;
      res.setHeader("Cache-Control", "no-store");
      res.setHeader("X-Content-Type-Options", "nosniff");
      res.setHeader("Referrer-Policy", "no-referrer");
      const send = (status, text = "") => {
        res.writeHead(status);
        res.end(text);
      };
      if (req.headers.host !== authority) return send(403);
      if (req.method === "GET" && req.url === "/") {
        res.setHeader("Content-Type", "text/html; charset=utf-8");
        return send(200, loginPage(cfg, state));
      }
      if (req.method !== "POST" || req.url !== "/session") return send(404);
      if (
        req.headers.origin !== origin ||
        !req.headers["content-type"]?.startsWith("application/json")
      )
        return send(403);
      if (accepting || finished) return send(409);
      let raw = "";
      req.on("data", (chunk) => {
        raw += chunk;
        if (Buffer.byteLength(raw) > 16384) req.destroy();
      });
      req.on("error", () => {});
      req.on("end", async () => {
        try {
          const body = JSON.parse(raw);
          if (
            body.state !== state ||
            typeof body.refreshToken !== "string" ||
            body.refreshToken.length > 4096 ||
            accepting ||
            finished
          )
            return send(400);
          accepting = true;
          const session = await exchangeToken(cfg.apiKey, body.refreshToken);
          if (session.uid !== body.uid) throw new Error("uid");
          if (finished || signal?.aborted) return;
          await save(session.refreshToken ?? body.refreshToken);
          if (finished || signal?.aborted) return;
          const account = {
            uid: session.uid,
            email:
              typeof body.email === "string" ? body.email.slice(0, 254) : null,
          };
          await saveAccount(account);
          send(204);
          // Let the browser receive the successful response before closing.
          res.on("finish", () => finish(null, account));
          if (res.writableFinished) finish(null, account);
        } catch {
          accepting = false;
          if (!finished) send(400);
        }
      });
    });
    const timer = setTimeout(
      () => finish(new Error("Hết thời gian đăng nhập. Hãy thử lại.")),
      timeoutMs,
    );
    signal?.addEventListener("abort", abort, { once: true });
    server.on("error", () =>
      finish(new Error("Chưa mở được trang đăng nhập trên máy.")),
    );
    server.listen(0, "127.0.0.1", async () => {
      const url = `http://localhost:${server.address().port}/`;
      onUrl(url);
      try {
        await open(url);
      } catch {
        finish(new Error("Chưa mở được trình duyệt đăng nhập."));
      }
    });
  });
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const cfg = await loadFirebaseConfig();
  const stamp = () => new Date().toISOString();
  try {
    switch (process.argv[2]) {
      case "login":
        await login(cfg);
        console.log("Đã đăng nhập. Bật đồng bộ nền bằng install.");
        break;
      case "once":
        console.log(
          `Đã ghi: ${(await syncOnce(cfg)).join(", ") || "chưa có nguồn nào"}`,
        );
        break;
      case "sync":
        for (;;) {
          try {
            console.log(`${stamp()} synced ${(await syncOnce(cfg)).join(",")}`);
          } catch (e) {
            console.log(`${stamp()} ${e.message}`);
          }
          await new Promise((r) => setTimeout(r, INTERVAL_MS));
        }
      case "install":
        if (!(await loadSecret()))
          throw new Error(
            "Chạy login trước: node tool/provider_bridge/cloud.mjs login",
          );
        console.log(
          `Companion chạy nền mỗi 5 phút, tự bật khi đăng nhập máy: ${await installBackground(
            {
              node: process.execPath,
              script: fileURLToPath(import.meta.url),
            },
          )}`,
        );
        break;
      case "uninstall":
        await uninstallBackground();
        console.log("Đã gỡ companion chạy nền.");
        break;
      case "logout":
        await uninstallBackground();
        await logout();
        console.log("Đã đăng xuất và gỡ chạy nền.");
        break;
      default:
        console.log(
          "Dùng: node tool/provider_bridge/cloud.mjs login | once | install | uninstall | logout",
        );
    }
  } catch (e) {
    console.error(e.message);
    process.exitCode = 1;
  }
}
