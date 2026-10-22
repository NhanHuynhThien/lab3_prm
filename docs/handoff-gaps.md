# Handoff gaps và quyết định xử lý

Cập nhật22/10/2026 theo [PDF17trang](ASSIGNMENT_REQUIREMENTS.md). Nguồn Lab2 là Figma và flutter-handoff trong [fidelity-check](fidelity-check.md). Topic StudentPay→TokenLedger đã được giảng viên chấp thuận theo user21/10; không suy thành đã duyệt fidelity hoặc miễn Firebase/tests.

| Gap handoff | Cách xử lý trong source | Trạng thái/bằng chứng |
|---|---|---|
| Nghiệp vụ chia tiền khác quản lý AI | Map8screens sang account/usage/purpose/quota; giữ 3 flows tạo usage, drilldown, quản lý account | Mapping tại fidelity; native từng case ở test report |
| Không định nghĩa rõ token/quota/cost | USD integer micros; null khác0; quota độc lập/stale; actual/manual/unknown có nhãn | Models/calculator tests; provider history không thành hóa đơn |
| Login/Profile chưa đủ Google state | Google-only AuthGate; Profile từ SDK; UID keyed container/navigator; không seed/bypass | Login/native restore đã quan sát; logout/A-B native đầy đủ còn thiếu |
| Tạo/sửa/xóa khi mạng lỗi/Back | Shared validation, DraftGuard, stable IDs/receipts/revisions, keep draft/last-good/Retry, guard double tap | Unit/widget pass; native token-pair error footer cần retest |
| Không có VM riêng cho mọi screen/state | Shared Riverpod providers tránh duplicate business state | Purpose/forms/export mapping còn cần làm rõ/refactor theo §5; không tạo VM rỗng |
| Màn nguồn AI không có trong Lab2 | Dashboard agent riêng; picker/analysis/source setup theo tokens; Gemini/Antigravity coverage rõ | Figma22/10 chưa annotate |
| Provider chỉ cho quota, không token/task/cost | Giữ unknown, official Antigravity4windows; Codex/Claude CLI có detail theo log; Gemini web chỉ activity | Không giả forecast/model usage/billing; xem provider-sync |
| Desktop/chữ lớn/iOS chrome | Android SafeArea,4tabs; desktop sidebar; responsive/TextScaler/reduced motion | Widget360/412/1440,text1/2; native exact360/412/TalkBack còn thiếu |
| PDF/notification/RC/Crash/Analytics không có handoff đầy đủ | Có services/controls/views nhưng không giả dữ liệu để đủ màn | Storage/metadata/routing/events/console gaps trong requirements audit |
| Đề cũ lẫn ARTEMIS/Final | Dùng đúng Lab3 PDF17trang/MobAI/7docs/report5–10p/video3–5m | Bỏ các roadmap/baseline cũ khỏi docs; lịch sử prompt giữ nguyên trong AI log |

Thiết kế thay đổi có lý do trong [design log](design-change-log.md); annotations21/10 không tự đại diện UI22/10. [Code review](code-review.md) ghi robustness/security findings; [test report](test-report.md) phân biệt kết quả thực với pending. Không giải quyết gap bằng runtime demo, open rules, fabricate MobAI/Console evidence hoặc tự bật billing.
