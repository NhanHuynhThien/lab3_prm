import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_sync_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/provider_usage_card.dart';
import '../widgets/gemini_web_import_panel.dart';

class ProviderConnectionsScreen extends ConsumerStatefulWidget {
  const ProviderConnectionsScreen({super.key});
  @override
  ConsumerState<ProviderConnectionsScreen> createState() => _ConnectionsState();
}

class _ConnectionsState extends ConsumerState<ProviderConnectionsScreen> {
  final _token = TextEditingController(
    text: const String.fromEnvironment('PROVIDER_BRIDGE_TOKEN'),
  );
  bool _confirmed = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerSyncProvider);
    final owner = ref.watch(cloudOwnerProvider);
    final now = ref.watch(nowProvider);
    final actions = ref.read(providerSyncProvider.notifier);
    return ContentPage(
      title: 'Kết nối nguồn AI',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const Text(
            'Companion là kết nối CLI tùy chọn trên Mac. Đăng nhập Google, ghi usage và Gemini API không cần companion.',
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusTag('ChatGPT / Codex', neutral: true),
              StatusTag('Claude', neutral: true),
              StatusTag('Gemini CLI', neutral: true),
              StatusTag('Antigravity', neutral: true),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            color: AppColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Nguồn trên máy của bạn'),
                if (state.enabled) ...[
                  const SizedBox(height: 16),
                  const Text('Tự cập nhật mỗi 60 giây khi ứng dụng hoạt động.'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.working ? null : actions.refresh,
                        icon: const Icon(Icons.sync),
                        label: Text(
                          state.working ? 'Đang đồng bộ...' : 'Cập nhật ngay',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          actions.disconnect();
                          _token.clear();
                        },
                        child: const Text('Ngắt kết nối'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Chạy companion trên Mac, dùng mã ghép nối của máy đó. '
                  'Dữ liệu chỉ giữ trong phiên hiện tại, không tự tải lên Firestore. '
                  'Số liệu website và phí đã charge có thể chưa có nguồn.',
                ),
                if (owner == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Đăng nhập Google để ghép nguồn dữ liệu.'),
                  ),
                if (!state.enabled && owner != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _token,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Mã ghép nối companion',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: AppColors.soft,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _confirmed,
                      onChanged: (value) =>
                          setState(() => _confirmed = value ?? false),
                      title: const Text(
                        'Tôi muốn xem dữ liệu tài khoản CLI trên máy này trong phiên hiện tại.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: !_confirmed || state.working
                        ? null
                        : () async {
                            await actions.connect(_token.text.trim());
                            if (mounted &&
                                ref.read(providerSyncProvider).snapshot !=
                                    null) {
                              _token.clear();
                            }
                          },
                    icon: const Icon(Icons.link),
                    label: const Text('Kết nối nguồn trên máy'),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
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
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Thiết lập companion'),
                SelectableText('node tool/provider_bridge/setup.mjs'),
                SizedBox(height: 8),
                SelectableText('node tool/provider_bridge/server.mjs'),
                SizedBox(height: 12),
                Text(
                  'Lệnh setup tạo mã ghép nối tại ~/.local/share/tokenledger/bridge-token trên Mac. '
                  'Đây không phải mật khẩu Google hoặc Gemini API key. '
                  'Android Emulator cần adb reverse tcp:8787 tcp:8787.',
                ),
                SizedBox(height: 12),
                Text(
                  'Claude cần status line theo hướng dẫn TASKS.md. '
                  'Gemini CLI cần lịch sử phiên; Antigravity dùng agy /usage. '
                  'Chưa có nguồn sẽ hiện “Cần kết nối nguồn”, không dùng dữ liệu mẫu.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
