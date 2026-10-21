import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/app.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';

import 'support/ledger_cloud_fake.dart';

import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'support/auth_fakes.dart';

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

class DirectDemoEntry extends DemoSessionViewModel {
  @override
  bool build() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late FakeAuthService service;
  late TrackingRepository repository;
  late ProviderContainer container;
  late GlobalKey boundary;

  Future<void> open(
    WidgetTester tester, {
    double width = 412,
    double scale = 1,
    bool demo = false,
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
        if (demo) demoSessionProvider.overrideWith(DirectDemoEntry.new),
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
    final finder = find.text(label).last;
    if (find.text(label).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    if (container.read(authSessionProvider).asData?.value != null &&
        !container.read(demoSessionProvider)) {
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

  setUp(() {
    service = FakeAuthService();
    repository = TrackingRepository();
  });

  testWidgets(
    'guard waits for restored auth, never reads local ledger or invents identity',
    (tester) async {
      service.initializationGate = Completer<void>();
      await open(tester);
      try {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(repository.loads, 0);
        expect(repository.saves, 0);
        service.user = const AuthUser(
          uid: 'A',
          displayName: 'Người A',
          email: 'a@example.test',
        );
        service.initializationGate!.complete();
        await settle(tester);
        expect(container.read(authSessionProvider).requireValue!.uid, 'A');
        expect(
          tester
              .widget<ProfileScreen>(find.byType(ProfileScreen))
              .user!
              .displayName,
          'Người A',
        );
        expect(find.text('a@example.test'), findsOneWidget);
        expect(find.text('Claude cá nhân'), findsNothing);
        expect(repository.loads, 0);
        expect(container.exists(ledgerProvider), isFalse);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'unknown deep link always re-enters the guard without loading data',
    (tester) async {
      await open(tester);
      await settle(tester);
      try {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushNamed('/accounts/claude/usage/new');
        await settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(find.text('Lưu phiên sử dụng'), findsNothing);
        expect(repository.loads, 0);
        expect(repository.saves, 0);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'auth failure offers Retry and offline local demo without cloud writes',
    (tester) async {
      service.initializationError = const AuthFailure(
        AuthProblem.network,
        'Không kết nối được dịch vụ đăng nhập.',
      );
      await open(tester);
      await settle(tester);
      try {
        expect(
          find.text('Không kết nối được dịch vụ đăng nhập.'),
          findsOneWidget,
        );
        expect(repository.loads, 0);
        service.initializationError = null;
        await tap(tester, 'Thử kết nối lại');
        await settle(tester);
        expect(service.initializations, 2);
        await tap(tester, 'Mở không gian demo');
        await settle(tester);
        expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
        expect(repository.loads, 1);
        expect(service.signIns, 0);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'direct demo mode never initializes Firebase and leaving returns to guarded login',
    (tester) async {
      await open(tester, demo: true);
      await settle(tester);
      try {
        expect(service.initializations, 0);
        expect(repository.loads, 1);
        container.read(demoSessionProvider.notifier).leave();
        await settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(service.initializations, 1);
        expect(find.text('Claude cá nhân'), findsNothing);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'Google cancellation/retry and double click never synthesize login success',
    (tester) async {
      await open(tester);
      await settle(tester);
      try {
        service.signInError = const AuthFailure(
          AuthProblem.cancelled,
          'Bạn đã hủy đăng nhập Google.',
        );
        await tap(tester, 'Đăng nhập bằng Google');
        await settle(tester);
        expect(find.text('Bạn đã hủy đăng nhập Google.'), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
        service.signInError = null;
        service.signInGate = Completer<void>();
        await tap(tester, 'Đăng nhập bằng Google');
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
        await container.read(authActionProvider.notifier).signIn();
        expect(service.signIns, 2);
        service.emit(
          const AuthUser(
            uid: 'A',
            displayName: 'Người A',
            email: 'a@example.test',
          ),
        );
        service.signInGate!.complete();
        await settle(tester);
        expect(find.text('Người A'), findsOneWidget);
        expect(repository.loads, 0);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'UID change and logout remove every old route and draft from navigation',
    (tester) async {
      service.user = const AuthUser(
        uid: 'A',
        displayName: 'Người A',
        email: 'a@example.test',
      );
      await open(tester);
      await settle(tester);
      try {
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).last,
        );
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Private route A draft')),
          ),
        );
        await settle(tester);
        expect(find.text('Private route A draft'), findsOneWidget);
        service.emit(
          const AuthUser(
            uid: 'B',
            displayName: 'Người B',
            email: 'b@example.test',
          ),
        );
        await settle(tester);
        expect(find.text('Private route A draft'), findsNothing);
        expect(find.text('Người A'), findsNothing);
        expect(find.text('Người B'), findsOneWidget);
        expect(
          tester.state<NavigatorState>(find.byType(Navigator).last).canPop(),
          isFalse,
        );
        await tap(tester, 'Đăng xuất Google');
        await settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(find.text('Người B'), findsNothing);
        expect(repository.loads, 0);
        expect(repository.saves, 0);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'same UID profile updates render current name/email without resetting session',
    (tester) async {
      service.user = const AuthUser(uid: 'A', displayName: 'Tên cũ');
      await open(tester);
      await settle(tester);
      try {
        service.emit(
          const AuthUser(
            uid: 'A',
            displayName: 'Tên mới',
            email: 'updated@example.test',
          ),
        );
        await settle(tester);
        expect(find.text('Tên mới'), findsOneWidget);
        expect(find.text('Tên cũ'), findsNothing);
        expect(repository.loads, 0);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'logout failure retains identity and Retry does not show false success',
    (tester) async {
      service.user = const AuthUser(uid: 'A', displayName: 'Người A');
      await open(tester);
      await settle(tester);
      try {
        service.signOutError = const AuthFailure(
          AuthProblem.network,
          'Không đăng xuất được. Hãy thử lại.',
        );
        await tap(tester, 'Đăng xuất Google');
        await settle(tester);
        expect(container.read(authSessionProvider).requireValue!.uid, 'A');
        expect(
          tester
              .widget<ProfileScreen>(find.byType(ProfileScreen))
              .user!
              .displayName,
          'Người A',
        );
        expect(find.text('Không đăng xuất được. Hãy thử lại.'), findsOneWidget);
        service.signOutError = null;
        service.signOutGate = Completer<void>();
        await tap(tester, 'Đăng xuất Google');
        await container.read(authActionProvider.notifier).signOut();
        expect(service.signOuts, 2);
        expect(find.text('Đang đăng xuất...'), findsOneWidget);
        service.signOutGate!.complete();
        await settle(tester);
        expect(find.text('Mở không gian demo'), findsOneWidget);
      } finally {
        await close(tester);
      }
    },
  );

  testWidgets(
    'stalled auth restore times out to Retry and demo instead of an endless loader',
    (tester) async {
      service.initializationGate = Completer<void>();
      await open(tester);
      try {
        await tester.pump(const Duration(seconds: 21));
        await settle(tester);
        expect(find.text('Thử kết nối lại'), findsOneWidget);
        expect(repository.loads, 0);
        await tap(tester, 'Mở không gian demo');
        await settle(tester);
        expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
        service.initializationGate!.complete();
        await tester.pump();
      } finally {
        await close(tester);
      }
    },
  );

  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'auth UI fits ${width.toInt()}dp text$scale with real fonts',
        (tester) async {
          await open(tester, width: width, scale: scale);
          await settle(tester);
          try {
            await tap(tester, 'Đăng nhập bằng Google');
            await settle(tester);
            expect(find.byType(ProfileScreen), findsNothing);
            if (scale == 1) await capture(tester, 'login-${width.toInt()}');
            service.emit(
              const AuthUser(
                uid: 'A',
                displayName: 'Nguyễn Văn An · TokenLedger',
                email: 'tokenledger.user@example.test',
              ),
            );
            await settle(tester);
            expect(find.text('Nguyễn Văn An · TokenLedger'), findsOneWidget);
            if (scale == 1) await capture(tester, 'profile-${width.toInt()}');
            await tap(tester, 'Mở demo local riêng biệt');
            await settle(tester);
            expect(
              find.text('Ngân sách còn lại · Kỳ hiện tại'),
              findsOneWidget,
            );
            container.read(demoSessionProvider.notifier).leave();
            await settle(tester);
            expect(find.text('Nguyễn Văn An · TokenLedger'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await close(tester);
          }
        },
      );
    }
  }
}
