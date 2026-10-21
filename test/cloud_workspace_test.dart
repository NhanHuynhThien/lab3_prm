import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/app.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/services/firestore_ledger_codec.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'support/auth_fakes.dart';
import 'support/ledger_cloud_fake.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21, 9);
  late FakeAuthService auth;
  late ProviderContainer root;
  late Map<String, LedgerCloudFake> stores;
  late GlobalKey boundary;
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> open(
    WidgetTester tester, {
    double width = 412,
    double scale = 1,
    bool corrupt = false,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    auth = FakeAuthService()
      ..user = const AuthUser(
        uid: 'A',
        displayName: 'User A',
        email: 'a@example.test',
      );
    stores = {'A': LedgerCloudFake(), 'B': LedgerCloudFake()..uid = 'B'};
    if (corrupt) {
      stores['A']!.documents['users/A/accounts/corrupt'] = {
        'updatedAt': Timestamp.now(),
      };
    }
    root = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
        clockProvider.overrideWithValue(() => now),
        cloudRepositoryFactoryProvider.overrideWithValue(
          () => FirestoreLedgerRepository(
            ownerId: auth.user!.uid,
            store: stores[auth.user!.uid]!,
            now: () => now,
          ),
        ),
      ],
    );
    boundary = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: root,
        child: RepaintBoundary(key: boundary, child: const TokenLedgerApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    root.dispose();
    await tester.pump();
    for (final store in stores.values) {
      await store.close();
    }
    await auth.changes.close();
  }

  Future<void> nav(WidgetTester tester, String label) async {
    final bar = find.byType(NavigationBar);
    final target = bar.evaluate().isNotEmpty
        ? find.descendant(of: bar, matching: find.text(label))
        : find.text(label == 'Tài khoản' ? 'Tài khoản AI' : label).first;
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label).first;
    if (find.text(label).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> form(WidgetTester tester) async {
    await nav(tester, 'Tài khoản');
    await tap(tester, 'Thêm tài khoản');
    await tester.enterText(find.byType(TextFormField).first, 'Private A');
  }

  testWidgets(
    'cloud account create fails with draft intact; retry saves one; reload retains',
    (tester) async {
      await open(tester);
      try {
        await form(tester);
        stores['A']!.failAfterCommit = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        await tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        expect(find.text('Private A'), findsOneWidget);
        stores['A']!.changes.addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, 'Thử lại');
        expect(find.text('Private A'), findsOneWidget);
        await tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsNothing);
        expect(find.text('Private A'), findsOneWidget);
        expect(
          stores['A']!.documents.keys
              .where((p) => p.contains('/accounts/'))
              .length,
          1,
        );
        // Destroy/recreate the user workspace; cloud store persists, filters/routes do not.
        auth.emit(null);
        await tester.pumpAndSettle();
        auth.emit(const AuthUser(uid: 'A', displayName: 'User A'));
        await tester.pumpAndSettle();
        await nav(tester, 'Tài khoản');
        expect(find.text('Private A'), findsOneWidget);
      } finally {
        await close(tester);
      }
    },
  );
  testWidgets(
    'UID switch disposes private draft/listeners and B never sees A or demo data',
    (tester) async {
      await open(tester);
      try {
        await form(tester);
        auth.emit(const AuthUser(uid: 'B', displayName: 'User B'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountFormScreen), findsNothing);
        expect(find.text('Private A'), findsNothing);
        expect(stores['A']!.activeListeners, 0);
        expect(stores['B']!.activeListeners, 4);
        await nav(tester, 'Cá nhân');
        expect(find.text('User B'), findsOneWidget);
        expect(find.text('Đã kết nối'), findsNWidgets(2));
        await tap(tester, 'Mở demo local riêng biệt');
        expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
        expect(stores['B']!.activeListeners, 0);
        await nav(tester, 'Cá nhân');
        await tap(tester, 'Thoát không gian demo');
        await nav(tester, 'Tài khoản');
        expect(find.text('Private A'), findsNothing);
        expect(stores['B']!.documents, isEmpty);
      } finally {
        await close(tester);
      }
    },
  );
  testWidgets(
    'last-good listener error keeps search and profile/logout accessible',
    (tester) async {
      await open(tester);
      try {
        await form(tester);
        await tap(tester, 'Lưu tài khoản');
        final search = find.byType(TextField).first;
        await tester.enterText(search, 'Private');
        await tester.pump();
        stores['A']!.changes.addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Private A'), findsOneWidget);
        expect(tester.widget<TextField>(search).controller!.text, 'Private');
        expect(find.textContaining('Lỗi kết nối'), findsOneWidget);
        await tap(tester, 'Thử lại');
        expect(find.text('Private A'), findsOneWidget);
        await nav(tester, 'Cá nhân');
        await tap(tester, 'Đăng xuất Google');
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(stores['A']!.activeListeners, 0);
      } finally {
        await close(tester);
      }
    },
  );
  testWidgets(
    'initial read failure never seeds cloud and Profile logout remains usable',
    (tester) async {
      await open(tester, corrupt: true);
      try {
        expect(
          find.textContaining('Không đọc được dữ liệu cloud'),
          findsOneWidget,
        );
        expect(root.exists(ledgerProvider), isFalse);
        await nav(tester, 'Cá nhân');
        expect(find.text('Lỗi kết nối'), findsOneWidget);
        expect(find.text('Đã kết nối'), findsOneWidget);
        await tap(tester, 'Đăng xuất Google');
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(stores['A']!.documents.length, 1);
      } finally {
        await close(tester);
      }
    },
  );
  testWidgets(
    'remote edit does not overwrite an open form draft or accept stale save',
    (tester) async {
      await open(tester);
      try {
        await form(tester);
        await tap(tester, 'Lưu tài khoản');
        await tester.ensureVisible(find.byTooltip('Mở chi tiết tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Mở chi tiết tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Sửa tài khoản'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Unsaved private draft',
        );
        final entry = stores['A']!.documents.entries.firstWhere(
          (e) => e.key.contains('/accounts/'),
        );
        final id = entry.key.split('/').last;
        final old = FirestoreLedgerCodec.account(id, entry.value, 'A');
        final external = FirestoreLedgerRepository(
          ownerId: 'A',
          store: stores['A']!,
          now: () => now,
        );
        await tester.runAsync(() async {
          await external.updateAccount(
            old.value.copyWith(alias: 'Remote changed'),
            expectedRevision: old.revision,
            operationId: 'remote-edit',
          );
          await external.close();
        });
        await tester.pumpAndSettle();
        expect(find.text('Unsaved private draft'), findsOneWidget);
        await tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        expect(find.text('Unsaved private draft'), findsOneWidget);
        expect(
          (stores['A']!.documents[entry.key]!['payload'] as Map)['alias'],
          'Remote changed',
        );
      } finally {
        await close(tester);
      }
    },
  );
  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('cloud UI ${width.toInt()}dp text$scale actual fonts', (
        tester,
      ) async {
        await open(tester, width: width, scale: scale);
        try {
          expect(tester.takeException(), isNull);
          await nav(tester, 'Cá nhân');
          expect(find.text('User A'), findsOneWidget);
          expect(find.text('Đã kết nối'), findsNWidgets(2));
          if (const bool.fromEnvironment('CLOUD_AUDIT_IMAGES')) {
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1);
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final file = File(
                '.taste-skill/firestore-ui/profile-${width.toInt()}-$scale.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes.buffer.asUint8List());
              image.dispose();
            });
          }
          expect(tester.takeException(), isNull);
          await nav(tester, 'Tài khoản');
          expect(tester.takeException(), isNull);
          await nav(tester, 'Phân tích');
          expect(tester.takeException(), isNull);
        } finally {
          await close(tester);
        }
      });
    }
  }
}
