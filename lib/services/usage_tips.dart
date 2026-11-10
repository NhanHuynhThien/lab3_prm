import '../models/ledger_enums.dart';
import '../models/provider_activity.dart';
import '../models/provider_usage.dart';

/// Rule-based tips from local token counts only; no prompt content is read.
List<String> usageTips(
  ProviderActivity activity,
  ProviderUsage usage,
  DateTime now,
) {
  final tips = <String>[];
  final t = activity.tokens;
  final input = t.input, output = t.output, cached = t.cached;

  if (input != null && output != null && output > 0 && input / output > 100) {
    tips.add(
      'Input gấp ${(input / output).round()} lần output: context đang rất nặng. '
      'Mở phiên mới khi đổi việc, dùng /compact và chỉ đính kèm file cần thiết.',
    );
  }
  if (input != null && cached != null && input > 0 && cached / input < .3) {
    tips.add(
      'Chỉ ${(cached * 100 / input).round()}% input được cache. Giữ phần hướng dẫn '
      'đầu phiên ổn định và làm liên tục trong một phiên để tận dụng cache.',
    );
  }

  int share(Purpose p) {
    final hit = activity.purposes.where((x) => x.purpose == p).firstOrNull;
    return t.total == 0 || hit == null
        ? 0
        : (hit.tokens.total * 100 / t.total).round();
  }

  final other = share(Purpose.other), debug = share(Purpose.debug);
  if (other >= 40) {
    tips.add(
      '$other% token chưa rõ mục đích. Nêu mục tiêu ở câu đầu (sửa lỗi, viết test…) '
      'để thống kê chính xác và agent làm đúng việc hơn.',
    );
  }
  if (debug >= 25) {
    tips.add(
      '$debug% token dùng để sửa lỗi. Gửi kèm log/stack trace và bước tái hiện '
      'ngay từ đầu để giảm số lượt hỏi lại.',
    );
  }

  for (final w in usage.windows) {
    final left = usage.remaining(w, now);
    if (left != null && left < 15) {
      tips.add(
        '${w.scopeLabel} chỉ còn ${left.toStringAsFixed(0)}%. '
        'Dùng model nhẹ hơn cho việc đơn giản cho tới khi hạn mức đặt lại.',
      );
    }
  }
  return tips;
}
