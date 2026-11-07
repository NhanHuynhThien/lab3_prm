import { localModelUsage } from "./models.mjs";
import { readGemini } from "./gemini.mjs";
import { readClaude } from "./claude.mjs";
import { withLocalUsage } from "./server.mjs";

// Token-only refreshes use local logs, retaining the last observed quota.
// Calling provider quota CLIs remains on the slower periodic refresh.
export async function collectTokenSnapshot(
  previous,
  {
    now = new Date(),
    models = localModelUsage,
    gemini = readGemini,
    claude = readClaude,
  } = {},
) {
  const [codexModels, claudeModels, google, claudeContext] = await Promise.all([
    models("codex", undefined, now),
    models("claude", undefined, now),
    gemini(undefined, now),
    claude(),
  ]);
  const providers = previous.providers.map((provider) => {
    if (provider.id === "google") return google;
    if (!["codex", "claude"].includes(provider.id)) return provider;
    let base = provider;
    if (provider.source === "Phiên lưu trên máy") {
      base = {
        ...provider,
        status: "setup",
        totalTokens: null,
        observedAt: null,
      };
    }
    if (provider.id === "claude" && claudeContext.status === "ready")
      base = claudeContext;
    return withLocalUsage(
      base,
      provider.id === "codex" ? codexModels : claudeModels,
      now,
    );
  });
  return { ...previous, collectedAt: now.toISOString(), providers };
}
