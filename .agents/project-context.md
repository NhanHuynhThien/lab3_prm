# Project context — 20/10/2026

## Mục tiêu và môi trường

TokenLedger chuyển core UI StudentPay Lab2 thành app quản lý AI account, cost/token/quota và công việc. Người dùng đã cho phép thay đổi chức năng, tạo logo, cài taste-skill và nâng cấp dashboard/animation. Firebase được hoãn rõ ràng.

Project package `token_ledger`, applicationId `com.tokenledger.token_ledger`, version 0.1.0+1. Flutter3.47.5, Dart3.13.4; dependencies được khóa bởi `pubspec.lock`. Android/web source có sẵn. Chưa có Android SDK trong lần kiểm tra19/10, nên không có APK/native test evidence.

## Đã thực hiện

- 12 screen files + usage detail sheet;4-tab mobile, sidebar desktop, IndexedStack giữ tab state.
- MVVM/Riverpod: ledger mutation VM, reporting projections, pure calculator, local repository.
- Account create/read/edit/archive/restore và hard delete khi rỗng; sessions CRUD; quota update.
- Analytics metric cost/token/sessions, purpose ring/legend và account comparison; drilldown history có filters/search.
- Money micros/parser; unknown metrics được giữ null; budget không phải provider balance.
- Seed3 accounts/12 sessions, cost$12.84/known tokens 286k; missing cost/token 1 session. Không phải dữ liệu sync.
- Original logo hexagon T/L: SVG, PNG1024, Flutter painter, Android/PWA icons.
- Taste-skill13 packages installed; framed-sheet seed1978369971, keep palette/type Lab2. Motion hỗ trợ reduced motion.
- Tests16; analyzer sạch và web release build đã pass ở lượt scaffold19/10. Verification20/10 được ghi trong test-report/log riêng khi chạy thật.

## Nguồn phải đọc

1. `docs/architecture.md`: data flow và invariants actual code.
2. `docs/lab2-ui-reference.md`: tokens,8-screen mapping, portable snapshots.
3. `docs/build-status.md`, `docs/test-report.md`: evidence và giới hạn.
4. `docs/TASK_CHECKLIST.md`: backlog đầy đủ; gates Firebase chưa đạt.
5. `docs/firebase-pending.md`: điều kiện nối backend sau.

Source Lab2 đã snapshot 20 PNG +3 text files, hashes trong `docs/references/lab2/provenance.json`. Không cần absolute machine path để đọc tham chiếu sau clone. Figma gốc có link trong README; live annotations vẫn pending.

## Chưa làm — không báo nhầm đã xong

- Firebase project/config/Auth/Firestore/rules/indexes/realtime/user isolation.
- FCM/Notification Center, RC, Crashlytics, Analytics DebugView, PDF/cloud upload.
- Đồng bộ usage/quota provider, API credentials, import CSV/pricing engine/cache buckets.
- Multi-window quota, IANA timezone/cycle tùy chỉnh, full router/deep links, discard-draft dialog.
- Android build/install và full accessibility/native keyboard verification.
- 10 MobAI scripts, healing/bug-catching exercise, AI PR review, report/video nộp bài.
- Lecturer approval về đổi chủ đề/làm nhóm, StudentID repo naming cuối, deadline/commit-count placeholder.

## Git và repo

Repo người dùng cung cấp: `https://github.com/NhanHuynhThien/lab3_prm.git`. Trước lần publication 20/10, GitHub repo private và trống; local chưa có Git. User đã yêu cầu cập nhật docs/agent rồi push source. Giữ visibility private. Đọc `git log/status/remote` để lấy state mới nhất, không hard-code commit SHA trong memory.

## Việc kế tiếp hợp lý

Nếu vẫn giữ Firebase pending: tiếp tục polish form/back-draft, kiểm tra text scale/keyboard/screens đầy đủ và chuẩn bị Android toolchain khi user yêu cầu. Khi user bật Firebase: bắt đầu auth/owner-scoped repository/rules trước services còn lại. Chỉ dùng dữ liệu thật sau khi có bảo vệ ownership và logging phù hợp.
