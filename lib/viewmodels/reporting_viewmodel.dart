import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import 'ledger_viewmodel.dart';

/// Derived screen state: views render results and never own accounting formulas.
class DashboardProjection {
  DashboardProjection({
    required this.sessions,
    required this.summary,
    required this.now,
    required this.budgetAccounts,
    required this.budget,
    required this.spent,
    required this.shares,
    required this.dailyCosts,
  });
  final List<UsageSession> sessions;
  final UsageSummary summary;
  final DateTime now;
  final List<AIAccount> budgetAccounts;
  final int budget, spent;
  int get remaining => budget - spent;
  final List<PurposeShare> shares;
  final List<int> dailyCosts;
}

final dashboardProjectionProvider = Provider<DashboardProjection>((ref) {
  final data = ref.watch(ledgerProvider).requireValue;
  final sessions = ref.watch(filteredSessionsProvider);
  final now = ref.watch(clockProvider)();
  final budgetAccounts = data.accounts
      .where((a) => !a.archived && a.budgetMicros != null)
      .toList();
  final monthly = UsageCalculator.filter(data.sessions, now);
  return DashboardProjection(
    sessions: sessions,
    summary: UsageCalculator.summarize(sessions),
    now: now,
    budgetAccounts: budgetAccounts,
    budget: budgetAccounts.fold<int>(0, (s, a) => s + a.budgetMicros!),
    spent: UsageCalculator.summarize(
      monthly.where((s) => budgetAccounts.any((a) => a.id == s.accountId)),
    ).costMicros,
    shares: UsageCalculator.shares(sessions, UsageMetric.sessions),
    dailyCosts: UsageCalculator.dailyCosts(sessions, now),
  );
});

class AccountProjection {
  AccountProjection(this.summary, this.totalSessions, this.shares);
  final UsageSummary summary;
  final int totalSessions;
  final List<PurposeShare> shares;
}

final accountProjectionProvider = Provider.family<AccountProjection, String>((
  ref,
  id,
) {
  final data = ref.watch(ledgerProvider).requireValue;
  final sessions = UsageCalculator.filter(
    data.sessions,
    ref.watch(clockProvider)(),
    accountId: id,
  );
  return AccountProjection(
    UsageCalculator.summarize(sessions),
    data.sessions.where((s) => s.accountId == id).length,
    UsageCalculator.shares(sessions, UsageMetric.sessions),
  );
});

class AccountComparison {
  AccountComparison(this.account, this.summary, this.value);
  final AIAccount account;
  final UsageSummary summary;
  final int value;
}

class AnalyticsProjection {
  AnalyticsProjection(this.summary, this.shares, this.comparisons);
  final UsageSummary summary;
  final List<PurposeShare> shares;
  final List<AccountComparison> comparisons;
  int get total => shares.fold<int>(0, (s, p) => s + p.value);
}

final analyticsProjectionProvider =
    Provider.family<AnalyticsProjection, UsageMetric>((ref, metric) {
      final data = ref.watch(ledgerProvider).requireValue;
      final sessions = ref.watch(filteredSessionsProvider);
      return AnalyticsProjection(
        UsageCalculator.summarize(sessions),
        UsageCalculator.shares(sessions, metric),
        data.accounts.map((a) {
          final summary = UsageCalculator.summarize(
            sessions.where((s) => s.accountId == a.id),
          );
          final value = switch (metric) {
            UsageMetric.cost => summary.costMicros,
            UsageMetric.tokens => summary.tokens,
            UsageMetric.sessions => summary.count,
          };
          return AccountComparison(a, summary, value);
        }).toList(),
      );
    });

class HistoryProjection {
  HistoryProjection(this.sessions)
    : summary = UsageCalculator.summarize(sessions);
  final List<UsageSession> sessions;
  final UsageSummary summary;
}

final historyProjectionProvider =
    Provider.family<HistoryProjection, (String?, Purpose?, String)>(
      (ref, query) => HistoryProjection(
        UsageCalculator.filter(
          ref.watch(ledgerProvider).requireValue.sessions,
          ref.watch(clockProvider)(),
          range: ref.watch(rangeProvider),
          accountId: query.$1,
          purpose: query.$2,
          search: query.$3,
        ),
      ),
    );
