import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_usage.dart';
import 'provider_brand_icon.dart';
import '../viewmodels/provider_sources_viewmodel.dart';

class ProviderSourcePicker extends ConsumerWidget {
  const ProviderSourcePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSourceProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in providerNames.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: ProviderBrandIcon(entry.key, size: 16),
                label: Text(entry.key == 'codex' ? 'Codex' : entry.value),
                selected: selected == entry.key,
                onSelected: (_) =>
                    ref.read(selectedSourceProvider.notifier).select(entry.key),
                showCheckmark: true,
              ),
            ),
        ],
      ),
    );
  }
}
