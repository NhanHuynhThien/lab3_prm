import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String confirm = 'Xác nhận',
}) async =>
    await showDialog<bool>(
      context: context,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

/// One confirmation/write at a time, including keyboard and repeated taps.
class ConfirmedActionButton extends StatefulWidget {
  const ConfirmedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.onSuccess,
    this.destructive = false,
  });
  final String label, title, message;
  final IconData icon;
  final Future<void> Function() onConfirm;
  final VoidCallback? onSuccess;
  final bool destructive;
  @override
  State<ConfirmedActionButton> createState() => _ConfirmedActionButtonState();
}

class _ConfirmedActionButtonState extends State<ConfirmedActionButton> {
  bool _working = false;
  Future<void> _run() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (!await confirmAction(
            context,
            widget.title,
            widget.message,
            confirm: widget.label,
          ) ||
          !mounted) {
        return;
      }
      await widget.onConfirm();
      if (mounted) widget.onSuccess?.call();
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: widget.destructive
        ? TextButton.styleFrom(foregroundColor: AppColors.danger)
        : null,
    onPressed: _working ? null : _run,
    icon: Icon(widget.icon),
    label: Text(_working ? 'Đang xử lý...' : widget.label),
  );
}
