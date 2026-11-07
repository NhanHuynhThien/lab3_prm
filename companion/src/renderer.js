import { SYNC_INTERVALS, DEFAULT_SYNC_INTERVAL_MS } from "./settings.mjs";
const el = (id) => document.getElementById(id);
let latest;
let working = false;
let consentChoice = false;
let autoStartChoice = true;
for (const interval of SYNC_INTERVALS) {
  const option = document.createElement("option");
  option.value = String(interval.milliseconds);
  option.textContent = interval.label;
  el("sync-interval").append(option);
}
el("sync-interval").value = String(DEFAULT_SYNC_INTERVAL_MS);

function render(state) {
  latest = state;
  const active = state.enabled && state.consent;
  el("account-title").textContent = state.account
    ? "Tài khoản đã kết nối"
    : "Kết nối tài khoản của bạn";
  el("account-detail").textContent =
    state.account?.email ??
    "Dùng cùng tài khoản Google với ứng dụng TokenLedger.";
  el("disconnect").hidden = !state.account;
  el("disconnect").disabled = working || state.signingIn || state.busy;
  el("consent").checked = state.consent || consentChoice;
  el("consent").disabled = state.consent || working || state.signingIn;
  el("consent").closest("label").hidden = state.consent;
  el("auto-start").checked =
    state.account && state.consent ? state.autoStart : autoStartChoice;
  el("auto-start").disabled = working || state.signingIn;
  el("sync-interval").value = String(
    state.syncIntervalMs ?? DEFAULT_SYNC_INTERVAL_MS,
  );
  el("sync-interval").disabled = working || state.signingIn;
  el("interval-description").textContent =
    `Gom thay đổi log trong ${(state.syncIntervalMs ?? DEFAULT_SYNC_INTERVAL_MS) / 1000} giây rồi gửi số liệu mới.`;
  el("connect").hidden = !!state.account && state.consent;
  el("connect").disabled = working || state.signingIn || !el("consent").checked;
  el("connect").querySelector("span").textContent = state.signingIn
    ? "Đang chờ đăng nhập…"
    : state.account
      ? "Bật đồng bộ nền"
      : "Đăng nhập Google";
  el("connect").querySelector("img").hidden = !!state.account;
  el("controls").hidden = !state.account || !state.consent;
  el("sync").disabled = working || state.busy || state.signingIn;
  el("sync").textContent = state.busy ? "Đang đồng bộ…" : "Đồng bộ ngay";
  el("pause").disabled = working || state.signingIn;
  el("pause").textContent = active ? "Tạm dừng" : "Tiếp tục";
  el("setup-title").textContent = active
    ? "Đồng bộ đang bật"
    : state.consent
      ? "Đồng bộ tạm dừng"
      : "Bắt đầu đồng bộ";
  el("setup-description").textContent = active
    ? "Token cập nhật khi log CLI thay đổi. Hạn mức được kiểm tra định kỳ."
    : state.consent
      ? "Bấm Tiếp tục để cập nhật tự động trở lại."
      : "Đăng nhập trong trình duyệt của bạn, sau đó quay lại đây.";
  el("login-note").hidden = !state.signingIn;
  el("error").hidden = !state.error;
  el("error").textContent = state.error ?? "";
  el("status").textContent = state.signingIn
    ? "Chờ đăng nhập"
    : state.busy
      ? "Đang đồng bộ"
      : state.error
        ? "Cần kiểm tra"
        : active
          ? "Đang kết nối"
          : state.account
            ? "Đã đăng nhập"
            : "Chưa kết nối";
  el("status").className =
    `badge${state.error ? " error" : active ? " ready" : ""}`;
  el("last-sync").textContent = state.lastSyncedAt
    ? new Intl.DateTimeFormat("vi-VN", {
        dateStyle: "short",
        timeStyle: "medium",
      }).format(new Date(state.lastSyncedAt))
    : "Chưa đồng bộ";
  for (const item of document.querySelectorAll("[data-source]")) {
    const ready = state.providers.includes(item.dataset.source);
    const target = item.querySelector(".source-status");
    target.textContent = ready
      ? "Đã đồng bộ"
      : state.lastSyncedAt
        ? "Chưa có số liệu"
        : "Chờ đồng bộ";
    target.className = `source-status${ready ? " ready" : ""}`;
  }
}
async function run(action) {
  if (working) return;
  working = true;
  if (latest) render(latest);
  try {
    render(await action());
  } catch {
    el("error").hidden = false;
    el("error").textContent = "Chưa hoàn tất thao tác. Hãy thử lại.";
  } finally {
    working = false;
    if (latest) render(latest);
  }
}
el("consent").addEventListener("change", () => {
  consentChoice = el("consent").checked;
  if (latest) render(latest);
});
el("auto-start").addEventListener("change", () => {
  autoStartChoice = el("auto-start").checked;
  if (latest?.account && latest.consent)
    void run(() => window.companion.autoStart(autoStartChoice));
});
el("sync-interval").addEventListener("change", () => {
  const milliseconds = Number(el("sync-interval").value);
  void run(() => window.companion.syncInterval(milliseconds));
});
el("connect").addEventListener("click", () => {
  const options = {
    consent: el("consent").checked,
    autoStart: el("auto-start").checked,
  };
  void run(() => window.companion.connect(options));
});
el("sync").addEventListener(
  "click",
  () => void run(() => window.companion.sync()),
);
el("pause").addEventListener(
  "click",
  () =>
    void run(() =>
      latest.enabled ? window.companion.pause() : window.companion.resume(),
    ),
);
el("disconnect").addEventListener(
  "click",
  () =>
    void run(async () => {
      consentChoice = false;
      return window.companion.disconnect();
    }),
);
window.companion.onChange(render);
void window.companion
  .status()
  .then(render)
  .catch(() => {
    el("status").textContent = "Chưa khởi động được";
  });
