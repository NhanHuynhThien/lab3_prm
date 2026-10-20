# Agent instructions — TokenLedger / PRM393 Lab 3

Cập nhật21/10/2026. Áp dụng cho toàn repo. Đây là hướng dẫn làm việc; [`.agents/project-context.md`](.agents/project-context.md) giữ trạng thái dự án và [`.agents/workflows.md`](.agents/workflows.md) giữ quy trình. Yêu cầu trực tiếp mới của người dùng có ưu tiên cao hơn các quyết định cũ ở đây.

## 1. Đọc trước khi sửa

1. `README.md`: chạy app, phạm vi đã có và giới hạn.
2. `docs/build-status.md`, `docs/architecture.md`: implementation thực tế.
3. `docs/TASK_CHECKLIST.md`: backlog, task IDs và gates chưa đạt.
4. `docs/lab2-ui-reference.md`, `docs/design-change-log.md`: core UI phải giữ.
5. `docs/firebase-pending.md`: ranh giới backend hiện tại.

Plan là mục tiêu; source/tests là bằng chứng implementation. Không suy ra một chức năng đã tồn tại chỉ vì nó xuất hiện trong plan/checklist.

## 2. Phạm vi và quyết định đang có hiệu lực

- Ứng dụng tên TokenLedger; Flutter Android là đích Lab3, web phục vụ preview/test.
- Người dùng cho phép đổi chức năng StudentPay sang quản lý account AI, token/cost/quota và mục đích công việc; giữ core UI Lab2.
- Firebase được người dùng yêu cầu pending. Chưa tự tạo project, thêm config/secret, deploy rules, bật telemetry hoặc làm Google login giả. Tiếp tục Firebase khi có yêu cầu mới cho phần đó.
- Login hiện là demo entry, Profile không có user Google thật. `/?demo=1` chỉ là đường preview của bản không có auth.
- Dashboard quản lý dữ liệu cá nhân local; chưa có admin đa user, quyền role hoặc provider sync.
- Không tự thêm chat AI, payment, cookie scraping hoặc backend secret để làm giả integration.
- Không chủ động tạo agent phụ; chỉ delegation nếu người dùng yêu cầu rõ hoặc một skill áp dụng yêu cầu rõ.
- Theo yêu cầu21/10: không khởi động, tạo hoặc sửa emulator vì máy yếu. Dùng Flutter tests và web preview; native device verification hoãn, không coi đây là blocker phải sửa máy ảo.

## 3. Kiến trúc và giới hạn lớp

- Dùng Riverpod nhất quán; không trộn Provider/BLoC/global mutable singleton.
- `lib/models/`: Dart thuần và JSON; giữ null semantics/schema version.
- `lib/services/`: persistence/external APIs và calculator thuần; chỉ services gọi SDK/backend.
- `lib/viewmodels/ledger_viewmodel.dart`: validations và mutation orchestration.
- `lib/viewmodels/reporting_viewmodel.dart`: projections/tổng/budget/shares/filter; không đặt công thức tài chính trong widget build.
- `lib/screens/` và `widgets/`: render state, controller interactions, navigation và component; không truy cập SharedPreferences/Firebase trực tiếp.
- Repository đang là snapshot load/save. Khi nối Firestore, thiết kế stream/atomic CRUD/owner scoping; không upload toàn snapshot để làm merge backend.
- Save thất bại không được publish success hoặc xóa draft. Giữ stable usage ID khi retry, guard double tap/concurrent writes.
- Giữ IndexedStack/tab state và reduced-motion behavior khi sửa animation/navigation.

## 4. Invariants dữ liệu

- App demo không yêu cầu password, API key, access token hay cookie của provider.
- USD integer micros;1USD=1,000,000 micros. Không dùng double làm nguồn tiền hoặc cộng currency khác nhau.
- Token/cost null nghĩa là chưa biết; không thay bằng0 rồi báo dữ liệu đầy đủ.
- Usage input/output cùng biết hoặc cùng trống; `knownTokens` chỉ là volume ghi nhận, không phản ánh quota thuê bao.
- Budget là hạn mức tiền tự đặt; không gọi remainingBudget là provider balance.
- Quota là snapshot nhập tay có observedAt/resetAt; quá reset là stale, không tự nhảy remaining 100%.
- Không cộng quota% giữa accounts hoặc suy quota từ usage sessions.
- Usage đã lưu không đổi accountId. Account có sessions không hard-delete; archive giữ lịch sử và chặn tạo session mới.
- Cost seed là dữ liệu giả định, không phải pricing hiện hành. Thêm integration/pricing phải có nguồn, scope và thời gian.
- Schema2 lưu timestamps UTC; reporting timezone IANA/cycle account đã có. Dữ liệu migrate giữ device, dữ liệu mới mặc định Asia/Ho_Chi_Minh; thay cycle/timezone phải có tests biên kỳ/DST.

