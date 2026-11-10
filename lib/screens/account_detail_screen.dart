import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../services/reporting_calendar.dart';
import '../widgets/data_scope_picker.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../models/auto_usage.dart';
import '../widgets/account_manage_actions.dart';
import '../widgets/common.dart';
import '../widgets/ledger_feedback.dart';
import 'account_form_screen.dart';
import 'dashboard_screen.dart';
import 'quota_form_screen.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;
  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  String get accountId => widget.accountId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(productFeaturesProvider.notifier).detail('account');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Tài khoản');
    if (feedback != null) return feedback;
    final data = state.requireValue;
    final a = data.account(accountId);
    if (a == null) {
      return const ContentPage(
        title: 'Tài khoản',
        child: EmptyFeedback(
          title: 'Không tìm thấy tài khoản',
          message: 'Tài khoản có thể đã bị xóa.',
        ),
      );
    }
    final now = ref.watch(nowProvider);
    final projection = ref.watch(accountProjectionProvider(a.id));
    final summary = projection.summary;
    final allCount = projection.totalSessions;
    final shares = projection.shares;
    final auto = isAutoId(a.id);
    final text = Theme.of(context).textTheme;
    return ContentPage(
      title: a.alias,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const DataScopePicker(),
          // The app bar already names the account; this row adds context.
          Row(
            children: [
              ProviderAvatar(a, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.product != a.alias)
                      Text(a.product, style: text.titleLarge),
                    Text(
                      '${a.provider} · ${a.billingMode.label}',
                      style: text.bodyMedium,
                    ),
                    Text(
                      'Kỳ bắt đầu ngày ${a.cycleStartDay} · ${ReportingCalendar.zoneLabel(a.timezone)}',
                      style: text.bodySmall,
                    ),
                    if (a.defaultModelId != null)
                      Text(
                        'Model gợi ý: ${a.defaultModelId}',
                        style: text.bodySmall,
                      ),
                    if (a.defaultPurposes.isNotEmpty)
                      Text(
                        'Mục đích gợi ý: ${a.defaultPurposes.map((p) => p.label).join(', ')}',
                        style: text.bodySmall,
                      ),
                  ],
                ),
              ),
              if (!auto)
                IconButton(
                  tooltip: 'Sửa tài khoản',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AccountFormScreen(account: a),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Panel(
            color: AppColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auto)
                  Text(
                    'Kỳ hiện tại · Gói thuê bao, Companion không đọc được hóa đơn',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Text(
                    'Ngân sách còn lại · Kỳ hiện tại · Theo nguồn đã chọn',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (projection.periodStart != null)
                  Text(
                    'Từ ${ReportingCalendar.dayKey(projection.periodStart!, a.timezone)} đến trước ${ReportingCalendar.dayKey(projection.periodEnd!, a.timezone)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (!auto) ...[
                  const SizedBox(height: 8),
                  Text(
                    a.budgetMicros == null
                        ? 'Chưa đặt ngân sách'
                        : money(projection.remainingBudgetMicros),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  AnimatedProgress(
                    value: projection.budgetProgress,
                    semanticValue: a.budgetMicros == null
                        ? 'Chưa đặt ngân sách'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  auto
                      ? '${compactTokens(summary.tokens)} token · ${summary.count} phiên'
                      : 'Đã ghi ${money(summary.costMicros)} · ${compactTokens(summary.tokens)} token · ${summary.count} phiên',
                ),
                if (!auto && summary.unknownCost > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${summary.unknownCost} phiên chưa biết chi phí.',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Hạn mức hiện tại',
                  action: a.archived || auto ? null : 'Thêm cửa sổ',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          QuotaFormScreen(account: a, newWindow: true),
                    ),
                  ),
                ),
                if (a.archived)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tài khoản đã lưu trữ. Khôi phục để cập nhật hạn mức.',
                    ),
                  ),
                if (a.quotaWindows.isEmpty)
                  const Text('Chưa có cửa sổ hạn mức nào.'),
                for (final q in a.quotaWindows) ...[
                  QuotaRow(
                    account: a,
                    quota: q,
                    now: now,
                    onTap: a.archived || auto
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  QuotaFormScreen(account: a, quota: q),
                            ),
                          ),
                  ),
                  Text(
                    'Quan sát ${shortDate(q.observedAt)} ${shortTime(q.observedAt)} · Reset ${shortDate(q.resetAt)} ${shortTime(q.resetAt)} · giờ thiết bị',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (q.sourceLabel.isNotEmpty) Text('Nguồn: ${q.sourceLabel}'),
                  if (q.note.isNotEmpty) Text(q.note),
                  if (!auto)
                    ConfirmedActionButton(
                      label: 'Xóa cửa sổ ${q.window}',
                      icon: Icons.delete_outline,
                      destructive: true,
                      title: 'Xóa cửa sổ hạn mức?',
                      message: 'Chỉ xóa snapshot này; không thay usage hoặc các cửa sổ khác.',
                      onConfirm: () => ref
                          .read(ledgerProvider.notifier)
                          .deleteQuota(a.id, q.windowKey),
                    ),
                  const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Dùng cho công việc gì?'),
                if (shares.isEmpty)
                  const Text('Chưa có công việc trong kỳ này.'),
                ...shares.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          purposeIcon(p.purpose),
                          size: 20,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.purpose.label)),
                        Text('${p.count} phiên'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AccountManageActions(account: a, sessionCount: allCount),
        ],
      ),
    );
  }
}
