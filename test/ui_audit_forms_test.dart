import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'support/app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadAppFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('forms keyboard and SafeArea $width text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewInsets);
        final container = ProviderContainer(
          overrides: [
            ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
            clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 10)),
          ],
        );
        final data = await container.read(ledgerProvider.future);
        try {
          for (final form in [
            const AccountFormScreen(),
            const UsageFormScreen(accountId: 'codex'),
            QuotaFormScreen(account: data.account('codex')!),
          ]) {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: buildAppTheme(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: form,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final field = find.byKey(
              ValueKey(
                form is AccountFormScreen
                    ? 'account-budget'
                    : form is UsageFormScreen
                    ? 'usage-note'
                    : 'quota-percent',
              ),
            );
            await tester.scrollUntilVisible(
              field,
              250,
              scrollable: find.byType(Scrollable).first,
            );
            await Scrollable.ensureVisible(
              tester.element(field),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.descendant(of: field, matching: find.byType(EditableText)),
            );
            await tester.pumpAndSettle();
            final save = find.byType(FilledButton).last;
            final rect = tester.getRect(save);
            expect(rect.bottom, lessThanOrEqualTo(500));
            expect(rect.top, greaterThan(24));
            expect(rect.height, greaterThanOrEqualTo(52));
            expect(save.hitTestable(), findsOneWidget);
            expect(
              find
                  .descendant(of: field, matching: find.byType(EditableText))
                  .hitTestable(),
              findsOneWidget,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: form.runtimeType.toString(),
            );
            await tester.pumpWidget(const SizedBox());
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          container.dispose();
        }
      });
    }
  }
}
