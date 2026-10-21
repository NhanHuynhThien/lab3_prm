import 'package:flutter/material.dart';

/// Keep large text and trailing figures readable without squeezing the label.
class AdaptivePair extends StatelessWidget {
  const AdaptivePair({
    super.key,
    required this.leading,
    required this.trailing,
    this.breakpoint = 360,
  });
  final Widget leading, trailing;
  final double breakpoint;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      return constraints.maxWidth / scale < breakpoint
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [leading, const SizedBox(height: 8), trailing],
            )
          : Row(
              children: [
                Expanded(child: leading),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
              ],
            );
    },
  );
}
