import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;

class StateRepository extends MemoryRepository {
  bool failReads = false;
  Completer<LedgerData?>? loading;
  Completer<void>? writing;
  int writes = 0;
  @override
  Future<LedgerData?> load() async {
    if (loading != null) return loading!.future;
    if (failReads) throw StateError('Read failed');
    return data;
  }

  @override
  Future<void> save(LedgerData value) async {
    writes++;
    if (writing != null) await writing!.future;
    await super.save(value);
  }
}

class AccessibilityHarness {
  final DateTime now = DateTime(2026, 10, 21, 10);

  static Future<void> loadFonts() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }

  ProviderContainer owner(StateRepository repo) => ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  Future<void> open(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen, {
    double width = 360,
    double scale = 1,
    bool reduce = true,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          key: UniqueKey(),
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduce,
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }
}
