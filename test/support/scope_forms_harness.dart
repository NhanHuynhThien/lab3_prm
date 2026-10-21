import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;

class ScopeFormsHarness {
  final DateTime now = DateTime.utc(2026, 10, 21, 10);
  late MemoryRepository repo;
  late ProviderContainer container;
  late GlobalKey<NavigatorState> nav;

  AIAccount account(String id, {String provider = 'OpenAI'}) => AIAccount(
    id: id,
    alias: 'Tài khoản $id',
    provider: provider,
    product: 'Công cụ',
    billingMode: BillingMode.api,
    plan: '',
    createdAt: now,
    defaultModelId: 'model-gợi-ý',
    defaultPurposes: [Purpose.review],
    quotaWindows: [
      QuotaSnapshot(
        window: 'Hàng tuần',
        usedPercent: 40,
        observedAt: now,
        resetAt: now.add(const Duration(days: 2)),
      ),
    ],
  );

  Future<void> open(WidgetTester tester, Widget page, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: nav,
          theme: buildAppTheme(),
          home: const Scaffold(body: Text('Home fixture')),
        ),
      ),
    );
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => page));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder target, {
    double step = 240,
  }) async {
    await tester.scrollUntilVisible(
      target,
      step,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> init() async {
    repo = MemoryRepository()
      ..data = LedgerData(
        accounts: [
          account('a'),
          account('b', provider: 'Anthropic'),
        ],
        sessions: [],
      );
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    await container.read(ledgerProvider.future);
  }
}
