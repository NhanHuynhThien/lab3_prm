import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/ledger_viewmodel.dart';
import '../models/cloud_sync_status.dart';
import '../widgets/account_card.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/provider_ledger_feedback.dart';
import 'account_form_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String _search = '';
  final _searchController = TextEditingController();
  bool _archived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Tài khoản AI');
    final cloud = ref.watch(cloudOwnerProvider) != null;
    if (feedback != null) {
      return cloud ? ProviderLedgerFeedback(feedback: feedback) : feedback;
    }
    final data = state.requireValue;
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
          'Tài khoản tự ghi, token và giới hạn cảnh báo.',
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm tài khoản hoặc nhà cung cấp',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (s) => setState(() => _search = s),
              ),
            ),
            const SizedBox(width: 4),
            const DataScopePicker(),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(value: false, label: Text('Đang dùng')),
            ButtonSegment(value: true, label: Text('Đã lưu trữ')),
          ],
          selected: {_archived},
          onSelectionChanged: (s) => setState(() => _archived = s.first),
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
        ...accounts.map((a) => AccountCard(key: ValueKey(a.id), account: a)),
      ],
    );
  }
}
