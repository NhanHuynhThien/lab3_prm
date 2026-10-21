import 'dart:async';

import 'package:token_ledger/models/ledger.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;

class PendingRepository extends MemoryRepository {
  Completer<void>? pending;
  int writes = 0;

  @override
  Future<void> save(LedgerData value) async {
    writes++;
    if (pending != null) await pending!.future;
    await super.save(value);
  }
}

UsageSession createTestUsage(
  DateTime now, {
  String id = 'work',
  String title = 'Work',
  int? input,
  int? output,
  int? cost,
  String note = '',
  DateTime? date,
  String account = 'codex',
}) => UsageSession(
  id: id,
  accountId: account,
  title: title,
  purpose: Purpose.code,
  occurredAt: date ?? now,
  inputTokens: input,
  outputTokens: output,
  costMicros: cost,
  note: note,
);

QuotaSnapshot createTestQuota(
  DateTime now, {
  int percent = 10,
  DateTime? observed,
  DateTime? reset,
  String window = '5 giờ',
}) => QuotaSnapshot(
  window: window,
  usedPercent: percent,
  observedAt: observed ?? now,
  resetAt: reset ?? now.add(const Duration(hours: 1)),
);
