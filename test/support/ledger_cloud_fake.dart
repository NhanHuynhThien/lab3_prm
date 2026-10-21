import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:token_ledger/services/firestore_ledger_store.dart';

/// Test-only optimistic transactions. This does NOT evaluate Security Rules.
class LedgerCloudFake implements LedgerCloudStore {
  String? uid = 'A';
  final documents = <String, CloudMap>{};
  final _versions = <String, int>{};
  final identity = StreamController<String?>.broadcast(sync: true);
  final changes = StreamController<void>.broadcast(sync: true);
  Object? failNext;
  Object? failAfterCommit;
  void Function()? beforeCommit;
  var transactionAttempts = 0;
  var activeListeners = 0;
  String? lastCollection, lastOrder;
  List<StoreFilter> lastFilters = [];
  bool fromCache = false, pending = false;
  @override
  String? get currentUid => uid;
  @override
  Stream<String?> get userIds => identity.stream;
  @override
  Object get serverTimestamp => Timestamp.fromDate(DateTime.utc(2026, 10, 21));
  void signIn(String? value) {
    uid = value;
    identity.add(value);
  }

  CloudMap? copy(CloudMap? value) => value == null
      ? null
      : {
          for (final e in value.entries)
            e.key: e.value is Map
                ? copy(Map<String, dynamic>.from(e.value as Map))
                : e.value is List
                ? List.of(e.value as List)
                : e.value,
        };
  @override
  Stream<StoreSnapshot> watch(
    String collection, {
    List<StoreFilter> filters = const [],
    required String orderBy,
  }) {
    lastCollection = collection;
    lastFilters = filters;
    lastOrder = orderBy;
    Object? field(CloudMap data, String key) {
      Object? value = data;
      for (final part in key.split('.')) {
        value = (value as Map)[part];
      }
      return value;
    }

    int compare(Object a, Object b) => a is Timestamp
        ? a.compareTo(b as Timestamp)
        : (a as Comparable).compareTo(b);
    StoreSnapshot snapshot() {
      final records =
          documents.entries
              .where(
                (e) =>
                    e.key.startsWith('$collection/') &&
                    e.key.split('/').length == 4,
              )
              .where(
                (e) => filters.every((filter) {
                  final value = field(e.value, filter.field);
                  return switch (filter.operator) {
                    '==' => value == filter.value,
                    '>=' => compare(value!, filter.value) >= 0,
                    '<' => compare(value!, filter.value) < 0,
                    _ => false,
                  };
                }),
              )
              .toList()
            ..sort(
              (a, b) =>
                  compare(field(b.value, orderBy)!, field(a.value, orderBy)!),
            );
      return StoreSnapshot(
        records
            .map((e) => StoreDocument(e.key.split('/').last, copy(e.value)!))
            .toList(),
        fromCache: fromCache,
        hasPendingWrites: pending,
      );
    }

    late StreamController<StoreSnapshot> controller;
    StreamSubscription<void>? sub;
    controller = StreamController(
      onListen: () {
        activeListeners++;
        sub = changes.stream.listen(
          (_) => controller.add(snapshot()),
          onError: controller.addError,
        );
        controller.add(snapshot());
      },
      onCancel: () async {
        activeListeners--;
        await sub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(LedgerTransaction) action) async {
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
    for (var attempt = 0; attempt < 10; attempt++) {
      transactionAttempts++;
      final tx = _FakeTransaction(this);
      final result = await action(tx);
      beforeCommit?.call();
      beforeCommit = null;
      if (tx.versions.entries.any((e) => (_versions[e.key] ?? 0) != e.value)) {
        continue;
      }
      for (final e in tx.writes.entries) {
        if (e.value == null) {
          documents.remove(e.key);
        } else {
          documents[e.key] = copy(e.value)!;
        }
        _versions[e.key] = (_versions[e.key] ?? 0) + 1;
      }
      changes.add(null);
      final lost = failAfterCommit;
      failAfterCommit = null;
      if (lost != null) throw lost;
      return result;
    }
    throw FirebaseException(plugin: 'cloud_firestore', code: 'aborted');
  }

  Future<void> close() async {
    await identity.close();
    await changes.close();
  }
}

class _FakeTransaction implements LedgerTransaction {
  _FakeTransaction(this.store);
  final LedgerCloudFake store;
  final versions = <String, int>{};
  final writes = <String, CloudMap?>{};
  @override
  Future<CloudMap?> get(String path) async {
    if (writes.isNotEmpty) throw StateError('Read after write in transaction');
    versions[path] = store._versions[path] ?? 0;
    return store.copy(store.documents[path]);
  }

  @override
  void set(String path, CloudMap data) {
    writes[path] = data;
  }

  @override
  void delete(String path) {
    writes[path] = null;
  }
}
