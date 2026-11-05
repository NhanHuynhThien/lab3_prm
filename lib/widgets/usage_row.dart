import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

class UsageRow extends StatelessWidget {
  const UsageRow({
    super.key,
    this.timezone = 'device',
    required this.session,
    required this.account,
    required this.onTap,
  });

  final UsageSession session;
  final String timezone;
  final AIAccount? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionSurface(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(purposeIcon(session.purpose), size: 22, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: AdaptivePair(
              breakpoint: 200,
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${account?.alias ?? 'Tài khoản đã xóa'} ·${session.purpose.label} · ${shortDate(session.occurredAt, timezone: timezone)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    session.costMicros == null
                        ? '—'
                        : money(session.costMicros),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.knownTokens == null
                        ? 'Chưa biết'
                        : '${compactTokens(session.knownTokens)} token',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
