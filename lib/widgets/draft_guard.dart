import 'package:flutter/material.dart';

/// Protects user-initiated Back navigation. A successful save may pop directly.
class DraftGuard extends StatefulWidget {
  const DraftGuard({
    super.key,
    required this.controllers,
    required this.hasChanges,
    required this.saving,
    required this.child,
  });

  final List<TextEditingController> controllers;
  final bool Function() hasChanges;
  final bool saving;
  final Widget child;

  @override
  State<DraftGuard> createState() => _DraftGuardState();
}

class _DraftGuardState extends State<DraftGuard> {
  bool _asking = false;

  Future<void> _onBack(bool didPop, Object? result) async {
    if (didPop || widget.saving || _asking) return;
    _asking = true;
    try {
      final discard = await showDialog<bool>(
        context: context,
        animationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (context) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          content: const Text(
            'Những thay đổi trong biểu mẫu này chưa được lưu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục sửa'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (discard == true && mounted && !widget.saving) {
        Navigator.of(context).pop(result);
      }
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(widget.controllers),
    builder: (context, child) => PopScope<Object?>(
      canPop: !widget.saving && !widget.hasChanges(),
      onPopInvokedWithResult: _onBack,
      child: ExcludeFocus(
        excluding: widget.saving,
        child: AbsorbPointer(absorbing: widget.saving, child: child),
      ),
    ),
    child: widget.child,
  );
}
