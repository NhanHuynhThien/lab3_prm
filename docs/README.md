# Tài liệu TokenLedger

Cập nhật 21/10/2026. Tài liệu chia trạng thái thực tế và mục tiêu triển khai để không nhầm scaffold local với bài Lab3 đã hoàn chỉnh.

## Bắt đầu

1. [README dự án](../README.md): clone/chạy local, chức năng và limitations.
2. [Build status](build-status.md): source/visual đã có, phần chưa kiểm chứng.
3. [Kiến trúc hiện hành](architecture.md): models/services/ViewModels/projections/data flow.
4. [Nguồn UI Lab2](lab2-ui-reference.md): token/mapping/source Figma.
5. [Yêu cầu Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md): baseline đề mới, toàn bộ việc thiếu/evidence và khác biệt hai mốc.
6. [Checklist](TASK_CHECKLIST.md), [roadmap](APP_COMPLETION_ROADMAP.md): tasks cũ và dependencies, đọc theo baseline mới.

## Danh mục

| Tài liệu | Nội dung | Trạng thái |
|---|---|---|
| [Analytics plan](analytics-plan.md) | Event/privacy/flow/questions/parameters | Đã viết trước instrumentation; DebugView/export-upload hooks pending |
| [Analytics/Remote Config](analytics-remote-config.md) | Implementation/defaults/console guide/manual web provenance | Client code có; console/Android/ARTEMIS còn chờ |
| [Yêu cầu Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md) | Requirement IDs/coverage/rubric/evidence/công việc còn lại | Baseline21/10; topic approved theo user, không phải các gates đã đạt |
| [Cloud workspace/rules](firestore-workspace.md) |4-tab cloud, VM/retry/lifecycle/revisions và hướng dẫn manual |326 Flutter tests/142 Rules API cases cũ; manual web user xác nhận, native còn chờ |
| [Firestore data contract](firestore-data-contract.md) | UID schema/mapping, streams/atomic CRUD/receipt/quota relations/query/indexes |Cloud UI/rules/deploy đã có;35 repository tests; manual acceptance còn chờ |
| [Firebase Auth setup](firebase-auth-setup.md) | C01–C03 Core/Auth/Google/guard/Profile/demo và manual checks | Code/config; web OAuth user xác nhận, native còn chờ |
| [Visual handoff21/10](visual-handoff-21-10.md) |8 mockups360/412, feedback/P0 fields, live links và bảng sai khác | Local source d4b6167; chưa pixel/native sign-off |
| [Local P0 upgrade](local-p0-upgrade.md) | Schema2/migration/model/default purposes/quota windows/cycle/timezone/source/analytics | Implementation local; full Firebase/native còn pending |
| [Scope decisions](scope-decisions.md) | A03–A06: thuật ngữ, P0/gaps SD01–SD08, trạng thái/lịch sử | Quyết định kỹ thuật; topic approved theo user, các nghiệm thu khác riêng |
| [Implementation plan](IMPLEMENTATION_PLAN.md) | Full product/flow/schema/Firebase/test/submission plan | Kế hoạch; nhiều phần chưa implement |
| [Task checklist](TASK_CHECKLIST.md) | P0/P1/P2 và gates | Một số local tasks done; backend/submission pending |
| [Architecture](architecture.md) | Kiến trúc code hiện tại | Đối chiếu source21/10; local + phần mở rộng B03–B13 |
| [Build status](build-status.md) | Local scaffold, design direction, visual review | Auth/Firestore workspace/rules đã có; services khác/manual native pending |
| [Design change log](design-change-log.md) | Mapping và khác biệt với StudentPay | Log local + live Figma annotation8 màn/trang07 |
| [Handoff gaps](handoff-gaps.md) | Khoảng trống spec và resolution | Phân biệt đã sửa và còn thiếu |
| [Lab2 reference](lab2-ui-reference.md) | Mapping/tokens/Figma gốc | Không giữ bản copy lịch sử trong source |
| [Test report](test-report.md) |326 unit/widget tests và giới hạn coverage | Không thay ARTEMIS/Android;142 Rules API cases không thay Final Emulator |
| [AI implementation log](implementation-ai-log.md) | Prompt thật/output/verify/decision |20 entries (entry12/14/18 Git-only, entry19 rubric/docs, entry13 visual/docs); cần đối chiếu chất lượng theo rubric |
| [Completion roadmap](APP_COMPLETION_ROADMAP.md) | Công việc hợp nhất, dependencies và acceptance | Local/Auth/Firestore đã có; L3 services/evidence và Final còn việc |
| [Fidelity draft](fidelity-check.md) | Audit B08–B13: mapping/component/layout/accessibility/states/brand/Figma | Đã có local audit F11–F13/mockups360/412; full visual sign-off/native pending |
| [Firebase pending](firebase-pending.md) | Điểm nối và thứ tự tích hợp | Core/Auth/Firestore đã có; FCM/Crash/PDF pending; Analytics/RC có client code, console pending |
| [Logo](../assets/brand/README.md) | Mark/source/icons/font license | Source SVG/painter và native icons |
| [AGENTS.md](../AGENTS.md) | Quy tắc làm việc trong repo | Entry point agent |
| [Agent workspace](../.agents/README.md) | Context/workflows/installed skills | Context/workflows; optional skills không có trong checkout |

## Deliverables còn thiếu theo hai đề mới

Lab3: design-traceability/test-plan/code-review còn thiếu; analytics-plan đã có nhưng DebugView và export/upload hooks còn pending; e2e_test ARTEMIS và evidence từng run; Storage rules (phụ thuộc REQ-SCOPE-04);RC defaults đã có; final console/manual/native evidence; report8–12p/slides12–15/video5–10m. Architecture có file nhưng cần diagrams/VM-service table/source cloud đầy đủ. Final: gap-review/data-model/cross-role-flow/ai-feature, packages/core/mobile/admin, Hosting URL, role Emulator tests và Final test-report/evidence; report10–15p/slides12–15/video8–12m. Danh sách chi tiết và acceptance tại ASSIGNMENT_REQUIREMENTS.md. Không tạo placeholder rồi báo hoàn tất.

## Quy tắc cập nhật

Ghi ngày và kết quả thật; không đổi ngày evidence cũ để giả thành lần chạy mới. Task có cùng tên chức năng chỉ được tick đúng scope: local CRUD không đồng nghĩa Firestore CRUD. Mọi lần đổi chức năng/UI cần cập nhật design/handoff log phù hợp. Repo private cần access cho người chấm trước submission.
