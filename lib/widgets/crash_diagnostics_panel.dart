import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';

/// Lab 3 section 6.7 requires these two explicit diagnostic controls.
class CrashDiagnosticsPanel extends ConsumerWidget {
  const CrashDiagnosticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Panel(
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Chẩn đoán Crashlytics',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: [
        const Text(
          'Dùng khi nghiệm thu kỹ thuật Lab 3. Cần kiểm tra kết quả trong Firebase Console.',
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(productFeaturesProvider.notifier)
                    .recordHandledError('Lab 3 handled exception');
                if (context.mounted) {
                  showMessage(
                    context,
                    'Đã gửi yêu cầu ghi lỗi. Kiểm tra Crashlytics để xác nhận.',
                  );
                }
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Ghi lỗi có xử lý'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tạo test crash?'),
                    content: const Text(
                      'Ứng dụng sẽ đóng ngay. Hãy lưu công việc trước khi tiếp tục.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Tạo test crash'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  ref.read(productFeaturesProvider.notifier).triggerCrash();
                }
              },
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Tạo test crash'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
      ],
    ),
  );
}
