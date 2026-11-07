import { test } from "node:test";
import assert from "node:assert/strict";
import { CompanionController } from "../src/controller.mjs";

function harness(overrides = {}) {
  const calls = [];
  let preferences = {};
  let account = { uid: "A", email: "a@example.test" };
  const dependencies = {
    readAccount: async () => account,
    readPreferences: async () => preferences,
    writePreferences: async (value) => {
      preferences = value;
    },
    login: async () => {
      calls.push("login");
    },
    setAutoStart: async (value) => {
      calls.push(`startup:${value}`);
    },
    retireLegacyService: async () => {
      calls.push("retire");
    },
    sync: async (uid) => {
      calls.push(`sync:${uid}`);
      return ["codex"];
    },
    logout: async () => {
      calls.push("logout");
      account = null;
    },
    ...overrides,
  };
  return {
    controller: new CompanionController(dependencies),
    calls,
    preferences: () => preferences,
  };
}

test("a remembered account requires consent before collecting or enabling startup", async () => {
  const h = harness();
  await h.controller.initialize();
  assert.equal(h.controller.state.account.uid, "A");
  assert.deepEqual(h.calls, []);
  await assert.rejects(
    h.controller.connect({ consent: false, autoStart: true }),
    /Đồng ý/,
  );
  assert.deepEqual(h.calls, []);
  await h.controller.close();
});

test("connect replaces legacy service, persists consent and syncs immediately", async () => {
  const h = harness();
  await h.controller.initialize();
  await h.controller.connect({ consent: true, autoStart: true });
  assert.deepEqual(h.calls, ["startup:true", "retire", "sync:A"]);
  assert.equal(h.preferences().uid, "A");
  assert.equal(h.preferences().enabled, true);
  assert.equal(h.preferences().consent, true);
  assert.deepEqual(h.controller.state.providers, ["codex"]);
  assert.ok(h.controller.state.lastSyncedAt);
  await h.controller.close();
});

test("restoring preferences for another UID never starts collection", async () => {
  const h = harness({
    readPreferences: async () => ({
      uid: "B",
      consent: true,
      enabled: true,
      providers: ["codex"],
    }),
  });
  await h.controller.initialize();
  assert.equal(h.controller.state.consent, false);
  assert.deepEqual(h.controller.state.providers, []);
  assert.deepEqual(h.calls, []);
  await h.controller.close();
});

test("concurrent sync requests share one call and logout waits for it", async () => {
  let finish;
  const h = harness({
    sync: (uid) =>
      new Promise((resolve) => {
        h.calls.push(`sync:${uid}`);
        finish = resolve;
      }),
  });
  await h.controller.initialize();
  h.controller.update({ consent: true });
  const first = h.controller.sync();
  await Promise.resolve();
  const second = h.controller.sync();
  const disconnected = h.controller.disconnect();
  assert.deepEqual(h.calls, ["sync:A"]);
  finish(["codex"]);
  await Promise.all([first, second, disconnected]);
  assert.deepEqual(h.calls, ["sync:A", "startup:false", "logout"]);
  assert.equal(h.controller.state.account, null);
  assert.deepEqual(h.controller.state.providers, []);
  assert.equal(h.preferences().enabled, false);
  await h.controller.close();
});

test("a synchronous collection failure can be retried without a stuck lock", async () => {
  let attempts = 0;
  const h = harness({
    sync: () => {
      if (++attempts === 1) throw new Error("offline");
      return ["claude"];
    },
  });
  await h.controller.initialize();
  h.controller.update({ consent: true });
  await h.controller.sync();
  assert.equal(h.controller.state.error, "offline");
  await h.controller.sync();
  assert.deepEqual(h.controller.state.providers, ["claude"]);
  assert.equal(h.controller.state.error, null);
  await h.controller.close();
});

test("pause persists disabled and resume performs a fresh sync", async () => {
  const h = harness();
  await h.controller.initialize();
  await h.controller.connect({ consent: true, autoStart: false });
  await h.controller.pause();
  assert.equal(h.preferences().enabled, false);
  await h.controller.enable();
  assert.equal(h.calls.filter((call) => call === "sync:A").length, 2);
  await h.controller.close();
});

