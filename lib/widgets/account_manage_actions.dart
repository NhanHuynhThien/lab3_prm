import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auto_usage.dart';
import '../models/ledger.dart';
import '../screens/history_screen.dart';
import '../screens/usage_form_screen.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'common.dart';

/// Log, history, archive and delete actions under an account. Companion
/// accounts fill and maintain themselves, so they only offer history.
class AccountManageActions extends ConsumerWidget {
  const AccountManageActions({
    super.key,
    required this.account,
    required this.sessionCount,
  });
  final AIAccount account;
  final int sessionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = account;
    final auto = isAutoId(a.id);
    final ledger = ref.read(ledgerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (auto)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Tự động từ Companion: phiên, token và hạn mức cập nhật mỗi lần '
              'đồng bộ. Mở từng phiên để sửa mục đích hoặc ẩn phiên.',
            ),
          ),
        if (!a.archived && !auto)
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
              builder: (_) =>
                  HistoryScreen(accountId: a.id, useAccountCycle: true),
            ),
          ),
          icon: const Icon(Icons.history),
          label: const Text('Lịch sử tài khoản'),
        ),
        if (!auto) ...[
          const SizedBox(height: 24),
          ConfirmedActionButton(
            label: a.archived ? 'Khôi phục tài khoản' : 'Lưu trữ tài khoản',
            icon: a.archived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            title: a.archived ? 'Khôi phục tài khoản?' : 'Lưu trữ tài khoản?',
            message: a.archived
                ? 'Tài khoản sẽ có thể ghi phiên mới.'
                : 'Lịch sử được giữ nguyên. Tài khoản không nhận phiên mới.',
            onConfirm: () => ledger.archiveAccount(a.id, !a.archived),
          ),
          if (sessionCount == 0 && a.quotaWindows.isNotEmpty)
            const Text(
              'Xóa các cửa sổ hạn mức ở trên để có thể xóa tài khoản này.',
            ),
          if (sessionCount == 0 && a.quotaWindows.isEmpty)
            ConfirmedActionButton(
              label: 'Xóa tài khoản rỗng',
              icon: Icons.delete_outline,
              destructive: true,
              title: 'Xóa ${a.alias}?',
              message:
                  'Tài khoản rỗng sẽ bị xóa vĩnh viễn. Không thể hoàn tác.',
              onConfirm: () => ledger.deleteAccount(a.id),
              onSuccess: () => Navigator.pop(context),
            ),
        ],
      ],
    );
  }
}
