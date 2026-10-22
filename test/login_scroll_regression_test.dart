import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/widgets/common.dart';
import 'package:token_ledger/widgets/google_sign_in_button.dart';

import 'support/auth_fakes.dart';
import 'support/auth_gate_harness.dart';

void main() {
  late AuthGateHarness h;

  setUpAll(AuthGateHarness.loadFonts);
  setUp(() {
    h = AuthGateHarness()
      ..service = FakeAuthService()
      ..repository = TrackingRepository();
  });

  testWidgets('Android overscroll never stretches content at either edge', (
    tester,
  ) async {
    await h.open(tester, width: 360);
    try {
      await tester.pumpAndSettle();
      final scroll = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scroll).position;
      final panel = tester.renderObject(find.byType(Panel).first);
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      final top = await tester.startGesture(tester.getCenter(scroll));
      await top.moveBy(const Offset(0, 180));
      await tester.pump(const Duration(milliseconds: 100));
      expect(panel.getTransformTo(null).getMaxScaleOnAxis(), closeTo(1, .001));
      expect(position.pixels, 0);
      await top.up();
      await tester.pumpAndSettle();
      await tester.drag(scroll, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final bottom = await tester.startGesture(tester.getCenter(scroll));
      await bottom.moveBy(const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 100));
      expect(panel.getTransformTo(null).getMaxScaleOnAxis(), closeTo(1, .001));
      expect(position.pixels, position.maxScrollExtent);
      await bottom.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      await h.close(tester);
    }
  });

  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('full Google button fits $width at text scale $scale', (
        tester,
      ) async {
        await h.open(tester, width: width, scale: scale);
        try {
          await tester.pumpAndSettle();
          final google = find.byType(GoogleSignInButton);
          await tester.ensureVisible(google);
          await tester.pumpAndSettle();
          expect(tester.getSize(google).height, greaterThanOrEqualTo(52));
          final icon = find.descendant(
            of: google,
            matching: find.byType(Image),
          );
          expect(tester.getSize(icon), const Size(20, 20));
          final demo = find.text('Mở không gian demo');
          expect(
            tester.getTopLeft(google).dy,
            lessThan(tester.getTopLeft(demo).dy),
          );
          expect(tester.takeException(), isNull);
        } finally {
          await h.close(tester);
        }
      });
    }
  }

  testWidgets('branded Google action retains busy guard and retry feedback', (
    tester,
  ) async {
    h.service.signInGate = Completer<void>();
    await h.open(tester);
    try {
      await tester.pumpAndSettle();
      await h.tap(tester, 'Đăng nhập bằng Google');
      expect(h.service.signIns, 1);
      expect(find.text('Đang đăng nhập...'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byType(GoogleSignInButton),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
      h.service.signInGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      expect(h.repository.loads, 0);
    } finally {
      await h.close(tester);
    }
  });
}
