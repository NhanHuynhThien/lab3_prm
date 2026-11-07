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
      return { providers: ["codex"], published: true };
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
  finish({ providers: ["codex"], published: true });
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
      return { providers: ["claude"], published: true };
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
      return { providers: ["codex"], published: true };
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
      return { providers: ["claude"], published: true };
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

test("legacy timing preferences are ignored and the watcher uses internal defaults", async () => {
  let options;
  const h = harness({
    readPreferences: async () => ({ uid: "A", syncIntervalMs: 30000 }),
    watchChanges: (_changed, value) => {
      options = value;
      return { close() {} };
    },
  });
  await h.controller.initialize();
  await h.controller.connect({ consent: true, autoStart: false });
  assert.equal(options, undefined);
  assert.equal("syncIntervalMs" in h.controller.snapshot(), false);
  assert.equal("syncIntervalMs" in h.preferences(), false);
  await h.controller.close();
});

test("unchanged background refreshes leave visible state and last sync untouched", async () => {
  let changed, finish;
  const h = harness({
    watchChanges: (callback) => {
      changed = callback;
      return { close() {} };
    },
    sync: () =>
      new Promise((resolve) => {
        finish = resolve;
      }),
  });
  await h.controller.initialize();
  h.controller.update({
    enabled: true,
    consent: true,
    providers: ["codex"],
    lastSyncedAt: "2026-11-01T00:00:00Z",
  });
  h.controller.schedule();
  const before = h.controller.snapshot();
  const events = [];
  h.controller.on("change", (state) => events.push(state));
  changed();
  const pending = h.controller.pending;
  await Promise.resolve();
  assert.equal(h.controller.state.busy, false);
  finish({ providers: ["codex"], published: false });
  await pending;
  assert.deepEqual(events, []);
  assert.deepEqual(h.controller.snapshot(), before);
  await h.controller.close();
});

test("new background data updates the last sync without showing a spinner", async () => {
  const h = harness();
  await h.controller.initialize();
  h.controller.update({ enabled: true, consent: true, lastSyncedAt: null });
  const events = [];
  h.controller.on("change", (state) => events.push(state));
  await h.controller.requestUsageSync();
  assert.ok(h.controller.state.lastSyncedAt);
  assert.deepEqual(h.controller.state.providers, ["codex"]);
  assert.equal(events.length, 1);
  assert.ok(events.every((state) => state.busy === false));
  await h.controller.close();
});

test("manual sync shows progress and shares an already running background upload", async () => {
  let finish,
    calls = 0;
  const h = harness({
    sync: () => {
      calls++;
      return new Promise((resolve) => {
        finish = resolve;
      });
    },
  });
  await h.controller.initialize();
  h.controller.update({ consent: true });
  const events = [];
  h.controller.on("change", (state) => events.push(state.busy));
  const background = h.controller.sync({ tokensOnly: true });
  await Promise.resolve();
  assert.equal(h.controller.state.busy, false);
  const manual = h.controller.sync({ interactive: true });
  assert.equal(h.controller.state.busy, true);
  finish({ providers: [], published: false });
  await Promise.all([background, manual]);
  assert.equal(calls, 1);
  assert.deepEqual(events, [true, false]);
  const next = h.controller.sync({ interactive: true });
  assert.equal(h.controller.state.busy, true);
  await Promise.resolve();
  finish({ providers: [], published: false });
  await next;
  assert.equal(calls, 2);
  assert.equal(h.controller.state.busy, false);
  await h.controller.close();
});
