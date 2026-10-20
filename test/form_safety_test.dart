import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

class ControlledRepository extends MemoryRepository {
  Completer<void>? pending;
  final List<LedgerData> attempts = [];

  @override
  Future<void> save(LedgerData value) async {
    attempts.add(value);
    if (pending != null) await pending!.future;
    await super.save(value);
  }
}

void main() {
  late ProviderContainer container;
  late ControlledRepository repository;
  final navigatorKey = GlobalKey<NavigatorState>();

  setUp(() async {
    repository = ControlledRepository();
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 10)),
      ],
    );
    await container.read(ledgerProvider.future);
    repository.attempts.clear();
  });
  tearDown(() => container.dispose());

  Widget screen(String kind) => switch (kind) {
    'account' => const AccountFormScreen(),
    'usage' => const UsageFormScreen(accountId: 'codex'),
    _ => QuotaFormScreen(account: repository.data!.account('codex')!),
  };
  String saveLabel(String kind) => switch (kind) {
    'account' => 'Lưu tài khoản',
    'usage' => 'Lưu phiên sử dụng',
    _ => 'Lưu hạn mức nhập tay',
  };

  Future<void> open(
    WidgetTester tester,
    Widget form, {
    double width = 412,
    double scale = 1,
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: Text('Home fixture')),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => form),
    );
    await tester.pumpAndSettle();
  }

  for (final kind in ['account', 'usage', 'quota']) {
    testWidgets('$kind clean Back exits, dirty Back can continue or discard', (
      tester,
    ) async {
      await open(tester, screen(kind));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home fixture'), findsOneWidget);
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen(kind)),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextFormField).first;
      final before = tester.widget<TextFormField>(field).controller!.text;
      await tester.enterText(field, 'Changed draft');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Changed draft',
      );
      // Restoring the initial value makes the form clean again.
      await tester.enterText(field, before);
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home fixture'), findsOneWidget);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen(kind)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Discard me');
      await tester.pump();
      // Exercise platform Back separately from the appbar BackButton.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Home fixture'), findsOneWidget);
      expect(repository.attempts, isEmpty);
    });

    for (final width in [360.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$kind fits ${width.toInt()}dp scale $scale with keyboard',
          (tester) async {
            await open(
              tester,
              screen(kind),
              width: width,
              scale: scale,
              keyboard: 300,
            );
            expect(tester.takeException(), isNull);
            final save = find.widgetWithText(FilledButton, saveLabel(kind));
            expect(save, findsOneWidget);
            final rect = tester.getRect(save);
            expect(rect.bottom, lessThanOrEqualTo(500));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            await tester.drag(find.byType(ListView), const Offset(0, -1600));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final kind in ['usage', 'account', 'quota']) {
    testWidgets(
      '$kind save failure keeps draft and retry uses the same ID once',
      (tester) async {
        await open(tester, screen(kind));
        await tester.enterText(find.byType(TextFormField).first, 'Retry draft');
        repository.failWrites = true;
        await tester.tap(find.text(saveLabel(kind)));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Retry draft',
        );
        expect(
          find.text('Chưa lưu được thay đổi. Vui lòng thử lại.'),
          findsOneWidget,
        );
        expect(repository.data!.sessions.length, 12);
        expect(repository.data!.accounts.length, 3);
        final first = repository.attempts.single;
        repository.failWrites = false;
        repository.pending = Completer<void>();
        await tester.tap(find.text(saveLabel(kind)));
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
        expect(find.byType(TextFormField), findsWidgets);
        final buttons = tester.widgetList<FilledButton>(
          find.byType(FilledButton),
        );
        expect(buttons.every((b) => b.onPressed == null), isTrue);
        expect(repository.attempts.length, 2);
        repository.pending!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Home fixture'), findsOneWidget);
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
        if (kind == 'usage') {
          expect(repository.data!.sessions.length, 13);
          expect(repository.data!.sessions.last.id, first.sessions.last.id);
          expect(repository.data!.sessions.last.costMicros, isNull);
        } else if (kind == 'account') {
          expect(repository.data!.accounts.length, 4);
          expect(repository.data!.accounts.last.id, first.accounts.last.id);
        } else {
          expect(
            repository.data!.account('codex')!.quota!.window,
            'Retry draft',
          );
          expect(repository.data!.accounts.length, 3);
        }
      },
    );
  }

  testWidgets('long account name fits usage picker at 360dp with large text', (
    tester,
  ) async {
    final account = repository.data!.account('codex')!;
    await container
        .read(ledgerProvider.notifier)
        .saveAccount(
          account.copyWith(alias: List.filled(8, 'Codex học').join(' ')),
        );
    await open(tester, screen('usage'), width: 360, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('archived usage opens with its account and saves history', (
    tester,
  ) async {
    final original = repository.data!.sessions.firstWhere(
      (s) => s.accountId == 'codex',
    );
    await container.read(ledgerProvider.notifier).archiveAccount('codex', true);
    await open(tester, UsageFormScreen(session: original));
    expect(
      find.textContaining('Bạn vẫn có thể sửa phiên lịch sử'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField).first, 'Edited archive');
    await tester.tap(find.text('Lưu phiên sử dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Home fixture'), findsOneWidget);
    expect(repository.data!.sessions.length, 12);
    expect(
      repository.data!.sessions.firstWhere((s) => s.id == original.id).title,
      'Edited archive',
    );
  });

  testWidgets('purpose round trip keeps usage draft without discard dialog', (
    tester,
  ) async {
    await open(tester, screen('usage'));
    await tester.enterText(find.byType(TextFormField).first, 'Keep my work');
    final purpose = find.text('Mục đích: Lập trình');
    await tester.ensureVisible(purpose);
    await tester.tap(purpose);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nghiên cứu'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Keep my work',
    );
    expect(find.text('Mục đích: Nghiên cứu'), findsOneWidget);
  });
}
