import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class CloudSyncBanner extends ConsumerStatefulWidget {
  const CloudSyncBanner({super.key});
  @override
  ConsumerState<CloudSyncBanner> createState() => _CloudSyncBannerState();
}

class _CloudSyncBannerState extends ConsumerState<CloudSyncBanner> {
  bool _retrying = false;
  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final vm = ref.read(ledgerProvider.notifier);
      if (vm is CloudLedgerViewModel) await vm.retry();
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(cloudSyncProvider);
    if (status.confirmed) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.soft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                status.error != null
                    ? '${status.label}: ${status.error}'
                    : '${status.label}. Chỉ lưu thay đổi khi máy chủ đã xác nhận dữ liệu.',
              ),
            ),
            TextButton(
              onPressed: _retrying ? null : _retry,
              child: Text(_retrying ? 'Đang tải...' : 'Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
