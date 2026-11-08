import 'package:characters/characters.dart';

import '../models/ledger.dart';
import 'reporting_calendar.dart';

/// Shared local schema/form rules. No provider pricing or quota inference.
abstract final class LedgerValidation {
  static const aliasLimit = 80;
  static const titleLimit = 120;
  static const shortTextLimit = 60;
  static const noteLimit = 1000;
  static const maxTokens = 1000000000;
  static const maxMoneyMicros = 9999999999999;
  static const maxExactInteger = 9007199254740991;
  static const providers = ['Anthropic', 'OpenAI', 'Google', 'Khác'];

  /// Product prefilled for each provider; a name the user typed is kept.
  static const productSuggestions = {
    'Anthropic': 'Claude',
    'OpenAI': 'Codex',
    'Google': 'Gemini',
  };

  static String? text(
    String? value,
    String label,
    int max, {
    bool required = true,
  }) {
    final trimmed = (value ?? '').trim();
    if (required && trimmed.isEmpty) return 'Nhập $label.';
    if ((value ?? '').characters.length > max) {
      return '$label tối đa $max ký tự.';
    }
    return null;
  }

  static String? tokenInput(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final number = RegExp(r'^\d+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    return number == null || number > maxTokens
        ? 'Nhập số nguyên từ 0 đến 1 tỷ.'
        : null;
  }

  static String? percentInput(String? raw) {
    final value = (raw ?? '').trim();
    final number = RegExp(r'^\d+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    return number == null || number > 100
        ? 'Nhập số nguyên từ 0 đến 100.'
        : null;
  }

  static void _check(String? error) {
    if (error != null) throw ArgumentError(error);
  }

  static void _id(String value) => _check(text(value, 'ID', 128));
  static void money(int? value) {
    if (value != null && (value < 0 || value > maxMoneyMicros)) {
      throw ArgumentError('USD cần từ 0 đến 9999999.999999.');
    }
  }

  static void quota(QuotaSnapshot value, {DateTime? now}) {
    _check(text(value.window, 'tên cửa sổ hạn mức', shortTextLimit));
    _check(text(value.windowKey, 'mã cửa sổ hạn mức', 128));
    _check(
      text(value.sourceLabel, 'nguồn quan sát', titleLimit, required: false),
    );
    _check(text(value.note, 'ghi chú hạn mức', noteLimit, required: false));
    if (value.usedPercent < 0 ||
        value.usedPercent > 100 ||
        !value.resetAt.isAfter(value.observedAt)) {
      throw ArgumentError('Quota cần 0–100% và reset sau thời điểm quan sát.');
    }
    if (now != null &&
        (value.observedAt.isAfter(now) || !value.resetAt.isAfter(now))) {
      throw ArgumentError(
        'Thời điểm quan sát không được ở tương lai; reset phải sau hiện tại.',
      );
    }
  }

  static void account(AIAccount value) {
    _id(value.id);
    if (value.isDemo != (value.dataSource == DataSource.demo)) {
      throw ArgumentError('Nguồn tài khoản và nhãn demo phải nhất quán.');
    }
    _check(text(value.alias, 'tên tài khoản', aliasLimit));
    if (!providers.contains(value.provider)) {
      throw ArgumentError('Nhà cung cấp không hợp lệ.');
    }
    _check(text(value.product, 'tên công cụ', shortTextLimit));
    _check(text(value.plan, 'tên gói', shortTextLimit, required: false));
    money(value.budgetMicros);
    _check(
      text(
        value.defaultModelId,
        'model mặc định',
        shortTextLimit,
        required: false,
      ),
    );
    if (value.defaultModelId != null && value.defaultModelId!.trim().isEmpty) {
      throw ArgumentError('Model trống cần để null.');
    }
    if (value.defaultPurposes.toSet().length != value.defaultPurposes.length) {
      throw ArgumentError('Mục đích mặc định bị trùng.');
    }
    ReportingCalendar.validateZone(value.timezone);
    if (value.cycleStartDay < 1 || value.cycleStartDay > 31) {
      throw ArgumentError('Ngày bắt đầu kỳ cần từ 1 đến 31.');
    }
    final windows = <String>{};
    final labels = <String>{};
    for (final q in value.quotaWindows) {
      quota(q); // Stale snapshots remain valid history.
      if (!windows.add(q.windowKey) ||
          !labels.add(q.window.trim().toLowerCase())) {
        throw ArgumentError('Trùng cửa sổ quota.');
      }
    }
  }

  static void usage(UsageSession value, {DateTime? now}) {
    _id(value.id);
    _id(value.accountId);
    _check(text(value.title, 'tên công việc', titleLimit));
    _check(text(value.note, 'ghi chú', noteLimit, required: false));
    _check(text(value.modelId, 'model', shortTextLimit, required: false));
    if (value.modelId != null && value.modelId!.trim().isEmpty) {
      throw ArgumentError('Model trống cần để null.');
    }
    if (value.isDemo != (value.dataSource == DataSource.demo)) {
      throw ArgumentError('Nhãn demo và nguồn dữ liệu phải nhất quán.');
    }
    if (value.costMicros == null &&
            value.costBasis != null &&
            value.costBasis != CostBasis.unknown ||
        value.costMicros != null && value.costBasis == CostBasis.unknown) {
      throw ArgumentError('Loại chi phí không khớp dữ liệu đã biết/chưa biết.');
    }
    for (final count in [value.inputTokens, value.outputTokens]) {
      if (count != null && (count < 0 || count > maxTokens)) {
        throw ArgumentError('Token cần là số nguyên từ 0 đến 1 tỷ.');
      }
    }
    if ((value.inputTokens == null) != (value.outputTokens == null)) {
      throw ArgumentError('Nhập cả input và output, hoặc để trống cả hai.');
    }
    money(value.costMicros);
    // Device-local calendar dates, matching the existing date picker.
    if (value.occurredAt.isBefore(DateTime(2020))) {
      throw ArgumentError('Ngày sử dụng phải từ 01/01/2020.');
    }
    if (now != null && value.occurredAt.isAfter(now)) {
      throw ArgumentError('Thời điểm sử dụng không được ở tương lai.');
    }
  }

  static void snapshot(LedgerData data) {
    ReportingCalendar.validateZone(data.reportingTimezone);
    final accountIds = <String>{};
    final usageIds = <String>{};
    var budget = 0, cost = 0, tokens = 0;
    for (final a in data.accounts) {
      account(a);
      if (!accountIds.add(a.id)) throw ArgumentError('Trùng ID tài khoản.');
      budget += a.budgetMicros ?? 0;
    }
    for (final s in data.sessions) {
      usage(
        s,
      ); // Do not reject stored history when the device clock moves back.
      if (!usageIds.add(s.id)) throw ArgumentError('Trùng ID phiên sử dụng.');
      if (!accountIds.contains(s.accountId)) {
        throw ArgumentError('Phiên không có tài khoản tương ứng.');
      }
      cost += s.costMicros ?? 0;
      tokens += s.knownTokens ?? 0;
    }
    if ([budget, cost, tokens].any((v) => v > maxExactInteger)) {
      throw ArgumentError(
        'Tổng dữ liệu vượt giới hạn số nguyên chính xác của bản web.',
      );
    }
  }
}
