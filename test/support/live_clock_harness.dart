import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/dashboard_screen.dart' show QuotaRow;
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;

class ClockRepository extends MemoryRepository {
  int writes = 0;
  @override
  Future<void> save(LedgerData value) async {
    writes++;
    await super.save(value);
  }
}

class LiveClockTestHarness {
  late DateTime clock;
  late ClockRepository repository;
  late ProviderContainer container;
  int reads = 0;

  Future<void> open(
    WidgetTester tester,
    DateTime start, {
    Duration? resetIn,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    clock = start;
    reads = 0;
    repository = ClockRepository()
      ..data = createDemoSeed(start, timezone: 'device');
    if (resetIn != null) {
      final data = repository.data!;
      repository.data = data.copyWith(
        accounts: data.accounts
            .map(
              (a) => a.id == 'claude'
                  ? a.copyWith(
                      quota: QuotaSnapshot(
                        window: '5 giờ',
                        usedPercent: 65,
                        observedAt: start,
                        resetAt: start.add(resetIn),
                      ),
                    )
                  : a,
            )
            .toList(),
      );
    }
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() {
          reads++;
          return clock;
        }),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await container.read(ledgerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final projection = ref.watch(dashboardProjectionProvider);
                return Column(
                  children: [
                    Text(
                      'month=${projection.now.month} count=${projection.summary.count} remaining=${projection.remaining}',
                    ),
                    QuotaRow(
                      account: ref
                          .watch(ledgerProvider)
                          .requireValue
                          .account('claude')!,
                      now: ref.watch(nowProvider),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
