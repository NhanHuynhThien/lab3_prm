import '../models/ledger.dart';
import '../services/usage_calculator.dart';

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
    this.dailyTokens = const [],
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
  final List<int?> dailyTokens;
  final int recentLimit, warningPercent;

  /// Any session in the range carries a cost (manual or API billing).
  bool get hasCost => summary.unknownCost < summary.count;
  List<UsageSession> get recentSessions => sessions.take(recentLimit).toList();
  bool get budgetWarning =>
      budgetAlerts.isNotEmpty ||
      budget > 0 &&
          UsageCalculator.reachesWarning(spent, budget, warningPercent);
}
