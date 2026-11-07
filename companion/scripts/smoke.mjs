import { _electron as electron } from "playwright";
import assert from "node:assert/strict";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const executablePath =
  process.env.COMPANION_EXECUTABLE ||
  resolve(
    root,
    "dist/mac-arm64/TokenLedger Companion.app/Contents/MacOS/TokenLedger Companion",
  );
const userData = await mkdtemp(resolve(tmpdir(), "tokenledger-companion-qa-"));
const errors = [];
let desktop;
try {
  desktop = await electron.launch({
    executablePath,
    args: [`--user-data-dir=${userData}`],
  });
  const window = await desktop.firstWindow();
  window.on("pageerror", (error) => errors.push(error.message));
  await window
    .getByRole("heading", {
      name: "Số liệu trên máy. Liền mạch với điện thoại.",
    })
    .waitFor();
  await window
    .locator("#status")
    .filter({ hasNotText: "Đang khởi động" })
    .waitFor();
  const security = await desktop.evaluate(({ BrowserWindow }) => {
    const prefs =
      BrowserWindow.getAllWindows()[0].webContents.getLastWebPreferences();
    return {
      contextIsolation: prefs.contextIsolation,
      nodeIntegration: prefs.nodeIntegration,
      sandbox: prefs.sandbox,
    };
  });
  assert.deepEqual(security, {
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
  });
  const bridge = await window.evaluate(() => ({
    node: typeof window.require,
    actions: Object.keys(window.companion).sort(),
  }));
  assert.equal(bridge.node, "undefined");
  assert.ok(!bridge.actions.includes("loadSecret"));
  assert.equal(await window.locator("#sync-interval").count(), 0);
  assert.ok(!bridge.actions.includes("syncInterval"));
  assert.equal(await window.locator("footer").count(), 0);
  await window.getByText("Giờ hiện tại", { exact: true }).waitFor();
  const clockBefore = await window.locator("#clock").textContent();
  assert.ok(clockBefore);
  await window.waitForFunction(
    (previous) => document.getElementById("clock").textContent !== previous,
    clockBefore,
    { timeout: 5000 },
  );
  const clockTime = await window.locator("#clock").getAttribute("datetime");
  assert.ok(Math.abs(Date.now() - Date.parse(clockTime)) < 3000);

  const consent = window.locator("#consent");
  if (await consent.isVisible()) {
    assert.equal(await window.locator("#connect").isDisabled(), true);
    await consent.check();
    assert.equal(await window.locator("#connect").isEnabled(), true);
  }
  assert.deepEqual(errors, []);
  const screenshot =
    process.env.COMPANION_SCREENSHOT ||
    resolve(tmpdir(), "tokenledger-companion.png");
  await window.screenshot({ path: screenshot });
  console.log(
    `PASS packaged app, live clock, consent controls, isolated renderer. Screenshot: ${screenshot}`,
  );
} finally {
  if (desktop) {
    await desktop.evaluate(({ app }) => app.quit()).catch(() => {});
    await desktop.close().catch(() => {});
  }
  await rm(userData, { recursive: true, force: true });
}
