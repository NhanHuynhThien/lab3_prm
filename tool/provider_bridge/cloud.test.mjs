import { test } from "node:test";
import assert from "node:assert/strict";
import { firebaseWebConfig, snapshotWrite, syncOnce } from "./cloud.mjs";
import {
  launchAgentPlist,
  systemdUnit,
  windowsTaskScript,
} from "./platform.mjs";

const cfg = {
  apiKey: "k",
  authDomain: "p.firebaseapp.com",
  projectId: "p",
  appId: "a",
};

test("reads only the public web Firebase config", () => {
  const dart = `static const FirebaseOptions android = FirebaseOptions(apiKey: 'other', appId: 'x', projectId: 'p');
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'k', appId: 'a', messagingSenderId: '1', projectId: 'p', authDomain: 'p.firebaseapp.com');`;
  assert.deepEqual(firebaseWebConfig(dart), cfg);
  assert.throws(() => firebaseWebConfig("nothing"));
});

test("write matches the Firestore rule: exact keys, server time, own uid", () => {
  const body = snapshotWrite("p", "U1", { schemaVersion: 1 });
  const w = body.writes[0];
  assert.equal(
    w.update.name,
    "projects/p/databases/(default)/documents/users/U1/provider_snapshots/latest",
  );
  assert.deepEqual(Object.keys(w.update.fields).sort(), ["json", "ownerId"]);
  assert.equal(w.update.fields.ownerId.stringValue, "U1");
  assert.deepEqual(JSON.parse(w.update.fields.json.stringValue), {
    schemaVersion: 1,
  });
  assert.deepEqual(w.updateTransforms, [
    { fieldPath: "savedAt", setToServerValue: "REQUEST_TIME" },
  ]);
});

test("launch agent runs sync at login, keeps alive and escapes paths", () => {
  const plist = launchAgentPlist({
    node: "/n",
    script: "/a&b/cloud.mjs",
    log: "/l",
  });
  assert.match(
    plist,
    /<string>\/a&amp;b\/cloud.mjs<\/string><string>sync<\/string>/,
  );
  assert.match(plist, /<key>RunAtLoad<\/key><true\/>/);
  assert.match(plist, /<key>KeepAlive<\/key><true\/>/);
});

test("sync exchanges the stored token, rotates it and writes as the user", async () => {
  const calls = [];
  let saved;
  const fetchImpl = async (url, init) => {
    calls.push({ url, init });
    if (url.startsWith("https://securetoken")) {
      return {
        ok: true,
        json: async () => ({
          id_token: "ID",
          user_id: "U1",
          refresh_token: "R2",
        }),
      };
    }
    return { ok: true };
  };
  const ready = await syncOnce(cfg, {
    fetchImpl,
    load: async () => "R1",
    save: async (v) => {
      saved = v;
    },
    collect: async () => ({
      schemaVersion: 1,
      providers: [
        { id: "codex", status: "ready" },
        { id: "google", status: "setup" },
      ],
    }),
  });
  assert.deepEqual(ready, ["codex"]);
  assert.equal(saved, "R2");
  assert.equal(calls[1].init.headers.Authorization, "Bearer ID");
  assert.match(
    calls[1].url,
    /projects\/p\/databases\/\(default\)\/documents:commit$/,
  );
  await assert.rejects(
    syncOnce(cfg, { fetchImpl, load: async () => null }),
    /login/,
  );
  await assert.rejects(
    syncOnce(cfg, {
      fetchImpl: async () => ({ ok: false, status: 400 }),
      load: async () => "R1",
    }),
    /hết hạn/,
  );
});

test("linux unit quotes paths and restarts; windows task passes paths via env", () => {
  const unit = systemdUnit({
    node: "/usr/bin/node",
    script: '/home/a b/"x"/cloud.mjs',
  });
  assert.match(
    unit,
    /ExecStart="\/usr\/bin\/node" "\/home\/a b\/\\"x\\"\/cloud.mjs" sync/,
  );
  assert.match(unit, /Restart=always/);
  const task = windowsTaskScript();
  assert.match(task, /\$env:TL_NODE/);
  assert.match(task, /-AtLogOn/);
  assert.doesNotMatch(
    task,
    /[A-Z]:\\/,
    "no machine paths baked into the script",
  );
});

test("unchanged token aggregate skips the Firestore commit", async () => {
  const urls = [];
  const ready = await syncOnce(cfg, {
    load: async () => "R1",
    save: async () => {},
    fetchImpl: async (url) => {
      urls.push(url);
      return {
        ok: true,
        json: async () => ({ id_token: "ID", user_id: "U1" }),
      };
    },
    collect: async () => ({ providers: [{ id: "codex", status: "ready" }] }),
    shouldWrite: () => false,
  });
  assert.deepEqual(ready, ["codex"]);
  assert.equal(urls.length, 1);
  assert.ok(urls[0].startsWith("https://securetoken"));
});
