import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_sync_status.dart';
import 'package:token_ledger/screens/provider_connections_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/provider_sync_viewmodel.dart';
import 'package:token_ledger/widgets/provider_usage_card.dart';

import 'support/auth_gate_harness.dart';
import 'support/provider_sync_fixtures.dart';

void main() {
  setUpAll(AuthGateHarness.loadFonts);
  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('provider model/quota cards fit $width text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fake = FakeProviderSync();
        final container = ProviderContainer(
          overrides: [
            cloudOwnerProvider.overrideWithValue('A'),
            providerSyncServiceProvider.overrideWithValue(fake),
          ],
        );
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: buildAppTheme(),
                home: const ProviderConnectionsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(fake.calls, 0);
          await container.read(providerSyncProvider.notifier).connect('a' * 64);
          await tester.pumpAndSettle();
          final list = tester
              .state<ScrollableState>(find.byType(Scrollable).last)
              .position;
          for (double y = 0; y <= list.maxScrollExtent; y += 300) {
            list.jumpTo(y);
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
          list.jumpTo(0);
          await tester.pumpAndSettle();
          // Direct pairing is hidden for the demo build.
          expect(find.text('Ghép trực tiếp (nhà phát triển)'), findsNothing);
          expect(find.text('Ngắt kết nối'), findsNothing);
          container.read(providerSyncProvider.notifier).disconnect();
          await tester.pumpAndSettle();
          expect(find.byType(ProviderUsageCard), findsNothing);
          expect(container.read(providerSyncProvider).snapshot, isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          container.dispose();
        }
      });
    }
  }
}
