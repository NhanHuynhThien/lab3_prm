import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import 'cloud_ledger_repository.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_store.dart';
import 'ledger_validation.dart';
import 'reporting_calendar.dart';

/// Fixed owner for the entire lifetime. Construct only after Auth initialization.
/// Not connected to the local ViewModel: that would seed/upload local data.
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
    // Shared-device privacy: do not persist private ledger documents to disk.
    // Configure before the first Firestore operation; subsequent sessions reuse
    // the setting and always query only their immutable UID path.
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
    required this._store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    FirestoreLedgerCodec.segment(ownerId);
    _guard();
    _identity = _store.userIds.listen(
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
  final LedgerCloudStore _store;
  final DateTime Function() _now;
  final Set<Future<void> Function()> _listeners = {};
  bool _closed = false;
  bool _revoked = false;
  late final StreamSubscription<String?> _identity;
  String get _root => 'users/$ownerId';
  String _path(String collection, String id) {
    try {
      return '$_root/$collection/${FirestoreLedgerCodec.segment(id)}';
    } catch (error) {
      throw _failure(error);
    }
  }

  String _quotaPath(String accountId, String key) {
    try {
      return '$_root/quota_windows/${FirestoreLedgerCodec.quotaId(accountId, key)}';
    } catch (error) {
      throw _failure(error);
    }
  }

  String _labelPath(String accountId, String label) =>
      '$_root/quota_labels/${FirestoreLedgerCodec.quotaId(accountId, label.trim().toLowerCase())}';
  void _label(CloudMap? label, String accountId, String key) {
    if (label == null ||
        label.length != 3 ||
        label['ownerId'] != ownerId ||
        label['accountId'] != accountId ||
        label['windowKey'] != key) {
      _conflict();
    }
  }

  void _guard() {
    if (_closed) {
      throw const CloudLedgerFailure(
        CloudLedgerProblem.closed,
        'Không gian dữ liệu đã đóng.',
      );
    }
    if (_revoked || _store.currentUid != ownerId) {
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

  Stream<CloudSnapshot<T>> _watch<T>(
    String collection,
    CloudRecord<T> Function(String, CloudMap, String, {bool pending}) decode, {
    List<StoreFilter> filters = const [],
    required String orderBy,
  }) {
    late StreamController<CloudSnapshot<T>> controller;
    StreamSubscription<StoreSnapshot>? data;
    StreamSubscription<String?>? auth;
    var stopped = false;
    Future<void> stop() async {
      if (stopped) return;
      stopped = true;
      _listeners.remove(stop);
      await data?.cancel();
      await auth?.cancel();
      // Do not await close: a paused consumer must not block logout/disposal.
      unawaited(controller.close());
    }

    void fail(Object error) {
      if (stopped) return;
      controller.addError(_failure(error));
      unawaited(stop());
    }

    controller = StreamController<CloudSnapshot<T>>(
      onListen: () {
        try {
          _guard();
          _listeners.add(stop);
          auth = _store.userIds.listen((uid) {
            if (uid != ownerId) {
              fail(
                const CloudLedgerFailure(
                  CloudLedgerProblem.unauthenticated,
                  'Phiên đăng nhập đã thay đổi.',
                ),
              );
            }
          }, onError: fail);
          data = _store
              .watch('$_root/$collection', filters: filters, orderBy: orderBy)
              .listen(
                (event) {
                  if (stopped) return;
                  try {
                    _guard();
                    controller.add(
                      CloudSnapshot(
                        event.documents.map(
                          (doc) => decode(
                            doc.id,
                            doc.data,
                            ownerId,
                            pending: event.hasPendingWrites,
                          ),
                        ),
                        fromCache: event.fromCache,
                        hasPendingWrites: event.hasPendingWrites,
                      ),
                    );
                  } catch (error) {
                    fail(error);
                  }
                },
                onError: fail,
                onDone: () => unawaited(stop()),
              );
        } catch (error) {
          fail(error);
        }
      },
      onCancel: stop,
      onPause: () => data?.pause(),
      onResume: () => data?.resume(),
    );
    return controller.stream;
  }

  @override
  Stream<CloudSnapshot<AIAccount>> watchAccounts({bool? archived}) => _watch(
    'accounts',
    FirestoreLedgerCodec.account,
    filters: [if (archived != null) StoreFilter('payload.archived', archived)],
    orderBy: 'updatedAt',
  );
  @override
  Stream<CloudSnapshot<UsageSession>> watchAllUsage() => _watch(
    'usage_sessions',
    FirestoreLedgerCodec.usage,
    orderBy: 'payload.occurredAt',
  );
  @override
  Stream<CloudSnapshot<AccountQuota>> watchAllQuotas() =>
      _watch('quota_windows', FirestoreLedgerCodec.quota, orderBy: 'updatedAt');
  @override
  Stream<CloudSnapshot<CloudSettings>> watchSettings() =>
      _watch('settings', FirestoreLedgerCodec.settings, orderBy: 'updatedAt');
  @override
  Future<int> setReportingTimezone(
    String zone, {
    int? expectedRevision,
    required String operationId,
  }) async {
    ReportingCalendar.validateZone(zone);
    final path = _path('settings', 'reporting');
    final payload = {'reportingTimezone': zone};
    return _write(
      operationId,
      {
        'kind': 'settings',
        'payload': payload,
        'expectedRevision': expectedRevision,
      },
      (tx) async {
        final old = await tx.get(path);
        if (old == null) {
          if (expectedRevision != null) _missing();
        } else {
          _revision(
            expectedRevision,
            FirestoreLedgerCodec.settings('reporting', old, ownerId).revision,
          );
        }
        final revision = old == null ? 1 : _next(old['revision'] as int);
        tx.set(
          path,
          _envelope(payload, revision, old: old, operationId: operationId),
        );
        return revision;
      },
    );
  }

  @override
  Stream<CloudSnapshot<UsageSession>> watchUsage(CloudUsageQuery query) {
    if (query.accountId != null) FirestoreLedgerCodec.segment(query.accountId!);
    return _watch(
      'usage_sessions',
      FirestoreLedgerCodec.usage,
      filters: [
        StoreFilter(
          'payload.occurredAt',
          Timestamp.fromDate(query.start),
          '>=',
        ),
        StoreFilter('payload.occurredAt', Timestamp.fromDate(query.end), '<'),
        if (query.accountId != null)
          StoreFilter('payload.accountId', query.accountId!),
        if (query.purpose != null)
          StoreFilter('payload.purpose', query.purpose!.name),
      ],
      orderBy: 'payload.occurredAt',
    );
  }

  @override
  Stream<CloudSnapshot<AccountQuota>> watchQuotas(String accountId) {
    FirestoreLedgerCodec.segment(accountId);
    return _watch(
      'quota_windows',
      FirestoreLedgerCodec.quota,
      filters: [StoreFilter('payload.accountId', accountId)],
      orderBy: 'updatedAt',
    );
  }

  Never _conflict() => throw const CloudLedgerFailure(
    CloudLedgerProblem.conflict,
    'Dữ liệu đã đổi hoặc thao tác không còn hợp lệ. Hãy tải lại.',
  );
  Never _missing() => throw const CloudLedgerFailure(
    CloudLedgerProblem.notFound,
    'Bản ghi không còn tồn tại. Hãy tải lại.',
  );
  void _revision(int? expected, int actual) {
    if (expected == null || expected != actual) _conflict();
  }

  int _next(int revision) {
    if (revision >= LedgerValidation.maxExactInteger) _conflict();
    return revision + 1;
  }

  CloudMap _envelope(
    CloudMap payload,
    int revision, {
    CloudMap? old,
    required String operationId,
  }) => {
    'ownerId': ownerId,
    'schemaVersion': 1,
    'revision': revision,
    'createdAt': old?['createdAt'] ?? _store.serverTimestamp,
    'updatedAt': _store.serverTimestamp,
    'payload': FirestoreLedgerCodec.toFirestore(payload),
    'lastOperationId': operationId,
  };

  /// Receipt and entity/counter commit together. No lost-ack duplicate or retry
  /// resurrection after a later delete. Never expire receipts independently.
  Future<int> _write(
    String operationId,
    CloudMap intent,
    Future<int> Function(LedgerTransaction) action,
  ) async {
    try {
      _guard();
      final receiptPath = _path('mutations', operationId);
      final encoded = jsonEncode(intent);
      final kind = intent['kind'] as String;
      final payload = intent['payload'] as CloudMap?;
      final collection = kind.contains('Account')
          ? 'accounts'
          : kind.contains('Usage')
          ? 'usage_sessions'
          : kind == 'settings'
          ? 'settings'
          : 'quota_windows';
      final entityId = collection == 'settings'
          ? 'reporting'
          : collection == 'quota_windows'
          ? FirestoreLedgerCodec.quotaId(
              (payload ?? intent)['accountId'] as String,
              (payload ?? intent)['windowKey'] as String,
            )
          : (payload ?? intent)['id'] as String;
      final actionName = kind.startsWith('delete')
          ? 'delete'
          : kind.startsWith('update') || intent['expectedRevision'] != null
          ? 'update'
          : 'create';
      final result = await _store.transaction((tx) async {
        _guard();
        final receipt = await tx.get(receiptPath);
        _guard();
        if (receipt != null) {
          if (receipt.length != 8 ||
              receipt['collection'] != collection ||
              receipt['entityId'] != entityId ||
              receipt['action'] != actionName ||
              receipt['ownerId'] != ownerId ||
              receipt['intent'] != encoded ||
              receipt['schemaVersion'] is! int ||
              receipt['schemaVersion'] != 1 ||
              receipt['revision'] is! int ||
              (receipt['revision'] as int) < 1 ||
              (receipt['revision'] as int) > LedgerValidation.maxExactInteger ||
              receipt['createdAt'] is! Timestamp) {
            _conflict();
          }
          return receipt['revision'] as int;
        }
        final revision = await action(tx);
        _guard();
        tx.set(receiptPath, {
          'ownerId': ownerId,
          'schemaVersion': 1,
          'intent': encoded,
          'revision': revision,
          'createdAt': _store.serverTimestamp,
          'collection': collection,
          'entityId': entityId,
          'action': actionName,
        });
        return revision;
      });
      _guard();
      return result;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<int> createAccount(
    AIAccount account, {
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.accountPayload(account);
      final path = _path('accounts', account.id);
      return await _write(
        operationId,
        {'kind': 'createAccount', 'payload': payload},
        (tx) async {
          if (await tx.get(path) != null) _conflict();
          tx.set(path, {
            ..._envelope(payload, 1, operationId: operationId),
            'usageCount': 0,
            'quotaCount': 0,
            'lastUsageMutationId': null,
            'lastQuotaMutationId': null,
          });
          return 1;
        },
      );
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<int> updateAccount(
    AIAccount account, {
    required int expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.accountPayload(account);
      final path = _path('accounts', account.id);
      return await _write(
        operationId,
        {
          'kind': 'updateAccount',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path) ?? _missing();
          final record = FirestoreLedgerCodec.account(account.id, old, ownerId);
          _revision(expectedRevision, record.revision);
          if (!account.createdAt.isAtSameMomentAs(record.value.createdAt) ||
              account.isDemo != record.value.isDemo ||
              account.dataSource != record.value.dataSource) {
            _conflict();
          }
          final revision = _next(record.revision);
          tx.set(path, {
            ...old,
            ..._envelope(payload, revision, old: old, operationId: operationId),
          });
          return revision;
        },
      );
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> deleteAccount(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = _path('accounts', id);
    await _write(
      operationId,
      {'kind': 'deleteAccount', 'id': id, 'expectedRevision': expectedRevision},
      (tx) async {
        final old = await tx.get(path) ?? _missing();
        final record = FirestoreLedgerCodec.account(id, old, ownerId);
        _revision(expectedRevision, record.revision);
        if (record.usageCount != 0 || record.quotaCount != 0) _conflict();
        tx.delete(path);
        return record.revision;
      },
    );
  }

  @override
  Future<int> createUsage(UsageSession usage, {required String operationId}) =>
      _saveUsage(usage, operationId: operationId);
  @override
  Future<int> updateUsage(
    UsageSession usage, {
    required int expectedRevision,
    required String operationId,
  }) => _saveUsage(
    usage,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );
  Future<int> _saveUsage(
    UsageSession usage, {
    int? expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.usagePayload(usage);
      final path = _path('usage_sessions', usage.id);
      final parent = _path('accounts', usage.accountId);
      return await _write(
        operationId,
        {
          'kind': 'saveUsage',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path);
          final account = await tx.get(parent) ?? _missing();
          LedgerValidation.usage(usage, now: _now());
          final a = FirestoreLedgerCodec.account(
            usage.accountId,
            account,
            ownerId,
          );
          if (expectedRevision == null) {
            if (old != null ||
                a.value.archived ||
                a.value.isDemo != usage.isDemo) {
              _conflict();
            }
            final count = _next(a.usageCount);
            tx.set(parent, {
              ...account,
              'usageCount': count,
              'revision': _next(a.revision),
              'lastUsageMutationId': usage.id,
              'lastOperationId': operationId,
              'updatedAt': _store.serverTimestamp,
            });
          } else {
            if (old == null) _missing();
            final existing = FirestoreLedgerCodec.usage(usage.id, old, ownerId);
            _revision(expectedRevision, existing.revision);
            if (existing.value.accountId != usage.accountId ||
                existing.value.isDemo != usage.isDemo ||
                existing.value.dataSource != usage.dataSource) {
              _conflict();
            }
          }
          final revision = old == null ? 1 : _next(old['revision'] as int);
          tx.set(
            path,
            _envelope(payload, revision, old: old, operationId: operationId),
          );
          return revision;
        },
      );
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> deleteUsage(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = _path('usage_sessions', id);
    await _write(
      operationId,
      {'kind': 'deleteUsage', 'id': id, 'expectedRevision': expectedRevision},
      (tx) async {
        final old = await tx.get(path) ?? _missing();
        final usage = FirestoreLedgerCodec.usage(id, old, ownerId);
        _revision(expectedRevision, usage.revision);
        final parent = _path('accounts', usage.value.accountId);
        final account = await tx.get(parent) ?? _missing();
        final a = FirestoreLedgerCodec.account(
          usage.value.accountId,
          account,
          ownerId,
        );
        if (a.usageCount < 1) _conflict();
        tx.set(parent, {
          ...account,
          'usageCount': a.usageCount - 1,
          'revision': _next(a.revision),
          'lastUsageMutationId': id,
          'lastOperationId': operationId,
          'updatedAt': _store.serverTimestamp,
        });
        tx.delete(path);
        return usage.revision;
      },
    );
  }

  @override
  Future<int> createQuota(AccountQuota quota, {required String operationId}) =>
      _saveQuota(quota, operationId: operationId);
  @override
  Future<int> updateQuota(
    AccountQuota quota, {
    required int expectedRevision,
    required String operationId,
  }) => _saveQuota(
    quota,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );
  Future<int> _saveQuota(
    AccountQuota quota, {
    int? expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.quotaPayload(quota);
      final path = _quotaPath(quota.accountId, quota.snapshot.windowKey);
      final parent = _path('accounts', quota.accountId);
      return await _write(
        operationId,
        {
          'kind': 'saveQuota',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path);
          final account = await tx.get(parent) ?? _missing();
          final a = FirestoreLedgerCodec.account(
            quota.accountId,
            account,
            ownerId,
          );
          if (a.value.archived) _conflict();
          CloudRecord<AccountQuota>? existing;
          if (expectedRevision == null) {
            if (old != null) _conflict();
            LedgerValidation.quota(quota.snapshot, now: _now());
          } else {
            if (old == null) _missing();
            existing = FirestoreLedgerCodec.quota(
              path.split('/').last,
              old,
              ownerId,
            );
            _revision(expectedRevision, existing.revision);
            final previous = existing.value.snapshot;
            if (!previous.observedAt.isAtSameMomentAs(
                  quota.snapshot.observedAt,
                ) ||
                !previous.resetAt.isAtSameMomentAs(quota.snapshot.resetAt) ||
                previous.usedPercent != quota.snapshot.usedPercent) {
              LedgerValidation.quota(quota.snapshot, now: _now());
            }
          }
          final labelPath = _labelPath(quota.accountId, quota.snapshot.window);
          final label = await tx.get(labelPath);
          final previousLabelPath = existing == null
              ? null
              : _labelPath(quota.accountId, existing.value.snapshot.window);
          if (previousLabelPath != null) {
            final previousLabel = previousLabelPath == labelPath
                ? label
                : await tx.get(previousLabelPath);
            _label(previousLabel, quota.accountId, quota.snapshot.windowKey);
          }
          if (label != null && previousLabelPath != labelPath) _conflict();
          final revision = old == null ? 1 : _next(old['revision'] as int);
          if (previousLabelPath != null && previousLabelPath != labelPath) {
            tx.delete(previousLabelPath);
          }
          tx.set(labelPath, {
            'ownerId': ownerId,
            'accountId': quota.accountId,
            'windowKey': quota.snapshot.windowKey,
          });
          tx.set(
            path,
            _envelope(payload, revision, old: old, operationId: operationId),
          );
          tx.set(parent, {
            ...account,
            'quotaCount': old == null ? _next(a.quotaCount) : a.quotaCount,
            'revision': _next(a.revision),
            'lastQuotaMutationId': path.split('/').last,
            'lastOperationId': operationId,
            'updatedAt': _store.serverTimestamp,
          });
          return revision;
        },
      );
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> deleteQuota(
    String accountId,
    String windowKey, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = _quotaPath(accountId, windowKey);
    final parent = _path('accounts', accountId);
    await _write(
      operationId,
      {
        'kind': 'deleteQuota',
        'accountId': accountId,
        'windowKey': windowKey,
        'expectedRevision': expectedRevision,
      },
      (tx) async {
        final old = await tx.get(path) ?? _missing();
        final q = FirestoreLedgerCodec.quota(
          path.split('/').last,
          old,
          ownerId,
        );
        _revision(expectedRevision, q.revision);
        final account = await tx.get(parent) ?? _missing();
        final a = FirestoreLedgerCodec.account(accountId, account, ownerId);
        if (a.quotaCount < 1) _conflict();
        final labelPath = _labelPath(accountId, q.value.snapshot.window);
        _label(await tx.get(labelPath), accountId, windowKey);
        tx.set(parent, {
          ...account,
          'quotaCount': a.quotaCount - 1,
          'revision': _next(a.revision),
          'lastQuotaMutationId': path.split('/').last,
          'lastOperationId': operationId,
          'updatedAt': _store.serverTimestamp,
        });
        tx.delete(path);
        tx.delete(labelPath);
        return q.revision;
      },
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _identity.cancel();
    await Future.wait(_listeners.toList().map((stop) => stop()));
  }
}
