import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import 'common.dart';

class StorageRecovery extends ConsumerWidget {
  const StorageRecovery({super.key, required this.error});
  final Object error;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    child: ErrorFeedback(
      message: 'Chưa đọc được dữ liệu. Bản đã lưu được giữ nguyên. $error',
      retry: () {
        final vm = ref.read(ledgerProvider.notifier);
        if (vm is CloudLedgerViewModel) {
          vm.retry().catchError((Object error) {
            if (context.mounted) showMessage(context, error.toString());
          });
        } else {
          ref.invalidate(ledgerProvider);
        }
      },
    ),
  );
}
