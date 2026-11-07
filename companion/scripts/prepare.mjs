import { mkdir, copyFile, readFile } from "node:fs/promises";
import { dirname, resolve, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const bridge = resolve(root, "../tool/provider_bridge");
const target = join(root, "runtime/provider_bridge");
const config = JSON.parse(
  await readFile(join(bridge, "firebase-config.json"), "utf8"),
);
const allowed = ["apiKey", "authDomain", "projectId", "appId"];
if (
  Object.keys(config).some((key) => !allowed.includes(key)) ||
  allowed.some((key) => typeof config[key] !== "string" || !config[key])
) {
  throw new Error("Firebase public config không hợp lệ.");
}
await mkdir(target, { recursive: true });
for (const name of [
  "cloud.mjs",
  "cloud-sync.mjs",
  "token-snapshot.mjs",
  "usage-watch.mjs",
  "platform.mjs",
  "server.mjs",
  "codex.mjs",
  "claude.mjs",
  "gemini.mjs",
  "antigravity.mjs",
  "models.mjs",
  "activity.mjs",
  "firebase-config.json",
])
  await copyFile(join(bridge, name), join(target, name));
console.log(
  "Prepared standalone companion runtime with public Firebase config.",
);
