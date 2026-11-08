import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// A titled settings section: rows in one panel, separated by dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Panel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Standard settings row: icon, title, optional detail and trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Sign-out style rows: danger colour (title and detail) and no chevron.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tone = destructive ? AppColors.danger : AppColors.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: AppSpace.md,
      leading: Icon(icon, color: tone),
      title: Text(
        title,
        style: destructive ? const TextStyle(color: AppColors.danger) : null,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: destructive
                  ? const TextStyle(color: AppColors.danger)
                  : null,
            ),
      trailing:
          trailing ??
          (onTap == null || destructive
              ? null
              : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
