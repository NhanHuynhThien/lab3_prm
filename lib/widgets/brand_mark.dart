import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original TokenLedger mark: a token hexagon enclosing a T-shaped ledger fold.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo TokenLedger',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(26),
      ),
      Paint()..color = AppColors.primary,
    );
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final hex = Path()
      ..moveTo(50, 18)
      ..lineTo(77, 34)
      ..lineTo(77, 66)
      ..lineTo(50, 82)
      ..lineTo(23, 66)
      ..lineTo(23, 34)
      ..close();
    canvas.drawPath(hex, stroke);
    canvas.drawLine(const Offset(36, 39), const Offset(64, 39), stroke);
    canvas.drawLine(const Offset(50, 39), const Offset(50, 65), stroke);
    canvas.drawLine(
      const Offset(50, 65),
      const Offset(64, 57),
      stroke..color = const Color(0xFFA6E9C8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BrandMark(size: compact ? 32 : 40),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          'TokenLedger',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(letterSpacing: -.6),
        ),
      ),
    ],
  );
}
