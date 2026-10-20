import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/widgets/brand_mark.dart';
import 'package:token_ledger/widgets/common.dart';

void main() {
  test(
    'B13 SVG source retains canonical geometry/colors and platform names',
    () {
      final svg = File('assets/brand/tokenledger-mark.svg').readAsStringSync();
      for (final token in [
        'viewBox="0 0 100 100"',
        'rx="26"',
        '#006C49',
        '#FFFFFF',
        '#A6E9C8',
        'stroke-width="5"',
        'M50 18 77 34V66L50 82 23 66V34Z',
        'M36 39H64M50 39V65',
        'M50 65 64 57',
      ]) {
        expect(svg, contains(token));
      }
      expect(
        File('web/manifest.json').readAsStringSync(),
        contains('"name": "TokenLedger"'),
      );
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="TokenLedger"'),
      );
    },
  );

  testWidgets(
    'B13 SVG-contract painter and all launcher icons have matching glyph geometry',
    (tester) async {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundary,
              child: const SizedBox.square(
                dimension: 512,
                child: BrandMark(size: 512),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        // Probe the canonical white hexagon/T and mint ledger branch, not a PNG
        // derived from the icon under test.
        for (final point in [
          (50, 18),
          (77, 34),
          (23, 66),
          (36, 39),
          (50, 50),
        ]) {
          final offset =
              ((point.$2 * 5.12).round() * 512 + (point.$1 * 5.12).round()) * 4;
          expect(rgba[offset], greaterThan(240));
          expect(rgba[offset + 1], greaterThan(240));
          expect(rgba[offset + 2], greaterThan(240));
        }
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        image.dispose();
        final paths = [
          ...Directory('android/app/src/main/res')
              .listSync()
              .whereType<Directory>()
              .where((d) => d.path.contains('mipmap-'))
              .map((d) => '${d.path}/ic_launcher.png'),
          'web/favicon.png',
          'web/icons/Icon-192.png',
          'web/icons/Icon-512.png',
        ];
        Future<(int, int, Uint8List)> decode(
          Uint8List bytes, {
          int? width,
          int? height,
        }) async {
          final codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: width,
            targetHeight: height,
          );
          final frame = await codec.getNextFrame();
          final result = (
            frame.image.width,
            frame.image.height,
            (await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List(),
          );
          frame.image.dispose();
          codec.dispose();
          return result;
        }

        for (final path in paths) {
          final actual = await decode(File(path).readAsBytesSync());
          final expected = await decode(
            png,
            width: actual.$1,
            height: actual.$2,
          );
          double error = 0;
          // Compare premultiplied colors, so invisible PNG corner RGB is irrelevant.
          for (var i = 0; i < actual.$3.length; i += 4) {
            for (var channel = 0; channel < 3; channel++) {
              error +=
                  (actual.$3[i + channel] * actual.$3[i + 3] / 255 -
                          expected.$3[i + channel] * expected.$3[i + 3] / 255)
                      .abs();
            }
          }
          expect(
            error / (actual.$1 * actual.$2 * 3),
            lessThan(8),
            reason: path,
          );
        }
        // Maskable variants retain the glyph at 78% scale, centered on a solid
        // primary square. The glyph must remain in the platform safe circle.
        for (final size in [192, 512]) {
          final mask = await decode(
            File('web/icons/Icon-maskable-$size.png').readAsBytesSync(),
          );
          var ink = 0;
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              final i = (y * size + x) * 4;
              expect(mask.$3[i + 3], 255);
              if (mask.$3[i] > 240 &&
                  mask.$3[i + 1] > 240 &&
                  mask.$3[i + 2] > 240) {
                ink++;
                expect(
                  math.sqrt(
                    math.pow(x - size / 2, 2) + math.pow(y - size / 2, 2),
                  ),
                  lessThan(size * .4),
                );
              }
            }
          }
          expect(ink, greaterThan(size * size * .03));
          final top = List.generate(
            size,
            (y) => mask.$3[((y * size) + (size ~/ 2)) * 4],
          ).indexWhere((r) => r > 240);
          expect(top / size, closeTo(.23, .015));
        }
      });
    },
  );

  testWidgets(
    'B13 product initials are graphemes and explicitly not official logos',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final account = createDemoSeed(DateTime(2026, 10, 21)).accounts.first
          .copyWith(product: '👩🏽‍💻 Công cụ cá nhân');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Column(
              children: [const BrandMark(), ProviderAvatar(account)],
            ),
          ),
        ),
      );
      expect(find.text('👩🏽‍💻'), findsOneWidget);
      expect(find.bySemanticsLabel('Logo TokenLedger'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Chữ viết tắt 👩🏽‍💻 Công cụ cá nhân; không phải logo nhà cung cấp',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );
}
