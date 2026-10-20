import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/ledger_feedback.dart';
import 'account_detail_screen.dart';
import 'history_screen.dart';
import 'usage_form_screen.dart';

class RangePicker extends ConsumerWidget {
  const RangePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<UsageRange>(
        tooltip: 'Chọn khoảng thời gian',
        initialValue: ref.watch(rangeProvider),
        onSelected: (value) => ref.read(rangeProvider.notifier).select(value),
        itemBuilder: (_) => UsageRange.values
            .map((v) => PopupMenuItem(value: v, child: Text(v.label)))
            .toList(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                ref.watch(rangeProvider).label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onAccounts,
    required this.onAnalytics,
  });
  final VoidCallback onAccounts, onAnalytics;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Tổng quan');
    if (feedback != null) return feedback;
    final data = state.requireValue;
    final projection = ref.watch(dashboardProjectionProvider);
    final sessions = projection.sessions;
    final summary = projection.summary;
    final now = projection.now;
    final budgetAccounts = projection.budgetAccounts;
    final budget = projection.budget;
    final spent = projection.spent;
    final remaining = projection.remaining;
    final shares = projection.shares;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeading(
          'Tổng quan',
          'AI đang hỗ trợ công việc của bạn như thế nào?',
          action: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const UsageFormScreen()),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Ghi sử dụng'),
          ),
        ),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [RangePicker(), DataScopePicker()],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final balance = Panel(
              color: AppColors.soft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngân sách còn lại · Kỳ hiện tại',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (budgetAccounts.isEmpty)
                    Text(
                      'Chưa đặt ngân sách',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  else
                    AnimatedMoney(micros: remaining),
                  const SizedBox(height: 16),
                  AnimatedProgress(
                    value: budget == 0 ? 0 : spent / budget,
                    semanticValue: budgetAccounts.isEmpty
                        ? 'Chưa đặt ngân sách'
                        : null,
                    color: remaining < 0 ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đã ghi ${money(spent)} / ${money(budget)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngân sách từng kỳ tài khoản theo nguồn đã chọn; không phải số dư nhà cung cấp.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
            final metrics = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          'Chi phí đã ghi',
                          money(summary.costMicros),
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          'Token đã ghi',
                          compactTokens(summary.tokens),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric('Phiên sử dụng', '${summary.count}'),
                      ),
                      Expanded(
                        child: _Metric(
                          'Tài khoản active',
                          '${data.accounts.where((a) => !a.archived).length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${summary.unknownCost} phiên chưa biết chi phí · ${summary.unknownTokens} phiên chưa biết token',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
            return c.maxWidth >= 680
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: balance),
                        const SizedBox(width: 16),
                        Expanded(child: metrics),
                      ],
                    ),
                  )
                : Column(
                    children: [balance, const SizedBox(height: 16), metrics],
                  );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final trend = Panel(
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
                    UsageBarChart(values: projection.dailyCosts, now: now),
                  const SizedBox(height: 16),
                  Text(
                    'Số liệu chi phí nhập tay theo khoảng thời gian đã chọn.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
            final quota = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Hạn mức tài khoản',
                    action: 'Xem tất cả',
                    onAction: onAccounts,
                  ),
                  if (data.accounts.where((a) => !a.archived).isEmpty)
                    const EmptyFeedback(
                      title: 'Chưa có tài khoản',
                      message: 'Thêm tài khoản AI để ghi nhận quota.',
                    ),
                  ...data.accounts
                      .where((a) => !a.archived)
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
                                builder: (_) =>
                                    AccountDetailScreen(accountId: a.id),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
            return c.maxWidth >= 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: trend),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: quota),
                    ],
                  )
                : Column(children: [trend, const SizedBox(height: 16), quota]);
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final latest = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Sử dụng gần đây',
                    action: 'Lịch sử',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HistoryScreen(),
                      ),
                    ),
                  ),
                  if (sessions.isEmpty)
                    const EmptyFeedback(
                      title: 'Chưa có phiên sử dụng',
                      message: 'Các phiên đã ghi sẽ xuất hiện ở đây.',
                    ),
                  ...sessions
                      .take(4)
                      .map(
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
            final purpose = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'AI dùng cho việc gì?',
                    action: 'Phân tích',
                    onAction: onAnalytics,
                  ),
                  if (shares.isEmpty)
                    const Text('Chưa có công việc trong kỳ đã chọn.'),
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
                                value: summary.count == 0
                                    ? 0
                                    : p.count / summary.count,
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            );
            return c.maxWidth >= 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: latest),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: purpose),
                    ],
                  )
                : Column(
                    children: [latest, const SizedBox(height: 16), purpose],
                  );
          },
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class QuotaRow extends StatelessWidget {
  const QuotaRow({
    super.key,
    required this.account,
    required this.now,
    this.onTap,
    this.compact = false,
    this.quota,
  });
  final AIAccount account;
  final QuotaSnapshot? quota;
  final DateTime now;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final q = quota ?? account.quota;
    final stale = q?.isStale(now) ?? false;
    return ActionSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 0 : 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quota == null ? account.product : q!.window,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  q == null
                      ? 'Chưa có dữ liệu'
                      : stale
                      ? 'Cần cập nhật'
                      : 'Còn ${q.remainingPercent}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            AnimatedProgress(
              value: q == null || stale ? 0 : q.usedPercent / 100,
              semanticValue: q == null
                  ? 'Chưa có dữ liệu quota'
                  : stale
                  ? 'Quota đã quá reset; cần cập nhật'
                  : 'Đã dùng ${q.usedPercent}%',
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              q == null
                  ? 'Thêm quota từ trang tài khoản'
                  : '${q.window}${quota == null && account.quotaWindows.length > 1 ? ' · +${account.quotaWindows.length - 1} cửa sổ khác' : ''} · ${q.source.label} lúc ${shortTime(q.observedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class UsageRow extends StatelessWidget {
  const UsageRow({
    super.key,
    this.timezone = 'device',
    required this.session,
    required this.account,
    required this.onTap,
  });
  final UsageSession session;
  final String timezone;
  final AIAccount? account;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionSurface(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(purposeIcon(session.purpose), size: 22, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: AdaptivePair(
              breakpoint: 200,
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${account?.product ?? 'Tài khoản đã xóa'} · ${session.purpose.label} · ${shortDate(session.occurredAt, timezone: timezone)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    session.costMicros == null
                        ? '—'
                        : money(session.costMicros),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.knownTokens == null
                        ? 'Chưa biết'
                        : '${compactTokens(session.knownTokens)} token',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
