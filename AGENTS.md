# TokenLedger — PRM393 Lab 3

## Chuẩn hiện hành — 22/10/2026

Người dùng chỉ định PDF **PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf**, **17 trang**. Đọc `docs/ASSIGNMENT_REQUIREMENTS.md` và `docs/requirements-audit.md` trước khi tiếp tục. Bản 18 trang/ARTEMIS và Final là tài liệu khác, không điều khiển lượt này. Prompt và checkpoint lịch sử giữ ở `docs/implementation-ai-log.md`; chỉ `docs/requirements-audit.md` điều khiển trạng thái hiện tại.

- Lab 3: ≥8 màn Lab2, 3 flows thật/error recovery; MVVM/Riverpod; Google Auth, Firestore CRUD/query/realtime/owner rules, PDF upload + URL/metadata Firestore, FCM, ≥2 RC, Crashlytics, Analytics.
- MobAI: 10 `.mob` trong `mobai_tests/`, kết quả thật, healing và bug-catching; unit/widget tests không thay gate này. Đề yêu cầu dedicated Google test account; user hiện cho phép tài khoản cá nhân để QA, không biến thành đã đạt gate dedicated account.
- AI review: ≥3 findings thật, ≥1 security/robustness, review cả firestore.rules, feature PR vào main, quyết định/fix/evidence; implementation log ≥6 prompts nguyên văn.
- Report 5–10 trang; video 3–5 phút. PDF này không yêu cầu slide deck hoặc ARTEMIS. Đừng tự bịa số commit cho `[N]` trong đề.
- Topic TokenLedger đã được giảng viên duyệt theo xác nhận user21/10; giữ traceability StudentPay→TokenLedger. Không xin lại topic.

## Phạm vi được người dùng cho phép

- Chỉ làm **lab3_prm**. Không khởi chạy lab1. User đã cho phép start emulator, build/install code mới và testing chi tiết từng màn/flow bằng tài khoản Google của họ.
- Chỉ dùng email để đăng nhập app. Không thao tác Gmail/mail, credential, 2FA, bảo mật, billing hoặc dữ liệu khác của tài khoản. Dùng dữ liệu QA có nhãn riêng; chỉ dọn dữ liệu do lượt test tạo.
- Runtime dùng Google login thật, không demo entry/query bypass/seed/reset demo. Fixture demo chỉ ở `test/support/`; fields legacy còn để đọc schema cũ, không phải chức năng runtime.
- Giữ hai control Crashlytics trong vùng chẩn đoán vì mục6.7 PDF yêu cầu; không nhầm chúng với demo login/data.
- Firebase hiện hành `tokenledger-nhan-20261021`, Spark; Auth/SHA/Firestore/RC đã setup theo lịch sử. Không tự bật billing, migrate project hoặc coi console evidence đã đạt. Storage/Analytics console còn phải kiểm.
- Provider companion local là extension user yêu cầu; không phải điều kiện để 3 core flows chạy. Không đọc provider credentials/cookies/private consumer endpoints, gọi model hoặc suy phí đã charge từ token.
- Không tự push/merge/deploy hoặc đổi visibility/remote name. Branch mới dùng `codex/`.
- Không chủ động tạo agent phụ trừ khi user hoặc skill áp dụng yêu cầu rõ.

## Kiến trúc

- Riverpod nhất quán. `models/` Dart thuần; `services/` persistence/SDK/API/calculators; `viewmodels/` state/business/orchestration; `screens/` và `widgets/` render, forward actions/navigation; `theme/` tokens; `utils/` formatting.
- Chỉ services gọi Firebase/external APIs. Không công thức tiền/tổng ở widget build. Gaps hiện tại phải ghi audit, không claim thư mục đúng là MVVM hoàn chỉnh.
- AuthGate tạo container/navigator riêng theo UID; share service boundaries thực từ root. Logout/UID change dispose drafts/listeners/provider snapshots. Async completion phải kiểm owner/session epoch trước publish.
- Cloud ledger streams + atomic transactions; không upload whole local snapshot. Save fail giữ draft/last-good, stable operation ID và chống double tap.
- USD integer micros; null khác0. Không cộng quota% giữa account/window hoặc biến budget tự đặt thành provider balance. Giữ UTC/IANA/account-cycle boundaries.
- Account có lịch sử archive; account rỗng được xóa. Usage edit giữ accountId; archived account không tạo usage mới.

## Design system và motion

- Đọc `docs/fidelity-check.md` và `docs/design-change-log.md`.
- Inter, primary#006C49, background#FAF8FF, mint#E8F7EF; radius20/12, spacing4/8/12/16/24/32, touch≥48, CTA52.
- Login tham chiếu composition BeeWise Mobile của user; dùng tokens/logo TokenLedger. Ghi rõ mọi đổi typography/palette và Figma còn cần annotate.
- 4 mobile tabs; desktop sidebar. Tôn trọng text scale/reduced motion, không perpetual decoration. Giữ tab state; tránh replay/chart work ở tab offstage.
- Dùng skill UI phù hợp theo preserve; không áp style web marketing trái system design mobile.

## Verification và bàn giao

- Dart files ≤300 lines. Khi thay runtime: format/analyze/tests liên quan; full tests khi sửa theme/model/navigation/bootstrap; thay dependency cần build web và Android phù hợp.
- User đã yêu cầu testing chi tiết: kiểm UI/Firestore thật, loading/empty/error/recovery, Back/draft, CRUD/reload, quota/time/unknown, PDF, source setup/errors, RC, notifications, logout. Ghi pass/fail/blocked từng case và môi trường; không gọi fake widget data là E2E.
- Không tạo `.mob`, prompt/review results, console screenshot hoặc thời gian chạy giả. Không dùng screenshot fixture làm fidelity native.
- Chỉ nêu test/build đã thực chạy; evidence online/console không tự suy từ SDK status. Giữ secrets và `.env.local` ngoài Git/log.
