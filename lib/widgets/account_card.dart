import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../screens/account_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import 'common.dart';

class AccountFact extends StatelessWidget {
  const AccountFact(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class AccountCard extends ConsumerWidget {
  const AccountCard({super.key, required this.account});

  final AIAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = ref.watch(accountProjectionProvider(account.id));
    final now = ref.watch(nowProvider);
    final summary = projection.summary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProviderAvatar(account),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.alias,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${account.provider} · ${account.billingMode.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mở chi tiết tài khoản',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AccountDetailScreen(accountId: account.id),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                AccountFact('Chi phí kỳ này', money(summary.costMicros)),
                AccountFact('Token đã ghi', compactTokens(summary.tokens)),
                AccountFact(
                  'Ngân sách kỳ',
                  account.budgetMicros == null
                      ? 'Chưa đặt'
                      : money(account.budgetMicros),
                ),
                AccountFact('Số phiên', '${summary.count}'),
              ],
            ),
            const SizedBox(height: 20),
            if (account.budgetMicros != null) ...[
              AnimatedProgress(
                value: projection.budgetProgress,
                color: (projection.remainingBudgetMicros ?? 0) < 0
                    ? AppColors.danger
                    : AppColors.primary,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              account.quotaWindows.isEmpty
                  ? 'Quota: chưa có dữ liệu'
                  : '${account.quotaWindows.length} cửa sổ quota · ${account.quotaWindows.where((q) => q.isStale(now)).length} cần cập nhật · Xem chi tiết',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
