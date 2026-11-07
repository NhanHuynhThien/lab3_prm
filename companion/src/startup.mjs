import { existsSync } from "node:fs";
import { mkdir, writeFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

export function startupSettings(app) {
  const file = join(
    homedir(),
    ".config/autostart/tokenledger-companion.desktop",
  );
  return {
    get() {
      return process.platform === "linux"
        ? existsSync(file)
        : app.getLoginItemSettings().openAtLogin;
    },
    async set(enabled) {
      if (typeof enabled !== "boolean")
        throw new Error("Thiết lập khởi động không hợp lệ.");
      if (!app.isPackaged && enabled) {
        throw new Error(
          "Mở bản ứng dụng đã đóng gói để bật khởi động cùng máy.",
        );
      }
      if (process.platform !== "linux") {
        app.setLoginItemSettings({
          openAtLogin: enabled,
          args: ["--background"],
        });
        return;
      }
      if (!enabled) {
        await rm(file, { force: true });
        return;
      }
      await mkdir(join(homedir(), ".config/autostart"), { recursive: true });
      const executable = app
        .getPath("exe")
        .replaceAll("\\", "\\\\")
        .replaceAll('"', '\\"')
        .replaceAll("%", "%%");
      await writeFile(
        file,
        `[Desktop Entry]\nType=Application\nName=TokenLedger Companion\nExec="${executable}" --background\nTerminal=false\n`,
        { mode: 0o600 },
      );
    },
  };
}
