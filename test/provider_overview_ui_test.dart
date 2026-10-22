import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_sync_status.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/viewmodels/provider_sync_viewmodel.dart';
import 'package:token_ledger/widgets/provider_sync_summary.dart';
import 'package:token_ledger/theme/app_theme.dart';

import 'support/auth_gate_harness.dart';
import 'support/provider_sync_fixtures.dart';

void main() {
  setUpAll(AuthGateHarness.loadFonts);
  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'AI overview quota/model/empty states at $width text $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final fake = FakeProviderSync();
          const path = String.fromEnvironment('PROVIDER_VISUAL_SNAPSHOT');
          if (path.isNotEmpty) {
            fake.value = ProviderSnapshot.fromJson(
              jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
            );
          }
          final container = ProviderContainer(
            overrides: [
              cloudOwnerProvider.overrideWithValue('A'),
              providerSyncServiceProvider.overrideWithValue(fake),
            ],
          );
          final boundary = GlobalKey();
          try {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: buildAppTheme(),
                  home: RepaintBoundary(
                    key: boundary,
                    child: const Scaffold(
                      body: SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: ProviderSyncSummary(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await container
                .read(providerSyncProvider.notifier)
                .connect('a' * 64);
            await tester.pumpAndSettle();
            expect(find.text('Hoạt động AI'), findsOneWidget);
            expect(find.text('Token lifetime · server'), findsOneWidget);
            final scroll = tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            for (
              double offset = 0;
              offset <= scroll.maxScrollExtent;
              offset += 300
            ) {
              scroll.jumpTo(offset);
              await tester.pump();
              expect(tester.takeException(), isNull);
            }
            scroll.jumpTo(0);
            await tester.pumpAndSettle();
            if (path.isNotEmpty) {
              await tester.runAsync(() async {
                final render =
                    boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final capture = await render.toImage(pixelRatio: 1);
                final bytes = await capture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('/tmp/tokenledger-ai-ui-${width.toInt()}-$scale.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
                capture.dispose();
              });
            }
            await tester.ensureVisible(
              find.widgetWithText(ChoiceChip, 'Antigravity'),
            );
            await tester.tap(find.widgetWithText(ChoiceChip, 'Antigravity'));

            await tester.pumpAndSettle();
            expect(find.text('Chưa đủ dữ liệu để đánh giá'), findsOneWidget);
            expect(find.text('Token lifetime · server'), findsNothing);
            container.read(providerSyncProvider.notifier).disconnect();
            await tester.ensureVisible(
              find.widgetWithText(ChoiceChip, 'Codex'),
            );
            await tester.tap(find.widgetWithText(ChoiceChip, 'Codex'));
            await tester.pumpAndSettle();
            expect(find.text('Chưa đủ dữ liệu để đánh giá'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            container.dispose();
          }
        },
      );
    }
  }
}
