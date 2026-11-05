import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import '../services/reporting_calendar.dart';
import 'ledger_viewmodel.dart';
import 'product_features_viewmodel.dart';

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
    this.recentLimit = 3,
    this.warningPercent = 80,
    this.budgetAlerts = const [],
    this.budgetUnknownCost = 0,
  });
  final List<BudgetAlert> budgetAlerts;
  final int budgetUnknownCost;
  final List<UsageSession> sessions;
  final UsageSummary summary;
  final DateTime now;
  final List<AIAccount> budgetAccounts;
  final int budget, spent;
  int get remaining => budget - spent;
  final List<PurposeShare> shares;
  final List<int?> dailyCosts;
  final int recentLimit, warningPercent;
  List<UsageSession> get recentSessions => sessions.take(recentLimit).toList();
  bool get budgetWarning =>
      budgetAlerts.isNotEmpty ||
      budget > 0 &&
          UsageCalculator.reachesWarning(spent, budget, warningPercent);
}

final dashboardProjectionProvider = Provider.autoDispose<DashboardProjection>((
  ref,
) {
  final data = ref.watch(ledgerProvider).requireValue;
  final sessions = ref.watch(filteredSessionsProvider);
  final now = ref.watch(nowProvider);
  final scope = ref.watch(effectiveDataScopeProvider);
  final config = ref.watch(productConfigProvider);
  final budgetAccounts = data.accounts
      .where(
        (a) =>
            !a.archived &&
            a.budgetMicros != null &&
            scope.includesAccount(a, data.sessions),
      )
      .toList();
  final alerts = <BudgetAlert>[];
  final budgetSessions = <UsageSession>[];
  for (final a in budgetAccounts) {
    final cycle = UsageCalculator.inCycle(data.sessions, a, now, scope: scope);
    budgetSessions.addAll(cycle);
    final used = UsageCalculator.summarize(cycle).costMicros;
    final limit = a.budgetMicros!;
    if (UsageCalculator.reachesWarning(used, limit, config.warningPercent)) {
      alerts.add(BudgetAlert(a, used));
    }
  }
  alerts.sort((x, y) => (y.exceeded ? 1 : 0) - (x.exceeded ? 1 : 0));
  final budgetSummary = UsageCalculator.summarize(budgetSessions);
  return DashboardProjection(
    sessions: sessions,
    summary: UsageCalculator.summarize(sessions),
    now: ReportingCalendar.at(now, data.reportingTimezone),
    budgetAccounts: budgetAccounts,
    budget: budgetAccounts.fold<int>(0, (s, a) => s + a.budgetMicros!),
    spent: budgetSummary.costMicros,
    budgetAlerts: alerts,
    budgetUnknownCost: budgetSummary.unknownCost,
    shares: UsageCalculator.shares(sessions, UsageMetric.sessions),
    // A fixed 7-day window: the selected range must not blank out recent days.
    dailyCosts: UsageCalculator.dailyCosts(
      data.sessions.where(scope.includes).toList(),
      now,
      timezone: data.reportingTimezone,
    ),
    recentLimit: config.recentLimit,
    warningPercent: config.warningPercent,
  );
});

class AccountProjection {
  AccountProjection(
    this.summary,
    this.totalSessions,
    this.shares,
    this.budgetMicros,
    this.periodStart,
    this.periodEnd,
  );
  final UsageSummary summary;
  final int totalSessions;
  final List<PurposeShare> shares;
  final int? budgetMicros;
  final DateTime? periodStart, periodEnd;
  int? get remainingBudgetMicros =>
      budgetMicros == null ? null : budgetMicros! - summary.costMicros;
  double get budgetProgress => budgetMicros == null || budgetMicros == 0
      ? 0
      : summary.costMicros / budgetMicros!;
}

final accountProjectionProvider = Provider.autoDispose
    .family<AccountProjection, String>((ref, id) {
      final data = ref.watch(ledgerProvider).requireValue;
      final account = data.account(id);
      final now = ref.watch(nowProvider);
      final sessions = account == null
          ? <UsageSession>[]
          : UsageCalculator.inCycle(
              data.sessions,
              account,
              now,
              scope: ref.watch(effectiveDataScopeProvider),
            );
      final cycle = account == null
          ? null
          : ReportingCalendar.cycle(
              now,
              account.timezone,
              account.cycleStartDay,
            );
      return AccountProjection(
        UsageCalculator.summarize(sessions),
        data.sessions.where((s) => s.accountId == id).length,
        UsageCalculator.shares(sessions, UsageMetric.sessions),
        account?.budgetMicros,
        cycle?.start,
        cycle?.end,
      );
    });

