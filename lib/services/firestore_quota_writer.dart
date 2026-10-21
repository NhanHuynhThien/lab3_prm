import '../models/cloud_ledger.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_store.dart';
import 'firestore_ledger_transactions.dart';
import 'ledger_validation.dart';
import 'reporting_calendar.dart';

class FirestoreQuotaWriter {
  FirestoreQuotaWriter({required this.runner, required this.now});

  final FirestoreTransactionRunner runner;
  final DateTime Function() now;

  void _label(CloudMap? label, String accountId, String key) {
    if (label == null ||
        label.length != 3 ||
        label['ownerId'] != runner.ownerId ||
        label['accountId'] != accountId ||
        label['windowKey'] != key) {
      runner.conflict();
    }
  }

  Future<int> setReportingTimezone(
    String zone, {
    int? expectedRevision,
    required String operationId,
  }) async {
    ReportingCalendar.validateZone(zone);
    final path = runner.path('settings', 'reporting');
    final payload = {'reportingTimezone': zone};
    return runner.write(
      operationId,
      {
        'kind': 'settings',
        'payload': payload,
        'expectedRevision': expectedRevision,
      },
      (tx) async {
        final old = await tx.get(path);
        if (old == null) {
          if (expectedRevision != null) runner.missing();
        } else {
          runner.checkRevision(
            expectedRevision,
            FirestoreLedgerCodec.settings(
              'reporting',
              old,
              runner.ownerId,
            ).revision,
          );
        }
        final revision = old == null ? 1 : runner.next(old['revision'] as int);
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
  }

  Future<int> createQuota(AccountQuota quota, {required String operationId}) =>
      saveQuota(quota, operationId: operationId);

  Future<int> updateQuota(
    AccountQuota quota, {
    required int expectedRevision,
    required String operationId,
  }) => saveQuota(
    quota,
    expectedRevision: expectedRevision,
    operationId: operationId,
  );

  Future<int> saveQuota(
    AccountQuota quota, {
    int? expectedRevision,
    required String operationId,
  }) async {
    try {
      final payload = FirestoreLedgerCodec.quotaPayload(quota);
      final path = runner.quotaPath(quota.accountId, quota.snapshot.windowKey);
      final parent = runner.path('accounts', quota.accountId);
      return await runner.write(
        operationId,
        {
          'kind': 'saveQuota',
          'payload': payload,
          'expectedRevision': expectedRevision,
        },
        (tx) async {
          final old = await tx.get(path);
          final account = await tx.get(parent) ?? runner.missing();
          final a = FirestoreLedgerCodec.account(
            quota.accountId,
            account,
            runner.ownerId,
          );
          if (a.value.archived) runner.conflict();
          CloudRecord<AccountQuota>? existing;
          if (expectedRevision == null) {
            if (old != null) runner.conflict();
            LedgerValidation.quota(quota.snapshot, now: now());
          } else {
            if (old == null) runner.missing();
            existing = FirestoreLedgerCodec.quota(
              path.split('/').last,
              old,
              runner.ownerId,
            );
            runner.checkRevision(expectedRevision, existing.revision);
            final previous = existing.value.snapshot;
            if (!previous.observedAt.isAtSameMomentAs(
                  quota.snapshot.observedAt,
                ) ||
                !previous.resetAt.isAtSameMomentAs(quota.snapshot.resetAt) ||
                previous.usedPercent != quota.snapshot.usedPercent) {
              LedgerValidation.quota(quota.snapshot, now: now());
            }
          }
          final labelPath = runner.labelPath(
            quota.accountId,
            quota.snapshot.window,
          );
          final label = await tx.get(labelPath);
          final previousLabelPath = existing == null
              ? null
              : runner.labelPath(
                  quota.accountId,
                  existing.value.snapshot.window,
                );
          if (previousLabelPath != null) {
            final previousLabel = previousLabelPath == labelPath
                ? label
                : await tx.get(previousLabelPath);
            _label(previousLabel, quota.accountId, quota.snapshot.windowKey);
          }
          if (label != null && previousLabelPath != labelPath) {
            runner.conflict();
          }
          final revision = old == null
              ? 1
              : runner.next(old['revision'] as int);
          if (previousLabelPath != null && previousLabelPath != labelPath) {
            tx.delete(previousLabelPath);
          }
          tx.set(labelPath, {
            'ownerId': runner.ownerId,
            'accountId': quota.accountId,
            'windowKey': quota.snapshot.windowKey,
          });
          tx.set(
            path,
            runner.envelope(
              payload,
              revision,
              old: old,
              operationId: operationId,
            ),
          );
          tx.set(parent, {
            ...account,
            'quotaCount': old == null
                ? runner.next(a.quotaCount)
                : a.quotaCount,
            'revision': runner.next(a.revision),
            'lastQuotaMutationId': path.split('/').last,
            'lastOperationId': operationId,
            'updatedAt': runner.store.serverTimestamp,
          });
          return revision;
        },
      );
    } catch (error) {
      throw runner.failure(error);
    }
  }

  Future<void> deleteQuota(
    String accountId,
    String windowKey, {
    required int expectedRevision,
    required String operationId,
  }) async {
    final path = runner.quotaPath(accountId, windowKey);
    final parent = runner.path('accounts', accountId);
    await runner.write(
      operationId,
      {
        'kind': 'deleteQuota',
        'accountId': accountId,
        'windowKey': windowKey,
        'expectedRevision': expectedRevision,
      },
      (tx) async {
        final old = await tx.get(path) ?? runner.missing();
        final q = FirestoreLedgerCodec.quota(
          path.split('/').last,
          old,
          runner.ownerId,
        );
        runner.checkRevision(expectedRevision, q.revision);
        final account = await tx.get(parent) ?? runner.missing();
        final a = FirestoreLedgerCodec.account(
          accountId,
          account,
          runner.ownerId,
        );
        if (a.quotaCount < 1) runner.conflict();
        final labelPath = runner.labelPath(accountId, q.value.snapshot.window);
        _label(await tx.get(labelPath), accountId, windowKey);
        tx.set(parent, {
          ...account,
          'quotaCount': a.quotaCount - 1,
          'revision': runner.next(a.revision),
          'lastQuotaMutationId': path.split('/').last,
          'lastOperationId': operationId,
          'updatedAt': runner.store.serverTimestamp,
        });
        tx.delete(path);
        tx.delete(labelPath);
        return q.revision;
      },
    );
  }
}
