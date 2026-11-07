import { EventEmitter } from "node:events";
import {
  DEFAULT_SYNC_INTERVAL_MS,
  isSyncInterval,
  normalizeSyncInterval,
} from "./settings.mjs";

export class CompanionController extends EventEmitter {
  constructor(dependencies) {
    super();
    this.d = dependencies;
    this.state = {
      account: null,
      syncIntervalMs: DEFAULT_SYNC_INTERVAL_MS,
      enabled: false,
      consent: false,
      busy: false,
      signingIn: false,
      lastSyncedAt: null,
      providers: [],
      error: null,
    };
    this.pending = null;
    this.connecting = null;
    this.timer = null;
    this.loginAbort = null;
    this.closing = false;
    this.watcher = null;
    this.usageDirty = false;
    this.retryTimer = null;
    this.retryAttempt = 0;
  }

  snapshot() {
    return structuredClone(this.state);
  }
  update(values) {
    Object.assign(this.state, values);
    this.emit("change", this.snapshot());
  }
  async persist() {
    await this.d.writePreferences({
      uid: this.state.account?.uid ?? null,
      syncIntervalMs: this.state.syncIntervalMs,
      enabled: this.state.enabled,
      consent: this.state.consent,
      lastSyncedAt: this.state.lastSyncedAt,
      providers: this.state.providers,
    });
  }
  async initialize() {
    const [account, preferences] = await Promise.all([
      this.d.readAccount(),
      this.d.readPreferences(),
    ]);
    const sameOwner = account && preferences.uid === account.uid;
    this.update({
      account,
      syncIntervalMs: normalizeSyncInterval(preferences.syncIntervalMs),
      consent: sameOwner && preferences.consent === true,
      lastSyncedAt: sameOwner ? (preferences.lastSyncedAt ?? null) : null,
      providers: sameOwner ? (preferences.providers ?? []) : [],
    });
    if (
      sameOwner &&
      preferences.consent === true &&
      preferences.enabled === true
    ) {
      await this.enable();
    }
  }
  stopSchedule() {
    clearInterval(this.timer);
    clearTimeout(this.retryTimer);
    this.watcher?.close();
    this.watcher = null;
    this.usageDirty = false;
  }
  requestUsageSync() {
    if (!this.state.enabled || !this.state.consent || this.closing) return;
    if (this.pending) {
      this.usageDirty = true;
      return this.pending;
    }
    return this.sync({ tokensOnly: true });
  }
  schedule() {
    this.stopSchedule();
    this.watcher =
      this.d.watchChanges?.(
        () => {
          void this.requestUsageSync();
        },
        {
          debounceMs: this.state.syncIntervalMs,
          maxWaitMs: this.state.syncIntervalMs,
          pollMs: Math.min(10_000, this.state.syncIntervalMs),
        },
      ) ?? null;
    this.watcher?.ready?.catch(() => {});
    this.timer = setInterval(() => {
      if (this.state.enabled) void this.sync();
    }, this.d.intervalMs ?? 300_000);
    this.timer.unref?.();
  }
  async setSyncInterval(milliseconds) {
    if (!isSyncInterval(milliseconds))
      throw new Error("Chọn chu kỳ 2, 5, 10 hoặc 30 giây.");
    this.update({ syncIntervalMs: milliseconds });
    await this.persist();
    if (this.state.enabled && !this.closing) {
      this.schedule();
      if (this.pending) this.usageDirty = true;
      else await this.requestUsageSync();
    }
  }
  connect(options) {
    if (this.connecting) return this.connecting;
    this.connecting = this.finishConnection(options).finally(() => {
      this.connecting = null;
    });
    return this.connecting;
  }
  async finishConnection({ consent, autoStart }) {
    if (consent !== true || typeof autoStart !== "boolean") {
      throw new Error("Đồng ý đồng bộ số liệu trước khi kết nối.");
    }
    if (this.state.signingIn || this.closing) return;
    this.update({ signingIn: true, error: null });
    this.loginAbort = new AbortController();
    try {
      if (!this.state.account) {
        await this.d.login({ signal: this.loginAbort.signal });
        if (this.closing) return;
        this.update({ account: await this.d.readAccount() });
      }
      if (!this.state.account)
        throw new Error("Chưa lưu được tài khoản đăng nhập.");
      // Preserve consent before changing OS startup settings, so a failed
      // startup registration can be retried without another Google login.
      this.update({ consent: true });
      await this.persist();
      await this.d.setAutoStart(autoStart);
      await this.enable();
    } catch (error) {
      if (!this.closing) this.update({ error: error.message });
    } finally {
      this.loginAbort = null;
      this.update({ signingIn: false });
    }
  }
  async enable() {
    if (!this.state.account || !this.state.consent || this.closing) return;
    // Replace the old CLI service only after the desktop app is connected.
    await this.d.retireLegacyService();
    this.update({ enabled: true, error: null });
    await this.persist();
    if (!this.state.enabled || this.closing) return;
    this.retryAttempt = 0;
    this.schedule();
    await this.sync();
  }
  async pause() {
    this.stopSchedule();
    this.timer = null;
    this.update({ enabled: false });
    await this.persist();
    await this.pending;
  }
  async sync({ tokensOnly = false } = {}) {
    if (this.pending) return this.pending;
    if (!this.state.account || !this.state.consent || this.closing) return;
    clearTimeout(this.retryTimer);
    const account = this.state.account;
    this.update({ busy: true, error: null });
    this.pending = Promise.resolve().then(async () => {
      try {
        const providers = await this.d.sync(account.uid, { tokensOnly });
        this.retryAttempt = 0;
        this.update({ providers, lastSyncedAt: new Date().toISOString() });
        await this.persist();
      } catch (error) {
        this.update({ error: error.message });
        if (this.state.enabled && !this.closing) {
          const wait =
            this.d.retryMs ??
            Math.min(30_000, 1000 * 2 ** Math.min(++this.retryAttempt, 5));
          this.retryTimer = setTimeout(() => {
            if (this.state.enabled && !this.closing)
              void this.sync({ tokensOnly });
          }, wait);
          this.retryTimer.unref?.();
        }
      } finally {
        this.pending = null;
        this.update({ busy: false });
        if (this.usageDirty && this.state.enabled && !this.closing) {
          this.usageDirty = false;
          queueMicrotask(() => {
            if (this.state.enabled && !this.closing)
              void this.sync({ tokensOnly: true });
          });
        }
      }
    });
    return this.pending;
  }
  async disconnect() {
    if (this.state.signingIn) this.loginAbort?.abort();
    await this.connecting;
    await this.pause();
    await this.d.setAutoStart(false);
    await this.d.logout();
    this.update({
      account: null,
      consent: false,
      providers: [],
      lastSyncedAt: null,
      error: null,
    });
    await this.persist();
  }
  async close() {
    this.closing = true;
    this.stopSchedule();
    this.loginAbort?.abort();
    await this.connecting;
    await this.pending;
  }
}
