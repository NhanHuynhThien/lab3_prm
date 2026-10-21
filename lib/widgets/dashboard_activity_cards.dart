import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../screens/account_detail_screen.dart';
import '../screens/history_screen.dart';
import '../services/usage_calculator.dart';
import 'charts.dart';
import 'common.dart';
import 'quota_row.dart';
import 'usage_row.dart';

class DashboardTrendCard extends StatelessWidget {
  const DashboardTrendCard({
    super.key,
    required this.sessions,
    required this.dailyCosts,
    required this.now,
  });

  final List<UsageSession> sessions;
  final List<int> dailyCosts;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Chi phí 7 ngày gần đây'),
        if (sessions.isEmpty)
          const EmptyFeedback(
            title: 'Chưa có sử dụng trong kỳ',
            message: 'Ghi một phiên để bắt đầu theo dõi.',
          )
        else
          UsageBarChart(values: dailyCosts, now: now),
        const SizedBox(height: 16),
        Text(
          'Số liệu chi phí nhập tay theo khoảng thời gian đã chọn.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class DashboardQuotaCard extends StatelessWidget {
  const DashboardQuotaCard({
    super.key,
    required this.accounts,
    required this.now,
    required this.onAccounts,
  });

  final List<AIAccount> accounts;
  final DateTime now;
  final VoidCallback onAccounts;

  @override
  Widget build(BuildContext context) {
    final active = accounts.where((a) => !a.archived).toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Hạn mức tài khoản',
            action: 'Xem tất cả',
            onAction: onAccounts,
          ),
          if (active.isEmpty)
            const EmptyFeedback(
              title: 'Chưa có tài khoản',
              message: 'Thêm tài khoản AI để ghi nhận quota.',
            ),
          ...active
              .take(3)
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QuotaRow(
                    account: a,
                    now: now,
                    compact: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDetailScreen(accountId: a.id),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
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

class DashboardPurposeCard extends StatelessWidget {
  const DashboardPurposeCard({
    super.key,
    required this.shares,
    required this.summaryCount,
    required this.onAnalytics,
  });

  final List<PurposeShare> shares;
  final int summaryCount;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'AI dùng cho việc gì?',
          action: 'Phân tích',
          onAction: onAnalytics,
        ),
        if (shares.isEmpty) const Text('Chưa có công việc trong kỳ đã chọn.'),
        ...shares
            .take(4)
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(p.purpose.label)),
                        Text('${p.count} phiên'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedProgress(
                      value: summaryCount == 0 ? 0 : p.count / summaryCount,
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}
