import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import 'account_form_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'quota_form_screen.dart';
import 'usage_form_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ledgerProvider).requireValue;
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
    final now = ref.watch(clockProvider)();
    final projection = ref.watch(accountProjectionProvider(a.id));
    final summary = projection.summary;
    final allCount = projection.totalSessions;
    final shares = projection.shares;
    return ContentPage(
      title: a.alias,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              ProviderAvatar(a, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.product,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${a.provider} · ${a.billingMode.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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
                Text(
                  'Ngân sách còn lại · Tháng ${now.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  a.budgetMicros == null
                      ? 'Chưa đặt ngân sách'
                      : money(a.budgetMicros! - summary.costMicros),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                AnimatedProgress(
                  value: a.budgetMicros == null || a.budgetMicros == 0
                      ? 0
                      : summary.costMicros / a.budgetMicros!,
                ),
                const SizedBox(height: 12),
                Text(
                  'Đã ghi ${money(summary.costMicros)} · ${compactTokens(summary.tokens)} token · ${summary.count} phiên',
                ),
                if (summary.unknownCost > 0)
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
                  'Hạn mức đã ghi nhận',
                  action: 'Cập nhật',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => QuotaFormScreen(account: a),
                    ),
                  ),
                ),
                QuotaRow(account: a, now: now),
                if (a.quota != null)
                  Text(
                    'Reset: ${shortDate(a.quota!.resetAt)} lúc ${shortTime(a.quota!.resetAt)} · Nguồn: nhập tay',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Không tự quy đổi hạn mức thuê bao thành số token.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
                  const Text('Chưa có công việc trong tháng này.'),
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
          if (!a.archived)
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UsageFormScreen(accountId: a.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ghi sử dụng cho tài khoản'),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => HistoryScreen(accountId: a.id),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Lịch sử tài khoản'),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () async {
              if (!await confirmAction(
                context,
                a.archived ? 'Khôi phục tài khoản?' : 'Lưu trữ tài khoản?',
                a.archived ? 'Tài khoản sẽ có thể ghi phiên mới.' : 'Lịch sử được giữ nguyên. Tài khoản không nhận phiên mới.',
              )) {
                return;
              }
              try {
                await ref
                    .read(ledgerProvider.notifier)
                    .archiveAccount(a.id, !a.archived);
              } catch (e) {
                if (context.mounted) showMessage(context, e.toString());
              }
            },
            icon: Icon(
              a.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            label: Text(
              a.archived ? 'Khôi phục tài khoản' : 'Lưu trữ tài khoản',
            ),
          ),
          if (allCount == 0)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () async {
                if (!await confirmAction(
                  context,
                  'Xóa ${a.alias}?',
                  'Tài khoản rỗng sẽ bị xóa khỏi dữ liệu trên thiết bị.',
                  confirm: 'Xóa tài khoản',
                )) {
                  return;
                }
                try {
                  await ref.read(ledgerProvider.notifier).deleteAccount(a.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) showMessage(context, e.toString());
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa tài khoản rỗng'),
            ),
        ],
      ),
    );
  }
}
