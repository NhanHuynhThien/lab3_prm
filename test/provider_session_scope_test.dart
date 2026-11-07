import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/viewmodels/provider_sync_viewmodel.dart';

import 'support/auth_fakes.dart';
import 'support/auth_gate_harness.dart';
import 'support/provider_sync_fixtures.dart';

void main() {
  setUpAll(AuthGateHarness.loadFonts);
  final token = 'a' * 64;
  final owner = AuthUser(uid: 'A', email: 'owner@example.test');

  for (final demo in [false]) {
    testWidgets('paired sources are session scoped; demo=$demo', (
      tester,
    ) async {
      final fake = FakeProviderSync();
      final h = AuthGateHarness()
        ..service = (FakeAuthService()..user = owner)
        ..repository = TrackingRepository();
      await h.open(tester, providerSyncFactory: () => fake);
      try {
        await tester.pumpAndSettle();
        final scope = ProviderScope.containerOf(
          tester.element(find.byType(ShellScreen)),
        );
        await scope.read(providerSyncProvider.notifier).connect(token);
        await tester.pumpAndSettle();
        expect(fake.calls, demo ? 0 : 1);
        expect(
          scope.read(providerSyncProvider).snapshot,
          demo ? isNull : isNotNull,
        );
        if (!demo) {
          expect(find.text('ChatGPT / Codex'), findsOneWidget);
          expect(
            scope
                .read(providerSyncProvider)
                .snapshot!
                .providers
                .first
                .models
                .first
                .model,
            'codex-test-model',
          );
          scope.read(providerSyncProvider.notifier).disconnect();
          await tester.pumpAndSettle();
          expect(fake.calls, 1);
          expect(scope.read(providerSyncProvider).snapshot, isNull);
          h.service.emit(const AuthUser(uid: 'B', email: 'other@example.test'));
          await tester.pumpAndSettle();
          final next = ProviderScope.containerOf(
            tester.element(find.byType(ShellScreen)),
          );
          expect(next.read(providerSyncProvider).snapshot, isNull);
          expect(fake.calls, 1);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await h.close(tester);
      }
    });
  }
}
