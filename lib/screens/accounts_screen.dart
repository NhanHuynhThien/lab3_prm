import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});
  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String _search = '';
  bool _archived = false;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ledgerProvider).requireValue;
    final now = ref.watch(clockProvider)();
    final accounts = data.accounts
        .where(
          (a) =>
              a.archived == _archived &&
              '${a.alias} ${a.product} ${a.provider}'.toLowerCase().contains(
                _search.toLowerCase(),
              ),
        )
        .toList();
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeading(
          'Tài khoản AI',
          'Quản lý công cụ, ngân sách và hạn mức của từng tài khoản.',
          action: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AccountFormScreen(),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm tài khoản'),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm tài khoản hoặc nhà cung cấp',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (s) => setState(() => _search = s),
              ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Đang dùng')),
                ButtonSegment(value: true, label: Text('Đã lưu trữ')),
              ],
              selected: {_archived},
              onSelectionChanged: (s) => setState(() => _archived = s.first),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (accounts.isEmpty)
          Panel(
            child: EmptyFeedback(
              title: 'Chưa có tài khoản phù hợp',
              message: _archived
                  ? 'Tài khoản đã lưu trữ vẫn giữ nguyên lịch sử sử dụng.'
                  : 'Thêm Claude, Codex hoặc công cụ AI khác để bắt đầu.',
              action: 'Thêm tài khoản',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AccountFormScreen(),
                ),
              ),
            ),
          ),
        ...accounts.map((a) {
          final summary = ref.watch(accountProjectionProvider(a.id)).summary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProviderAvatar(a),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.alias,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${a.provider} · ${a.billingMode.label}',
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
                                AccountDetailScreen(accountId: a.id),
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
                      _AccountFact(
                        'Chi phí tháng này',
                        money(summary.costMicros),
                      ),
                      _AccountFact(
                        'Token đã ghi',
                        compactTokens(summary.tokens),
                      ),
                      _AccountFact('Ngân sách tháng', money(a.budgetMicros)),
                      _AccountFact('Số phiên', '${summary.count}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedProgress(
                    value: a.budgetMicros == null || a.budgetMicros == 0
                        ? 0
                        : summary.costMicros / a.budgetMicros!,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.quota == null
                        ? 'Quota: chưa có dữ liệu'
                        : a.quota!.isStale(now)
                        ? 'Quota: cần cập nhật'
                        : 'Quota ${a.quota!.window}: còn ${a.quota!.remainingPercent}% · Nhập tay',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AccountFact extends StatelessWidget {
  const _AccountFact(this.label, this.value);
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
