import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_sync_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/provider_usage_card.dart';
import '../widgets/gemini_web_import_panel.dart';

// DEMO: ẩn phần "Ghép trực tiếp (nhà phát triển)". Đổi thành `kDebugMode`
// (import package:flutter/foundation.dart) để hiện lại khi phát triển.
const _showDirectPairing = false;

class ProviderConnectionsScreen extends ConsumerStatefulWidget {
  const ProviderConnectionsScreen({super.key});
  @override
  ConsumerState<ProviderConnectionsScreen> createState() => _ConnectionsState();
}

class _ConnectionsState extends ConsumerState<ProviderConnectionsScreen> {
  final _token = TextEditingController();
  bool _confirmed = false, _showToken = false;

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
            'Companion chạy nền trên máy tính, đọc log Codex, Claude, Gemini CLI và Antigravity rồi ghi số liệu token vào tài khoản Google của bạn. App chỉ đọc từ tài khoản, không cần mã ghép nối.',
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
          // Direct pairing is a developer tool; users only need the background sync.
          if (_showDirectPairing) ...[
            const SizedBox(height: 16),
            Panel(
              child: ExpansionTile(
                // Rebuild when pairing changes so a live pairing opens expanded.
                key: ValueKey(state.enabled),
                initiallyExpanded: state.enabled,
                tilePadding: EdgeInsets.zero,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: const Text('Ghép trực tiếp (nhà phát triển)'),
                subtitle: const Text('Không cần cho người dùng'),
                children: [
                  if (state.enabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Tự cập nhật mỗi 60 giây khi ứng dụng hoạt động.',
                    ),
                    ActionButtons(
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
                    'Chỉ dùng khi phát triển: chạy node tool/provider_bridge/server.mjs, '
                    'dán mã trong ~/.local/share/tokenledger/bridge-token. '
                    'Emulator tự kết nối qua 10.0.2.2; máy thật cần adb reverse tcp:8787 tcp:8787.',
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
                      obscureText: !_showToken,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Mã ghép nối companion',
                        suffixIcon: IconButton(
                          tooltip: _showToken ? 'Ẩn mã' : 'Hiện mã',
                          onPressed: () =>
                              setState(() => _showToken = !_showToken),
                          icon: Icon(
                            _showToken
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
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
                          'Tôi muốn lưu số liệu token CLI trên máy này vào tài khoản của tôi.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
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
          ],
          const SizedBox(height: 16),
          if (state.snapshot case final snapshot?)
            for (final usage in snapshot.providers) ...[
              ProviderUsageCard(usage: usage, now: now),
              const SizedBox(height: 16),
            ],
          const GeminiWebImportPanel(),
          const SizedBox(height: 16),
          const Panel(
            child: Text(
              'Claude cần bật status line theo file do node tool/provider_bridge/setup.mjs tạo. '
              'Gemini CLI cần lịch sử phiên; Antigravity dùng agy /usage. '
              'Chưa có nguồn sẽ hiện “Cần kết nối nguồn”, không dùng dữ liệu mẫu.',
            ),
          ),
        ],
      ),
    );
  }
}
