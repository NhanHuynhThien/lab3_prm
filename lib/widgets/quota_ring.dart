import 'package:flutter/material.dart';

import '../models/agent_dashboard.dart';
import '../theme/app_theme.dart';

/// Colours for each [QuotaLevel], shared by the ring and the card tint.
extension QuotaLevelStyle on QuotaLevel {
  Color get color => switch (this) {
    QuotaLevel.normal => AppColors.primary,
    QuotaLevel.warning => AppColors.amber,
    QuotaLevel.alert => AppColors.danger,
  };

  /// Card background; normal cards keep the plain surface.
  Color get tint => switch (this) {
    QuotaLevel.normal => AppColors.surface,
    QuotaLevel.warning => AppColors.amberSoft,
    QuotaLevel.alert => AppColors.error,
  };
}

/// Static circular gauge of quota used, with the percent in the middle.
class QuotaRing extends StatelessWidget {
  const QuotaRing({super.key, required this.usedPercent, required this.level});
  final double usedPercent;
  final QuotaLevel level;

  @override
  Widget build(BuildContext context) {
    final label = '${usedPercent.toStringAsFixed(0)}%';
    return Semantics(
      label: 'Đã dùng $label hạn mức',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSpace.quotaRing,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: (usedPercent / 100).clamp(0, 1),
              strokeWidth: AppSpace.xs,
              color: level.color,
              backgroundColor: AppColors.line,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: level.color),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
