import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_ledger.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/firestore_ledger_repository.dart';

final cloudRepositoryFactoryProvider =
    Provider<CloudLedgerRepository Function()>(
      (ref) => FirestoreLedgerRepository.forCurrentUser,
    );

final cloudOwnerProvider = Provider<String?>((ref) => null);

final cloudRepositoryProvider = Provider.autoDispose<CloudLedgerRepository>((
  ref,
) {
  final repo = ref.read(cloudRepositoryFactoryProvider)();
  if (repo.ownerId != ref.read(cloudOwnerProvider)) {
    unawaited(repo.close());
    throw const CloudLedgerFailure(
      CloudLedgerProblem.unauthenticated,
      'Phiên đã thay đổi.',
    );
  }
  ref.onDispose(() => unawaited(repo.close()));
  return repo;
});

class CloudSyncStatus {
  const CloudSyncStatus({
    this.loading = true,
    this.fromCache = false,
    this.pending = false,
    this.error,
    this.coherent = false,
  });

  final bool loading, fromCache, pending, coherent;
  final Object? error;

  bool get confirmed =>
      !loading && !fromCache && !pending && coherent && error == null;

  String get label => error != null
      ? 'Lỗi kết nối'
      : loading || !coherent
      ? 'Đang đồng bộ'
      : pending
      ? 'Chờ xác nhận'
      : fromCache
      ? 'Bản lưu cache'
      : 'Đã kết nối';
}
