import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/gemini_activity_viewmodel.dart';
import 'common.dart';

class GeminiWebImportPanel extends ConsumerWidget {
  const GeminiWebImportPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geminiActivityProvider);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Gemini web · nhập hoạt động'),
          const Text(
            'Tải bản xuất Google Takeout: My Activity → Gemini Apps → định dạng JSON. Giải nén và chọn MyActivity.json.',
          ),
          const SizedBox(height: 12),
          Text(
            'App chỉ giữ tổng số hoạt động và ngày sử dụng trong phiên đăng nhập. Nội dung hội thoại không được tải lên cloud. Quota và token không có trong bản xuất sẽ để trống.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.working
                ? null
                : () async {
                    try {
                      final files = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (!context.mounted || files.isEmpty) return;
                      final file = files.single;
                      final length = await file.length();
                      if (!context.mounted) return;
                      if ((length ?? 8 * 1024 * 1024 + 1) > 8 * 1024 * 1024) {
                        showMessage(
                          context,
                          'Chọn file JSON nhỏ hơn 8 MB. Hãy xuất riêng hoạt động Gemini.',
                        );
                        return;
                      }
                      final bytes = await file.readAsBytes();
                      if (!context.mounted) return;
                      await ref
                          .read(geminiActivityProvider.notifier)
                          .importBytes(bytes);
                    } catch (_) {
                      if (context.mounted) {
                        showMessage(
                          context,
                          'Chưa mở được bộ chọn file. Hãy thử lại.',
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.file_upload_outlined),
            label: Text(
              state.working
                  ? 'Đang phân tích file...'
                  : 'Chọn file JSON Gemini',
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          if (state.summary != null) ...[
            const SizedBox(height: 16),
            Text(
              '${state.summary!.activityCount} hoạt động · ${state.summary!.activeDays} ngày sử dụng trong 30 ngày',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: ref.read(geminiActivityProvider.notifier).clear,
              child: const Text('Bỏ bản nhập trong phiên này'),
            ),
          ],
        ],
      ),
    );
  }
}
