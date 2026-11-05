import 'package:flutter/material.dart';

import '../screens/provider_connections_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class OptionalSourcePrompt extends StatelessWidget {
  const OptionalSourcePrompt({super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.laptop_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đồng bộ CLI trên máy tính',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Tùy chọn bổ sung cho Codex, Claude Code, Gemini CLI và Antigravity. Bạn vẫn quản lý tài khoản, ghi usage và phân tích bằng Gemini mà không cần companion.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ProviderConnectionsScreen(),
            ),
          ),
          icon: const Icon(Icons.link),
          label: const Text('Kết nối CLI (tùy chọn)'),
        ),
      ],
    ),
  );
}
