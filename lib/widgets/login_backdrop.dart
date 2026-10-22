import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Static tinted shapes, adapted from BeeWise. No blur or perpetual ticker.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -box.maxWidth * .35,
            left: -box.maxWidth * .2,
            child: Container(
              width: box.maxWidth * 1.3,
              height: box.maxWidth.clamp(320, 620),
              decoration: const BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.all(Radius.elliptical(480, 260)),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration: const BoxDecoration(
                color: AppColors.frame,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
