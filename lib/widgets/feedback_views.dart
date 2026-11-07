import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FormSaveFooter extends StatelessWidget {
  const FormSaveFooter({super.key, required this.child, this.error});
  final Widget child;
  final String? error;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(error!, style: const TextStyle(color: AppColors.danger)),
        ),
        const SizedBox(height: AppSpace.md),
      ],
      child,
    ],
  );
}

class LoadingFeedback extends StatelessWidget {
  const LoadingFeedback({super.key, this.label = 'Đang tải dữ liệu'});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    excludeSemantics: true,
    child: Center(
      child: CircularProgressIndicator(
        value: MediaQuery.disableAnimationsOf(context) ? .5 : null,
      ),
    ),
  );
}

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onPressed,
  });
  final String label;
  final bool saving;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: saving ? null : onPressed,
    child: Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saving) ...[
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  value: MediaQuery.disableAnimationsOf(context) ? .5 : null,
                  strokeWidth: 2,
                  color: AppColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              saving ? 'Đang lưu...' : label,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class EmptyFeedback extends StatelessWidget {
  const EmptyFeedback({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  @override
  // Left-aligned so it lines up with the card title above it.
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inbox_outlined, size: 24, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onAction,
                        child: Text(action!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ErrorFeedback extends StatelessWidget {
  const ErrorFeedback({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => EmptyFeedback(
    title: 'Không thể tải dữ liệu',
    message: message,
    action: 'Thử lại',
    onAction: retry,
  );
}
