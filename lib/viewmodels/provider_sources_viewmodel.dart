import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_usage.dart';
import 'gemini_activity_viewmodel.dart';
import 'provider_sync_viewmodel.dart';

class SelectedSource extends Notifier<String> {
  @override
  String build() => 'codex';
  void select(String id) {
    if (providerNames.containsKey(id)) state = id;
  }
}

final selectedSourceProvider = NotifierProvider<SelectedSource, String>(
  SelectedSource.new,
);

final providerSourcesProvider = Provider<List<ProviderUsage>>((ref) {
  final rows =
      ref.watch(providerSyncProvider.select((s) => s.snapshot?.providers)) ??
      const <ProviderUsage>[];
  final activity = ref.watch(geminiActivityProvider.select((s) => s.summary));
  return [
    for (final id in providerNames.keys)
      if (id == 'gemini-web' && activity != null)
        ProviderUsage(
          id: id,
          status: 'ready',
          source: 'Google Takeout · Gemini Apps',
          coverage: 'Hoạt động 30 ngày từ bản xuất Google. File không cung cấp token, quota hoặc hóa đơn.',
          observedAt: activity.importedAt,
          windows: const [],
        )
      else
        rows.where((r) => r.id == id).firstOrNull ??
            ProviderUsage(
              id: id,
              status: 'setup',
              source: providerNames[id]!,
              coverage: id == 'gemini-web'
                  ? 'Nhập file JSON Gemini Apps từ Google Takeout để xem tần suất hoạt động.'
                  : 'Kết nối nguồn trên Mac để đọc số liệu.',
              observedAt: null,
              windows: const [],
            ),
  ];
});
