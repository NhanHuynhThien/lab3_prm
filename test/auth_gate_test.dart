import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/auth_fakes.dart';
import 'support/auth_gate_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthGateHarness h;

  setUpAll(() async {
    await AuthGateHarness.loadFonts();
  });

  setUp(() {
    h = AuthGateHarness()
      ..service = FakeAuthService()
      ..repository = TrackingRepository();
  });

  testWidgets(
    'guard waits for restored auth, never reads local ledger or invents identity',
    (tester) async {
      h.service.initializationGate = Completer<void>();
      await h.open(tester);
      try {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(h.repository.loads, 0);
        expect(h.repository.saves, 0);
        h.service.user = const AuthUser(
          uid: 'A',
          displayName: 'Người A',
          email: 'a@example.test',
        );
        h.service.initializationGate!.complete();
        await h.settle(tester);
        expect(h.container.read(authSessionProvider).requireValue!.uid, 'A');
        expect(
          tester
              .widget<ProfileScreen>(find.byType(ProfileScreen))
              .user!
              .displayName,
          'Người A',
        );
        expect(find.text('a@example.test'), findsOneWidget);
        expect(find.text('Claude cá nhân'), findsNothing);
        expect(h.repository.loads, 0);
        expect(h.container.exists(ledgerProvider), isFalse);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'unknown deep link always re-enters the guard without loading data',
    (tester) async {
      await h.open(tester);
      await h.settle(tester);
      try {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushNamed('/accounts/claude/usage/new');
        await h.settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(find.text('Lưu phiên sử dụng'), findsNothing);
        expect(h.repository.loads, 0);
        expect(h.repository.saves, 0);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'auth failure offers Retry and offline local demo without cloud writes',
    (tester) async {
      h.service.initializationError = const AuthFailure(
        AuthProblem.network,
        'Không kết nối được dịch vụ đăng nhập.',
      );
      await h.open(tester);
      await h.settle(tester);
      try {
        expect(
          find.text('Không kết nối được dịch vụ đăng nhập.'),
          findsOneWidget,
        );
        expect(h.repository.loads, 0);
        h.service.initializationError = null;
        await h.tap(tester, 'Thử kết nối lại');
        await h.settle(tester);
        expect(h.service.initializations, 2);
        await h.tap(tester, 'Mở không gian demo');
        await h.settle(tester);
        expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
        expect(h.repository.loads, 1);
        expect(h.service.signIns, 0);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'direct demo mode never initializes Firebase and leaving returns to guarded login',
    (tester) async {
      await h.open(tester, demo: true);
      await h.settle(tester);
      try {
        expect(h.service.initializations, 0);
        expect(h.repository.loads, 1);
        h.container.read(demoSessionProvider.notifier).leave();
        await h.settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(h.service.initializations, 1);
        expect(find.text('Claude cá nhân'), findsNothing);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'Google cancellation/retry and double click never synthesize login success',
    (tester) async {
      await h.open(tester);
      await h.settle(tester);
      try {
        h.service.signInError = const AuthFailure(
          AuthProblem.cancelled,
          'Bạn đã hủy đăng nhập Google.',
        );
        await h.tap(tester, 'Đăng nhập bằng Google');
        await h.settle(tester);
        expect(find.text('Bạn đã hủy đăng nhập Google.'), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
        h.service.signInError = null;
        h.service.signInGate = Completer<void>();
        await h.tap(tester, 'Đăng nhập bằng Google');
        expect(find.text('Đang đăng nhập...'), findsOneWidget);
        final workingButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Đang đăng nhập...'),
        );
        expect(workingButton.onPressed, isNull);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Mở không gian demo'),
              )
              .onPressed,
          isNull,
        );
        await h.container.read(authActionProvider.notifier).signIn();
        expect(h.service.signIns, 2);
        h.service.emit(
          const AuthUser(
            uid: 'A',
            displayName: 'Người A',
            email: 'a@example.test',
          ),
        );
        h.service.signInGate!.complete();
        await h.settle(tester);
        expect(find.text('Người A'), findsOneWidget);
        expect(h.repository.loads, 0);
      } finally {
        await h.close(tester);
      }
    },
  );
}
