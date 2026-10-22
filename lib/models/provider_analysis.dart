import 'provider_usage.dart';

/// A transparent assessment of observed metrics, not an invented model answer.
class ProviderAnalysis {
  const ProviderAnalysis(this.title, this.message, {this.warning = false});
  final String title, message;
  final bool warning;

  factory ProviderAnalysis.evaluate(ProviderUsage source, DateTime now) {
    if (source.status != 'ready') {
      return const ProviderAnalysis(
        'Chưa đủ dữ liệu',
        'Kết nối nguồn để đánh giá mức sử dụng. Chưa có số liệu không đồng nghĩa với chưa sử dụng.',
      );
    }
    final fresh =
        source.windows.where((w) => source.remaining(w, now) != null).toList()
          ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    if (fresh.isNotEmpty) {
      final tightest = fresh.first;
      final remaining = source.remaining(tightest, now)!;
      return ProviderAnalysis(
        remaining <= 10
            ? 'Sắp hết hạn mức'
            : remaining <= 25
            ? 'Nên theo dõi hạn mức'
            : 'Còn hạn mức sử dụng',
        '${tightest.displayLabel} còn ${remaining.toStringAsFixed(1)}%. '
        'Mỗi cửa sổ được đánh giá riêng; không cộng phần trăm giữa các model hoặc tài khoản.',
        warning: remaining <= 25,
      );
    }
    if (source.windows.isNotEmpty) {
      return const ProviderAnalysis(
        'Cần cập nhật hạn mức',
        'Bản đọc đã cũ hoặc qua thời điểm đặt lại. Cập nhật nguồn trước khi dựa vào phần trăm còn lại.',
        warning: true,
      );
    }
    if (source.id == 'gemini-web') {
      return const ProviderAnalysis(
        'Đã có lịch sử hoạt động',
        'Có thể xem tần suất sử dụng theo ngày. Google Takeout không xác nhận token, hạn mức hoặc chi phí.',
      );
    }
    return const ProviderAnalysis(
      'Đã có token, chưa có hạn mức',
      'Số token phản ánh phần lịch sử mà nguồn cung cấp. Chưa thể kết luận bạn sắp hết quota hoặc đã trả bao nhiêu tiền.',
    );
  }
}
