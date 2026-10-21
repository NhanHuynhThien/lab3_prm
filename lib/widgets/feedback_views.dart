import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton(onPressed: onAction, child: Text(action!)),
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
