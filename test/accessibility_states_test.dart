import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_detail_screen.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/accounts_screen.dart';
import 'package:token_ledger/screens/dashboard_screen.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/screens/login_screen.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/screens/purpose_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/charts.dart';
import 'package:token_ledger/widgets/common.dart';
import 'package:token_ledger/widgets/draft_guard.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

class StateRepository extends MemoryRepository {
  bool failReads = false;
  Completer<LedgerData?>? loading;
  Completer<void>? writing;
  int writes = 0;
  @override
  Future<LedgerData?> load() async {
    if (loading != null) return loading!.future;
    if (failReads) throw StateError('Read failed');
    return data;
  }

  @override
  Future<void> save(LedgerData value) async {
    writes++;
    if (writing != null) await writing!.future;
    await super.save(value);
  }
}

void main() {
  final now = DateTime(2026, 10, 21, 10);
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  ProviderContainer owner(StateRepository repo) => ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  Future<void> open(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen, {
    double width = 360,
    double scale = 1,
    bool reduce = true,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          key: UniqueKey(),
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduce,
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  test('B11 Lab2 text/control contrast pairs meet explicit thresholds', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    for (final bg in [
      AppColors.surface,
      AppColors.background,
      AppColors.soft,
      AppColors.neutral,
    ]) {
      for (final fg in [
        AppColors.text,
        AppColors.muted,
        AppColors.primary,
        AppColors.danger,
      ]) {
        expect(ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg / $bg');
      }
    }
    expect(ratio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(ratio(AppColors.border, AppColors.surface), greaterThanOrEqualTo(3));
  });

  testWidgets(
    'B11 action row supports semantic button/selection, Tab and Enter',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ActionSurface(
              selected: true,
              onTap: () => taps++,
              child: const Text('Mở lịch sử'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ActionSurface)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byType(ActionSurface)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasFocusAction: true,
          hasTapAction: true,
          label: 'Mở lịch sử',
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.foregroundDecoration is BoxDecoration &&
              (w.foregroundDecoration! as BoxDecoration).border != null,
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'B11 chart dates/units and progress have one final semantic value',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 328,
                  child: UsageBarChart(
                    values: const [0, 1000000, 0, 0, 0, 0, 2000000],
                    now: DateTime(2026, 1, 1),
                  ),
                ),
                const AnimatedProgress(value: .25),
                const AnimatedMoney(micros: 12340000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Chi phí nhập tay, USD.*26/12/2025: \$0.00.*1/1/2026: \$2.00',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byType(AnimatedProgress)),
        matchesSemantics(value: '25%'),
      );
      expect(find.bySemanticsLabel(r'$12.34'), findsOneWidget);
      semantics.dispose();
    },
  );

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'B11 labels, contrast and touch targets on purpose and shell $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final repo = StateRepository();
        final container = owner(repo);
        await container.read(ledgerProvider.future);
        try {
          await open(
            tester,
            container,
            const PurposeScreen(selected: Purpose.code),
            width: width,
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await open(tester, container, const ShellScreen(), width: width);
          await tester.pumpAndSettle();
          for (final tab in [
            'Tổng quan',
            'Tài khoản',
            'Phân tích',
            'Cá nhân',
          ]) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
        } finally {
          semantics.dispose();
          await close(tester, container);
        }
      },
    );

    testWidgets('B12 empty, not-found and disabled states $width', (
      tester,
    ) async {
      final seed = createDemoSeed(now);
      final repo = StateRepository()
        ..data = LedgerData(accounts: [], sessions: []);
      final container = owner(repo);
      await container.read(ledgerProvider.future);
      try {
        for (final screen in [
          const AccountDetailScreen(accountId: 'missing'),
          AccountFormScreen(account: seed.accounts.first),
          QuotaFormScreen(account: seed.accounts.first),
          UsageFormScreen(session: seed.sessions.first),
        ]) {
          await open(tester, container, screen, width: width, scale: 2);
          await tester.pumpAndSettle();
          expect(find.text('Không tìm thấy tài khoản'), findsOneWidget);
          expect(find.byType(SaveButton), findsNothing);
          expect(tester.takeException(), isNull);
        }
        await open(tester, container, const UsageFormScreen(), width: width);
        await tester.pumpAndSettle();
        expect(find.text('Thêm tài khoản trước'), findsOneWidget);
        await tester.tap(find.text('Thêm tài khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Thêm tài khoản AI'), findsOneWidget);
        await open(tester, container, const ShellScreen(), width: width);
        await tester.pumpAndSettle();
        for (final tab in ['Tài khoản', 'Phân tích', 'Cá nhân', 'Tổng quan']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await open(tester, container, const LoginScreen(), width: width);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(
                  OutlinedButton,
                  'Google Sign-In · Chưa kết nối',
                ),
              )
              .onPressed,
          isNull,
        );
      } finally {
        await close(tester, container);
      }
    });

    testWidgets(
      'B12 reset/clear cancel, failure, pending and successful recovery $width',
      (tester) async {
        final repo = StateRepository();
        final container = owner(repo);
        await container.read(ledgerProvider.future);
        final vm = container.read(ledgerProvider.notifier);
        await vm.deleteUsage(repo.data!.sessions.first.id);
        final before = repo.data!;
        try {
          await open(
            tester,
            container,
            const Scaffold(body: ProfileScreen()),
            width: width,
          );
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Xóa dữ liệu demo'));
          await tester.tap(find.text('Xóa dữ liệu demo'));
          await tester.pumpAndSettle();
          expect(find.textContaining('không thể hoàn tác'), findsOneWidget);
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
          expect(repo.data, same(before));
          repo.failWrites = true;
          await tester.tap(find.text('Khôi phục dữ liệu mẫu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(repo.data, same(before));
          expect(find.textContaining('disk full'), findsOneWidget);
          repo.failWrites = false;
          await reveal(tester, find.text('Khôi phục dữ liệu mẫu'));
          await tester.tap(find.text('Khôi phục dữ liệu mẫu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(repo.data!.sessions.length, 12);
          repo.writing = Completer<void>();
          final writes = repo.writes;
          await tester.tap(find.text('Xóa dữ liệu demo'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận'));
          await tester.pump();
          expect(
            tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Thoát không gian demo'),
                )
                .onPressed,
            isNull,
          );
          expect(repo.writes, writes + 1);
          expect(repo.data!.sessions.length, 12);
          repo.writing!.complete();
          repo.writing = null;
          await tester.pumpAndSettle();
          expect(repo.data!.accounts, isEmpty);
          expect(repo.data!.sessions, isEmpty);
          await reveal(tester, find.text('Khôi phục dữ liệu mẫu'));
          await tester.tap(find.text('Khôi phục dữ liệu mẫu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(repo.data!.accounts.length, 3);
        } finally {
          await close(tester, container);
        }
      },
    );
  }

  testWidgets(
    'B12 cold usage route loads then errors/retries without an init crash',
    (tester) async {
      final repo = StateRepository()..loading = Completer<LedgerData?>();
      final container = owner(repo);
      try {
        await open(tester, container, const UsageFormScreen());
        expect(find.byType(LoadingFeedback), findsOneWidget);
        repo.loading!.completeError(StateError('Read failed'));
        repo.loading = null;
        await tester.pumpAndSettle();
        expect(find.text('Thử lại'), findsOneWidget);
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.text('Lưu phiên sử dụng'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await close(tester, container);
      }
    },
  );

  for (final kind in ['usage', 'account', 'quota', 'history', 'accounts']) {
    testWidgets('B12 $kind reload error/Retry preserves draft or filter', (
      tester,
    ) async {
      final repo = StateRepository();
      final container = owner(repo);
      final data = await container.read(ledgerProvider.future);
      final screen = switch (kind) {
        'usage' => const UsageFormScreen(accountId: 'codex'),
        'account' => const AccountFormScreen(),
        'quota' => QuotaFormScreen(account: data.account('codex')!),
        'history' => const HistoryScreen(),
        _ => const Scaffold(body: AccountsScreen()),
      };
      try {
        await open(tester, container, screen);
        await tester.pumpAndSettle();
        final field = find.byType(TextField).first;
        await tester.enterText(field, 'Dữ liệu giữ nguyên');
        await tester.pump();
        repo.failReads = true;
        container.invalidate(ledgerProvider);
        await tester.pumpAndSettle();
        expect(find.text('Thử lại'), findsOneWidget);
        repo.failReads = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          'Dữ liệu giữ nguyên',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await close(tester, container);
      }
    });
  }

  testWidgets('B11 dynamic reduced motion keeps tab filters and scroll', (
    tester,
  ) async {
    final repo = StateRepository();
    final container = owner(repo);
    await container.read(ledgerProvider.future);
    final reduce = ValueNotifier(false);
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => ValueListenableBuilder<bool>(
              valueListenable: reduce,
              builder: (context, value, _) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: value),
                child: child!,
              ),
            ),
            home: const ShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản').last);
      await tester.pump();
      reduce.value = true;
      await tester.pumpAndSettle();
      final fades = tester.widgetList<FadeTransition>(
        find.byKey(const ValueKey('tab-transition')),
      );
      expect(fades.every((w) => w.opacity.value == 1), isTrue);
      await tester.enterText(find.byType(TextField).first, 'Claude');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phân tích').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Token').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tổng quan').last);
      await tester.pumpAndSettle();
      expect(scroll.pixels, 300);
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'Claude',
      );
      await tester.tap(find.text('Phân tích').last);
      await tester.pumpAndSettle();
      expect(find.text('Theo mục đích · token'), findsOneWidget);
    } finally {
      reduce.dispose();
      await close(tester, container);
    }
  });

  testWidgets('B11 reduced busy indicators are static and retain status', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  const LoadingFeedback(),
                  SaveButton(label: 'Lưu', saving: true, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .every((w) => w.value == .5),
      isTrue,
    );
    expect(find.text('Đang lưu...'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byType(LoadingFeedback))
          .getSemanticsData()
          .value,
      isEmpty,
    );
    expect(
      tester.getSemantics(find.byType(SaveButton)).getSemanticsData().value,
      isEmpty,
    );
    semantics.dispose();
  });

  testWidgets(
    'B12 confirmation guards double tap, failure/retry and removed owner',
    (tester) async {
      var writes = 0;
      var fail = true;
      final gate = Completer<void>();
      Widget button() => ConfirmedActionButton(
        label: 'Xóa phiên',
        icon: Icons.delete_outline,
        title: 'Xóa phiên?',
        message: 'Không thể hoàn tác.',
        onConfirm: () async {
          writes++;
          if (fail) throw StateError('write failed');
          await gate.future;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: button()),
        ),
      );
      final point = tester.getCenter(find.text('Xóa phiên'));
      await tester.tapAt(point);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa phiên'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.textContaining('write failed'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Xóa phiên'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa phiên'));
      await tester.pump();
      expect(writes, 2);
      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Xóa phiên'), findsOneWidget);
      await tester.tap(find.text('Xóa phiên'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'B12 removed usage is not resurrected by opening its old edit route',
    (tester) async {
      final seed = createDemoSeed(now);
      final repo = StateRepository()
        ..data = LedgerData(accounts: seed.accounts, sessions: []);
      final container = owner(repo);
      await container.read(ledgerProvider.future);
      try {
        await open(
          tester,
          container,
          UsageFormScreen(session: seed.sessions.first),
        );
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy phiên sử dụng'), findsOneWidget);
        expect(find.byType(SaveButton), findsNothing);
        expect(repo.writes, 0);
      } finally {
        await close(tester, container);
      }
    },
  );

  testWidgets(
    'B12 dirty Back remains protected while a form shows a reload error',
    (tester) async {
      final repo = StateRepository();
      final container = owner(repo);
      await container.read(ledgerProvider.future);
      try {
        await open(
          tester,
          container,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const UsageFormScreen(accountId: 'codex'),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở form'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Draft còn nguyên',
        );
        repo.failReads = true;
        container.invalidate(ledgerProvider);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục sửa'));
        await tester.pumpAndSettle();
        repo.failReads = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          'Draft còn nguyên',
        );
      } finally {
        await close(tester, container);
      }
    },
  );

  testWidgets(
    'B11 reduced route transitions and dialog use no visual animation',
    (tester) async {
      Widget? transition;
      const child = Text('Không chuyển động');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  transition = const MotionAwareTransitions().buildTransitions(
                    MaterialPageRoute<void>(builder: (_) => child),
                    context,
                    const AlwaysStoppedAnimation(.25),
                    const AlwaysStoppedAnimation(0),
                    child,
                  );
                  return Scaffold(
                    body: Column(
                      children: [
                        transition!,
                        TextButton(
                          onPressed: () => confirmAction(
                            context,
                            'Xác nhận?',
                            'Không thể hoàn tác.',
                          ),
                          child: const Text('Dialog'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(transition, same(child));
      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();
      expect(
        ModalRoute.of(tester.element(find.byType(AlertDialog)))!
            .transitionDuration,
        Duration.zero,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'B11 saving guard excludes keyboard focus as well as pointer input',
    (tester) async {
      final controller = TextEditingController();
      final saving = ValueNotifier(false);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: saving,
                builder: (context, value, _) => DraftGuard(
                  controllers: [controller],
                  hasChanges: () => true,
                  saving: value,
                  child: TextField(controller: controller),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final focus = tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode;
        expect(focus.hasFocus, isTrue);
        saving.value = true;
        await tester.pump();
        expect(focus.hasFocus, isFalse);
        expect(focus.canRequestFocus, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focus.hasFocus, isFalse);
        saving.value = false;
        await tester.pump();
        expect(focus.canRequestFocus, isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        saving.dispose();
      }
    },
  );
  testWidgets(
    'B11 unknown/stale quota and missing budget never speak measured zero percent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final unknown = AIAccount(
          id: 'unknown',
          alias: 'Chưa biết',
          provider: 'OpenAI',
          product: 'Codex',
          billingMode: BillingMode.api,
          plan: '',
          createdAt: now,
        );
        final stale = unknown.copyWith(
          quota: QuotaSnapshot(
            window: '5 giờ',
            usedPercent: 70,
            observedAt: now.subtract(const Duration(hours: 6)),
            resetAt: now.subtract(const Duration(hours: 1)),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Column(
                children: [
                  QuotaRow(account: unknown, now: now),
                  QuotaRow(account: stale, now: now),
                  const AnimatedProgress(
                    value: 0,
                    semanticValue: 'Chưa đặt ngân sách',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final nodes = find.byType(AnimatedProgress);
        expect(
          tester.getSemantics(nodes.at(0)).getSemanticsData().value,
          'Chưa có dữ liệu quota',
        );
        expect(
          tester.getSemantics(nodes.at(1)).getSemanticsData().value,
          'Quota đã quá reset; cần cập nhật',
        );
        expect(
          tester.getSemantics(nodes.at(2)).getSemanticsData().value,
          'Chưa đặt ngân sách',
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
