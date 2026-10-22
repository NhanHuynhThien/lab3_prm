import 'provider_usage.dart';

class AntigravityGroupAnalysis {
  AntigravityGroupAnalysis(
    this.name,
    this.windows,
    ProviderUsage source,
    DateTime now,
  ) {
    final fresh =
        windows.where((w) => source.remaining(w, now) != null).toList()
          ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    limiting = fresh.firstOrNull;
    remaining = limiting == null ? null : source.remaining(limiting!, now);
  }
  final String name;
  final List<ProviderQuota> windows;
  late final ProviderQuota? limiting;
  late final double? remaining;

  String get title => name.toLowerCase().contains('gemini')
      ? 'Nhóm Gemini'
      : name.toLowerCase().contains('claude') &&
            name.toLowerCase().contains('gpt')
      ? 'Nhóm Claude & GPT'
      : name;

  String get assessment => remaining == null
      ? 'Cần cập nhật quota trước khi đánh giá.'
      : remaining! <= 10
      ? 'Hạn mức ${limiting!.windowLabel} sắp hết; đây là cửa sổ cần chú ý nhất của nhóm.'
      : remaining! <= 25
      ? 'Theo dõi cửa sổ ${limiting!.windowLabel}; còn ${remaining!.toStringAsFixed(1)}%.'
      : 'Còn ${remaining!.toStringAsFixed(1)}% trong cửa sổ chặt nhất có dữ liệu hợp lệ. Không cộng phần trăm giữa các cửa sổ.';
}

List<AntigravityGroupAnalysis> antigravityGroups(
  ProviderUsage source,
  DateTime now,
) {
  final grouped = <String, List<ProviderQuota>>{};
  for (final window in source.windows) {
    grouped.putIfAbsent(window.groupLabel, () => []).add(window);
  }
  return grouped.entries
      .map(
        (e) => AntigravityGroupAnalysis(
          e.key,
          List.unmodifiable(e.value),
          source,
          now,
        ),
      )
      .toList();
}
