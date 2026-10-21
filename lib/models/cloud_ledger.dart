import 'ledger.dart';

enum CloudLedgerProblem {
  unauthenticated,
  permission,
  unavailable,
  conflict,
  notFound,
  invalidData,
  closed,
}

class CloudLedgerFailure implements Exception {
  const CloudLedgerFailure(this.problem, this.message);
  final CloudLedgerProblem problem;
  final String message;
  @override
  String toString() => message;
}

/// Revision is an optimistic concurrency token, not a financial counter.
class CloudRecord<T> {
  const CloudRecord({
    required this.id,
    required this.ownerId,
    required this.value,
    required this.revision,
    this.createdAt,
    this.updatedAt,
    this.usageCount = 0,
    this.quotaCount = 0,
  });
  final String id, ownerId;
  final T value;
  final int revision, usageCount, quotaCount;
  final DateTime? createdAt, updatedAt;
}

class CloudSnapshot<T> {
  CloudSnapshot(
    Iterable<CloudRecord<T>> records, {
    required this.fromCache,
    required this.hasPendingWrites,
  }) : records = List.unmodifiable(records);
  final List<CloudRecord<T>> records;
  final bool fromCache, hasPendingWrites;
  bool get serverConfirmed => !fromCache && !hasPendingWrites;
}

class AccountQuota {
  const AccountQuota({required this.accountId, required this.snapshot});
  final String accountId;
  final QuotaSnapshot snapshot;
}

class CloudSettings {
  const CloudSettings(this.reportingTimezone);
  final String reportingTimezone;
}

/// Complete interval, never a paginated source for report totals.
class CloudUsageQuery {
  CloudUsageQuery({
    required DateTime start,
    required DateTime end,
    this.accountId,
    this.purpose,
  }) : start = start.toUtc(),
       end = end.toUtc() {
    if (!end.isAfter(start)) {
      throw ArgumentError('Khoảng thời gian không hợp lệ.');
    }
  }
  final DateTime start, end;
  final String? accountId;
  final Purpose? purpose;
}