## 5. UI kế thừa Lab2

- Nguồn tham chiếu: `docs/lab2-ui-reference.md` và Figma gốc; implementation token hiện tại nằm trong `lib/theme/app_theme.dart`. Không copy lại ảnh/tài liệu lịch sử vào runtime assets.
- Giữ Inter, primary#006C49, background#FAF8FF, mint#E8F7EF, card radius20, control12, spacing4/8/12/16/24/32, touch>=48dp, CTA52dp.
- Mobile giữ 4 destinations: Tổng quan/Tài khoản/Phân tích/Cá nhân. Desktop có sidebar mở rộng; không ép giao diện web vào điện thoại.
- Xem và đọc skill UI phù hợp trước khi áp dụng; bộ skill từng cài trong `.agents/skills/` là local tooling và được gitignore; checkout hiện tại không có thư mục này. Fresh clone không cần bộ skill hoặc Node để build Flutter.
- Existing direction: framed-sheet, seed1978369971. Giữ palette/type Lab2; các quy tắc skill mâu thuẫn yêu cầu kế thừa phải được ghi ngoại lệ có lý do, không thay nguồn thiết kế âm thầm.
- Logo gốc SVG/Flutter painter và icons phải cùng geometry. Không trình bày chữ cái provider avatar như logo chính thức.
- Motion dùng AppMotion và tôn trọng system disableAnimations; không thêm loop decoration hoặc animation che data lỗi.
- Sửa UI phải update design log, kiểm tra360/412dp và desktop khi liên quan. B13 đã annotate8 original frames; bước2 thêm8 mockups360/412 và state/P0 boards theo source d4b6167 (docs/visual-handoff-21-10.md). Audit local không phải pixel/native/lecturer sign-off.

## 6. Verification và bằng chứng

- Thay Dart: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, tests có liên quan; chạy full `flutter test` khi thay model/VM/theme/navigation dùng chung.
- Thay dependency/assets/runtime bootstrap: `flutter pub get`, analyze/test phù hợp và web build nếu ảnh hưởng bundling.
- Docs-only: kiểm tra local links, path portability, facts và checklist states. Không rerun build chỉ để tạo thêm log nếu code runtime không đổi.
- Browser inspector taste-skill không hiểu Dart/CanvasKit DOM. Khi dùng phải đánh giá ảnh render + Flutter tests; không thêm hidden h1 để qua gate giả. Output inspector là local artifact, không commit.
- Android SDK chưa có ở lần doctor19/10; trước khi claim APK/device test cần xác minh lại toolchain. Không claim web test thay Android/MobAI.
- Không tạo `.mob`, AI review findings, prompt logs hoặc console screenshots giả. Mỗi evidence ghi môi trường/thời gian và scope thật.
- AI log có14 prompt nguồn thực đến publication ngày21/10 (entry12/14 Git-only, entry13 visual/docs); vẫn cần đối chiếu scope/chất lượng theo rubric trước nộp. Không chia prompt thành các entry tưởng tượng.

## 7. Git và bàn giao

- Repo đích: `https://github.com/NhanHuynhThien/lab3_prm.git`; giữ visibility hiện có, không tự đổi public/private hoặc mời cộng tác viên.
- Publication đầu tiên vào main theo yêu cầu20/10; feature branches sau dùng prefix `codex/` trừ khi user chỉ định tên khác.
- Trước push: kiểm tra remote refs, staged diff, ignore rules và secret scan. Không force push hoặc ghi đè history người khác.
- Commit source Flutter, pubspec.lock, required platform/font assets và docs/agent instructions. Không commit vendor skills/skill lock, inspector output, tài liệu/ảnh nguồn copy, PDF đề bài, build/cache, scripting bytecode, machine paths, signing keys hoặc generated registrants.
- Không sửa SDK/dependency vendor ngoài phạm vi để chữa lỗi app. Không viết lại `.agents/skills/` third-party như thể đây là code sản phẩm.
- Cập nhật README/build-status/checklist/handoff gaps khi behavior thay đổi; report ngắn gọn phần đã làm, tests thực chạy, rủi ro/phần pending và commit/branch khi publish.
- Repo hiện private; lecturer access/submission rubric vẫn cần được xử lý đúng lúc, không tự báo final submission đã đạt.
