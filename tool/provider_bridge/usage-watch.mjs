import { watch } from "node:fs";
import { lstat, readdir } from "node:fs/promises";
import { join, basename } from "node:path";
import { homedir } from "node:os";
import { createHash } from "node:crypto";
import { stateDir } from "./claude.mjs";

const roots = () => [
  {
    path: join(homedir(), ".codex/sessions"),
    accepts: (name) => name.endsWith(".jsonl"),
    depth: 7,
  },
  {
    path: join(homedir(), ".claude/projects"),
    accepts: (name) => name.endsWith(".jsonl"),
    depth: 7,
  },
  {
    path: join(homedir(), ".gemini/tmp"),
    accepts: (name) => /^session-.*\.jsonl?$/.test(name),
    depth: 4,
  },
  {
    path: stateDir,
    accepts: (name) => name === "claude-metrics.json",
    depth: 0,
  },
];

// Metadata only. The collectors remain responsible for reading allowed usage
// files and projecting them into aggregate fields.
async function fingerprint(root) {
  const hash = createHash("sha256");
  let count = 0;
  async function walk(directory, depth) {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
      if (count >= 500) break;
      if (entry.isSymbolicLink()) continue;
      const file = join(directory, entry.name);
      if (entry.isDirectory() && depth < root.depth)
        await walk(file, depth + 1);
      else if (entry.isFile() && root.accepts(entry.name)) {
        try {
          const stat = await lstat(file);
          if (!stat.isFile()) continue;
          hash.update(`${file}:${stat.size}:${stat.mtimeMs}:${stat.ctimeMs}\n`);
          count++;
        } catch {
          /* A session can rotate while it is being scanned. */
        }
      }
    }
  }
  await walk(root.path, 0);
  return hash.digest("hex");
}

export function watchUsageChanges(
  onChange,
  {
    directories = roots(),
    debounceMs = 1000,
    maxWaitMs = 3000,
    pollMs = 10_000,
    watchImpl = watch,
  } = {},
) {
  let stopped = false,
    debounce,
    deadline,
    polling = false;
  const watchers = new Map(),
    fingerprints = new Map();
  function flush() {
    clearTimeout(debounce);
    clearTimeout(deadline);
    debounce = deadline = null;
    if (!stopped) onChange();
  }
  function changed() {
    if (stopped) return;
    clearTimeout(debounce);
    debounce = setTimeout(flush, debounceMs);
    deadline ??= setTimeout(flush, maxWaitMs);
    debounce.unref?.();
    deadline.unref?.();
  }
  async function scan() {
    if (stopped || polling) return;
    polling = true;
    try {
      for (const root of directories) {
        let stat;
        try {
          stat = await lstat(root.path);
        } catch {
          if (stopped) return;
          if (fingerprints.has(root.path)) {
            fingerprints.delete(root.path);
            watchers.get(root.path)?.close();
            watchers.delete(root.path);
            changed();
          }
          continue;
        }
        if (stopped) return;
        if (!stat.isDirectory() || stat.isSymbolicLink()) continue;
        if (!watchers.has(root.path)) {
          try {
            const watcher = watchImpl(
              root.path,
              { recursive: root.depth > 0, persistent: false },
              (_event, filename) => {
                if (
                  filename == null ||
                  root.accepts(basename(String(filename)))
                )
                  changed();
              },
            );
            watcher.on("error", () => {
              watcher.close();
              watchers.delete(root.path);
            });
            watchers.set(root.path, watcher);
          } catch {
            /* The metadata poll covers unavailable native watchers. */
          }
        }
        const next = await fingerprint(root);
        if (stopped) return;
        const previous = fingerprints.get(root.path);
        if (previous !== undefined && next !== previous) changed();
        // A directory created after startup must also trigger collection.
        if (previous === undefined && initialized) changed();
        fingerprints.set(root.path, next);
      }
    } finally {
      polling = false;
      initialized = true;
    }
  }
  let initialized = false;
  const ready = scan();
  const poll = setInterval(() => void scan(), pollMs);
  poll.unref?.();
  return {
    ready,
    close() {
      stopped = true;
      clearInterval(poll);
      clearTimeout(debounce);
      clearTimeout(deadline);
      for (const watcher of watchers.values()) watcher.close();
      watchers.clear();
    },
  };
}
