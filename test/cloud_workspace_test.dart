import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/services/firestore_ledger_codec.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/cloud_workspace_harness.dart';

void main() {
  late CloudWorkspaceHarness h;

  setUpAll(() async {
    await CloudWorkspaceHarness.loadFonts();
  });

  setUp(() {
    h = CloudWorkspaceHarness();
  });

  testWidgets(
    'cloud account create fails with draft intact; retry saves one; reload retains',
    (tester) async {
      await h.open(tester);
      try {
        await h.form(tester);
        h.stores['A']!.failAfterCommit = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        await h.tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        expect(find.text('Private A'), findsOneWidget);
        h.stores['A']!.changes.addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        await tester.pumpAndSettle();
        await h.tap(tester, 'Thử lại');
        expect(find.text('Private A'), findsOneWidget);
        await h.tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsNothing);
        await h.reveal(tester, find.text('Private A'));
        expect(find.text('Private A'), findsOneWidget);
        expect(
          h.stores['A']!.documents.keys
              .where((p) => p.contains('/accounts/'))
              .length,
          1,
        );
        h.auth.emit(null);
        await tester.pumpAndSettle();
        h.auth.emit(const AuthUser(uid: 'A', displayName: 'User A'));
        await tester.pumpAndSettle();
        await h.nav(tester, 'Tài khoản');
        await h.reveal(tester, find.text('Private A'));
        expect(find.text('Private A'), findsOneWidget);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'UID switch disposes private draft/listeners and B never sees A or demo data',
    (tester) async {
      await h.open(tester);
      try {
        await h.form(tester);
        h.auth.emit(const AuthUser(uid: 'B', displayName: 'User B'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountFormScreen), findsNothing);
        expect(find.text('Private A'), findsNothing);
        expect(h.stores['A']!.activeListeners, 0);
        expect(h.stores['B']!.activeListeners, 4);
        await h.nav(tester, 'Cá nhân');
        expect(find.text('User B'), findsOneWidget);
        expect(find.text('Đã kết nối'), findsNWidgets(2));
        await h.tap(tester, 'Mở demo local riêng biệt');
        expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
        expect(h.stores['B']!.activeListeners, 0);
        await h.nav(tester, 'Cá nhân');
        await h.tap(tester, 'Thoát không gian demo');
        await h.nav(tester, 'Tài khoản');
        expect(find.text('Private A'), findsNothing);
        expect(h.stores['B']!.documents, isEmpty);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'last-good listener error keeps search and profile/logout accessible',
    (tester) async {
      await h.open(tester);
      try {
        await h.form(tester);
        await h.tap(tester, 'Lưu tài khoản');
        await h.reveal(tester, find.byType(TextField));
        final search = find.byType(TextField).first;
        await tester.enterText(search, 'Private');
        await tester.pump();
        h.stores['A']!.changes.addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        await tester.pumpAndSettle();
        await h.reveal(tester, find.text('Private A'));
        expect(find.text('Private A'), findsOneWidget);
        expect(tester.widget<TextField>(search).controller!.text, 'Private');
        expect(find.textContaining('Lỗi kết nối'), findsOneWidget);
        await h.tap(tester, 'Thử lại');
        expect(find.text('Private A'), findsOneWidget);
        await h.nav(tester, 'Cá nhân');
        await h.tap(tester, 'Đăng xuất Google');
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(h.stores['A']!.activeListeners, 0);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'initial read failure never seeds cloud and Profile logout remains usable',
    (tester) async {
      await h.open(tester, corrupt: true);
      try {
        expect(find.text('Hoạt động AI'), findsOneWidget);
        await h.reveal(
          tester,
          find.textContaining('Không đọc được dữ liệu cloud'),
        );
        expect(
          find.textContaining('Không đọc được dữ liệu cloud'),
          findsOneWidget,
        );
        expect(h.root.exists(ledgerProvider), isFalse);
        await h.nav(tester, 'Cá nhân');
        expect(find.text('Lỗi kết nối'), findsOneWidget);
        expect(find.text('Đã kết nối'), findsOneWidget);
        await h.tap(tester, 'Đăng xuất Google');
        expect(find.text('Mở không gian demo'), findsOneWidget);
        expect(h.stores['A']!.documents.length, 1);
      } finally {
        await h.close(tester);
      }
    },
  );

  testWidgets(
    'remote edit does not overwrite an open form draft or accept stale save',
    (tester) async {
      await h.open(tester);
      try {
        await h.form(tester);
        await h.tap(tester, 'Lưu tài khoản');
        await h.reveal(tester, find.byTooltip('Mở chi tiết tài khoản'));
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
        final entry = h.stores['A']!.documents.entries.firstWhere(
          (e) => e.key.contains('/accounts/'),
        );
        final id = entry.key.split('/').last;
        final old = FirestoreLedgerCodec.account(id, entry.value, 'A');
        final external = FirestoreLedgerRepository(
          ownerId: 'A',
          store: h.stores['A']!,
          now: () => h.now,
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
        await h.tap(tester, 'Lưu tài khoản');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        expect(find.text('Unsaved private draft'), findsOneWidget);
        expect(
          (h.stores['A']!.documents[entry.key]!['payload'] as Map)['alias'],
          'Remote changed',
        );
      } finally {
        await h.close(tester);
      }
    },
  );
}
