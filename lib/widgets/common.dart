import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppSpace.cardRadius),
      border: color == AppColors.surface
          ? Border.all(color: AppColors.line)
          : null,
    ),
    child: child,
  );
}

class StatusTag extends StatelessWidget {
  const StatusTag(
    this.label, {
    super.key,
    this.warning = false,
    this.neutral = false,
  });
  final String label;
  final bool warning, neutral;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: warning
          ? AppColors.error
          : neutral
          ? AppColors.neutral
          : AppColors.soft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: warning
            ? AppColors.danger
            : neutral
            ? AppColors.muted
            : AppColors.primary,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
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
  Widget build(BuildContext context) => Padding(
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
  );
}

class ErrorFeedback extends StatelessWidget {
  const ErrorFeedback({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => EmptyFeedback(
    title: 'Không thể tải dữ liệu',
    message: message,
    action: 'Thử lại',
    onAction: retry,
  );
}

class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    this.color = AppColors.primary,
  });
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value * 100).round()}%',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: AppMotion.duration(context, AppMotion.chart),
      curve: AppMotion.curve,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: 6,
        borderRadius: BorderRadius.circular(4),
        backgroundColor: AppColors.disabled,
        color: color,
      ),
    ),
  );
}

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, required this.micros, this.style});
  final int micros;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: micros.toDouble(), end: micros.toDouble()),
    duration: AppMotion.duration(context, AppMotion.medium),
    curve: AppMotion.curve,
    builder: (_, value, _) => Text(
      money(value.round()),
      style: style ?? Theme.of(context).textTheme.displaySmall,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: c.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  if (action != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: action!,
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: text),
                  ?action,
                ],
              ),
      );
    },
  );
}

IconData purposeIcon(Purpose purpose) => switch (purpose) {
  Purpose.code => Icons.code_rounded,
  Purpose.debug => Icons.bug_report_outlined,
  Purpose.review => Icons.fact_check_outlined,
  Purpose.test => Icons.science_outlined,
  Purpose.learn => Icons.school_outlined,
  Purpose.write => Icons.edit_note_outlined,
  Purpose.research => Icons.travel_explore_outlined,
  Purpose.design => Icons.design_services_outlined,
  Purpose.other => Icons.more_horiz_rounded,
};

class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar(this.account, {super.key, this.size = 40});
  final AIAccount account;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.neutral,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      account.product.isEmpty ? '?' : account.product.substring(0, 1),
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

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

class ContentPage extends StatelessWidget {
  const ContentPage({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });
  final String title;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 720, child: child),
    ),
    bottomNavigationBar: footer == null
        ? null
        : SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Center(
                heightFactor: 1,
                child: SizedBox(width: 688, child: footer),
              ),
            ),
          ),
  );
}
