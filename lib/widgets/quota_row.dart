import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../utils/formatters.dart';
import 'common.dart';

class QuotaRow extends StatelessWidget {
  const QuotaRow({
    super.key,
    required this.account,
    required this.now,
    this.onTap,
    this.compact = false,
    this.quota,
  });

  final AIAccount account;
  final QuotaSnapshot? quota;
  final DateTime now;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final q = quota ?? account.limitingQuota(now);
    final stale = q?.isStale(now) ?? false;
    return ActionSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 0 : 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quota == null ? account.product : q!.window,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  q == null
                      ? 'Chưa có dữ liệu'
                      : stale
                      ? 'Cần cập nhật'
                      : 'Còn ${q.remainingPercent}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            AnimatedProgress(
              value: q == null || stale ? 0 : q.usedPercent / 100,
              semanticValue: q == null
                  ? 'Chưa có dữ liệu quota'
                  : stale
                  ? 'Quota đã quá reset; cần cập nhật'
                  : 'Đã dùng ${q.usedPercent}%',
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              q == null
                  ? 'Thêm quota từ trang tài khoản'
                  : '${q.window}${quota == null && account.quotaWindows.length > 1 ? ' · +${account.quotaWindows.length - 1} cửa sổ khác' : ''} · ${q.source.label} ${shortDate(q.observedAt)} ${shortTime(q.observedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
