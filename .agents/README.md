# Agent workspace

Entry point: [AGENTS.md](../AGENTS.md).

- [Project context](project-context.md): implementation hiện tại và phần pending.
- [Workflows](workflows.md): Flutter build/test, UI/domain/docs và Git.

Bộ skill từng cài ở `.agents/skills/` được gitignore cùng cache/lock; thư mục đó không có trong checkout hiện tại. Đây là công cụ phát triển tùy chọn; source Flutter không import hoặc bundle chúng. Fresh clone chỉ cần Flutter SDK và các dependencies trong pubspec.

Không tự đưa vendor skill files, output inspector hoặc bản copy tài liệu lịch sử trở lại repo. Đối chiếu UI Lab2 qua `docs/lab2-ui-reference.md` và Figma gốc; giữ Firebase pending cho đến yêu cầu mới.
