import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auto_usage.dart';
import '../models/cloud_sync_status.dart';
import '../services/auto_usage_store.dart';

final autoUsageStoreProvider = Provider<AutoUsageStore>(
  (ref) => FirestoreAutoUsageStore(),
);

/// Companion rows of the signed-in UID. Lives in the session container, so a
/// logout or UID change disposes the listener with the rest of the workspace.
class AutoUsageViewModel extends Notifier<List<AutoUsageEntry>> {
  @override
  List<AutoUsageEntry> build() {
    final uid = ref.watch(cloudOwnerProvider);
    if (uid == null) return const [];
    try {
      final sub = ref.read(autoUsageStoreProvider).watch(uid).listen(
        (rows) {
          if (ref.mounted) state = List.unmodifiable(rows);
        },
        // Automatic rows are optional; the manual ledger keeps working.
        onError: (_) {},
      );
      ref.onDispose(() => unawaited(sub.cancel()));
    } catch (_) {
      // No Firestore in this build (tests, local mode): nothing to show.
    }
    return const [];
  }

  String get _uid =>
      ref.read(cloudOwnerProvider) ??
      (throw StateError('Cần đăng nhập để sửa dữ liệu tự động.'));

  Future<void> edit(String id, AutoUsageEdit edit) =>
      ref.read(autoUsageStoreProvider).edit(_uid, id, edit);

  Future<void> hide(String id) =>
      ref.read(autoUsageStoreProvider).hide(_uid, id);
}

final autoUsageProvider =
    NotifierProvider<AutoUsageViewModel, List<AutoUsageEntry>>(
      AutoUsageViewModel.new,
    );
