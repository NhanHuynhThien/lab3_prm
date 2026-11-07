export const SYNC_INTERVALS = [
  { milliseconds: 2000, label: "2 giây" },
  { milliseconds: 5000, label: "5 giây" },
  { milliseconds: 10000, label: "10 giây" },
  { milliseconds: 30000, label: "30 giây" },
];
export const DEFAULT_SYNC_INTERVAL_MS = 5000;
export function isSyncInterval(value) {
  return SYNC_INTERVALS.some((interval) => interval.milliseconds === value);
}
export function normalizeSyncInterval(value) {
  return isSyncInterval(value) ? value : DEFAULT_SYNC_INTERVAL_MS;
}
