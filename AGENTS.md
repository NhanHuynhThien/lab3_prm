# Agent instructions — TokenLedger / PRM393 Lab 3

Verification lượt UI:355/355 Flutter tests26s,12/12 Node tests pass,
analyzer sạch2.5s,154files format0changed, tất cả Dart<=300lines.
APK debug9.3s/web release18.3s build pass; APK install/start thành công.
Log chính Android PID5269 xác nhận `Provider sync: 1 ready sources; 6 model rows.`
Google session đã restore và owner auto-connect hoạt động thật trên emulator;
không coi log này là nghiệm thu mọi màn hình, Claude/Gemini/Antigravity/invoice.
Ảnh render QA với snapshot Codex thật đã xem ở412 text1 và360 text2;
6 cấu hình360/412/1440 text1/2 pass. Xem docs/provider-sync.md.


## Bố cục thống kê và tự kết nối local — 21/10/2026

Nguồn AI có vùng riêng ở đầu Tổng quan/Tài khoản/Phân tích, chọn từng Codex,
Claude, Gemini, Antigravity. Quota còn lại/reset hiển thị lớn, model/token có
nhãn nguồn; sổ thủ công tách riêng, Tổng quan thu gọn khi chưa có account.
Không suy ra usage=0 khi thiếu nguồn. Antigravity là trạng thái chưa hỗ trợ,
không có adapter mới trong lượt UI này. Gemini web/AI Pro invoice vẫn pending.
Nguồn AI không bị shell chặn bởi Firestore loading/error.

User xác nhận Codex trên Mac cùng email và yêu cầu sửa việc không hiện dữ liệu.
Build local có thể opt-in auto-connect bằng PROVIDER_BRIDGE_OWNER_EMAIL + token
trong .env.local. Chỉ email Firebase khớp mới auto-connect; mặc định bỏ trống,
demo/khác UID/email không kế thừa snapshot. Logout vẫn dispose state/timer,
Ngắt kết nối có hiệu lực trong phiên. Không hardcode email/token trong runtime
source hay ghi snapshot vào Firestore. Skill taste áp dụng theo hướng preserve,
Inter/palette/radius Lab2 được giữ; không áp dụng quy tắc web marketing vào app.
Xem docs/provider-sync.md và docs/design-change-log.md cho QA hiện hành.


## Firebase mới do người dùng sở hữu — 21/10/2026

Theo yêu cầu trực tiếp, app đã chuyển từ `tokenledger-lab3` sang
`tokenledger-nhan-20261021` (TokenLedger Nhan), owner `nhanhuynh7115@gmail.com`.
Yêu cầu mới thay ràng buộc skip Firebase cũ trong phạm vi project mới. Người dùng
đã xác nhận quyền OAuth rộng của Firebase CLI và email hỗ trợ hiển thị cho người
dùng app. Chỉ thao tác project mới; không xóa/sửa project cũ hay migrate user data.
Spark, Google Auth enabled, SHA-1/SHA-256 debug Mac registered, localhost allowed,
Firestore Standard `(default)` Singapore với rules/indexes repo đã deploy,
Remote Config v1 defaults 3/80 đã publish và đọc lại. Client Android/web và
`.firebaserc` đã cập nhật. Analytics SDK còn trong app nhưng project mới chưa liên
kết GA; không claim Analytics console đã có dữ liệu. Không bật billing/Storage.
Analyzer sạch, 48 Auth/RC tests pass, APK debug 7.0s và web release 19.9s pass;
APK đã install/open trên emulator. Native Google login đang chờ user thử, không
coi build/deploy là OAuth pass. Chi tiết `docs/firebase-project-migration.md`.


## Đồng bộ provider mới —21/10/2026

Verification cuối:346Flutter+12Node tests pass; analyzer sạch;147file format0
changed/<=300lines; APK debug11.6s/web release20.6s. DartHTTP live bridge đọc
Codex6models/2quota windows; Claude/Gemini setup. APK installed/adb reverse8787,
Studio reopened; không claim OAuth/invoice/web-consumer full coverage.

