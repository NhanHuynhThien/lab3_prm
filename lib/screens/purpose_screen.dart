import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PurposeScreen extends StatelessWidget {
  const PurposeScreen({super.key, required this.selected});
  final Purpose selected;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Chọn mục đích',
    child: GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio:
          .9 / (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 2),
      children: Purpose.values
          .map(
            (p) => Semantics(
              selected: p == selected,
              button: true,
              child: Material(
                color: p == selected ? AppColors.soft : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, p),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          purposeIcon(p),
                          size: 28,
                          color: p == selected
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
