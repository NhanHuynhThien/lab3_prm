import 'package:flutter/material.dart';

import '../models/ledger.dart';
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

class AccountCycleFields extends StatelessWidget {
  const AccountCycleFields({
    super.key,
    required this.timezoneController,
    required this.cycleController,
    required this.budgetController,
  });

  final TextEditingController timezoneController;
  final TextEditingController cycleController;
  final TextEditingController budgetController;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        key: const ValueKey('account-timezone'),
        controller: timezoneController,
        decoration: const InputDecoration(
          labelText: 'Múi giờ chu kỳ · IANA',
          helperText: 'Ví dụ Asia/Ho_Chi_Minh, America/New_York; device giữ chính sách cũ.',
        ),
        validator: (v) {
          try {
            ReportingCalendar.validateZone((v ?? '').trim());
            return null;
          } catch (_) {
            return 'Nhập múi giờ IANA hợp lệ.';
          }
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        key: const ValueKey('account-cycle'),
        controller: cycleController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Ngày bắt đầu kỳ ngân sách',
          helperText: '1–31. Tháng ngắn dùng ngày cuối tháng, không cộng thêm phí thuê bao.',
        ),
        validator: (v) {
          final raw = (v ?? '').trim();
          final n = RegExp(r'^\d+$').hasMatch(raw) ? int.tryParse(raw) : null;
          return n == null || n < 1 || n > 31 ? 'Nhập ngày từ 1 đến 31.' : null;
        },
      ),
      const SizedBox(height: 24),
      TextFormField(
        key: const ValueKey('account-budget'),
        controller: budgetController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Ngân sách theo dõi mỗi kỳ · USD',
          hintText: '20.00',
          helperText: 'USD · Ngân sách tự đặt theo chu kỳ đã chọn. Để trống nếu chưa đặt.',
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
      const SizedBox(height: 24),
      const Text(
        'Ngân sách tự đặt không phải số dư API hay hạn mức thuê bao. Thay đổi chu kỳ chỉ đổi cách xem báo cáo, không sửa thời điểm phiên cũ.',
        style: TextStyle(color: AppColors.muted),
      ),
    ],
  );
}
