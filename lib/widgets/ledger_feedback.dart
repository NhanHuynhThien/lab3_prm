import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import 'common.dart';
import 'storage_recovery.dart';

/// Routes above the shell must handle reload/error just like the shell itself.
Widget? ledgerFeedback(
  AsyncValue<LedgerData> state,
  String title, {
  bool missing = false,
}) {
  if (state.hasError) {
    return ContentPage(
      title: title,
      child: Center(child: StorageRecovery(error: state.error!)),
    );
  }
  if (state.isLoading || !state.hasValue) {
    return ContentPage(title: title, child: const LoadingFeedback());
  }
  if (missing) {
    return ContentPage(
      title: title,
      child: const EmptyFeedback(
        title: 'Không tìm thấy tài khoản',
        message: 'Tài khoản có thể đã bị xóa. Quay lại danh sách để kiểm tra.',
      ),
    );
  }
  return null;
}
