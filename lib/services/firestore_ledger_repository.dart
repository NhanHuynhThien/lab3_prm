import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import 'cloud_ledger_repository.dart';
import 'firestore_account_usage_writer.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_store.dart';
import 'firestore_ledger_transactions.dart';
import 'firestore_quota_writer.dart';
import 'firestore_stream_watcher.dart';

class FirestoreLedgerRepository implements CloudLedgerRepository {
  factory FirestoreLedgerRepository.forCurrentUser() {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw const CloudLedgerFailure(
        CloudLedgerProblem.unauthenticated,
        'Cần đăng nhập trước khi mở dữ liệu cloud.',
      );
    }
    final firestore = FirebaseFirestore.instance;
    if (firestore.settings.persistenceEnabled != false) {
      firestore.settings = const Settings(persistenceEnabled: false);
    }
    return FirestoreLedgerRepository(
      ownerId: uid,
      store: FirestoreLedgerStore(firestore: firestore, auth: auth),
    );
  }

  FirestoreLedgerRepository({
    required this.ownerId,
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    FirestoreLedgerCodec.segment(ownerId);
    _runner = FirestoreTransactionRunner(
      ownerId: ownerId,
      store: store,
      guard: _guard,
      failure: _failure,
    );
    _accountUsageWriter = FirestoreAccountUsageWriter(
      runner: _runner,
      now: _now,
    );
    _quotaWriter = FirestoreQuotaWriter(runner: _runner, now: _now);
    _watcher = FirestoreStreamWatcher(
      ownerId: ownerId,
      store: store,
      guard: _guard,
      failure: _failure,
      listeners: _listeners,
    );
    _guard();
    _identity = store.userIds.listen(
      (uid) {
        if (uid != ownerId) _revoked = true;
      },
      onError: (Object error) {
        _revoked = true;
      },
    );
  }

  @override
  final String ownerId;
  final LedgerCloudStore store;
  final DateTime Function() _now;
  late final FirestoreTransactionRunner _runner;
  late final FirestoreAccountUsageWriter _accountUsageWriter;
  late final FirestoreQuotaWriter _quotaWriter;
  late final FirestoreStreamWatcher _watcher;
  final Set<Future<void> Function()> _listeners = {};
  bool _closed = false;
  bool _revoked = false;
  late final StreamSubscription<String?> _identity;

  void _guard() {
    if (_closed) {
      throw const CloudLedgerFailure(
        CloudLedgerProblem.closed,
        'Không gian dữ liệu đã đóng.',
      );
    }
    if (_revoked || store.currentUid != ownerId) {
      _revoked = true;
      throw const CloudLedgerFailure(
        CloudLedgerProblem.unauthenticated,
        'Phiên đăng nhập đã thay đổi. Hãy mở lại không gian dữ liệu.',
      );
    }
  }

  CloudLedgerFailure _failure(Object error) {
    if (error is CloudLedgerFailure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const CloudLedgerFailure(
          CloudLedgerProblem.permission,
          'Chưa có quyền truy cập dữ liệu. Kiểm tra Security Rules.',
        ),
        'unauthenticated' => const CloudLedgerFailure(
          CloudLedgerProblem.unauthenticated,
          'Cần đăng nhập lại để truy cập dữ liệu.',
        ),
        'aborted' || 'already-exists' => const CloudLedgerFailure(
          CloudLedgerProblem.conflict,
          'Dữ liệu đã đổi. Hãy tải lại trước khi lưu.',
        ),
        _ => const CloudLedgerFailure(
          CloudLedgerProblem.unavailable,
          'Chưa xác nhận được kết quả từ máy chủ. Giữ bản nháp và thử lại.',
        ),
      };
    }
    return const CloudLedgerFailure(
      CloudLedgerProblem.invalidData,
      'Dữ liệu không hợp lệ hoặc phiên bản chưa được hỗ trợ.',
    );
  }

  @override
  Stream<CloudSnapshot<AIAccount>> watchAccounts({bool? archived}) =>
      _watcher.watchAccounts(archived: archived);

  @override
  Stream<CloudSnapshot<UsageSession>> watchAllUsage() =>
      _watcher.watchAllUsage();

  @override
  Stream<CloudSnapshot<AccountQuota>> watchAllQuotas() =>
      _watcher.watchAllQuotas();

  @override
  Stream<CloudSnapshot<CloudSettings>> watchSettings() =>
      _watcher.watchSettings();

  @override
  Stream<CloudSnapshot<UsageSession>> watchUsage(CloudUsageQuery query) =>
      _watcher.watchUsage(query);

  @override
  Stream<CloudSnapshot<AccountQuota>> watchQuotas(String accountId) =>
      _watcher.watchQuotas(accountId);

  @override
  Future<int> setReportingTimezone(
    String zone, {
    int? expectedRevision,
    required String operationId,
  }) => _quotaWriter.setReportingTimezone(
    zone,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<int> createAccount(AIAccount account, {required String operationId}) =>
      _accountUsageWriter.createAccount(account, operationId: operationId);

  @override
  Future<int> updateAccount(
    AIAccount account, {
    required int expectedRevision,
    required String operationId,
  }) => _accountUsageWriter.updateAccount(
    account,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<void> deleteAccount(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) => _accountUsageWriter.deleteAccount(
    id,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<int> createUsage(UsageSession usage, {required String operationId}) =>
      _accountUsageWriter.createUsage(usage, operationId: operationId);

  @override
  Future<int> updateUsage(
    UsageSession usage, {
    required int expectedRevision,
    required String operationId,
  }) => _accountUsageWriter.updateUsage(
    usage,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<void> deleteUsage(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) => _accountUsageWriter.deleteUsage(
    id,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<int> createQuota(AccountQuota quota, {required String operationId}) =>
      _quotaWriter.createQuota(quota, operationId: operationId);

  @override
  Future<int> updateQuota(
    AccountQuota quota, {
    required int expectedRevision,
    required String operationId,
  }) => _quotaWriter.updateQuota(
    quota,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<void> deleteQuota(
    String accountId,
    String windowKey, {
    required int expectedRevision,
    required String operationId,
  }) => _quotaWriter.deleteQuota(
    accountId,
    windowKey,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  @override
  Future<void> close() async {
    _closed = true;
    await _identity.cancel();
    await Future.wait(_listeners.toList().map((stop) => stop()));
  }
}
