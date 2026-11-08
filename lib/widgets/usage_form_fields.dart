import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../screens/purpose_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

class UsageAccountSelector extends StatelessWidget {
  const UsageAccountSelector({
    super.key,
    required this.selectedAccount,
    required this.accounts,
    required this.session,
    required this.saving,
    required this.onAccountSelected,
  });

  final AIAccount? selectedAccount;
  final List<AIAccount> accounts;
  final UsageSession? session;
  final bool saving;
  final ValueChanged<String?> onAccountSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        session?.dataSource.label ?? 'Dữ liệu nhập tay',
        style: const TextStyle(color: AppColors.muted),
      ),
      if (selectedAccount?.archived == true)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            session != null
                ? 'Tài khoản đã lưu trữ. Bạn vẫn có thể sửa phiên lịch sử này.'
                : 'Tài khoản đã lưu trữ. Chọn tài khoản đang hoạt động để ghi phiên mới.',
          ),
        ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey(selectedAccount?.id),
        initialValue: selectedAccount?.id,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Tài khoản AI'),
        items: accounts
            .map(
              (a) => DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.alias}${a.archived ? ' · Đã lưu trữ' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: session != null || saving ? null : onAccountSelected,
        validator: (v) => v == null
            ? 'Chọn tài khoản.'
            : session == null && accounts.any((a) => a.id == v && a.archived)
            ? 'Chọn tài khoản đang hoạt động.'
            : null,
      ),
    ],
  );
}

class UsagePurposeSelector extends StatelessWidget {
  const UsagePurposeSelector({
    super.key,
    required this.purpose,
    required this.onPurposeChanged,
  });

  final Purpose purpose;
  final ValueChanged<Purpose> onPurposeChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () async {
      final p = await Navigator.push<Purpose>(
        context,
        MaterialPageRoute(builder: (_) => PurposeScreen(selected: purpose)),
      );
      if (p != null && context.mounted) {
        onPurposeChanged(p);
      }
    },
    child: Row(
      children: [
        Icon(purposeIcon(purpose)),
        const SizedBox(width: 12),
        Expanded(child: Text('Mục đích: ${purpose.label}')),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class UsageTokenInputs extends StatelessWidget {
  const UsageTokenInputs({
    super.key,
    required this.inputController,
    required this.outputController,
    required this.validator,
  });

  final TextEditingController inputController;
  final TextEditingController outputController;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Token sử dụng', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Chưa biết số token? Để trống cả hai ô, không nhập 0 thay cho dữ liệu thiếu.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: inputController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Input token'),
              validator: validator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: outputController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Output token'),
              validator: validator,
            ),
          ),
        ],
      ),
    ],
  );
}

class UsageCostSection extends StatelessWidget {
  const UsageCostSection({
    super.key,
    required this.costController,
    required this.costBasis,
    required this.onCostBasisChanged,
    required this.date,
    required this.onDateChanged,
    required this.now,
    this.saving = false,
  });

  final TextEditingController costController;
  final CostBasis costBasis;
  final ValueChanged<CostBasis> onCostBasisChanged;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime now;
  final bool saving;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: costController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Chi phí đã biết · USD',
          hintText: '0.00',
          helperText: 'Để trống nếu chưa biết. Không tự quy đổi phí gói thành giá token.',
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
      // The type only applies to a known cost; save ignores it otherwise.
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: costController,
        builder: (context, value, _) => value.text.trim().isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 24),
                child: DropdownButtonFormField<CostBasis>(
                  isExpanded: true,
                  initialValue: costBasis,
                  decoration: const InputDecoration(
                    labelText: 'Loại chi phí',
                    helperText: 'Không tự ước tính giá. Dữ liệu cũ không tự coi là chi phí thực.',
                  ),
                  items:
                      [
                            CostBasis.manual,
                            CostBasis.actual,
                            CostBasis.unspecified,
                          ]
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(
                                b.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: saving ? null : (b) => onCostBasisChanged(b!),
                ),
              ),
      ),
      const SizedBox(height: 24),
      Text(
        'Ngày sử dụng nhập theo giờ thiết bị; lịch sử và biểu đồ dùng múi giờ báo cáo đã chọn.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date.isAfter(now) ? now : date,
            firstDate: DateTime(2020),
            lastDate: now,
          );
          if (picked != null && context.mounted) {
            final candidate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              date.hour,
              date.minute,
            );
            onDateChanged(candidate.isAfter(now) ? now : candidate);
          }
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text('Ngày sử dụng: ${shortDate(date)}/${date.year}'),
      ),
    ],
  );
}
