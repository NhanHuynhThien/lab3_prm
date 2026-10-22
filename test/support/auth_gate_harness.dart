import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/app.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/provider_auto_connect.dart';
import 'package:token_ledger/viewmodels/provider_sync_viewmodel.dart';
import 'package:token_ledger/services/provider_sync_service.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;
import 'auth_fakes.dart';
import 'ledger_cloud_fake.dart';

class TrackingRepository extends MemoryRepository {
  int loads = 0, saves = 0;
  @override
  Future<LedgerData?> load() async {
    loads++;
    return super.load();
  }

  @override
  Future<void> save(LedgerData value) async {
    saves++;
    await super.save(value);
  }
}

class AuthGateHarness {
  late FakeAuthService service;
  late TrackingRepository repository;
  late ProviderContainer container;
  late GlobalKey boundary;

  static Future<void> loadFonts() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }

  Future<void> open(
    WidgetTester tester, {
    double width = 412,
    double scale = 1,
    ProviderAutoConnect? autoConnect,
    ProviderSyncService Function()? providerSyncFactory,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(service),
        if (autoConnect != null)
          providerAutoConnectProvider.overrideWithValue(autoConnect),
        if (providerSyncFactory != null)
          providerSyncServiceFactoryProvider.overrideWithValue(
            providerSyncFactory,
          ),
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 10)),
        cloudRepositoryFactoryProvider.overrideWithValue(() {
          final store = LedgerCloudFake()..uid = service.user!.uid;
          addTearDown(store.close);
          return FirestoreLedgerRepository(
            ownerId: service.user!.uid,
            store: store,
          );
        }),
      ],
    );
    boundary = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: boundary, child: const TokenLedgerApp()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await service.changes.close();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    if (find.text(label).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    if (container.read(authSessionProvider).asData?.value != null) {
      final nav = find.byType(NavigationBar);
      final profile = nav.evaluate().isNotEmpty
          ? find.descendant(of: nav, matching: find.text('Cá nhân'))
          : find.text('Cá nhân');
      if (profile.evaluate().isNotEmpty) {
        await tester.tap(profile.first);
        await tester.pumpAndSettle();
      }
    }
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('AUTH_AUDIT_IMAGES')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final out = File('.taste-skill/c01-c03/$name.png');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
  }
}
