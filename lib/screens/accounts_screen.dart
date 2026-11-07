import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/ledger_viewmodel.dart';
import '../models/cloud_sync_status.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../widgets/account_card.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/provider_sync_summary.dart';
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
    final hasSources = ref.watch(hasObservedSourcesProvider);
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
        if (cloud && hasSources) ...[
          const ProviderSyncSummary(),
          const SizedBox(height: 24),
          const SectionTitle('Sổ tài khoản nhập tay'),
        ],
        const DataScopePicker(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm tài khoản hoặc nhà cung cấp',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (s) => setState(() => _search = s),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(value: false, label: Text('Đang dùng')),
                  ButtonSegment(value: true, label: Text('Đã lưu trữ')),
                ],
                selected: {_archived},
                onSelectionChanged: (s) => setState(() => _archived = s.first),
              ),
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
        ...accounts.map((a) => AccountCard(key: ValueKey(a.id), account: a)),
        if (!cloud && hasSources) ...[
          const SizedBox(height: 16),
          const ProviderSyncSummary(),
        ],
      ],
    );
  }
}
