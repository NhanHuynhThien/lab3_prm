import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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

class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.semanticValue,
  });
  final double value;
  final Color color;
  final String? semanticValue;
  @override
  Widget build(BuildContext context) => Semantics(
    value: semanticValue ?? '${(value * 100).round()}%',
    excludeSemantics: true,
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
  Widget build(BuildContext context) => Semantics(
    label: money(micros),
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: micros.toDouble(), end: micros.toDouble()),
      duration: AppMotion.duration(context, AppMotion.medium),
      curve: AppMotion.curve,
      builder: (_, value, _) => Text(
        money(value.round()),
        style: style ?? Theme.of(context).textTheme.displaySmall,
      ),
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
      if (mounted) showMessage(context, error.toString());
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
    appBar: AppBar(
      toolbarHeight: math.max(
        kToolbarHeight,
        MediaQuery.textScalerOf(context).scale(26) * 2 + AppSpace.xs,
      ),
      title: Tooltip(
        message: title,
        child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 720, child: child),
    ),
    bottomNavigationBar: footer == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
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
          ),
  );
}
