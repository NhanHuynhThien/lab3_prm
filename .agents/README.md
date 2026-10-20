# Agent workspace — TokenLedger

Hướng dẫn entry point của Codex là [`AGENTS.md`](../AGENTS.md) ở root. `.agents/` là thư mục hỗ trợ; không tạo thêm `.agent` trùng nghĩa.

| Tài liệu | Dùng khi |
|---|---|
| [Project context](project-context.md) | Bắt đầu lượt mới, cần biết state hiện tại và pending |
| [Workflows](workflows.md) | Build/test/UI/docs/Git/Firebase continuation |
| [Root agent instructions](../AGENTS.md) | Quy tắc kiến trúc, dữ liệu, thiết kế và verification |
| [`skills/`](skills/) |13 skill third-party cài từ Leonxlnx/taste-skill |
| [Skill lock](../skills-lock.json) | Source path và hash khi đã cài |

Các file context/workflows là tài liệu repo do dự án quản lý; `skills/` giữ hướng dẫn vendor. Không sửa vendor chỉ để phản ánh state dự án. Không cần cài lại npx mỗi lượt khi bộ skill đã có; đọc đúng SKILL.md cần dùng.

Trạng thái ghi ngày 20/10/2026. Khi user đổi quyết định, cập nhật tài liệu sau khi có kết quả thực; ưu tiên yêu cầu trực tiếp mới hơn thông tin lịch sử.
