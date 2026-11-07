import { createHash } from "node:crypto";
import { syncOnce } from "./cloud.mjs";
import { collectSnapshot } from "./server.mjs";
import { collectTokenSnapshot } from "./token-snapshot.mjs";

export function snapshotDigest(snapshot) {
  // Collection clocks and the sliding window advance on every read. Actual
  // usage timestamps, quota reset times and aggregate values remain hashed.
  const json = JSON.stringify(snapshot, (key, value) =>
    ["collectedAt", "observedAt", "periodStart", "periodEnd"].includes(key)
      ? undefined
      : value,
  );
  return createHash("sha256").update(json).digest("hex");
}

export function createCloudSync(
  config,
  {
    full = collectSnapshot,
    tokens = collectTokenSnapshot,
    write = syncOnce,
  } = {},
) {
  let owner = null,
    snapshot = null,
    digest = null;
  return async (uid, { tokensOnly = false } = {}) => {
    if (uid !== owner) {
      owner = uid;
      snapshot = null;
      digest = null;
    }
    let next,
      nextDigest,
      published = false;
    const providers = await write(config, {
      expectedUid: uid,
      collect: async () => {
        next = tokensOnly && snapshot ? await tokens(snapshot) : await full();
        nextDigest = snapshotDigest(next);
        return next;
      },
      shouldWrite: () => {
        published = !tokensOnly || nextDigest !== digest;
        return published;
      },
    });
    // Failed writes never replace the last successfully published baseline.
    snapshot = next;
    digest = nextDigest;
    return { providers, published };
  };
}
