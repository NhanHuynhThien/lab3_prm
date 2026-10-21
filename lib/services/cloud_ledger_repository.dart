import '../models/cloud_ledger.dart';
import '../models/ledger.dart';

/// Separate from the local snapshot repository: no load/save entire dataset.
/// Each write needs a stable, unique operation ID and edits need a read revision.
abstract interface class CloudLedgerRepository {
  String get ownerId;
  Stream<CloudSnapshot<AIAccount>> watchAccounts({bool? archived});
  Stream<CloudSnapshot<UsageSession>> watchUsage(CloudUsageQuery query);
  Stream<CloudSnapshot<UsageSession>> watchAllUsage();
  Stream<CloudSnapshot<AccountQuota>> watchAllQuotas();
  Stream<CloudSnapshot<CloudSettings>> watchSettings();
  Future<int> setReportingTimezone(
    String zone, {
    int? expectedRevision,
    required String operationId,
  });
  Stream<CloudSnapshot<AccountQuota>> watchQuotas(String accountId);
  Future<int> createAccount(AIAccount account, {required String operationId});
  Future<int> updateAccount(
    AIAccount account, {
    required int expectedRevision,
    required String operationId,
  });
  Future<void> deleteAccount(
    String id, {
    required int expectedRevision,
    required String operationId,
  });
  Future<int> createUsage(UsageSession usage, {required String operationId});
  Future<int> updateUsage(
    UsageSession usage, {
    required int expectedRevision,
    required String operationId,
  });
  Future<void> deleteUsage(
    String id, {
    required int expectedRevision,
    required String operationId,
  });
  Future<int> createQuota(AccountQuota quota, {required String operationId});
  Future<int> updateQuota(
    AccountQuota quota, {
    required int expectedRevision,
    required String operationId,
  });
  Future<void> deleteQuota(
    String accountId,
    String windowKey, {
    required int expectedRevision,
    required String operationId,
  });
  Future<void> close();
}
