import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/provider_usage_card.dart';
import '../widgets/gemini_web_import_panel.dart';

class ProviderConnectionsScreen extends ConsumerWidget {
  const ProviderConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerSyncProvider);
    final now = ref.watch(nowProvider);
    return ContentPage(
      title: 'Kết nối nguồn AI',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const Text(
            'Companion chạy nền trên máy tính, đọc log Codex, Claude, Gemini CLI và Antigravity rồi ghi số liệu token vào tài khoản Google của bạn. App chỉ đọc từ tài khoản, không cần mã ghép nối.',
          ),
          const SizedBox(height: 16),
          Panel(
            color: AppColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Đồng bộ nền từ máy tính'),
                Text(
                  state.snapshot == null
                      ? 'Chưa nhận được số liệu nào cho tài khoản này.'
                      : 'Số liệu nhận lúc ${shortDate(state.snapshot!.collectedAt)} ${shortTime(state.snapshot!.collectedAt)}. Tự cập nhật khi companion ghi bản mới.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Cài TokenLedger Companion trên máy tính.\n'
                  '2. Mở Companion và đăng nhập cùng tài khoản Google.\n'
                  '3. Bật đồng bộ nền. Số liệu sẽ tự xuất hiện ở đây.',
                ),
                const SizedBox(height: 8),
                Text(
                  'Chỉ gửi con số tổng hợp (token, model, mục đích), không gửi nội dung chat. Tạm dừng hoặc đăng xuất ngay trong Companion.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.snapshot case final snapshot?)
            for (final usage in snapshot.providers) ...[
              ProviderUsageCard(usage: usage, now: now),
              const SizedBox(height: 16),
            ],
          const GeminiWebImportPanel(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
