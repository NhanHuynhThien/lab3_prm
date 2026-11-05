import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../screens/history_screen.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';
import 'common.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.labels,
    required this.icons,
    this.user,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final List<String> labels;
  final List<IconData> icons;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSpace.sidebar,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLockup(),
                  const SizedBox(height: 36),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 12),
                    child: Text(
                      'Không gian làm việc',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  ...List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: selectedIndex == i
                            ? AppColors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ActionSurface(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelectTab(i),
                          selected: selectedIndex == i,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icons[i],
                                  size: 21,
                                  color: selectedIndex == i
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontWeight: selectedIndex == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HistoryScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.history_rounded, size: 20),
                    label: const Text('Lịch sử sử dụng'),
                  ),
                  const Spacer(),
                  Panel(
                    color: AppColors.soft,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.storage_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dữ liệu cá nhân trên cloud',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sổ ghi nhận được đồng bộ theo tài khoản Google. Nguồn AI có nhãn và thời điểm riêng.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.disabled,
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Tài khoản Google',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              user?.email ?? 'Không gian cá nhân',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
