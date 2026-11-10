import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_dashboard.dart';
import '../models/cloud_sync_status.dart';
import '../models/provider_usage.dart';
import '../services/local_alert_notifier.dart';
import '../services/token_alert_store.dart';
import '../utils/formatters.dart';
import 'ledger_viewmodel.dart';
import 'provider_sources_viewmodel.dart';
import 'reporting_viewmodel.dart';

final tokenAlertStoreProvider = Provider<TokenAlertStore>(
  (ref) => TokenAlertStore(null, ref.watch(cloudOwnerProvider)),
);
final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => SystemAlertNotifier(),
);

/// Token limit per account id; absent means no limit.
class TokenLimitsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    unawaited(
      ref.read(tokenAlertStoreProvider).loadLimits().then((v) {
        if (ref.mounted) state = {...v, ...state};
      }),
    );
    return const {};
  }

  Future<void> set(String accountId, int? limit) async {
    await ref.read(tokenAlertStoreProvider).saveLimit(accountId, limit);
    final next = {...state};
    limit == null ? next.remove(accountId) : next[accountId] = limit;
    state = next;
  }
}

final tokenLimitsProvider =
    NotifierProvider<TokenLimitsNotifier, Map<String, int>>(
      TokenLimitsNotifier.new,
    );

/// Limit key for a companion agent; manual accounts use their own id.
String agentLimitKey(String sourceId) => 'agent:$sourceId';

/// Quota window with the most usage that is still current, if any.
ProviderQuota? tightestQuota(ProviderUsage source, DateTime now) =>
    AgentDashboard([source], now).limiting(source);

/// Phone notifications: companion agents when the tightest quota reaches the
/// chosen percent (once per reset), manual accounts at 80%/100% of a token
/// limit (once per budget cycle).
final tokenAlertWatcherProvider = Provider<void>((ref) {
  final limits = ref.watch(tokenLimitsProvider);
  if (limits.isEmpty) return;
  final store = ref.read(tokenAlertStoreProvider);
  void notify(String key, String title, String body) => unawaited(
    ref
        .read(alertNotifierProvider)
        .show(key.hashCode & 0x7fffffff, title, body),
  );

  final now = ref.watch(nowProvider);
  for (final source in ref.watch(providerSourcesProvider)) {
    final key = agentLimitKey(source.id);
    final percent = limits[key];
    final quota = percent == null ? null : tightestQuota(source, now);
    if (quota == null || quota.usedPercent < percent!) continue;
    unawaited(() async {
      final cycle = '$key.$percent.${quota.resetsAt.millisecondsSinceEpoch}';
      if (!await store.claimOnce(cycle)) return;
      notify(
        key,
        '${source.name} đã dùng ${quota.usedPercent.toStringAsFixed(0)}% hạn mức',
        '${quota.scopeLabel} · ${quota.usageLabel} · đặt lại ${resetLabel(quota.resetsAt, now)}.',
      );
    }());
  }
  final data = ref.watch(ledgerProvider).asData?.value;
  if (data == null) return;
  for (final account in data.accounts.where((a) => !a.archived)) {
    final limit = limits[account.id];
    if (limit == null) continue;
    final projection = ref.watch(accountProjectionProvider(account.id));
    final start = projection.periodStart;
    if (start == null) continue;
    final tokens = projection.summary.tokens;
    unawaited(() async {
      final level = await store.claimLevel(
        accountId: account.id,
        cycle: '${start.toUtc().millisecondsSinceEpoch}',
        tokens: tokens,
        limit: limit,
      );
      if (level == null) return;
      notify(
        account.id,
        level >= 100
            ? '${account.alias} đã chạm giới hạn token'
            : '${account.alias} đã dùng $level% giới hạn token',
        '${compactTokens(tokens)} / ${compactTokens(limit)} token trong kỳ này.',
      );
    }());
  }
});
