# Tài liệu TokenLedger

Cập nhật 21/10/2026. Tài liệu chia trạng thái thực tế và mục tiêu triển khai để không nhầm scaffold local với bài Lab3 đã hoàn chỉnh.

## Bắt đầu

1. [README dự án](../README.md): clone/chạy local, chức năng và limitations.
2. [Build status](build-status.md): source/visual đã có, phần chưa kiểm chứng.
3. [Kiến trúc hiện hành](architecture.md): models/services/ViewModels/projections/data flow.
4. [Nguồn UI Lab2](lab2-ui-reference.md): token/mapping/source Figma.
5. [Checklist](TASK_CHECKLIST.md): làm tiếp theo dependency và evidence gates.

## Danh mục

| Tài liệu | Nội dung | Trạng thái |
|---|---|---|
| [Local P0 upgrade](local-p0-upgrade.md) | Schema2/migration/model/default purposes/quota windows/cycle/timezone/source/analytics | Implementation local; full Firebase/native còn pending |
| [Scope decisions](scope-decisions.md) | A03–A06: thuật ngữ, P0/gaps SD01–SD08, trạng thái/lịch sử | Hoàn tất quyết định kỹ thuật; không thay lecturer approval |
| [Implementation plan](IMPLEMENTATION_PLAN.md) | Full product/flow/schema/Firebase/test/submission plan | Kế hoạch; nhiều phần chưa implement |
| [Task checklist](TASK_CHECKLIST.md) | P0/P1/P2 và gates | Một số local tasks done; backend/submission pending |
| [Architecture](architecture.md) | Kiến trúc code hiện tại | Đối chiếu source21/10; local + phần mở rộng B03–B13 |
| [Build status](build-status.md) | Local scaffold, design direction, visual review | App local hoạt động; Firebase pending |
| [Design change log](design-change-log.md) | Mapping và khác biệt với StudentPay | Log local + live Figma annotation8 màn/trang07 |
| [Handoff gaps](handoff-gaps.md) | Khoảng trống spec và resolution | Phân biệt đã sửa và còn thiếu |
| [Lab2 reference](lab2-ui-reference.md) | Mapping/tokens/Figma gốc | Không giữ bản copy lịch sử trong source |
| [Test report](test-report.md) |200 unit/widget tests và giới hạn coverage | Không phải MobAI/Firebase evidence |
| [AI implementation log](implementation-ai-log.md) | Prompt thật/output/verify/decision |12 entries (entry12 Git-only); cần đối chiếu chất lượng theo rubric |
| [Completion roadmap](APP_COMPLETION_ROADMAP.md) | Công việc hợp nhất, dependencies và acceptance | A03–A06 hoàn tất; B01–B14 local/annotation đã kiểm chứng21/10; Firebase pending |
| [Fidelity draft](fidelity-check.md) | Audit B08–B13: mapping/component/layout/accessibility/states/brand/Figma | Đã xem8 final360/annotate live Figma; full QA412/mockup/final fidelity pending |
| [Firebase pending](firebase-pending.md) | Điểm nối và thứ tự tích hợp | Chưa có project/config/SDK |
| [Logo](../assets/brand/README.md) | Mark/source/icons/font license | Source SVG/painter và native icons |
| [AGENTS.md](../AGENTS.md) | Quy tắc làm việc trong repo | Entry point agent |
| [Agent workspace](../.agents/README.md) | Context/workflows/installed skills | Context/workflows; optional skills không có trong checkout |

## Deliverables đề yêu cầu chưa có

`analytics-plan.md`, `code-review.md`, MobAI scripts, Firebase rules/indexes, report5–10 trang và video3–5 phút phải tạo khi thực hiện phần tương ứng. fidelity-check.md hiện là bản audit local, chưa nghiệm thu F11–F13. Chưa có PR hoặc AI PR findings; không dùng tài liệu architecture này làm bằng chứng đã code review.

## Quy tắc cập nhật

Ghi ngày và kết quả thật; không đổi ngày evidence cũ để giả thành lần chạy mới. Task có cùng tên chức năng chỉ được tick đúng scope: local CRUD không đồng nghĩa Firestore CRUD. Mọi lần đổi chức năng/UI cần cập nhật design/handoff log phù hợp. Repo private cần access cho người chấm trước submission.
