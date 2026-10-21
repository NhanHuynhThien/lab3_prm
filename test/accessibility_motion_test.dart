import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/common.dart';
import 'package:token_ledger/widgets/draft_guard.dart';

import 'support/accessibility_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AccessibilityHarness h;

  setUpAll(() async {
    await AccessibilityHarness.loadFonts();
  });

  setUp(() {
    h = AccessibilityHarness();
  });

  testWidgets('B11 dynamic reduced motion keeps tab filters and scroll', (
    tester,
  ) async {
    final repo = StateRepository();
    final container = h.owner(repo);
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
      await h.close(tester, container);
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
}
