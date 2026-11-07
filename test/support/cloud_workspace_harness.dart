import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/app.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;
import 'auth_fakes.dart';
import 'ledger_cloud_fake.dart';

class CloudWorkspaceHarness {
  final DateTime now = DateTime.utc(2026, 10, 21, 9);
  late FakeAuthService auth;
  late ProviderContainer root;
  late Map<String, LedgerCloudFake> stores;
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

  /// Accounts is a page pushed from Profile, not a tab.
  Future<void> nav(WidgetTester tester, String label) async {
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    }
    final tab = label == 'Tài khoản' ? 'Cá nhân' : label;
    final bar = find.byType(NavigationBar);
    final target = bar.evaluate().isNotEmpty
        ? find.descendant(of: bar, matching: find.text(tab))
        : find.text(tab).first;
    await tester.tap(target);
    await tester.pumpAndSettle();
    if (label == 'Tài khoản') await tap(tester, 'Tài khoản tự ghi');
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

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}
