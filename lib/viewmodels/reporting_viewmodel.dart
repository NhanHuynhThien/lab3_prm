import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import '../services/reporting_calendar.dart';
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

final dashboardProjectionProvider = Provider.autoDispose<DashboardProjection>((
  ref,
) {
  final data = ref.watch(ledgerProvider).requireValue;
  final sessions = ref.watch(filteredSessionsProvider);
  final now = ref.watch(nowProvider);
  final scope = ref.watch(effectiveDataScopeProvider);
  final budgetAccounts = data.accounts
      .where(
        (a) =>
            !a.archived &&
            a.budgetMicros != null &&
            scope.includesAccount(a, data.sessions),
      )
      .toList();
  final budgetSessions = [
    for (final a in budgetAccounts)
      ...UsageCalculator.inCycle(data.sessions, a, now, scope: scope),
  ];
  return DashboardProjection(
    sessions: sessions,
    summary: UsageCalculator.summarize(sessions),
    now: ReportingCalendar.at(now, data.reportingTimezone),
    budgetAccounts: budgetAccounts,
    budget: budgetAccounts.fold<int>(0, (s, a) => s + a.budgetMicros!),
    spent: UsageCalculator.summarize(budgetSessions).costMicros,
    shares: UsageCalculator.shares(sessions, UsageMetric.sessions),
    dailyCosts: UsageCalculator.dailyCosts(
      sessions,
      now,
      timezone: data.reportingTimezone,
    ),
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
      final sessions = account == null
          ? <UsageSession>[]
          : UsageCalculator.inCycle(
              data.sessions,
              account,
              ref.watch(nowProvider),
              scope: ref.watch(effectiveDataScopeProvider),
            );
      return AccountProjection(
        UsageCalculator.summarize(sessions),
        data.sessions.where((s) => s.accountId == id).length,
        UsageCalculator.shares(sessions, UsageMetric.sessions),
        data.account(id)?.budgetMicros,
        account == null
            ? null
            : ReportingCalendar.cycle(
                ref.watch(nowProvider),
                account.timezone,
                account.cycleStartDay,
              ).start,
        account == null
            ? null
            : ReportingCalendar.cycle(
                ref.watch(nowProvider),
                account.timezone,
                account.cycleStartDay,
              ).end,
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
        data.accounts
            .map((a) => a.provider)
            .toSet()
            .map((provider) {
              final summary = UsageCalculator.summarize(
                sessions.where(
                  (s) => data.account(s.accountId)?.provider == provider,
                ),
              );
              return ProviderComparison(provider, summary, switch (metric) {
                UsageMetric.cost => summary.costMicros,
                UsageMetric.tokens => summary.tokens,
                UsageMetric.sessions => summary.count,
              });
            })
            .where((p) => p.summary.count > 0)
            .toList(),
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
