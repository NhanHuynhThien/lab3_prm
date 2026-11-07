import {
  app,
  BrowserWindow,
  ipcMain,
  Menu,
  Tray,
  nativeImage,
  shell,
  powerMonitor,
} from "electron";
import { join, dirname, resolve, delimiter } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import { CompanionController } from "./controller.mjs";
import { preferencesStore } from "./storage.mjs";
import { startupSettings } from "./startup.mjs";
import {
  login,
  logout,
  syncOnce,
  readAccount,
  loadFirebaseConfig,
} from "../runtime/provider_bridge/cloud.mjs";
import { uninstallBackground } from "../runtime/provider_bridge/platform.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const page = resolve(here, "index.html");
const assets = resolve(here, "../assets");
// Finder and background launches have a minimal PATH. Use ordinary CLI install
// locations without sourcing shell profiles or reading provider credentials.
process.env.PATH = [
  ...new Set(
    [
      ...(process.env.PATH ?? "").split(delimiter),
      join(homedir(), ".local/bin"),
      "/opt/homebrew/bin",
      "/usr/local/bin",
      join(homedir(), ".npm-global/bin"),
    ].filter(Boolean),
  ),
].join(delimiter);

let window,
  tray,
  controller,
  quitting = false;
const userDataArgument = process.argv.find((argument) =>
  argument.startsWith("--user-data-dir="),
);
if (userDataArgument)
  app.setPath(
    "userData",
    resolve(userDataArgument.slice("--user-data-dir=".length)),
  );
const startup = startupSettings(app);
if (!app.requestSingleInstanceLock()) app.quit();
else {
  app.on("second-instance", () => showWindow());
  app.on("activate", () => showWindow());
  app.on("window-all-closed", () => {});
  app.on("before-quit", () => {
    quitting = true;
    void controller?.close();
  });
  app
    .whenReady()
    .then(async () => {
      const preferences = preferencesStore(app.getPath("userData"));
      const config = await loadFirebaseConfig();
      controller = new CompanionController({
        readAccount,
        readPreferences: preferences.read,
        writePreferences: preferences.write,
        login: (options) =>
          login(config, { ...options, open: (url) => shell.openExternal(url) }),
        setAutoStart: (value) => startup.set(value),
        retireLegacyService: uninstallBackground,
        logout,
        sync: async (expectedUid) => {
          try {
            return await syncOnce(config, { expectedUid });
          } catch {
            throw new Error(
              "Chưa đồng bộ được. Kiểm tra kết nối mạng hoặc đăng nhập lại.",
            );
          }
        },
      });
      controller.on("change", publish);
      ipcMain.handle("companion:action", async (event, action, value) => {
        if (
          event.sender !== window?.webContents ||
          event.senderFrame !== event.sender.mainFrame
        ) {
          throw new Error("Yêu cầu không hợp lệ.");
        }
        try {
          switch (action) {
            case "status":
              break;
            case "connect":
              if (
                typeof value !== "object" ||
                value === null ||
                Object.keys(value).some(
                  (key) => !["consent", "autoStart"].includes(key),
                )
              )
                throw new Error("Dữ liệu kết nối không hợp lệ.");
              await controller.connect(value);
              break;
            case "sync":
              await controller.sync();
              break;
            case "pause":
              await controller.pause();
              break;
            case "resume":
              await controller.enable();
              break;
            case "disconnect":
              await controller.disconnect();
              break;
            case "auto-start":
              await startup.set(value);
              break;
            default:
              throw new Error("Thao tác không hợp lệ.");
          }
        } catch (error) {
          controller.update({ error: error.message });
        }
        return status();
      });
      const icon = nativeImage
        .createFromPath(join(assets, "tray.png"))
        .resize({ width: 18, height: 18 });
      icon.setTemplateImage(process.platform === "darwin");
      tray = new Tray(icon);
      tray.setToolTip("TokenLedger Companion");
      tray.on("click", showWindow);
      makeWindow();
      publish();
      powerMonitor.on("resume", () => {
        if (controller.state.enabled) void controller.sync();
      });
      void controller.initialize().catch(() => {
        controller.update({
          error: "Chưa khôi phục được đồng bộ. Hãy thử kết nối lại.",
        });
      });
    })
    .catch(() => {
      console.error(
        "Companion startup failed. Check the application installation.",
      );
      app.quit();
    });
}

function status() {
  return {
    ...controller.snapshot(),
    autoStart: startup.get(),
    packaged: app.isPackaged,
  };
}
function publish() {
  if (!controller) return;
  const state = status();
  if (window && !window.isDestroyed())
    window.webContents.send("companion:state", state);
  tray?.setContextMenu(
    Menu.buildFromTemplate([
      { label: "Mở TokenLedger Companion", click: showWindow },
      {
        label: state.busy ? "Đang đồng bộ…" : "Đồng bộ ngay",
        enabled: !!state.account && state.consent && !state.busy,
        click: () => void controller.sync(),
      },
      {
        label: state.enabled ? "Tạm dừng đồng bộ" : "Tiếp tục đồng bộ",
        enabled: !!state.account && state.consent,
        click: () =>
          void (state.enabled ? controller.pause() : controller.enable()),
      },
      { type: "separator" },
      { label: "Thoát Companion", click: () => app.quit() },
    ]),
  );
}
function makeWindow() {
  window = new BrowserWindow({
    width: 840,
    height: 820,
    minWidth: 620,
    minHeight: 690,
    title: "TokenLedger Companion",
    backgroundColor: "#FAF8FF",
    icon: join(assets, "icon.png"),
    show: false,
    webPreferences: {
      preload: join(here, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webSecurity: true,
    },
  });
  window.setMenuBarVisibility(false);
  window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  window.webContents.on("will-navigate", (event) => event.preventDefault());
  window.webContents.session.setPermissionRequestHandler(
    (_contents, _permission, callback) => callback(false),
  );
  window.webContents.on("did-finish-load", publish);
  window.on("close", (event) => {
    if (!quitting) {
      event.preventDefault();
      window.hide();
    }
  });
  window.once("ready-to-show", () => {
    if (!process.argv.includes("--background")) window.show();
  });
  void window.loadFile(page);
}
function showWindow() {
  if (!controller) return;
  if (!window || window.isDestroyed()) {
    if (app.isReady()) makeWindow();
    return;
  }
  if (window.isMinimized()) window.restore();
  window.show();
  window.focus();
}
