import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { preferencesStore } from "../src/storage.mjs";

test("preferences remain owner-scoped, validate fields and use private file mode", async () => {
  const root = await mkdtemp(join(tmpdir(), "tokenledger-preferences-"));
  try {
    const store = preferencesStore(root);
    assert.equal((await store.read()).consent, false);
    await store.write({
      uid: "A",
      consent: true,
      enabled: true,
      providers: ["codex", "private-field"],
    });
    assert.deepEqual((await store.read()).providers, ["codex"]);
    assert.equal((await store.read()).uid, "A");
    assert.equal(
      (await stat(join(root, "preferences.json"))).mode & 0o777,
      0o600,
    );
    await writeFile(join(root, "preferences.json"), "broken");
    assert.equal((await store.read()).enabled, false);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("legacy interval fields do not override background sync or discard consent", async () => {
  const root = await mkdtemp(join(tmpdir(), "tokenledger-preferences-"));
  try {
    const store = preferencesStore(root);
    await store.write({
      uid: "A",
      consent: true,
      enabled: true,
      syncIntervalMs: 30000,
    });
    const preferences = await store.read();
    assert.equal(preferences.uid, "A");
    assert.equal(preferences.consent, true);
    assert.equal(preferences.enabled, true);
    assert.equal("syncIntervalMs" in preferences, false);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
