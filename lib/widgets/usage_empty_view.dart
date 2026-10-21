import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../screens/account_form_screen.dart';
import 'common.dart';

Widget? checkUsageEmptyGuards({
  required BuildContext context,
  required LedgerData data,
  required String? accountId,
  required UsageSession? session,
  required List<AIAccount> accounts,
  required ValueChanged<String> onAccountCreated,
}) {
  final selected = data.account(accountId ?? '');
  if (session != null &&
      (selected == null || !data.sessions.any((s) => s.id == session.id))) {
    return ContentPage(
      title: 'Sửa phiên sử dụng',
      child: EmptyFeedback(
        title: selected == null
            ? 'Không tìm thấy tài khoản'
            : 'Không tìm thấy phiên sử dụng',
        message: 'Quay lại lịch sử và tải lại dữ liệu trước khi sửa phiên.',
      ),
    );
  }
  if (accounts.isEmpty) {
    return ContentPage(
      title: 'Ghi sử dụng',
      child: EmptyFeedback(
        title: 'Thêm tài khoản trước',
        message: 'Mỗi phiên cần gắn với một tài khoản AI đang hoạt động.',
        action: 'Thêm tài khoản',
        onAction: () async {
          final id = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const AccountFormScreen()),
          );
          if (id != null) onAccountCreated(id);
        },
      ),
    );
  }
  return null;
}

class UsageTitleField extends StatelessWidget {
  const UsageTitleField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLength: 80,
    decoration: const InputDecoration(
      labelText: 'Đã dùng AI cho việc gì?',
      hintText: 'Ví dụ: Sửa lỗi Google Sign-In',
    ),
    validator: (v) => (v == null || v.trim().isEmpty)
        ? 'Nhập tên công việc.'
        : v.trim().length > 80
        ? 'Tên công việc không quá 80 ký tự.'
        : null,
  );
}

class UsageNoteField extends StatelessWidget {
  const UsageNoteField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('usage-note'),
    controller: controller,
    validator: (v) => (v != null && v.trim().length > 200)
        ? 'Ghi chú không quá 200 ký tự.'
        : null,
    maxLines: 3,
    maxLength: 200,
    decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
  );
}

class UsageModelField extends StatelessWidget {
  const UsageModelField({
    super.key,
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('usage-model'),
    controller: controller,
    maxLength: 60,
    onChanged: onChanged,
    decoration: const InputDecoration(
      labelText: 'Model sử dụng (tùy chọn)',
      helperText: 'Gợi ý từ tài khoản; để trống nếu chưa biết.',
    ),
    validator: (v) => (v != null && v.trim().length > 60)
        ? 'Model không quá 60 ký tự.'
        : null,
  );
}
