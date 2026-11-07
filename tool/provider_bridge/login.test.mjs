import { test } from "node:test";
import assert from "node:assert/strict";
import { login, syncOnce } from "./cloud.mjs";

const config = {
  apiKey: "public",
  projectId: "test",
  authDomain: "test.firebaseapp.com",
  appId: "test",
};

test("browser login enforces origin, state and verified UID before persisting a session", async () => {
  let url;
  let notify;
  const ready = new Promise((resolve) => {
    notify = resolve;
  });
  const saved = [];
  const pending = login(config, {
    open: () => {},
    onUrl: (value) => {
      url = value;
      notify();
    },
    exchangeToken: async () => ({ uid: "A", refreshToken: "rotated" }),
    save: async (value) => saved.push(value),
    saveAccount: async (account) => saved.push(account),
  });
  await ready;
  const page = await (await fetch(url)).text();
  const state = page.match(/state: "([a-f0-9]{64})"/)[1];
  const origin = new URL(url).origin;
  const post = (body, headers = {}) =>
    fetch(`${origin}/session`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Origin: origin,
        ...headers,
      },
      body: JSON.stringify(body),
    });
  assert.equal(
    (
      await post(
        { state, uid: "A", refreshToken: "test" },
        { Origin: "https://untrusted.example" },
      )
    ).status,
    403,
  );
  assert.equal(
    (await post({ state: "wrong", uid: "A", refreshToken: "test" })).status,
    400,
  );
  assert.equal(
    (await post({ state, uid: "B", refreshToken: "test" })).status,
    400,
  );
  assert.deepEqual(saved, []);
  assert.equal(
    (
      await post({
        state,
        uid: "A",
        email: "a@example.test",
        refreshToken: "test",
      })
    ).status,
    204,
  );
  const account = await pending;
  assert.deepEqual(account, { uid: "A", email: "a@example.test" });
  assert.equal(saved[0], "rotated");
  assert.equal(saved.length, 2);
  assert.ok(!url.includes("test"));
});

test("cancelled browser login closes its listener without storing a session", async () => {
  const abort = new AbortController();
  let notify;
  const ready = new Promise((resolve) => {
    notify = resolve;
  });
  const pending = login(config, {
    signal: abort.signal,
    open: () => {},
    onUrl: notify,
    save: async () => assert.fail("must not save"),
  });
  await ready;
  abort.abort();
  await assert.rejects(pending, /hủy/);
});

test("sync cannot collect or write under a UID that differs from the selected account", async () => {
  await assert.rejects(
    syncOnce(config, {
      expectedUid: "A",
      load: async () => "refresh",
      fetchImpl: async () => ({
        ok: true,
        json: async () => ({ id_token: "ID", user_id: "B" }),
      }),
      collect: async () => assert.fail("must not collect"),
      save: async () => assert.fail("must not save"),
    }),
    /Tài khoản/,
  );
});
