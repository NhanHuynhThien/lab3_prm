import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.semanticValue,
  });
  final double value;
  final Color color;
  final String? semanticValue;
  @override
  Widget build(BuildContext context) => Semantics(
    value: semanticValue ?? '${(value * 100).round()}%',
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: AppMotion.duration(context, AppMotion.chart),
      curve: AppMotion.curve,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: 6,
        borderRadius: BorderRadius.circular(4),
        backgroundColor: AppColors.disabled,
        color: color,
      ),
    ),
  );
}

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, required this.micros, this.style});
  final int micros;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Semantics(
    label: money(micros),
    excludeSemantics: true,
    child: Text(
      money(micros),
      style: style ?? Theme.of(context).textTheme.displaySmall,
    ),
  );
}
