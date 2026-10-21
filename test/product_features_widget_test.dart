import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/app.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/services/remote_config_service.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/product_features_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'product_features_test.dart'
    show FakeAnalyticsTransport, FakeConfigTransport;
import 'support/auth_fakes.dart';
import 'support/ledger_cloud_fake.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Profile RC refresh/error/fonts ${width}dp scale$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final transport = FakeConfigTransport()..remote(6, 55);
        final config = RemoteConfigService(transport);
        final analytics = AnalyticsService(FakeAnalyticsTransport());
        await analytics.setOwner('A');
        final container = ProviderContainer(
          overrides: [
            analyticsServiceProvider.overrideWithValue(analytics),
            remoteConfigServiceProvider.overrideWithValue(config),
            ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
            cloudOwnerProvider.overrideWithValue('A'),
          ],
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildAppTheme(),
              home: RepaintBoundary(
                key: boundary,
                child: const Scaffold(
                  body: ProfileScreen(
                    user: AuthUser(uid: 'A', displayName: 'Fixture user'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final refresh = find.byKey(const ValueKey('refresh-product-config'));
        await tester.scrollUntilVisible(refresh, 240, maxScrolls: 30);
        await Scrollable.ensureVisible(tester.element(refresh), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(refresh);
        await tester.pumpAndSettle();
        expect(find.text('Phiên gần đây: 6 · nguồn remote'), findsOneWidget);
        expect(
          find.text('Cảnh báo ngân sách: 55% · nguồn remote'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('FEATURE_IMAGES')) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('config-recent-value')),
          );
          await tester.pumpAndSettle();
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final folder = Directory('.taste-skill/product-features');
            folder.createSync(recursive: true);
            File('${folder.path}/profile-${width.toInt()}-$scale.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        transport.fetchError = StateError('private error');
        await tester.scrollUntilVisible(refresh, 240, maxScrolls: 30);
        await Scrollable.ensureVisible(tester.element(refresh), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(refresh);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Chưa lấy được cấu hình mới.'),
          findsOneWidget,
        );
        expect(find.text('Phiên gần đây: 6 · nguồn remote'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.pumpAndSettle();
        await analytics.close();
        await config.close();
      });
    }
  }
  testWidgets(
    'root auth shares features with cloud, same-tab/rebuild no duplicate; demo stops business tracking',
    (tester) async {
      final auth = FakeAuthService()..user = const AuthUser(uid: 'A');
      final backend = FakeAnalyticsTransport();
      final analytics = AnalyticsService(backend);
      final transport = FakeConfigTransport();
      final config = RemoteConfigService(transport);
      final store = LedgerCloudFake();
      final root = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          analyticsServiceProvider.overrideWithValue(analytics),
          remoteConfigServiceProvider.overrideWithValue(config),
          ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
          cloudRepositoryFactoryProvider.overrideWithValue(
            () => FirestoreLedgerRepository(ownerId: 'A', store: store),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: root,
          child: const TokenLedgerApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(backend.events.where((e) => e.name == 'login'), hasLength(1));
      expect(
        backend.events.where((e) => e.parameters['screen_name'] == 'overview'),
        hasLength(1),
      );
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      expect(
        backend.events.where((e) => e.parameters['screen_name'] == 'accounts'),
        hasLength(1),
      );
      expect(transport.fetches, 1);
      root.read(demoSessionProvider.notifier).enter();
      await tester.pumpAndSettle();
      final count = backend.events.length;
      await tester.tap(find.text('Phân tích').last);
      await tester.pumpAndSettle();
      expect(backend.events, hasLength(count));
      expect(backend.uid, isNull);
      await tester.pumpWidget(const SizedBox());
      root.dispose();
      await tester.pumpAndSettle();
      await analytics.close();
      await config.close();
      await tester.runAsync(() async {
        await store.close();
        await auth.changes.close();
      });
    },
  );
  testWidgets('initial demo does not initialize auth or product SDKs', (
    tester,
  ) async {
    final auth = FakeAuthService();
    final backend = FakeAnalyticsTransport();
    final analytics = AnalyticsService(backend);
    final transport = FakeConfigTransport();
    final config = RemoteConfigService(transport);
    final root = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        analyticsServiceProvider.overrideWithValue(analytics),
        remoteConfigServiceProvider.overrideWithValue(config),
        ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
      ],
    );
    root.read(demoSessionProvider.notifier).enter();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: root, child: const TokenLedgerApp()),
    );
    await tester.pumpAndSettle();
    expect(auth.initializations, 0);
    expect(backend.calls, isEmpty);
    expect(transport.prepares, 0);
    await tester.pumpWidget(const SizedBox());
    root.dispose();
    await tester.pumpAndSettle();
    await analytics.close();
    await config.close();
    await tester.runAsync(() async {
      await auth.changes.close();
    });
  });
}
