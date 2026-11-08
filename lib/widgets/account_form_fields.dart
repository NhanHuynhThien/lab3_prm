import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../services/ledger_validation.dart';
import '../services/reporting_calendar.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PurposeChipsSelector extends StatelessWidget {
  const PurposeChipsSelector({
    super.key,
    required this.purposes,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<Purpose> purposes;
  final ValueChanged<Set<Purpose>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Mục đích gợi ý', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Purpose.values
            .map(
              (p) => FilterChip(
                label: Text(p.label),
                selected: purposes.contains(p),
                onSelected: enabled
                    ? (selected) {
                        final next = Set<Purpose>.from(purposes);
                        if (selected) {
                          next.add(p);
                        } else {
                          next.remove(p);
                        }
                        onChanged(next);
                      }
                    : null,
              ),
            )
            .toList(),
      ),
    ],
  );
}

class AccountBudgetField extends StatelessWidget {
  const AccountBudgetField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        key: const ValueKey('account-budget'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Ngân sách theo dõi mỗi kỳ · USD',
          hintText: '20.00',
          helperText: 'Để trống nếu chưa đặt.',
        ),
        validator: (v) {
          try {
            parseUsd(v ?? '');
            return null;
          } catch (e) {
            return 'Nhập số USD không âm hợp lệ.';
          }
        },
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        'Đây là mức bạn tự đặt để theo dõi, không phải số dư hay hạn mức của nhà cung cấp.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class AccountCycleFields extends StatefulWidget {
  const AccountCycleFields({
    super.key,
    required this.timezoneController,
    required this.cycleController,
  });

  final TextEditingController timezoneController;
  final TextEditingController cycleController;

  /// Suggestions shown while typing a zone; the list has ~600 entries.
  static const zoneSuggestionLimit = 20;

  @override
  State<AccountCycleFields> createState() => _AccountCycleFieldsState();
}

class _AccountCycleFieldsState extends State<AccountCycleFields> {
  final _zoneFocus = FocusNode();

  @override
  void dispose() {
    _zoneFocus.dispose();
    super.dispose();
  }

  Iterable<String> _zones(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    return ReportingCalendar.zoneNames
        .where((z) => z.toLowerCase().contains(query))
        .take(AccountCycleFields.zoneSuggestionLimit);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RawAutocomplete<String>(
        textEditingController: widget.timezoneController,
        focusNode: _zoneFocus,
        optionsBuilder: _zones,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextFormField(
              key: const ValueKey('account-timezone'),
              controller: controller,
              focusNode: focusNode,
              autocorrect: false,
              onFieldSubmitted: (_) => onSubmitted(),
              decoration: const InputDecoration(
                labelText: 'Múi giờ của chu kỳ',
                helperText: 'Gõ tên thành phố để tìm, ví dụ Ho_Chi_Minh.',
                suffixIcon: Icon(Icons.public_rounded),
              ),
              validator: (v) {
                try {
                  ReportingCalendar.validateZone((v ?? '').trim());
                  return null;
                } catch (_) {
                  return 'Chọn một múi giờ trong danh sách.';
                }
              },
            ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: AppSpace.xs,
            borderRadius: BorderRadius.circular(AppSpace.controlRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: AppSpace.suggestionListHeight,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final zone in options)
                    ListTile(title: Text(zone), onTap: () => onSelected(zone)),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpace.lg),
      TextFormField(
        key: const ValueKey('account-cycle'),
        controller: widget.cycleController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Ngày bắt đầu kỳ ngân sách',
          helperText: '1–31. Tháng không đủ ngày sẽ dùng ngày cuối tháng.',
        ),
        validator: (v) {
          final raw = (v ?? '').trim();
          final n = RegExp(r'^\d+$').hasMatch(raw) ? int.tryParse(raw) : null;
          return n == null || n < 1 || n > 31 ? 'Nhập ngày từ 1 đến 31.' : null;
        },
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        'Đổi chu kỳ chỉ đổi cách xem báo cáo, không sửa các lần ghi cũ.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// Optional account settings, collapsed for a new account.
///
/// Fields stay mounted while collapsed so [formKey] still validates them.
class AccountAdvancedSection extends StatelessWidget {
  const AccountAdvancedSection({
    super.key,
    required this.controller,
    required this.formKey,
    required this.initiallyExpanded,
    required this.plan,
    required this.model,
    required this.timezone,
    required this.cycle,
    required this.purposes,
    required this.onPurposesChanged,
    this.enabled = true,
  });

  final ExpansibleController controller;
  final GlobalKey<FormState> formKey;
  final bool initiallyExpanded;
  final TextEditingController plan, model, timezone, cycle;
  final Set<Purpose> purposes;
  final ValueChanged<Set<Purpose>> onPurposesChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    controller: controller,
    initiallyExpanded: initiallyExpanded,
    maintainState: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: AppSpace.lg),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    title: const Text('Tùy chọn nâng cao'),
    subtitle: const Text('Gói, model, mục đích và chu kỳ'),
    children: [
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: plan,
              maxLength: LedgerValidation.shortTextLimit,
              decoration: const InputDecoration(labelText: 'Tên gói'),
              validator: (v) => LedgerValidation.text(
                v,
                'tên gói',
                LedgerValidation.shortTextLimit,
                required: false,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            TextFormField(
              key: const ValueKey('account-model'),
              controller: model,
              maxLength: LedgerValidation.shortTextLimit,
              decoration: const InputDecoration(
                labelText: 'Model mặc định',
                helperText: 'Có thể đổi ở từng lần ghi sử dụng.',
              ),
              validator: (v) => LedgerValidation.text(
                v,
                'model mặc định',
                LedgerValidation.shortTextLimit,
                required: false,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            PurposeChipsSelector(
              purposes: purposes,
              onChanged: onPurposesChanged,
              enabled: enabled,
            ),
            const SizedBox(height: AppSpace.xl),
            AccountCycleFields(
              timezoneController: timezone,
              cycleController: cycle,
            ),
          ],
        ),
      ),
    ],
  );
}
