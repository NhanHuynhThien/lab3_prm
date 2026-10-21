import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared keyboard, semantics and focus treatment for tappable data rows.
class ActionSurface extends StatefulWidget {
  const ActionSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.selected,
  });
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool? selected;
  @override
  State<ActionSurface> createState() => _ActionSurfaceState();
}

class _ActionSurfaceState extends State<ActionSurface> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onTap != null,
    enabled: widget.onTap == null ? null : true,
    selected: widget.selected,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpace.touch,
        minWidth: AppSpace.touch,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          onFocusChange: (value) => setState(() => _focused = value),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: _focused
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}