Người dùng đã yêu cầu đồng bộ mặc định ChatGPT/Codex, Claude, Gemini, gồm
model/token/chi phí. Yêu cầu này cho phép extension companion local, thay giới
hạn “chưa provider sync” trong lịch sử, không cho phép thay Firebase đang do bạn
người dùng quản lý. Đọc docs/provider-sync.md. Companion Node chỉ loopback với
pairing token/CORS/Host/auth, không phải server triển khai Final. Không đọc/in
provider credentials, scrape cookies/private consumer endpoints, gọi model hoặc
đổi billing. Claude/Gemini thiếu nguồn thật hiện setup, không giả ready.
Model history30ngày local có thể nhiều account; không khẳng định owner là email
Google. Không cộng local models vào lifetime server/manual ledger; không coi
API-equivalent estimate là phí thuê bao đã charge. Pairing theo workspace,
logout/UID change dọn state; giữ core Lab2 và3 provider mặc định.

## Setup Android và login/scroll mới —21/10/2026

Người dùng đã yêu cầu cài Android Studio, setup máy ảo và thao tác kết nối Google.
Yêu cầu mới thay ràng buộc không emulator của các lượt cũ trong phạm vi công việc
này. Mac đã có Studio/SDK/JDK/AVD ARM64 `TokenLedger_API_36` (2 CPU/2GB RAM),
Flutter Android doctor pass và APK debug build/install/start. Không suy thành
Google OAuth đã pass. SHA debug Mac khác máy trước; config hiện chưa có SHA mới.
Console tài khoản người dùng chưa thấy `tokenledger-lab3`; người dùng xác nhận
Firebase do bạn setup và yêu cầu skip thao tác Firebase Console. Không tự đổi
project/provider/config hoặc tạo project thay thế; SHA Mac cần nhờ owner thêm. Xem
`docs/google-login-environment.md` cho env JSON, VS Code và checklist.
Login dùng GoogleSignInButton/icon chính thức; app tắt Material3 overscroll
stretch theo yêu cầu. Giữ core Lab2 và accessibility, không khóa text scale.
Không nhập mật khẩu/2FA thay người dùng, không ghi credential vào env hoặc repo.

Final verification lượt Analytics/RC:326/326 Flutter tests185s, analyzer sạch14.9s, format76files0changed, web JS53.8s;52lib/24test Dart,113runtime hashes. Native/console/ARTEMIS pending; user-reported web1–7 đã ghi. Không rerun chỉ vì docs-only sau mốc này; chưa commit/push.


## Tiếp tục Analytics/Remote Config21/10

Analytics13/RemoteConfig7 client đã code theo docs/analytics-plan.md (viết trước tracking) và docs/analytics-remote-config.md. Google-only typed/noPII business events, session UID queue/dedupe/success-only mutations; demo dùng no-op. RC shared app values/defaults3recent/80warning, Profile refresh/status và projections giữ full totals. User xác nhận manual web1–7/A-B/offline đạt; không claim native/concurrency/DebugView/console/ARTEMIS. Không Android emulator, billing, Firebase config publish/deploy hoặc push ở lượt này. FCM/Crash/PDF/Final còn pending; không gộp Crashlytics thành Analytics đã nối. AI log20 entries thật, tests cuối xem test-report.


## Baseline rubric21/10 — áp dụng trước các ghi chú cũ

