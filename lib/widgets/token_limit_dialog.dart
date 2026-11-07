import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/token_alert_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/token_limit_viewmodel.dart';
import 'common.dart';

/// Sets or clears the token limit that triggers phone notifications.
Future<void> showTokenLimitDialog(
  BuildContext context,
  WidgetRef ref,
  String accountId, {
  bool percent = false,
}) async {
  final current = ref.read(tokenLimitsProvider)[accountId];
  final result = await showDialog<_Result>(
    context: context,
    builder: (_) => _LimitDialog(current, percent: percent),
  );
  if (result == null) return;
  await ref.read(tokenLimitsProvider.notifier).set(accountId, result.limit);
}

class _Result {
  const _Result(this.limit);
  final int? limit;
}

/// Owns its controller so it is disposed only after the close animation.
class _LimitDialog extends StatefulWidget {
  const _LimitDialog(this.current, {required this.percent});
  final int? current;

  /// Percent of quota used (1–100) instead of a token count.
  final bool percent;
  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  late final _controller = TextEditingController(
    text: widget.current?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.percent ? 'Cảnh báo hạn mức' : 'Giới hạn token'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.percent ? 'Hạn mức đã dùng' : 'Số token',
        suffixText: widget.percent ? '%' : null,
        helperText: widget.percent
            ? 'Báo lên điện thoại khi quota đã dùng đạt mức này.'
            : 'Báo lên điện thoại khi đạt 80% và 100%.',
      ),
    ),
    actions: [
      if (widget.current != null)
        TextButton(
          onPressed: () => Navigator.pop(context, const _Result(null)),
          child: const Text('Bỏ giới hạn'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(_controller.text.trim());
          final max = widget.percent ? 100 : TokenAlertStore.maxLimit;
          if (value == null || value <= 0 || value > max) {
            showMessage(
              context,
              widget.percent
                  ? 'Nhập từ 1 đến 100%.'
                  : 'Nhập số token lớn hơn 0.',
            );
            return;
          }
          Navigator.pop(context, _Result(value));
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}

/// Token count with optional limit bar and the button that edits the limit.
class TokenMeter extends ConsumerWidget {
  const TokenMeter({
    super.key,
    required this.limitKey,
    required this.tokens,
    required this.caption,
    required this.footer,
  });
  final String limitKey, caption, footer;
  final int? tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(tokenLimitsProvider)[limitKey];
    final used = tokens ?? 0;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                tokens == null ? '—' : compactTokens(tokens),
                style: text.headlineMedium,
              ),
            ),
            Text(
              limit == null ? caption : '/ ${compactTokens(limit)} token',
              style: text.bodyMedium,
            ),
          ],
        ),
        if (limit != null) ...[
          const SizedBox(height: AppSpace.sm),
          AnimatedProgress(
            value: used / limit,
            color: used >= limit
                ? AppColors.danger
                : used * 100 >= limit * TokenAlertStore.warnPercent
                ? AppColors.amber
                : AppColors.primary,
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(child: Text(footer, style: text.bodySmall)),
            TextButton.icon(
              onPressed: () => showTokenLimitDialog(context, ref, limitKey),
              icon: Icon(
                limit == null
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_outlined,
                size: 18,
              ),
              label: Text(limit == null ? 'Đặt giới hạn' : 'Sửa giới hạn'),
            ),
          ],
        ),
      ],
    );
  }
}
