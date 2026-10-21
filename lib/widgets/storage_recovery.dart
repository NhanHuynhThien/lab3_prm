import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ledger_repository.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import 'common.dart';

class StorageRecovery extends ConsumerStatefulWidget {
  const StorageRecovery({super.key, required this.error});
  final Object error;
  @override
  ConsumerState<StorageRecovery> createState() => _StorageRecoveryState();
}

class _StorageRecoveryState extends ConsumerState<StorageRecovery> {
  bool _working = false;

  Future<void> _recover() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final confirmed = await confirmAction(
        context,
        'Khôi phục dữ liệu local?',
        'App sẽ sao lưu dữ liệu hiện tại trước khi thay bằng dữ liệu mẫu. Chỉ tiếp tục nếu bạn muốn thay thế không gian local này.',
        confirm: 'Sao lưu và khôi phục',
      );
      if (!confirmed || !mounted) return;
      await ref.read(ledgerProvider.notifier).recoverDemo();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorFeedback(
            message: ref.read(ledgerProvider.notifier).isCloud
                ? 'Không đọc được dữ liệu cloud. Demo local không thay thế dữ liệu của bạn. ${widget.error}'
                : 'Dữ liệu local chưa đọc được; không gian hiện tại chưa bị ghi đè. ${widget.error}',
            retry: _working
                ? null
                : () {
                    final vm = ref.read(ledgerProvider.notifier);
                    if (vm is CloudLedgerViewModel) {
                      vm.retry().catchError((Object error) {
                        if (context.mounted) {
                          showMessage(context, error.toString());
                        }
                      });
                    } else {
                      ref.invalidate(ledgerProvider);
                    }
                  },
          ),
          if (widget.error is LedgerStorageException)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: OutlinedButton(
                onPressed: _working ? null : _recover,
                child: Text(
                  _working ? 'Đang xử lý...' : 'Khôi phục dữ liệu local',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
