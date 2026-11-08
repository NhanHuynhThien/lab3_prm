import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cloud_workspace_harness.dart';

void main() {
  late CloudWorkspaceHarness h;

  setUpAll(() async {
    await CloudWorkspaceHarness.loadFonts();
  });

  setUp(() {
    h = CloudWorkspaceHarness();
  });

  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('cloud UI ${width.toInt()}dp text$scale actual fonts', (
        tester,
      ) async {
        await h.open(tester, width: width, scale: scale);
        try {
          expect(tester.takeException(), isNull);
          await h.nav(tester, 'Cá nhân');
          expect(find.text('User A'), findsWidgets);
          expect(find.text('Đã kết nối'), findsOneWidget);
          if (const bool.fromEnvironment('CLOUD_AUDIT_IMAGES')) {
            await tester.runAsync(() async {
              final render =
                  h.boundary.currentContext!.findRenderObject()!
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
          await h.nav(tester, 'Tài khoản');
          expect(tester.takeException(), isNull);
          await h.nav(tester, 'Phân tích');
          expect(tester.takeException(), isNull);
        } finally {
          await h.close(tester);
        }
      });
    }
  }
}
