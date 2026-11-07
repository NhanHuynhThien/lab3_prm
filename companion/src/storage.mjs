import { readFile, writeFile, rename, mkdir, rm } from "node:fs/promises";
import { join } from "node:path";
import { randomUUID } from "node:crypto";

export function preferencesStore(directory) {
  const file = join(directory, "preferences.json");
  return {
    async read() {
      try {
        const value = JSON.parse(await readFile(file, "utf8"));
        return {
          uid: typeof value.uid === "string" ? value.uid : null,
          enabled: value.enabled === true,
          consent: value.consent === true,
          lastSyncedAt:
            typeof value.lastSyncedAt === "string" &&
            Number.isFinite(Date.parse(value.lastSyncedAt))
              ? value.lastSyncedAt
              : null,
          providers: Array.isArray(value.providers)
            ? value.providers.filter((id) =>
                ["codex", "claude", "google", "antigravity"].includes(id),
              )
            : [],
        };
      } catch {
        return { enabled: false, consent: false };
      }
    },
    async write(value) {
      await mkdir(directory, { recursive: true, mode: 0o700 });
      const temp = join(directory, `${randomUUID()}.tmp`);
      try {
        await writeFile(temp, JSON.stringify(value), { mode: 0o600 });
        await rename(temp, file);
      } finally {
        await rm(temp, { force: true });
      }
    },
  };
}
