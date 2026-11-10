import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';

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
    'UID change and logout remove every old route and draft from navigation',
    (tester) async {
      h.service.user = const AuthUser(
        uid: 'A',
        displayName: 'Người A',
        email: 'a@example.test',
      );
      await h.open(tester);
      await h.settle(tester);
      try {
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).last,
        );
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Private route A draft')),
          ),
        );
        await h.settle(tester);
        expect(find.text('Private route A draft'), findsOneWidget);
        h.service.emit(
          const AuthUser(
            uid: 'B',
            displayName: 'Người B',
            email: 'b@example.test',
          ),
        );
        await h.settle(tester);
        expect(find.text('Private route A draft'), findsNothing);
        expect(find.text('Người A'), findsNothing);
        expect(find.text('Người B'), findsOneWidget); // header island
        expect(
          tester.state<NavigatorState>(find.byType(Navigator).last).canPop(),
          isFalse,
        );
        await h.tap(tester, 'Đăng xuất');
        await h.settle(tester);
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
        expect(find.text('Người B'), findsNothing);
        expect(h.repository.loads, 0);
        expect(h.repository.saves, 0);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'same UID profile updates render current name/email without resetting session',
    (tester) async {
      h.service.user = const AuthUser(uid: 'A', displayName: 'Tên cũ');
      await h.open(tester);
      await h.settle(tester);
      try {
        h.service.emit(
          const AuthUser(
            uid: 'A',
            displayName: 'Tên mới',
            email: 'updated@example.test',
          ),
        );
        await h.settle(tester);
        expect(find.text('Tên mới'), findsOneWidget); // header island
        expect(find.text('Tên cũ'), findsNothing);
        expect(h.repository.loads, 0);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'logout failure retains identity and Retry does not show false success',
    (tester) async {
      h.service.user = const AuthUser(uid: 'A', displayName: 'Người A');
      await h.open(tester);
      await h.settle(tester);
      try {
        h.service.signOutError = const AuthFailure(
          AuthProblem.network,
          'Không đăng xuất được. Hãy thử lại.',
        );
        await h.tap(tester, 'Đăng xuất');
        await h.settle(tester);
        expect(h.container.read(authSessionProvider).requireValue!.uid, 'A');
        expect(
          tester
              .widget<ProfileScreen>(find.byType(ProfileScreen))
              .user!
              .displayName,
          'Người A',
        );
        expect(find.text('Không đăng xuất được. Hãy thử lại.'), findsOneWidget);
        h.service.signOutError = null;
        h.service.signOutGate = Completer<void>();
        await h.tap(tester, 'Đăng xuất');
        await h.container.read(authActionProvider.notifier).signOut();
        expect(h.service.signOuts, 2);
        expect(find.text('Đang đăng xuất...'), findsOneWidget);
        h.service.signOutGate!.complete();
        await h.settle(tester);
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'stalled auth restore times out to Retry and demo instead of an endless loader',
    (tester) async {
      h.service.initializationGate = Completer<void>();
      await h.open(tester);
      try {
        await tester.pump(const Duration(seconds: 21));
        await h.settle(tester);
        expect(find.text('Thử kết nối lại'), findsOneWidget);
        expect(h.repository.loads, 0);
        expect(find.text('Mở không gian demo'), findsNothing);
        h.service.initializationGate!.complete();
        await tester.pump();
      } finally {
        await h.close(tester);
      }
    },
  );

  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'auth UI fits ${width.toInt()}dp text$scale with real fonts',
        (tester) async {
          await h.open(tester, width: width, scale: scale);
          await h.settle(tester);
          try {
            await h.tap(tester, 'Đăng nhập bằng Google');
            await h.settle(tester);
            expect(find.byType(ProfileScreen), findsNothing);
            if (scale == 1) await h.capture(tester, 'login-${width.toInt()}');
            h.service.emit(
              const AuthUser(
                uid: 'A',
                displayName: 'Nguyễn Văn An · TokenLedger',
                email: 'tokenledger.user@example.test',
              ),
            );
            await h.settle(tester);
            expect(find.text('Nguyễn Văn An · TokenLedger'), findsWidgets);
            if (scale == 1) await h.capture(tester, 'profile-${width.toInt()}');
            expect(find.text('Mở demo local riêng biệt'), findsNothing);
            expect(find.text('Nguyễn Văn An · TokenLedger'), findsWidgets);
            expect(tester.takeException(), isNull);
          } finally {
            await h.close(tester);
          }
        },
      );
    }
  }
}
