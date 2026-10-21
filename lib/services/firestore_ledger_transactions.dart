import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_ledger.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_store.dart';
import 'ledger_validation.dart';

class FirestoreTransactionRunner {
  FirestoreTransactionRunner({
    required this.ownerId,
    required this.store,
    required this.guard,
    required this.failure,
  });

  final String ownerId;
  final LedgerCloudStore store;
  final void Function() guard;
  final CloudLedgerFailure Function(Object) failure;

  String get root => 'users/$ownerId';

  String path(String collection, String id) {
    try {
      return '$root/$collection/${FirestoreLedgerCodec.segment(id)}';
    } catch (error) {
      throw failure(error);
    }
  }

  String quotaPath(String accountId, String key) {
    try {
      return '$root/quota_windows/${FirestoreLedgerCodec.quotaId(accountId, key)}';
    } catch (error) {
      throw failure(error);
    }
  }

  String labelPath(String accountId, String label) =>
      '$root/quota_labels/${FirestoreLedgerCodec.quotaId(accountId, label.trim().toLowerCase())}';

  Never conflict() => throw const CloudLedgerFailure(
    CloudLedgerProblem.conflict,
    'Dữ liệu đã đổi hoặc thao tác không còn hợp lệ. Hãy tải lại.',
  );

  Never missing() => throw const CloudLedgerFailure(
    CloudLedgerProblem.notFound,
    'Bản ghi không còn tồn tại. Hãy tải lại.',
  );

  void checkRevision(int? expected, int actual) {
    if (expected == null || expected != actual) conflict();
  }

  int next(int revision) {
    if (revision >= LedgerValidation.maxExactInteger) conflict();
    return revision + 1;
  }

  CloudMap envelope(
    CloudMap payload,
    int revision, {
    CloudMap? old,
    required String operationId,
  }) => {
    'ownerId': ownerId,
    'schemaVersion': 1,
    'revision': revision,
    'createdAt': old?['createdAt'] ?? store.serverTimestamp,
    'updatedAt': store.serverTimestamp,
    'payload': FirestoreLedgerCodec.toFirestore(payload),
    'lastOperationId': operationId,
  };

  Future<int> write(
    String operationId,
    CloudMap intent,
    Future<int> Function(LedgerTransaction) action,
  ) async {
    try {
      guard();
      final receiptPath = path('mutations', operationId);
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
      final result = await store.transaction((tx) async {
        guard();
        final receipt = await tx.get(receiptPath);
        guard();
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
            conflict();
          }
          return receipt['revision'] as int;
        }
        final revision = await action(tx);
        guard();
        tx.set(receiptPath, {
          'ownerId': ownerId,
          'schemaVersion': 1,
          'intent': encoded,
          'revision': revision,
          'createdAt': store.serverTimestamp,
          'collection': collection,
          'entityId': entityId,
          'action': actionName,
        });
        return revision;
      });
      guard();
      return result;
    } catch (error) {
      throw failure(error);
    }
  }
}
