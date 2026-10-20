import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class UsageBarChart extends StatelessWidget {
  const UsageBarChart({super.key, required this.values, required this.now});
  final List<int> values;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final highest = values.fold<int>(0, math.max);
    return Semantics(
      label: 'Chi phí 7 ngày: ${values.map((v) => money(v)).join(', ')}',
      child: SizedBox(
        height: 174,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final date = now.subtract(Duration(days: 6 - i));
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      money(values[i]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: highest == 0 ? 0 : values[i] / highest,
                          ),
                          duration: AppMotion.duration(
                            context,
                            AppMotion.chart,
                          ),
                          curve: AppMotion.curve,
                          builder: (_, v, _) => FractionallySizedBox(
                            widthFactor: .65,
                            heightFactor: values[i] == 0
                                ? 0
                                : math.max(v, .015),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i == 6
                                    ? AppColors.primary
                                    : AppColors.chartTertiary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${date.day}/${date.month}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class PurposeRing extends StatelessWidget {
  const PurposeRing({super.key, required this.shares, required this.center});
  final List<PurposeShare> shares;
  final String center;
  static const colors = [
    AppColors.primary,
    AppColors.chartSecondary,
    AppColors.chartTertiary,
    AppColors.disabled,
  ];
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    height: 172,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.duration(context, AppMotion.chart),
            curve: AppMotion.curve,
            builder: (_, value, _) =>
                CustomPaint(painter: _RingPainter(shares, value)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(center, style: Theme.of(context).textTheme.headlineSmall),
            Text('đã ghi nhận', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.shares, this.progress);
  final List<PurposeShare> shares;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(10);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;
    canvas.drawOval(rect, paint..color = AppColors.line);
    final total = shares.fold<int>(0, (s, p) => s + p.value);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < shares.length; i++) {
      final sweep = shares[i].value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        math.max(0, sweep * progress - .035),
        false,
        paint..color = PurposeRing.colors[math.min(i, 3)],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}
