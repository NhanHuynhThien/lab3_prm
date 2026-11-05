import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class UsageBarChart extends StatelessWidget {
  const UsageBarChart({super.key, required this.values, required this.now});
  final List<int?> values;
  final DateTime now;
  static String _label(int? value) => value == null ? '—' : money(value);
  @override
  Widget build(BuildContext context) {
    final highest = values.fold<int>(0, (a, b) => math.max(a, b ?? 0));
    return Semantics(
      excludeSemantics: true,
      label:
          'Chi phí nhập tay, USD. ${values.indexed.map((entry) {
            final date = DateTime(now.year, now.month, now.day - (values.length - 1 - entry.$1));
            return '${date.day}/${date.month}/${date.year}: ${money(entry.$2)}';
          }).join('; ')}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final style = Theme.of(context).textTheme.bodySmall!;
          final scaler = MediaQuery.textScalerOf(context);
          double labelWidth(String text) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
            )..layout();
            return painter.width;
          }

          final columnWidth = values.indexed.fold<double>(0, (width, entry) {
            final date = DateTime(
              now.year,
              now.month,
              now.day - (values.length - 1 - entry.$1),
            );
            return math.max(
              width,
              math.max(
                    labelWidth(_label(entry.$2)),
                    labelWidth('${date.day}/${date.month}'),
                  ) +
                  16,
            );
          });
          final scrolls = columnWidth * values.length > constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    constraints.maxWidth,
                    columnWidth * values.length,
                  ),
                  height: 134 + scaler.scale(14) * 40 / 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(values.length, (i) {
                      final date = DateTime(
                        now.year,
                        now.month,
                        now.day - (values.length - 1 - i),
                      );
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _label(values[i]),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: highest == 0
                                          ? 0
                                          : (values[i] ?? 0) / highest,
                                    ),
                                    duration: AppMotion.duration(
                                      context,
                                      AppMotion.chart,
                                    ),
                                    curve: AppMotion.curve,
                                    builder: (_, v, _) => FractionallySizedBox(
                                      widthFactor: .65,
                                      heightFactor: (values[i] ?? 0) == 0
                                          ? 0
                                          : math.max(v, .015),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: i == 6
                                              ? AppColors.primary
                                              : AppColors.chartTertiary,
                                          borderRadius:
                                              const BorderRadius.vertical(
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
              ),
              if (scrolls)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Cuộn ngang để xem đủ 7 ngày.', style: style),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PurposeRing extends StatelessWidget {
  const PurposeRing({
    super.key,
    required this.shares,
    required this.center,
    this.onSelected,
  });
  final List<PurposeShare> shares;
  final ValueChanged<PurposeShare>? onSelected;
  final String center;
  static const colors = [
    AppColors.primary,
    AppColors.amber,
    AppColors.accent,
    AppColors.chartSecondary,
    AppColors.chartTertiary,
  ];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    bool fits(String text, TextStyle? style) =>
        (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout()).width <=
        132;
    final inline =
        fits(center, theme.headlineSmall) &&
        fits('đã ghi nhận', theme.bodySmall);
    final caption = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(center, textAlign: TextAlign.center, style: theme.headlineSmall),
        Text(
          'đã ghi nhận',
          textAlign: TextAlign.center,
          style: theme.bodySmall,
        ),
      ],
    );
    final ring = GestureDetector(
      onTapUp: onSelected == null
          ? null
          : (details) {
              final offset = details.localPosition - const Offset(86, 86);
              if (offset.distance < 66 || offset.distance > 86) {
                return;
              }
              final total = shares.fold<int>(0, (sum, p) => sum + p.value);
              if (total <= 0) {
                return;
              }
              var angle =
                  (math.atan2(offset.dy, offset.dx) + math.pi / 2) %
                  (math.pi * 2);
              for (final share in shares) {
                final sweep = share.value / total * math.pi * 2;
                if (angle < math.max(0, sweep - .035)) {
                  onSelected!(share);
                  return;
                }
                angle -= sweep;
              }
            },
      child: SizedBox(
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
            if (inline) caption,
          ],
        ),
      ),
    );
    return inline
        ? ring
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [ring, const SizedBox(height: 12), caption],
          );
  }
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
        paint..color = PurposeRing.colors[i % PurposeRing.colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.shares != shares;
}
