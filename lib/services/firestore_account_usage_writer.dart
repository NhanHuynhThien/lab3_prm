import '../models/ledger.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_transactions.dart';
import 'ledger_validation.dart';

class FirestoreAccountUsageWriter {
  FirestoreAccountUsageWriter({required this.runner, required this.now});

  final FirestoreTransactionRunner runner;
  final DateTime Function() now;

  Future<int> createAccount(
    AIAccount account, {
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.accountPayload(account);
      final path = runner.path('accounts', account.id);
      return await runner.write(
        operationId,
        {'kind': 'createAccount', 'payload': payload},
        (tx) async {
          if (await tx.get(path) != null) runner.conflict();
          tx.set(path, {
            ...runner.envelope(payload, 1, operationId: operationId),
            'usageCount': 0,
            'quotaCount': 0,
            'lastUsageMutationId': null,
            'lastQuotaMutationId': null,
          });
          return 1;
        },
      );
    } catch (error) {
      throw runner.failure(error);
    }
  }

  Future<int> updateAccount(
    AIAccount account, {
    required int expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.accountPayload(account);
      final path = runner.path('accounts', account.id);
      return await runner.write(
        operationId,
        {
          'kind': 'updateAccount',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path) ?? runner.missing();
          final record = FirestoreLedgerCodec.account(
            account.id,
            old,
            runner.ownerId,
          );
          runner.checkRevision(expectedRevision, record.revision);
          if (!account.createdAt.isAtSameMomentAs(record.value.createdAt) ||
              account.isDemo != record.value.isDemo ||
              account.dataSource != record.value.dataSource) {
            runner.conflict();
          }
          final revision = runner.next(record.revision);
          tx.set(path, {
            ...old,
            ...runner.envelope(
              payload,
              revision,
              old: old,
              operationId: operationId,
            ),
          });
          return revision;
        },
      );
    } catch (error) {
      throw runner.failure(error);
    }
  }

  Future<void> deleteAccount(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = runner.path('accounts', id);
    await runner.write(
      operationId,
      {'kind': 'deleteAccount', 'id': id, 'expectedRevision': expectedRevision},
      (tx) async {
        final old = await tx.get(path) ?? runner.missing();
        final record = FirestoreLedgerCodec.account(id, old, runner.ownerId);
        runner.checkRevision(expectedRevision, record.revision);
        if (record.usageCount != 0 || record.quotaCount != 0) runner.conflict();
        tx.delete(path);
        return record.revision;
      },
    );
  }

  Future<int> createUsage(UsageSession usage, {required String operationId}) =>
      saveUsage(usage, operationId: operationId);

  Future<int> updateUsage(
    UsageSession usage, {
    required int expectedRevision,
    required String operationId,
  }) => saveUsage(
    usage,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  Future<int> saveUsage(
    UsageSession usage, {
    int? expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.usagePayload(usage);
      final path = runner.path('usage_sessions', usage.id);
      final parent = runner.path('accounts', usage.accountId);
      return await runner.write(
        operationId,
        {
          'kind': 'saveUsage',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path);
          final account = await tx.get(parent) ?? runner.missing();
          LedgerValidation.usage(usage, now: now());
          final a = FirestoreLedgerCodec.account(
            usage.accountId,
            account,
            runner.ownerId,
          );
          if (expectedRevision == null) {
            if (old != null ||
                a.value.archived ||
                a.value.isDemo != usage.isDemo) {
              runner.conflict();
            }
            final count = runner.next(a.usageCount);
            tx.set(parent, {
              ...account,
              'usageCount': count,
              'revision': runner.next(a.revision),
              'lastUsageMutationId': usage.id,
              'lastOperationId': operationId,
              'updatedAt': runner.store.serverTimestamp,
            });
          } else {
            if (old == null) runner.missing();
            final existing = FirestoreLedgerCodec.usage(
              usage.id,
              old,
              runner.ownerId,
            );
            runner.checkRevision(expectedRevision, existing.revision);
            if (existing.value.accountId != usage.accountId ||
                existing.value.isDemo != usage.isDemo ||
                existing.value.dataSource != usage.dataSource) {
              runner.conflict();
            }
          }
          final revision = old == null
              ? 1
              : runner.next(old['revision'] as int);
          tx.set(
            path,
            runner.envelope(
              payload,
              revision,
              old: old,
              operationId: operationId,
            ),
          );
          return revision;
        },
      );
    } catch (error) {
      throw runner.failure(error);
    }
  }

  Future<void> deleteUsage(
    String id, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = runner.path('usage_sessions', id);
    await runner.write(
      operationId,
      {'kind': 'deleteUsage', 'id': id, 'expectedRevision': expectedRevision},
      (tx) async {
        final old = await tx.get(path) ?? runner.missing();
        final usage = FirestoreLedgerCodec.usage(id, old, runner.ownerId);
        runner.checkRevision(expectedRevision, usage.revision);
        final parent = runner.path('accounts', usage.value.accountId);
        final account = await tx.get(parent) ?? runner.missing();
        final a = FirestoreLedgerCodec.account(
          usage.value.accountId,
          account,
          runner.ownerId,
        );
        if (a.usageCount < 1) runner.conflict();
        tx.set(parent, {
          ...account,
          'usageCount': a.usageCount - 1,
          'revision': runner.next(a.revision),
          'lastUsageMutationId': id,
          'lastOperationId': operationId,
          'updatedAt': runner.store.serverTimestamp,
        });
        tx.delete(path);
        return usage.revision;
      },
    );
  }
}
