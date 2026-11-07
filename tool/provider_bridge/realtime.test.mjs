import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, appendFile, rm } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { setTimeout as delay } from "node:timers/promises";
import { EventEmitter } from "node:events";
import { watchUsageChanges } from "./usage-watch.mjs";
import { createCloudSync, snapshotDigest } from "./cloud-sync.mjs";
import { collectTokenSnapshot } from "./token-snapshot.mjs";

const directory = (path) => ({
  path,
  depth: 3,
  accepts: (name) => name.endsWith(".jsonl"),
});
async function until(predicate, timeout = 2000) {
  const end = Date.now() + timeout;
  while (!predicate()) {
    if (Date.now() >= end) assert.fail("Timed out waiting for a usage change");
    await delay(10);
  }
}

test("native watcher detects a nested usage append and stops after close", async () => {
  const root = await mkdtemp(join(tmpdir(), "tl-watch-"));
  let changes = 0;
  const monitor = watchUsageChanges(() => changes++, {
    directories: [directory(root)],
    debounceMs: 20,
    maxWaitMs: 60,
    pollMs: 60_000,
  });
  try {
    await mkdir(join(root, "sessions"));
    await writeFile(join(root, "sessions/session.jsonl"), "{}\n");
    await monitor.ready;
    await appendFile(join(root, "sessions/session.jsonl"), '{"tokens":2}\n');
    await until(() => changes > 0);
    monitor.close();
    const stopped = changes;
    await appendFile(join(root, "sessions/session.jsonl"), "{}\n");
    await delay(80);
    assert.equal(changes, stopped);
  } finally {
    monitor.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("event bursts coalesce, and unrelated file names are ignored", async () => {
  const root = await mkdtemp(join(tmpdir(), "tl-watch-"));
  let receive,
    changes = 0;
  const monitor = watchUsageChanges(() => changes++, {
    directories: [directory(root)],
    debounceMs: 20,
    maxWaitMs: 60,
    pollMs: 60_000,
    watchImpl: (_path, _options, callback) => {
      receive = callback;
      const emitter = new EventEmitter();
      emitter.close = () => {};
      return emitter;
    },
  });
  try {
    await monitor.ready;
    receive("change", "auth.json");
    await delay(50);
    assert.equal(changes, 0);
    for (let i = 0; i < 20; i++) receive("change", "usage.jsonl");
    await until(() => changes === 1);
    await delay(70);
    assert.equal(changes, 1);
    monitor.close();
    receive("change", "usage.jsonl");
    await delay(40);
    assert.equal(changes, 1);
  } finally {
    monitor.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("fallback handles absent roots and unsupported native watches", async () => {
  const root = await mkdtemp(join(tmpdir(), "tl-watch-"));
  const source = join(root, "new-source");
  let changes = 0;
  const monitor = watchUsageChanges(() => changes++, {
    directories: [directory(source)],
    debounceMs: 10,
    maxWaitMs: 30,
    pollMs: 20,
    watchImpl: () => {
      throw new Error("unsupported");
    },
  });
  try {
    await monitor.ready;
    await mkdir(source);
    await writeFile(join(source, "usage.jsonl"), "{}");
    await until(() => changes > 0);
    const first = changes;
    await appendFile(join(source, "usage.jsonl"), "\n{}");
    await until(() => changes > first);
  } finally {
    monitor.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("snapshot digest ignores collection clocks and detects token changes", () => {
  const first = {
    collectedAt: "a",
    providers: [
      {
        observedAt: "a",
        activity: { periodStart: "a", periodEnd: "b", totalTokens: 10 },
      },
    ],
  };
  const clock = structuredClone(first);
  clock.collectedAt = "b";
  clock.providers[0].observedAt = "b";
  clock.providers[0].activity.periodEnd = "c";
  assert.equal(snapshotDigest(first), snapshotDigest(clock));
  clock.providers[0].activity.totalTokens = 11;
  assert.notEqual(snapshotDigest(first), snapshotDigest(clock));
});

test("token refresh uses local readers and retains observed provider quotas", async () => {
  const old = {
    schemaVersion: 1,
    collectedAt: "old",
    providers: [
      {
        id: "codex",
        status: "ready",
        source: "Phiên lưu trên máy",
        totalTokens: 5,
      },
      { id: "claude", status: "setup", source: "Claude", windows: [] },
      { id: "google", totalTokens: 0 },
      {
        id: "antigravity",
        windows: [{ usedPercent: 20 }],
        observedAt: "quota-observed",
      },
    ],
  };
  const next = await collectTokenSnapshot(old, {
    now: new Date("2026-11-07T00:00:00Z"),
    models: async () => ({
      activity: { totalTokens: 25 },
      models: [{ model: "m", totalTokens: 25 }],
      modelsCoverage: "local",
    }),
    gemini: async () => ({ id: "google", totalTokens: 30 }),
    claude: async () => ({ status: "setup" }),
  });
  assert.equal(next.providers[0].totalTokens, 25);
  assert.equal(next.providers[2].totalTokens, 30);
  assert.deepEqual(next.providers[3], old.providers[3]);
  assert.equal(old.providers[0].totalTokens, 5);
});

test("cloud sync skips unchanged token snapshots, retries failed writes and resets on UID change", async () => {
  let full = 0,
    tokens = 0,
    writes = 0,
    amount = 10,
    fail = false;
  const snapshot = () => ({
    schemaVersion: 1,
    collectedAt: String(Date.now()),
    providers: [{ id: "codex", status: "ready", totalTokens: amount }],
  });
  const sync = createCloudSync(
    {},
    {
      full: async () => {
        full++;
        return snapshot();
      },
      tokens: async () => {
        tokens++;
        return snapshot();
      },
      write: async (_config, options) => {
        const next = await options.collect();
        if (options.shouldWrite(next)) {
          writes++;
          if (fail) {
            fail = false;
            throw new Error("offline");
          }
        }
        return ["codex"];
      },
    },
  );
  assert.deepEqual(await sync("A"), { providers: ["codex"], published: true });
  assert.deepEqual(await sync("A", { tokensOnly: true }), {
    providers: ["codex"],
    published: false,
  });
  assert.equal(writes, 1);
  amount = 20;
  fail = true;
  await assert.rejects(sync("A", { tokensOnly: true }), /offline/);
  assert.equal((await sync("A", { tokensOnly: true })).published, true);
  assert.equal(writes, 3);
  await sync("B", { tokensOnly: true });
  assert.equal(full, 2);
  assert.equal(tokens, 3);
  assert.equal(writes, 4);
});
