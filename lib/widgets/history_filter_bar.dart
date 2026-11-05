import 'package:flutter/material.dart';

import '../models/ledger.dart';
import 'range_picker.dart';

/// Account, purpose and provider filters; "all" is a null selection.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.accounts,
    required this.accountId,
    required this.purpose,
    required this.provider,
    required this.onAccount,
    required this.onPurpose,
    required this.onProvider,
  });

  final List<AIAccount> accounts;
  final String? accountId, provider;
  final Purpose? purpose;
  final ValueChanged<String?> onAccount, onProvider;
  final ValueChanged<Purpose?> onPurpose;

  @override
  Widget build(BuildContext context) {
    String alias(String id) {
      final a = accounts.where((a) => a.id == id).firstOrNull;
      if (a == null) return 'Tài khoản đã xóa';
      return a.archived ? '${a.alias} · Đã lưu trữ' : a.alias;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterMenu<String>(
            allLabel: 'Mọi tài khoản',
            tooltip: 'Lọc theo tài khoản',
            selected: accountId,
            options: accounts
                .where((a) => provider == null || a.provider == provider)
                .map((a) => a.id)
                .toList(),
            labelOf: alias,
            onChanged: onAccount,
          ),
          const SizedBox(width: 8),
          _FilterMenu<Purpose>(
            allLabel: 'Mọi mục đích',
            tooltip: 'Lọc theo mục đích',
            selected: purpose,
            options: Purpose.values,
            labelOf: (p) => p.label,
            onChanged: onPurpose,
          ),
          const SizedBox(width: 8),
          _FilterMenu<String>(
            allLabel: 'Mọi nhà cung cấp',
            tooltip: 'Lọc theo nhà cung cấp',
            selected: provider,
            options: accounts.map((a) => a.provider).toSet().toList(),
            labelOf: (p) => p,
            onChanged: onProvider,
          ),
        ],
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.allLabel,
    required this.tooltip,
    required this.selected,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String allLabel, tooltip;
  final T? selected;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = selected;
    // Wrapped in a record: a menu treats a plain null value as "dismissed".
    return PopupMenuButton<({T? value})>(
      tooltip: tooltip,
      initialValue: (value: current),
      onSelected: (choice) => onChanged(choice.value),
      itemBuilder: (_) => [
        PopupMenuItem(value: (value: null), child: Text(allLabel)),
        for (final option in options)
          PopupMenuItem(value: (value: option), child: Text(labelOf(option))),
      ],
      child: FilterButton(
        current == null ? allLabel : labelOf(current),
        active: current != null,
      ),
    );
  }
}