class AccountComparison {
  AccountComparison(this.account, this.summary, this.value);
  final AIAccount account;
  final UsageSummary summary;
  final int value;
}

class ProviderComparison {
  ProviderComparison(this.provider, this.summary, this.value);
  final String provider;
  final UsageSummary summary;
  final int value;
}

class AnalyticsProjection {
  AnalyticsProjection(
    this.summary,
    this.shares,
    this.comparisons,
    this.providers,
  );
  final UsageSummary summary;
  final List<PurposeShare> shares;
  final List<AccountComparison> comparisons;
  final List<ProviderComparison> providers;
  int get total => shares.fold<int>(0, (s, p) => s + p.value);
}

final analyticsProjectionProvider = Provider.autoDispose
    .family<AnalyticsProjection, UsageMetric>((ref, metric) {
      final data = ref.watch(ledgerProvider).requireValue;
      final sessions = ref.watch(filteredSessionsProvider);
      int value(UsageSummary summary) => switch (metric) {
        UsageMetric.cost => summary.costMicros,
        UsageMetric.tokens => summary.tokens,
        UsageMetric.sessions => summary.count,
      };
      // One pass over the sessions instead of one per account and provider.
      final byAccount = <String, List<UsageSession>>{};
      final byProvider = <String, List<UsageSession>>{};
      for (final s in sessions) {
        (byAccount[s.accountId] ??= []).add(s);
        final provider = data.account(s.accountId)?.provider;
        if (provider != null) (byProvider[provider] ??= []).add(s);
      }
      return AnalyticsProjection(
        UsageCalculator.summarize(sessions),
        UsageCalculator.shares(sessions, metric),
        [
          for (final a in data.accounts)
            if (byAccount[a.id] case final rows?)
              () {
                final summary = UsageCalculator.summarize(rows);
                return AccountComparison(a, summary, value(summary));
              }(),
        ],
        [
          for (final provider in data.accounts.map((a) => a.provider).toSet())
            if (byProvider[provider] case final rows?)
              () {
                final summary = UsageCalculator.summarize(rows);
                return ProviderComparison(provider, summary, value(summary));
              }(),
        ],
      );
    });

class HistoryProjection {
  HistoryProjection(this.sessions)
    : summary = UsageCalculator.summarize(sessions);
  final List<UsageSession> sessions;
  final UsageSummary summary;
}

typedef HistoryQuery = ({
  String? accountId,
  Purpose? purpose,
  String? provider,
  String search,
  bool useAccountCycle,
});

final historyQueryProjectionProvider = Provider.autoDispose
    .family<HistoryProjection, HistoryQuery>((ref, query) {
      final data = ref.watch(ledgerProvider).requireValue;
      final now = ref.watch(nowProvider);
      final account = data.account(query.accountId ?? '');
      final cycle = query.useAccountCycle && account != null
          ? ReportingCalendar.cycle(
              now,
              account.timezone,
              account.cycleStartDay,
            )
          : null;
      return HistoryProjection(
        UsageCalculator.filter(
          data.sessions,
          now,
          range: ref.watch(rangeProvider),
          timezone: data.reportingTimezone,
          scope: ref.watch(effectiveDataScopeProvider),
          accountId: query.accountId,
          purpose: query.purpose,
          provider: query.provider,
          accounts: data.accounts,
          search: query.search,
          periodStart: cycle?.start,
          periodEnd: cycle?.end,
        ),
      );
    });

final historyProjectionProvider = Provider.autoDispose
    .family<HistoryProjection, (String?, Purpose?, String)>(
      (ref, q) => ref.watch(
        historyQueryProjectionProvider((
          accountId: q.$1,
          purpose: q.$2,
          provider: null,
          search: q.$3,
          useAccountCycle: false,
        )),
      ),
    );
final providerHistoryProjectionProvider = Provider.autoDispose
    .family<HistoryProjection, (String, String)>(
      (ref, q) => ref.watch(
        historyQueryProjectionProvider((
          accountId: null,
          purpose: null,
          provider: q.$1,
          search: q.$2,
          useAccountCycle: false,
        )),
      ),
    );
final accountCycleHistoryProvider = Provider.autoDispose
    .family<HistoryProjection, (String, String)>(
      (ref, q) => ref.watch(
        historyQueryProjectionProvider((
          accountId: q.$1,
          purpose: null,
          provider: null,
          search: q.$2,
          useAccountCycle: true,
        )),
      ),
    );
