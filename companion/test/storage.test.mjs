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

test("sync window is persisted, and invalid legacy settings use the default", async () => {
  const root = await mkdtemp(join(tmpdir(), "tokenledger-preferences-"));
  try {
    const store = preferencesStore(root);
    await store.write({ syncIntervalMs: 10000 });
    assert.equal((await store.read()).syncIntervalMs, 10000);
    await store.write({ syncIntervalMs: 1 });
    assert.equal((await store.read()).syncIntervalMs, 5000);
    await store.write({});
    assert.equal((await store.read()).syncIntervalMs, 5000);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