test("closing aborts an unfinished browser login and does not start sync", async () => {
  const h = harness({
    readAccount: async () => null,
    login: ({ signal }) =>
      new Promise((_resolve, reject) => {
        signal.addEventListener("abort", () => reject(new Error("cancelled")), {
          once: true,
        });
      }),
  });
  await h.controller.initialize();
  const connecting = h.controller.connect({ consent: true, autoStart: true });
  await h.controller.close();
  await connecting;
  assert.deepEqual(h.calls, []);
});

test("a usage change during an upload schedules one latest token refresh", async () => {
  let changed, finish;
  const modes = [];
  const h = harness({
    watchChanges: (callback) => {
      changed = callback;
      return { close() {} };
    },
    sync: async (_uid, options) => {
      modes.push(options.tokensOnly);
      if (modes.length === 1)
        await new Promise((resolve) => {
          finish = resolve;
        });
      return ["codex"];
    },
  });
  await h.controller.initialize();
  const connecting = h.controller.connect({ consent: true, autoStart: false });
  while (!finish) await new Promise((resolve) => setImmediate(resolve));
  changed();
  changed();
  changed();
  finish();
  await connecting;
  while (h.controller.pending) await h.controller.pending;
  assert.deepEqual(modes, [false, true]);
  await h.controller.pause();
  changed();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(modes, [false, true]);
  await h.controller.close();
});

test("failed realtime uploads retry and closing disposes the watcher", async () => {
  let attempts = 0,
    closed = 0;
  const h = harness({
    retryMs: 10,
    watchChanges: () => ({ close: () => closed++ }),
    sync: async () => {
      if (++attempts === 1) throw new Error("offline");
      return ["claude"];
    },
  });
  await h.controller.initialize();
  await h.controller.connect({ consent: true, autoStart: false });
  const deadline = Date.now() + 1000;
  while (attempts < 2 && Date.now() < deadline)
    await new Promise((resolve) => setTimeout(resolve, 10));
  assert.equal(attempts, 2);
  assert.equal(h.controller.state.error, null);
  await h.controller.close();
  assert.equal(closed, 1);
});

test("sync interval defaults to five seconds and restores a saved choice", async () => {
  const fresh = harness();
  await fresh.controller.initialize();
  assert.equal(fresh.controller.state.syncIntervalMs, 5000);
  await fresh.controller.close();
  const restored = harness({
    readPreferences: async () => ({ uid: "A", syncIntervalMs: 30000 }),
  });
  await restored.controller.initialize();
  assert.equal(restored.controller.state.syncIntervalMs, 30000);
  await restored.controller.close();
});

test("changing an active sync window reconfigures the watcher and validates input", async () => {
  const windows = [];
  let closed = 0;
  const h = harness({
    watchChanges: (_changed, options) => {
      windows.push(options);
      return { close: () => closed++ };
    },
  });
  await h.controller.initialize();
  await h.controller.connect({ consent: true, autoStart: false });
  assert.equal(windows[0].maxWaitMs, 5000);
  await h.controller.setSyncInterval(2000);
  assert.equal(windows[1].debounceMs, 2000);
  assert.equal(windows[1].maxWaitMs, 2000);
  assert.equal(h.preferences().syncIntervalMs, 2000);
  await assert.rejects(h.controller.setSyncInterval(0), /chu kỳ/);
  await assert.rejects(h.controller.setSyncInterval("2000"), /chu kỳ/);
  assert.equal(windows.length, 2);
  await h.controller.close();
  assert.equal(closed, 2);
});

test("changing the window during an upload keeps the latest follow-up refresh", async () => {
  let finish;
  const modes = [];
  const h = harness({
    watchChanges: () => ({ close() {} }),
    sync: async (_uid, options) => {
      modes.push(options.tokensOnly);
      if (modes.length === 1)
        await new Promise((resolve) => {
          finish = resolve;
        });
      return ["codex"];
    },
  });
  await h.controller.initialize();
  const connecting = h.controller.connect({ consent: true, autoStart: false });
  while (!finish) await new Promise((resolve) => setImmediate(resolve));
  await h.controller.setSyncInterval(10000);
  finish();
  await connecting;
  while (h.controller.pending) await h.controller.pending;
  assert.deepEqual(modes, [false, true]);
  assert.equal(h.controller.state.syncIntervalMs, 10000);
  await h.controller.close();
});
