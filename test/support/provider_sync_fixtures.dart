import 'package:token_ledger/services/provider_snapshot_store.dart';

import 'dart:async';

import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/services/provider_sync_service.dart';

Map<String, dynamic> syncFixture({DateTime? now}) {
  now ??= DateTime.now().toUtc();
  return {
    'schemaVersion': 1,
    'collectedAt': now.toIso8601String(),
    'providers': [
      for (final id in ['codex', 'claude', 'google'])
        {
          'id': id,
          'status': 'ready',
          'source': '$id fixture',
          'coverage': 'Chỉ fixture kiểm thử, không phải tài khoản thật.',
          'observedAt': now.toIso8601String(),
          'plan': id == 'codex' ? 'business' : null,
          'windows': id == 'google'
              ? []
              : [
                  {
                    'label': '5 giờ',
                    'usedPercent': 25,
                    'resetsAt': now
                        .add(const Duration(hours: 5))
                        .toIso8601String(),
                  },
                ],
          'totalTokens': id == 'claude' ? null : 12345,
          'contextTokens': id == 'claude' ? 1200 : null,
          'estimatedCostMicros': id == 'claude' ? 125000 : null,
          'models': [
            {
              'model': '$id-test-model',
              'inputTokens': 100,
              'outputTokens': 20,
              'totalTokens': 120,
              'estimatedCostMicros': null,
            },
          ],
        },
    ],
  };
}

class FakeProviderSync implements ProviderSyncService {
  int calls = 0;
  Object? error;
  Completer<ProviderSnapshot>? gate;
  ProviderSnapshot value = ProviderSnapshot.fromJson(syncFixture());
  @override
  Future<ProviderSnapshot> fetch(String token) async {
    calls++;
    if (error != null) throw error!;
    return gate?.future ?? value;
  }

  @override
  void close() {}
}

class FakeSnapshotStore implements ProviderSnapshotStore {
  final saved = <String, ProviderSnapshot>{};
  @override
  Stream<ProviderSnapshot?> watch(String uid) => Stream.value(saved[uid]);
  @override
  Future<void> save(String uid, ProviderSnapshot snapshot) async =>
      saved[uid] = snapshot;
}
