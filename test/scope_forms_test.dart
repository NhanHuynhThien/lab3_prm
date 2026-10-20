import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/analytics_screen.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/widgets/charts.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

void main() {
  final now = DateTime.utc(2026, 10, 21, 10);
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

  setUp(() async {
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
  });
  tearDown(() => container.dispose());

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'model/defaults/cycle save failure retains new fields and retry at ${width.toInt()}',
      (tester) async {
        await open(
          tester,
          AccountFormScreen(account: repo.data!.account('a')),
          width,
        );
        final model = find.byKey(const ValueKey('account-model'));
        await reveal(tester, model);
        await tester.enterText(model, 'model-riêng');
        await reveal(tester, find.text('Kiểm thử'));
        await tester.tap(find.text('Kiểm thử'));
        await tester.pumpAndSettle();
        final zone = find.byKey(const ValueKey('account-timezone'));
        await reveal(tester, zone);
        await tester.enterText(zone, 'America/New_York');
        final cycle = find.byKey(const ValueKey('account-cycle'));
        await reveal(tester, cycle);
        await tester.enterText(cycle, '31');
        repo.failWrites = true;
        await tester.tap(find.text('Lưu tài khoản'));
        await tester.pumpAndSettle();
        expect(repo.data!.account('a')!.defaultModelId, 'model-gợi-ý');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        await reveal(tester, model, step: -240);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-riêng',
        );
        repo.failWrites = false;
        await tester.tap(find.text('Lưu tài khoản'));
        await tester.pumpAndSettle();
        final saved = repo.data!.account('a')!;
        expect(saved.defaultModelId, 'model-riêng');
        expect(saved.defaultPurposes, [Purpose.review, Purpose.test]);
        expect(saved.timezone, 'America/New_York');
        expect(saved.cycleStartDay, 31);
        expect(saved.quotaWindows.single.window, 'Hàng tuần');
        expect(find.text('Home fixture'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'usage model/purpose suggestions editable, retry preserves provenance at ${width.toInt()}',
      (tester) async {
        await open(tester, const UsageFormScreen(accountId: 'a'), width);
        expect(find.text('Mục đích: Code review'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Công việc thực',
        );
        final model = find.byKey(const ValueKey('usage-model'));
        await reveal(tester, model);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-gợi-ý',
        );
        await tester.enterText(model, 'model-cho-phiên');
        repo.failWrites = true;
        await tester.tap(find.text('Lưu phiên sử dụng'));
        await tester.pumpAndSettle();
        expect(repo.data!.sessions, isEmpty);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-cho-phiên',
        );
        repo.failWrites = false;
        await tester.tap(find.text('Lưu phiên sử dụng'));
        await tester.pumpAndSettle();
        final saved = repo.data!.sessions.single;
        expect(saved.modelId, 'model-cho-phiên');
        expect(saved.purpose, Purpose.review);
        expect(saved.dataSource, DataSource.manual);
        expect(saved.isDemo, isFalse);
        expect(saved.costMicros, isNull);
        expect(saved.effectiveCostBasis, CostBasis.unknown);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'second quota window source/note survive failed save without replacing week at ${width.toInt()}',
      (tester) async {
        await open(
          tester,
          QuotaFormScreen(account: repo.data!.account('a')!, newWindow: true),
          width,
        );
        await tester.enterText(
          find.byKey(const ValueKey('quota-percent')),
          '0',
        );
        final source = find.byKey(const ValueKey('quota-source'));
        await reveal(tester, source);
        await tester.enterText(source, 'Trang usage đã quan sát');
        final note = find.byKey(const ValueKey('quota-note'));
        await reveal(tester, note);
        await tester.enterText(note, 'Giữ độc lập với tuần');
        repo.failWrites = true;
        await tester.tap(find.text('Lưu hạn mức nhập tay'));
        await tester.pumpAndSettle();
        expect(repo.data!.account('a')!.quotaWindows.length, 1);
        expect(
          tester.widget<TextFormField>(note).controller!.text,
          'Giữ độc lập với tuần',
        );
        repo.failWrites = false;
        await tester.tap(find.text('Lưu hạn mức nhập tay'));
        await tester.pumpAndSettle();
        final windows = repo.data!.account('a')!.quotaWindows;
        expect(windows.length, 2);
        expect(windows.first.usedPercent, 40);
        expect(windows.last.usedPercent, 0);
        expect(windows.last.source, DataSource.manual);
        expect(windows.last.sourceLabel, 'Trang usage đã quan sát');
        expect(windows.last.note, 'Giữ độc lập với tuần');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'provider history groups days in selected timezone; zone save failure preserves draft and search',
    (tester) async {
      repo.data = repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Công việc tối',
            purpose: Purpose.code,
            occurredAt: DateTime.utc(2026, 10, 20, 17, 30),
          ),
          UsageSession(
            id: 'y',
            accountId: 'a',
            title: 'Công việc chiều',
            purpose: Purpose.code,
            occurredAt: DateTime.utc(2026, 10, 20, 16),
          ),
          UsageSession(
            id: 'z',
            accountId: 'b',
            title: 'Không thuộc provider',
            purpose: Purpose.code,
            occurredAt: now,
          ),
        ],
      );
      container.invalidate(ledgerProvider);
      await container.read(ledgerProvider.future);
      await open(tester, const HistoryScreen(provider: 'OpenAI'), 412);
      await tester.enterText(find.byType(TextField).first, 'Công việc');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('21/10/2026'));
      expect(find.text('21/10/2026'), findsOneWidget);
      await reveal(tester, find.text('20/10/2026'));
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('Không thuộc provider'), findsNothing);
      await reveal(tester, find.text('Múi giờ báo cáo'), step: -240);
      await tester.tap(find.text('Múi giờ báo cáo'));
      await tester.pumpAndSettle();
      final zone = find.byKey(const ValueKey('reporting-timezone'));
      await tester.enterText(zone, 'Made/Up');
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(find.text('Múi giờ IANA không hợp lệ.'), findsOneWidget);
      await tester.enterText(zone, 'UTC');
      repo.failWrites = true;
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(repo.data!.reportingTimezone, 'Asia/Ho_Chi_Minh');
      expect(tester.widget<TextFormField>(zone).controller!.text, 'UTC');
      repo.failWrites = false;
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(repo.data!.reportingTimezone, 'UTC');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Công việc',
      );
      await reveal(tester, find.text('20/10/2026'));
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('21/10/2026'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown cost defaults analytics to count; provider tap opens exact history',
    (tester) async {
      repo.data = repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Chưa biết tiền',
            purpose: Purpose.code,
            occurredAt: now,
          ),
        ],
      );
      container.invalidate(ledgerProvider);
      await container.read(ledgerProvider.future);
      await open(tester, const Scaffold(body: AnalyticsScreen()), 412);
      expect(
        tester
            .widget<SegmentedButton<UsageMetric>>(
              find.byType(SegmentedButton<UsageMetric>),
            )
            .selected,
        {UsageMetric.sessions},
      );
      await reveal(tester, find.text('OpenAI'));
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HistoryScreen>(find.byType(HistoryScreen)).provider,
        'OpenAI',
      );
      await reveal(tester, find.text('Chưa biết tiền'));
      expect(find.text('Chưa biết tiền'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'donut sector opens same purpose filter as its accessible legend',
    (tester) async {
      repo.data = repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Lập trình',
            purpose: Purpose.code,
            occurredAt: now,
          ),
          UsageSession(
            id: 'y',
            accountId: 'a',
            title: 'Review',
            purpose: Purpose.review,
            occurredAt: now,
          ),
        ],
      );
      container.invalidate(ledgerProvider);
      await container.read(ledgerProvider.future);
      await open(tester, const Scaffold(body: AnalyticsScreen()), 412);
      await reveal(tester, find.byType(PurposeRing));
      final start = tester.getTopLeft(find.byType(PurposeRing));
      await tester.tapAt(start + const Offset(162, 86));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HistoryScreen>(find.byType(HistoryScreen)).purpose,
        Purpose.code,
      );
      await reveal(tester, find.text('Lập trình').last);
      expect(find.text('Review'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'chip-only changes guard Back and optional model/default purposes can be cleared',
    (tester) async {
      await open(
        tester,
        AccountFormScreen(account: repo.data!.account('a')),
        360,
      );
      final chip = find.widgetWithText(FilterChip, 'Code review');
      await reveal(tester, chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      final model = find.byKey(const ValueKey('account-model'));
      await reveal(tester, model, step: -240);
      await tester.enterText(model, '');
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      expect(repo.data!.account('a')!.defaultModelId, isNull);
      expect(repo.data!.account('a')!.defaultPurposes, isEmpty);
      expect(repo.data!.account('a')!.quotaWindows.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'new account retries keep creation timestamp even when clock advances',
    (tester) async {
      var clock = now;
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => clock),
        ],
      );
      await container.read(ledgerProvider.future);
      await open(tester, const AccountFormScreen(), 360);
      await tester.enterText(find.byType(TextFormField).first, 'Retry clock');
      repo.failWrites = true;
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      clock = clock.add(const Duration(minutes: 2));
      repo.failWrites = false;
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      final saved = repo.data!.accounts.singleWhere(
        (a) => a.alias == 'Retry clock',
      );
      expect(saved.createdAt.isAtSameMomentAs(now), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'new usage suggests the selected source instead of accidentally recording into a seed account',
    (tester) async {
      final seed = createDemoSeed(now);
      repo.data = repo.data!.copyWith(
        accounts: [...seed.accounts, ...repo.data!.accounts],
        sessions: seed.sessions,
      );
      container.invalidate(ledgerProvider);
      await container.read(ledgerProvider.future);
      await open(tester, const UsageFormScreen(), 360);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'a',
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'Công việc nhập tay sau seed',
      );
      await tester.tap(find.text('Lưu phiên sử dụng'));
      await tester.pumpAndSettle();
      final saved = repo.data!.sessions.last;
      expect(saved.accountId, 'a');
      expect(saved.dataSource, DataSource.manual);
      expect(saved.isDemo, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
