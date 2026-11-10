import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/widgets/common.dart';

import 'support/app_fonts.dart';

// QA-only gallery: exercises the same theme/widgets used by the app, no route
// or dependencies are added to the production navigation.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});
  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Component QA')),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (value) => setState(() => selected = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          label: 'Tài khoản',
        ),
        NavigationDestination(
          icon: Icon(Icons.donut_large),
          label: 'Phân tích',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Cá nhân',
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Button'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Chính')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
              OutlinedButton(onPressed: () {}, child: const Text('Phụ')),
              TextButton(onPressed: () {}, child: const Text('Text')),
              IconButton(
                onPressed: () {},
                tooltip: 'Thao tác',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SaveButton(label: 'Lưu', saving: true, onPressed: () {}),
          const SizedBox(height: 24),
          const SectionTitle('Textfield'),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Mặc định',
              helperText: 'Thông tin hướng dẫn dài có thể xuống dòng khi phóng lớn chữ.',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'Nội dung đã nhập',
            decoration: const InputDecoration(labelText: 'Đã điền'),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Lỗi',
              errorText: 'Nhập số USD không âm hợp lệ.',
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            enabled: false,
            decoration: InputDecoration(labelText: 'Không khả dụng'),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Card'),
          const Panel(child: Text('Surface card')),
          const SizedBox(height: 16),
          const Panel(
            color: AppColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mint summary'),
                SizedBox(height: 12),
                AnimatedProgress(value: .5),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Dialog'),
          OutlinedButton(
            onPressed: () => confirmAction(
              context,
              'Xác nhận thay đổi?',
              'Dữ liệu local chỉ được thay sau khi xác nhận.',
            ),
            child: const Text('Mở xác nhận'),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Loading'),
          const SizedBox(height: 64, child: LoadingFeedback()),
          const SizedBox(height: 24),
          const SectionTitle('Empty'),
          EmptyFeedback(
            title: 'Chưa có dữ liệu',
            message: 'Thêm một phiên sử dụng để bắt đầu.',
            action: 'Thêm phiên',
            onAction: () {},
          ),
          const SectionTitle('Error'),
          ErrorFeedback(
            message: 'Dữ liệu chưa đọc được. Thử lại để giữ nguyên không gian hiện tại.',
            retry: () {},
          ),
        ],
      ),
    ),
  );
}

const _imageRoot = String.fromEnvironment(
  'UI_AUDIT_OUTPUT',
  defaultValue: '.taste-skill/b08-b10',
);

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
      testWidgets('nine component families $width text $scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: boundary, child: child!),
            ),
            home: const ComponentGallery(),
          ),
        );
        // The gallery intentionally contains a live spinner: no pumpAndSettle.
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        for (final type in [
          FilledButton,
          OutlinedButton,
          TextButton,
          IconButton,
        ]) {
          final size = tester.getSize(find.byType(type).first);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(
            size.height,
            greaterThanOrEqualTo(type == FilledButton ? 52 : 48),
          );
        }
        final button = find.widgetWithText(FilledButton, 'Chính');
        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await gesture.up();
        await tester.tap(find.text('Tài khoản'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        final field = find.byType(TextField).first;
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.enterText(field, 'Nội dung có dấu tiếng Việt');
        await tester.pump();
        expect(
          tester.widget<TextField>(field).controller?.text ??
              tester
                  .widget<EditableText>(
                    find.descendant(
                      of: field,
                      matching: find.byType(EditableText),
                    ),
                  )
                  .controller
                  .text,
          'Nội dung có dấu tiếng Việt',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.scrollUntilVisible(
          find.text('Mở xác nhận'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Mở xác nhận')),
          alignment: .5,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Mở xác nhận'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Hủy'));
        await tester.pump(const Duration(milliseconds: 500));
        final state = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        state.position.jumpTo(state.position.maxScrollExtent);
        await tester.pump();
        expect(find.text('Thử lại'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('UI_AUDIT_IMAGES') && scale == 1) {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File('$_imageRoot/components-${width.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
