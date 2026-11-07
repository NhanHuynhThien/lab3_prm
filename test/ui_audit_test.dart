import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_detail_screen.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/accounts_screen.dart';
import 'package:token_ledger/screens/analytics_screen.dart';
import 'package:token_ledger/screens/dashboard_screen.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/screens/login_screen.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/screens/purpose_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

const _imageRoot = String.fromEnvironment(
  'UI_AUDIT_OUTPUT',
  defaultValue: '.taste-skill/b08-b10',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 412.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final stress in [false, true]) {
        testWidgets(
          'all screens ${width.toInt()}x800 text $scale stress $stress',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            final repository = MemoryRepository();
            if (stress) {
              repository.data = LedgerData(
                accounts: [
                  AIAccount(
                    id: 'codex',
                    alias: ('Tài khoản dùng cho nghiên cứu và lập trình ' * 2)
                        .substring(0, 80),
                    provider: 'OpenAI',
                    product: 'Công cụ nghiên cứu và lập trình mở rộng',
                    billingMode: BillingMode.api,
                    plan: 'Gói thử nghiệm',
                    createdAt: DateTime(2026),
                    budgetMicros: 9999999999999,
                    quota: QuotaSnapshot(
                      window: 'Cửa sổ hạn mức thử nghiệm rất dài',
                      usedPercent: 99,
                      observedAt: DateTime(2026, 10, 21, 9),
                      resetAt: DateTime(2026, 10, 21, 15),
                    ),
                  ),
                ],
                sessions: [
                  UsageSession(
                    id: 'long',
                    accountId: 'codex',
                    title:
                        'Nghiên cứu và kiểm thử chức năng với nội dung dài ' *
                        2,
                    purpose: Purpose.research,
                    occurredAt: DateTime(2026, 10, 21, 9),
                    inputTokens: 1000000000,
                    outputTokens: 1000000000,
                    costMicros: 9999999999999,
                    note: 'Ghi chú công việc dài. ' * 40,
                  ),
                ],
              );
            }
            final container = ProviderContainer(
              overrides: [
                ledgerRepositoryProvider.overrideWithValue(repository),
                clockProvider.overrideWithValue(
                  () => DateTime(2026, 10, 21, 10),
                ),
              ],
            );
            await container.read(ledgerProvider.future);
            final a = repository.data!.account('codex')!;
            final screens = <String, Widget>{
              'dashboard': DashboardScreen(
                onAccounts: () {},
                onAnalytics: () {},
              ),
              'usage': UsageFormScreen(
                accountId: 'codex',
                session: stress ? repository.data!.sessions.first : null,
              ),
              'purpose': const PurposeScreen(selected: Purpose.code),
              'analytics': const AnalyticsScreen(),
              'history': const HistoryScreen(),
              'accounts': const AccountsScreen(),
              'account-form': AccountFormScreen(account: stress ? a : null),
              'account-detail': const AccountDetailScreen(accountId: 'codex'),
              'login': const LoginScreen(),
              'profile': const ProfileScreen(),
              'quota': QuotaFormScreen(account: a),
              'shell': const ShellScreen(),
            };
            try {
              for (final entry in screens.entries) {
                final boundary = GlobalKey();
                await tester.pumpWidget(
                  UncontrolledProviderScope(
                    container: container,
                    child: MaterialApp(
                      theme: buildAppTheme(),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(scale),
                          disableAnimations: true,
                        ),
                        child: RepaintBoundary(key: boundary, child: child!),
                      ),
                      home: Scaffold(
                        key: ValueKey(entry.key),
                        body: SafeArea(child: entry.value),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${entry.key} initial',
                );
                if (entry.key == 'dashboard') {
                  final action = find.ancestor(
                    of: find.text('Ghi sử dụng'),
                    matching: find.byWidgetPredicate((w) => w is FilledButton),
                  );
                  final actionRect = tester.getRect(action);
                  final rangeRect = tester.getRect(find.byType(RangePicker));
                  expect(
                    actionRect.center.dy,
                    closeTo(rangeRect.center.dy, 0.1),
                  );
                  expect(actionRect.height, closeTo(rangeRect.height, 0.1));
                  expect(actionRect.width, closeTo(rangeRect.width, 0.1));
                  expect(actionRect.left, greaterThanOrEqualTo(0));
                  expect(rangeRect.right, lessThanOrEqualTo(width));
                  expect(
                    find.descendant(
                      of: find.byType(FilterBar),
                      matching: find.byType(SingleChildScrollView),
                    ),
                    findsNothing,
                  );
                }
                if (find.byType(AppBar).evaluate().isNotEmpty) {
                  final bar = tester.getRect(find.byType(AppBar));
                  final title = tester.getRect(
                    find
                        .descendant(
                          of: find.byType(AppBar),
                          matching: find.byType(Text),
                        )
                        .first,
                  );
                  expect(
                    title.top,
                    greaterThanOrEqualTo(bar.top),
                    reason: '${entry.key} title top',
                  );
                  expect(
                    title.bottom,
                    lessThanOrEqualTo(bar.bottom),
                    reason: '${entry.key} title bottom',
                  );
                }
                if (const bool.fromEnvironment('UI_AUDIT_IMAGES') &&
                    ((!stress && scale == 1) ||
                        (stress && scale == 2 && width == 360)) &&
                    width != 768) {
                  await tester.runAsync(() async {
                    final render =
                        boundary.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary;
                    final image = await render.toImage(pixelRatio: 1);
                    final bytes = (await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    ))!;
                    final file = File(
                      '$_imageRoot/${entry.key}-${width.toInt()}-$scale-$stress.png',
                    );
                    await file.parent.create(recursive: true);
                    await file.writeAsBytes(bytes.buffer.asUint8List());
                    image.dispose();
                  });
                }
                if (entry.key == 'history') {
                  final context = tester.element(find.byType(HistoryScreen));
                  showUsageDetail(context, repository.data!.sessions.first);
                  await tester.pumpAndSettle();
                  expect(
                    tester.takeException(),
                    isNull,
                    reason: 'usage detail sheet',
                  );
                  final scroll = tester.state<ScrollableState>(
                    find.byType(Scrollable).last,
                  );
                  scroll.position.jumpTo(scroll.position.maxScrollExtent);
                  await tester.pumpAndSettle();
                  expect(find.text('Sửa phiên').hitTestable(), findsOneWidget);
                  expect(find.text('Xóa phiên').hitTestable(), findsOneWidget);
                  expect(tester.takeException(), isNull);
                  Navigator.of(context).pop();
                  await tester.pumpAndSettle();
                }
                // Scroll every vertical viewport to exercise lazily built rows and footers.
                final lists = find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                );
                for (var i = 0; i < lists.evaluate().length; i++) {
                  final state = tester.state<ScrollableState>(lists.at(i));
                  for (var step = 0; step < 30; step++) {
                    final position = state.position;
                    if (position.pixels >= position.maxScrollExtent) break;
                    position.jumpTo(
                      (position.pixels + 500).clamp(
                        0,
                        position.maxScrollExtent,
                      ),
                    );
                    await tester.pumpAndSettle();
                    expect(
                      tester.takeException(),
                      isNull,
                      reason: '${entry.key} scrolling',
                    );
                  }
                }
              }
            } finally {
              await tester.pumpWidget(const SizedBox());
              container.dispose();
            }
          },
        );
      }
    }
  }
}
