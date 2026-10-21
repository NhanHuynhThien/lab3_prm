import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';

export 'action_dialogs.dart';
export 'action_surface.dart';
export 'adaptive_pair.dart';
export 'animated_indicators.dart';
export 'content_page.dart';
export 'feedback_views.dart';

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
  Widget build(BuildContext context) => Semantics(
    label: 'Chữ viết tắt ${account.product}; không phải logo nhà cung cấp',
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        account.product.isEmpty ? '?' : account.product.characters.first,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  );
}
