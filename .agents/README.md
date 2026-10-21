# Agent workspace

Entry point: [AGENTS.md](../AGENTS.md).

- [Baseline Lab3 + Final](../docs/ASSIGNMENT_REQUIREMENTS.md): yêu cầu hiện hành/công việc còn lại, topic approved theo user21/10.
- [Project context](project-context.md): implementation hiện tại và phần pending.
- [Workflows](workflows.md): Flutter build/test, UI/domain/docs và Git.

Bộ skill từng cài ở `.agents/skills/` được gitignore cùng cache/lock; thư mục đó không có trong checkout hiện tại. Đây là công cụ phát triển tùy chọn; source Flutter không import hoặc bundle chúng. Fresh clone chỉ cần Flutter SDK và các dependencies trong pubspec.

Không tự đưa vendor skill files, output inspector hoặc bản copy tài liệu lịch sử trở lại repo. Đối chiếu UI Lab2 qua `docs/lab2-ui-reference.md` và Figma gốc; Auth/Firestore đã có; services mới/Final còn backlog và chỉ triển khai khi được yêu cầu. ARTEMIS thay MobAI; đọc baseline trước ghi chú lịch sử.
