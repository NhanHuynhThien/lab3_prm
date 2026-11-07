import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Equal-width actions that reflow within the screen at larger text sizes.
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.children, this.maxColumns = 2});

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns =
          ((constraints.maxWidth + AppSpace.sm) / (140 * scale + AppSpace.sm))
              .floor()
              .clamp(1, maxColumns.clamp(1, children.length));
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: AppSpace.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var i = start;
                    i < children.length && i < start + columns;
                    i++
                  ) ...[
                    if (i > start) const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSpace.button,
                        ),
                        child: children[i],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// A selected filter with a surface that fills its assigned action cell.
class SelectionButton extends StatelessWidget {
  const SelectionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.soft : AppColors.surface,
        foregroundColor: selected ? AppColors.primary : AppColors.text,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: AppSpace.sm)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
