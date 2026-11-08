import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../screens/history_screen.dart';
import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'charts.dart';
import 'common.dart';
import 'usage_row.dart';

class DashboardTrendCard extends StatelessWidget {
  const DashboardTrendCard({
    super.key,
    required this.dailyCosts,
    required this.now,
  });

  final List<int?> dailyCosts;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Chi phí 7 ngày gần đây'),
        if (dailyCosts.every((v) => v == 0))
          const EmptyFeedback(
            title: 'Chưa có chi phí trong 7 ngày qua',
            message: 'Ghi một phiên để bắt đầu theo dõi.',
          )
        else
          UsageBarChart(values: dailyCosts, now: now),
        const SizedBox(height: 16),
        Text(
          'Luôn tính 7 ngày gần nhất theo chi phí nhập tay. “—” là ngày có phiên nhưng chưa biết chi phí.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class DashboardRecentCard extends StatelessWidget {
  const DashboardRecentCard({
    super.key,
    required this.sessions,
    required this.recentSessions,
    required this.data,
  });

  final List<UsageSession> sessions;
  final List<UsageSession> recentSessions;
  final LedgerData data;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Sử dụng gần đây',
          action: 'Lịch sử',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
          ),
        ),
        if (sessions.isEmpty)
          const EmptyFeedback(
            title: 'Chưa có phiên sử dụng',
            message: 'Các phiên đã ghi sẽ xuất hiện ở đây.',
          ),
        ...recentSessions.map(
          (s) => UsageRow(
            timezone: data.reportingTimezone,
            session: s,
            account: data.account(s.accountId),
            onTap: () => showUsageDetail(context, s),
          ),
        ),
      ],
    ),
  );
}

/// One-line recap of the manual ledger when agents lead the overview.
class DashboardLedgerSummaryCard extends StatelessWidget {
  const DashboardLedgerSummaryCard({
    super.key,
    required this.summary,
    required this.rangeLabel,
  });

  final UsageSummary summary;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final cost = summary.unknownCost == summary.count
        ? 'chưa có chi phí'
        : money(summary.costMicros);
    return Panel(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.cardRadius),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sổ tự ghi · $rangeLabel',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${summary.count} lần ghi · '
                    '${compactTokens(summary.tokens)} token · $cost',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
