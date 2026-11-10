import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workspace_tab.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../models/cloud_sync_status.dart';
import '../widgets/account_card.dart';
import '../widgets/common.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/provider_ledger_feedback.dart';
import 'provider_connections_screen.dart';

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
    final feedback = ledgerFeedback(state, WorkspaceTab.accounts.label);
    final cloud = ref.watch(cloudOwnerProvider) != null;
    if (feedback != null) {
      return cloud ? ProviderLedgerFeedback(feedback: feedback) : feedback;
    }
    final data = state.requireValue;
    // Archived history exists only from older manual accounts.
    final hasArchived = data.accounts.any((a) => a.archived);
    final archived = _archived && hasArchived;
    final accounts = data.accounts
        .where(
          (a) =>
              a.archived == archived &&
              '${a.alias} ${a.product} ${a.provider}'.toLowerCase().contains(
                _search.toLowerCase(),
              ),
        )
        .toList();

    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeading(
          WorkspaceTab.accounts.label,
          'Companion tự thêm tài khoản khi bạn dùng Codex, Claude Code hoặc Gemini CLI.',
        ),
        if (data.accounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm tài khoản hoặc nhà cung cấp',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (s) => setState(() => _search = s),
            ),
          ),
        if (hasArchived)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SegmentedButton<bool>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: false, label: Text('Đang dùng')),
                ButtonSegment(value: true, label: Text('Đã lưu trữ')),
              ],
              selected: {archived},
              onSelectionChanged: (s) => setState(() => _archived = s.first),
            ),
          ),
        if (accounts.isEmpty)
          Panel(
            child: EmptyFeedback(
              title: _search.isEmpty
                  ? 'Chưa có tài khoản nào'
                  : 'Không có tài khoản phù hợp',
              message: _search.isEmpty
                  ? 'Mở Companion trên máy tính, đăng nhập cùng tài khoản Google và bật đồng bộ.'
                  : 'Thử từ khóa khác.',
              action: _search.isEmpty ? 'Kết nối nguồn AI' : null,
              onAction: _search.isEmpty
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProviderConnectionsScreen(),
                      ),
                    )
                  : null,
            ),
          ),
        ...accounts.map((a) => AccountCard(key: ValueKey(a.id), account: a)),
      ],
    );
  }
}
