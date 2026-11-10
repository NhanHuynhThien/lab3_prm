import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auto_usage.dart';
import '../models/ledger.dart';
import '../screens/account_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/reporting_viewmodel.dart';
import 'common.dart';
import 'token_limit_dialog.dart';

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
            const SizedBox(height: AppSpace.lg),
            TokenMeter(
              limitKey: account.id,
              tokens: summary.tokens,
              caption: 'token kỳ này',
              // Subscriptions bill a flat fee: no per-session cost to show.
              footer: isAutoId(account.id)
                  ? '${summary.count} phiên'
                  : '${money(summary.costMicros)} · ${summary.count} phiên',
            ),
          ],
        ),
      ),
    );
  }
}