- Đọc `docs/ASSIGNMENT_REQUIREMENTS.md` trước triển khai tiếp. Hai đề mới L3 18 trang/Final9 trang đã được đối chiếu; topic TokenLedger được giảng viên duyệt theo user21/10. Không xin duyệt lại topic; roles Final/Storage khác nhau vẫn cần chốt.
- L3: ARTEMIS pytest ≥10cases×3runs + Pro exploratory15–30m/native/error/analytics; AI review≥5findings/≥2kinds/≥3separate finding-ID fix commits; report8–12p/slides12–15/video5–10m. MobAI/.mob/healing/3findings/6prompt gate cũ không còn là rubric hiện hành.
- Final: roles/admin/shared core/mobile+web/Hosting/inbox/cross-role/Gemini level2/AppCheck/RC và Emulator role tests là P0 Final; chưa implement. Không tự thêm AI/admin chỉ vì ghi vào backlog. L3 Storage khác Final device PDF; không dùng Cloudinary tự thay đề, không đổi billing trong lượt docs.
- Không chạy/tạo/sửa Android emulator. Firebase Emulator khác máy ảo Android, Final yêu cầu tests nhưng cần thống nhất môi trường nhẹ/máy khác/CI trước khi chạy; không tự bỏ gate hoặc báo Rules API thay Emulator.


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
- Người dùng21/10 đã tiếp tục Auth và Firestore đến mục3–5. Web Auth do user xác nhận;4-tab cloud/VM/revisions/last-good/retry/lifecycle và rules/indexes đã code/deploy tokenledger-lab3/(default).299 Flutter tests/142 Rules API cases pass; native/SDK CRUD/A-B thật vẫn cần nghiệm thu. FCM/RC/Crash/Analytics SDK/PDF chưa triển khai. Không đổi billing/telemetry ngoài phạm vi mới hoặc làm Google login giả.
- Login Google dùng AuthService thật; guard đợi userChanges, Profile dùng metadata SDK. `/?demo=1` là sandbox local riêng, không upload seed hoặc bypass backend auth. Authenticated workspace có4 tab/cloud ledger, user mới empty; không dùng local seed giả dữ liệu cloud.
- Dashboard dùng dữ liệu cloud của UID hoặc local demo tùy workspace; chưa có admin đa user, quyền role hoặc provider sync.
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
- Repository local là snapshot load/save; cloud dùng CloudLedgerViewModel/CloudLedgerRepository streams và atomic CRUD, container độc lập theo UID/demo. Giữ last-good/query/draft khi lỗi, hủy listeners/routes/state khi auth đổi. Đọc docs/firestore-workspace.md và docs/firestore-data-contract.md; không upload toàn snapshot để merge backend hoặc tự bật disk persistence.
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
- AI log có20 prompt nguồn thực đến Firestore workspace ngày21/10 (entry12/14/18 Git-only, entry19 cập nhật rubric/docs, entry13 visual/docs); vẫn cần đối chiếu scope/chất lượng theo rubric trước nộp. Không chia prompt thành các entry tưởng tượng.

## 7. Git và bàn giao

- Repo đích: `https://github.com/NhanHuynhThien/lab3_prm.git`; giữ visibility hiện có, không tự đổi public/private hoặc mời cộng tác viên.
- Publication đầu tiên vào main theo yêu cầu20/10; feature branches sau dùng prefix `codex/` trừ khi user chỉ định tên khác.
- Trước push: kiểm tra remote refs, staged diff, ignore rules và secret scan. Không force push hoặc ghi đè history người khác.
- Commit source Flutter, pubspec.lock, required platform/font assets và docs/agent instructions. Không commit vendor skills/skill lock, inspector output, tài liệu/ảnh nguồn copy, PDF đề bài, build/cache, scripting bytecode, machine paths, signing keys hoặc generated registrants.
- Không sửa SDK/dependency vendor ngoài phạm vi để chữa lỗi app. Không viết lại `.agents/skills/` third-party như thể đây là code sản phẩm.
- Cập nhật README/build-status/checklist/handoff gaps khi behavior thay đổi; report ngắn gọn phần đã làm, tests thực chạy, rủi ro/phần pending và commit/branch khi publish.
- Repo hiện private; lecturer access/submission rubric vẫn cần được xử lý đúng lúc, không tự báo final submission đã đạt.
