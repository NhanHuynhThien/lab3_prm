import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_usage.dart';
import 'provider_brand_icon.dart';
import 'action_buttons.dart';
import '../viewmodels/provider_sources_viewmodel.dart';

class ProviderSourcePicker extends ConsumerWidget {
  const ProviderSourcePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSourceProvider);
    return ActionButtons(
      children: [
        for (final entry in providerNames.entries)
          SelectionButton(
            icon: ProviderBrandIcon(entry.key, size: 18, framed: false),
            label: entry.key == 'codex' ? 'Codex' : entry.value,
            selected: selected == entry.key,
            onPressed: () =>
                ref.read(selectedSourceProvider.notifier).select(entry.key),
          ),
      ],
    );
  }
}
