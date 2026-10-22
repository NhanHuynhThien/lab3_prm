# Test report — Flutter local và lịch sử verification

## Tích hợp toàn diện Firebase Services (Crashlytics, FCM, PDF Export & Cloud Storage) — 22/10/2026

Verification sau khi hoàn thành tích hợp trọn bộ 6 dịch vụ Firebase theo yêu cầu Lab 3:
- **Firebase Crashlytics**:
  - `CrashlyticsService` & `FirebaseCrashlyticsTransport` tích hợp `firebase_crashlytics: ^6.0.0`.
  - Thiết lập hook toàn cục `FlutterError.onError` và `PlatformDispatcher.instance.onError`.
  - Hỗ trợ bind owner UID, custom diagnostic keys (`app_flavor`, `user_type`), ghi lỗi handled non-fatal và deliberate test crash.
  - Safe fallback trên nền tảng Web (`kIsWeb`) tránh ngoại lệ không hỗ trợ.
- **Firebase Cloud Messaging (FCM) & Notification Center**:
  - `NotificationService` & `FirebaseNotificationTransport` tích hợp `firebase_messaging: ^17.0.0`.
  - Xin quyền thông báo (alert, badge, sound), lắng nghe foreground notification stream, notification opened stream, background isolate handler.
  - Trung tâm thông báo `NotificationCenterSheet` trong Profile & chuông thông báo có unread badge trên `DashboardScreen`.
  - Hỗ trợ xem danh sách thông báo, đánh dấu đã đọc (`markAsRead`), gửi thông báo mẫu để kiểm thử.
- **Xuất báo cáo PDF & Cloud Storage**:
  - `PdfReportService` & `PdfReportBuilders` tạo file PDF chuẩn chỉnh khổ A4, nhận diện thương hiệu TokenLedger với header, bảng tổng quan chi phí, bảng tài khoản AI, bảng phân bổ mục đích và bảng các phiên gần nhất.
  - Lưu file cục bộ qua `path_provider` và mở xem trước bằng `open_filex: ^5.0.0`.
  - `FirebaseStorageTransport` & `ReportManagementService` tải file lên Firebase Storage theo đường dẫn `reports/{uid}/{fileName}` với metadata và theo dõi tiến trình upload.
  - Quy tắc bảo mật `firebase/storage.rules` giới hạn quyền đọc/ghi nghiêm ngặt theo UID người sở hữu (`request.auth.uid == uid`).
  - Giao diện `ExportReportDialog` và danh sách báo cáo trong Profile trực quan, có nút Mở PDF và Tải lên Cloud.
- **Analytics mở rộng**:
  - Thêm các sự kiện: `export_report` (format: pdf), `upload_report` (destination: cloud_storage), `notification_received`, `notification_opened`.

| Check thực chạy | Kết quả | Ghi chú |
|---|---|---|
| Full flutter test | **370/370 tests pass (352s)** | Toàn bộ 370 tests pass 100%, bổ sung 4 test suites mới cho Crashlytics, Notification, PDF và Report Management (15 tests) |
| flutter analyze | **No issues found! (35.2s)** | 0 errors, 0 warnings, 0 lints trên toàn bộ mã nguồn |
| Kiểm tra giới hạn dòng `tool/check_line_limits.dart` | **170/170 files <= 300 dòng (100% pass)** | Toàn bộ 170 tệp Dart trong `lib/` và `test/` đạt chuẩn <= 300 dòng |
| Gradle compile | **BUILD SUCCESSFUL (2m 27s)** | `:app:processDebugGoogleServices` hoàn tất thành công, không xung đột plugin Android |
| Firebase Storage rules CLI deploy probe | **Bucket Setup Required** | File `firebase/storage.rules` hợp lệ, cấu hình `firebase.json` sẵn sàng; cần kích hoạt "Get Started" trên Firebase Console để tạo bucket trước khi deploy rules |

## Tối ưu hiệu năng, kiến trúc & giới hạn 300 dòng — 21/10/2026

Verification sau khi hoàn thành đợt refactoring, tối ưu hiệu năng và kiểm soát giới hạn dòng:
- Flutter 3.47.4 / Dart 3.13.3 trên Windows.
- Script tự động: `dart run tool/check_line_limits.dart` kiểm tra toàn bộ 134 file Dart trong `lib/` và `test/`. Kết quả: **134/134 files đạt <= 300 dòng vật lý (100% pass)**.
- Đã gỡ bỏ dependency thừa `cupertino_icons: ^1.0.8` khỏi `pubspec.yaml`, giảm dung lượng icon asset và tree-shaking overhead.
- Tối ưu `CloudLedgerViewModel.publish()`: chuyển từ lookup $O(N \times M)$ lồng nhau sang precomputed maps $O(N + M)$ cho quota snapshots và usage counters.
- Thu hẹp vùng repaint / rebuild: thêm `RepaintBoundary` cho 4 tabs chính trong `ShellScreen`, tách `AccountCard` thành `ConsumerWidget` riêng biệt tránh rebuild toàn bộ danh sách khi 1 account thay đổi.

| Check thực chạy | Kết quả | Ghi chú |
|---|---|---|
| Kiểm tra giới hạn dòng `tool/check_line_limits.dart` | **134 files <= 300 dòng (100% pass)** | 66 lib files, 68 test files (bao gồm các test harness helpers) |
| Full flutter test `--concurrency=1` | **326/326 tests pass (221s)** | Toàn bộ 326 tests pass 100%, bảo toàn 100% logic nghiệp vụ và invariants |
| flutter analyze | **No issues found! (13.7s)** | 0 errors, 0 warnings, 0 lints |
| dart format `--output=none --set-exit-if-changed lib test` | **134 files formatted (0 changed)** | Mã nguồn được format chuẩn theo Dart guidelines |
| flutter build web `--release --no-pub --no-wasm-dry-run` | **Built build/web (71.6s)** | Bundle JS: 4,178,237 bytes (~4.18 MB) |
| git diff --check | **Clean (0 whitespace/conflict errors)** | Không phát sinh lỗi whitespace hoặc xung đột |

## Analytics/Remote Config — kết quả cuối21/10/2026

Source working tree sau main484cc41, chưa commit lượt docs/features. Flutter3.47.4/Dart3.13.3 trên Windows; không emulator/native/browser-driven test. firebase_analytics13.0.0/remote_config7.0.0 resolve thành công bằng flutter pub add (6 dependencies mới, không sửa SDK/vendor). Runtime snapshot113 files trong tooling local giữ nguồn đã verify; không dùng SHA main cũ đại diện code mới.

| Check thực chạy | Kết quả |
|---|---|
| Service/privacy/identity/RC/VM mutation/projection mới |19/19 tests pass; success-only/noPII/dedupe/owner clear/stale queue/cache/default/failure/retry/single-flight/dispose/full-dataset |
| UI/lifecycle mới |8/8 pass: Profile360/412/1440×800 text1/2, fonts thật, refresh/error/last-good; root services shared, initial overview/tab event/no duplicate, demo không init SDK |
| Full flutter test --no-pub --concurrency=1 --dart-define=FEATURE_IMAGES=true --reporter expanded |**326/326 pass185s**,27 tests mới; giữ299 assertions/tests trước |
| flutter analyze --no-pub |**No issues found**,14.9s sau lint fixes |
| dart format --output=none --set-exit-if-changed lib test |**76 files0changed**,52 lib/24 test Dart files |
| flutter build web --release --no-pub --no-wasm-dry-run |**Built build/web**,JS compile53.8s; không Wasm/Android APK/deploy |
| Docs/config/source audit |28 Markdown,0 broken local links/fences/machine paths;93 roadmap/196 checklist IDs giữ đủ,89 requirement IDs unique;20 AI entries thật;144 candidate files/113 runtime hashes, không phát hiện secret theo patterns đã kiểm;3 public Firebase client-key occurrences đúng2 config files |

Lượt đầu UI helper không thấy control lazy/offscreen và capture/cleanup async kẹt fake clock; đã sửa scroll/pump và raster real-async/stream cleanup, giữ assertions, dừng đúng task test trees. Lượt sandbox format cuối không trả output; chạy lại bằng quyền SDK phù hợp pass0changed, không sửa SDK/dependency vendor hoặc dừng flutter run người dùng.6 ảnh Profile đã tạo trong .taste-skill ignored, đã xem360text2/412text1/1440text1; các viewport còn lại có Flutter assertions. Không dùng ảnh fixture làm console/Auth người dùng evidence.

Manual web: user xác nhận account/usage/quota/reporting/unknown/validation/draft/archive/delete/reload/A-B/offline1–7 đạt theo [record](analytics-remote-config.md). Đây là user provenance, không phải agent native/automation/real concurrency stress. Rules/indexes không đổi trong lượt này;142 Rules API cases/5READY là evidence cũ, không chạy lại hoặc claim Emulator.

**Pending:** Remote Config console publish→app before/after, DebugView từng event+params/UID, Android/native/ARTEMIS analytics assertion, export/upload event hooks khi PDF có code; FCM/Crash/PDF/Final requirements. App hiển thị SDK/effective config state, không claim console receipt. Không Firebase admin writes/publish/billing/telemetry console setup hoặc Git push trong lượt này.


## Audit Markdown theo hai đề mới —21/10/2026

Docs-only sau khi user xác nhận topic được giảng viên duyệt: đọc L3 18 trang/FA9 trang, baseline ASSIGNMENT_REQUIREMENTS.md có **89 requirement IDs** (6 scope +47 Lab3 +36 Final), kèm bảng coverage từng mục/phụ lục/rubric và điều kiện evidence.2 scope IDs done (topic approval/user provenance, đối chiếu đề);87 IDs chưa đóng toàn scope, gồm1 optional bonus, không suy thành87 features chưa code. B/A local checked giữ đúng scope lịch sử.

Kiểm links/fences/portability trên26 Markdown; roadmap93 IDs và checklist196 IDs giữ đủ/không trùng; requirement IDs unique/contiguous. AI log19 entries thật.104 runtime SHA256 khớp baseline trước299 Flutter/142 Rules API tests; chỉ .md thay đổi, source/config/dependencies không đổi. Lượt này không chạy Flutter/analyzer/build/ARTEMIS/Firebase Emulator/deploy, không thay billing hoặc phát sinh console/test evidence mới. Chưa commit/push.

Baseline hiện hành cập nhật thresholds/tools/deliverables, không fabricate findings/trace/approval và không đóng native/manual/backend gates. Topic approval không đồng nghĩa đã duyệt Final roles/PDF miễn trừ. Kiểm tra lại bằng git diff --check và local audit trước bàn giao; artifacts audit ở .taste-skill ignored, không commit.


## Cập nhật yêu cầu21/10 — ưu tiên hơn checkpoint phía dưới

[Baseline Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md) đã đối chiếu đủ hai PDF mới. Giảng viên chấp thuận đổi sang TokenLedger theo xác nhận trực tiếp của người dùng21/10; các câu còn chờ duyệt chủ đề phía dưới là lịch sử. Không suy thành duyệt roles Final, miễn Storage/tests hoặc nghiệm thu UI.

Auth/Firestore workspace/rules/indexes đã có tại main484cc41;299 Flutter tests/142 Rules API cases là evidence trước lượt docs, manual CRUD/A-B/native còn chờ. Đề mới yêu cầu ARTEMIS (không MobAI), AI review5 findings/3 separate fixes, report8–12p/slides12–15/video5–10m. Final cần roles/admin/shared core/cross-role/Gemini/AppCheck và Emulator tests; PDF L3 Storage khác Final device save/share. Baseline mới giữ mọi việc còn mở, không tick từ lượt docs này. Các checkpoint phía dưới chỉ có hiệu lực trong scope/time ghi tại từng mục.


Hiện trạng mục3–5 Firestore workspace21/10/2026:46 lib/22 test Dart files (2 helpers),299 Flutter tests pass162s;25 VM/workspace tests mới. Rules API142 cases pass; rules/indexes deploy và hash/unauth403 đã xác nhận. Web release48.3s, analyzer sạch; readiness/native/manual limits xem phần cuối. Các số274/239 và foundation/Auth phía dưới là checkpoints lịch sử.

Hiện trạng Firestore foundation21/10/2026:44 lib/20 test Dart files (2 support helpers),274 tests.35 tests cloud mới pass; full274/274 pass138s, sau đó siết receipt/path validation và chạy lại35 tests liên quan pass. Analyzer sạch; build/format cuối ghi tại phần Firestore foundation cuối file. Kết quả239 tests sau Auth bên dưới là checkpoint trước lượt repository.

Hiện trạng Auth21/10/2026:39 lib/18 test Dart files (gồm support helper); full239/239 tests pass140s, analyzer sạch, format57 files0 changed. Baseline trước Auth:33 lib/14 test files,200 tests. Mục upgrade cuối file ghi môi trường/build/evidence/giới hạn. Các bảng16/38/106/142/168 tests và A03–A06 docs-only bên dưới là lịch sử, không phải kết quả runtime hiện hành.

Lịch sử scaffold20/10/2026. Kết quả là unit/widget tests của Flutter, chưa phải MobAI/Firebase/Android integration evidence.

## Firestore foundation — kết quả cuối21/10/2026

- Môi trường Flutter3.47.4/Dart3.13.3, Windows; cloud_firestore7.0.0, platform interface8.0.8/web5.7.4. Dependency resolve thành công, không nâng các dependency cũ.
- `flutter test --no-pub --concurrency=1 --reporter expanded`: **274/274 pass138s** gồm35 tests cloud mới. Sau đó siết allowlist/schema/revision/timestamp receipt và typed errors ở path helper; chạy lại toàn suite repository **35/35 pass**, không chạy lại toàn app chỉ vì docs. Source UI/Auth/local model/VM không đổi trong lượt này, trừ comment mô tả local repository.
- `flutter analyze --no-pub`: **No issues found**, lần cuối7.7s. Format64 Dart files0 changed sau chỉnh sửa cuối.44 lib/20 test files gồm2 test support helpers.
- `flutter build web --release --no-pub --no-wasm-dry-run`: **thành công71.0s** sau thay đổi source cuối. Không APK/native/device/emulator hoặc database/rules integration.
- Audit24 Markdown: local links/fences/portability sạch,93 roadmap IDs/196 checklist IDs unique,16 AI entries nguồn thực. Candidate secret-pattern scan125 files không phát hiện private/provider/admin/OAuth secrets theo patterns; Firebase client keys chỉ ở config đã cho phép. Không phải audit toàn lịch sử Git.

Tests dùng LedgerCloudFake optimistic transactions: check versions trước commit, retry contention, fail/lost acknowledgement, read-after-write bị chặn; kiểm account/usage/quota CRUD/revisions/receipt/labels/UID/metadata/lifecycle. Không evaluate Security Rules hoặc xác nhận hành vi backend thật.5 composite indexes có file, chưa deploy/configure CLI. App vẫn dùng local demo và authenticated Profile riêng; bước rules và VM/UI chưa làm. Người dùng báo web OAuth/reload/logout/Users đã thành công và tạo Firestore; không gán là agent/native verification.

Logs local ignored: `.taste-skill/firestore-foundation/full-tests.log`, `repository-tests.log`, `web-build.log`, `final-audit.json`. Thiết kế/giới hạn tiếp nối: [data contract](firestore-data-contract.md).

## Cloud workspace/rules — kết quả cuối21/10/2026

Môi trường Windows/Flutter3.47.4/Dart3.13.3; Google web Auth và Firestore creation được user xác nhận trước lượt này. Không tạo Google test users, không đọc/ghi ledger documents thật hoặc chạy emulator/native.

| Kiểm tra | Kết quả thật / scope |
|---|---|
| Full Flutter regression | **299/299 pass162s**,25 tests mới (14 cloud VM,11 cloud workspace);15 Auth tests cập nhật giữ assertions |
| Analyze | **No issues found**, lần cuối7.9s sau disk-cache setting; lần regression trước18.5s |
| Format |68 Dart files; formatter đã áp dụng cho source mới, kiểm lại0 changed trước bàn giao |
| Web release | **Pass48.3s**, `--release --no-pub --no-wasm-dry-run`; có SDK factory tắt disk persistence |
| Rules Test API | **142/142 pass**, no compile issues; point-state get/getAfter/exists/existsAfter mocks, không document writes/emulator |
| Deployment | CLI deploy rules/indexes riêng vào tokenledger-lab3/(default) thành công; Standard/asia-southeast1 |
| Remote rule source | SHA256 `42f9dcf5d72393a3b5c942c88c7ed76ea4cfdff5458f2ed2e1bc3e0cc31ad86d`, khớp local và source142 tests |
| Index readiness | **5/5 READY** lúc2026-10-21T06:09:30Z; lúc đọc trước còn CREATING, không gọi accepted là READY. Receipt.intent có0 indexes đúng exemption |
| Live negative read | Không auth: HTTP403/PERMISSION_DENIED, không trả ledger data |
| UI engine |360/412/1440×800 text1/2, real Inter/MaterialIcons; Profile fixture ảnh360/text1 và1440/text2 đã xem, không console/Google user evidence |

Coverage mới: cùng dataset cho projections/totals, empty user không seed, atomic CRUD/quota/settings, revision từ lúc mở form, pending command/receipt retry sau lost acknowledgement, query error giữ last good/search/draft, Retry ngay trên form route, initial failure vẫn logout được, disposal lúc bootstrap, concurrent retries, A→B container/routes/listeners cleanup và cloud↔demo không trộn dữ liệu.

Các iterations trước final có lỗi fixture/import/finder/lazy footer/desktop nav/Flutter binding; stale-form test bị treo khi await external fake repository.close trong fake async, đã chuyển external fixture sang tester.runAsync rồi pass, giữ assertions. Chỉ dừng các cây task test đã xác minh, không dừng flutter run của user. API rules phát hiện hash hex uppercase và max1000 expressions ở quota edit; đã sửa lowercase/branch selection rồi142 cases pass. Một regression trước final được dừng sau khi đã biết test helper lỗi; chỉ log `regression-final.log` đại diện full pass.

Sau regression có cấu hình SDK factory tắt disk persistence, được kiểm analyzer/web compile; fake store tests không kiểm native SDK disk cache behavior. SDK in-memory cache không được tuyên bố đã xóa vật lý. Chưa có actual authenticated SDK CRUD/reload/A-B/backend contention hoặc native/Play services evidence mới; GATE-03/04 và emulator task vẫn chưa đạt từ các số tests/simulations này. FCM/RC/Crash/Analytics SDK/PDF còn pending, Figma chưa sync cloud.

Logs/ảnh ignored tại `.taste-skill/firestore-ui/`: `regression-final.log`, `web-final.log`, `rules-final.json`, `deploy.log`, `backend-before.json`, `deploy-verification.json` và Profile fixtures. Scripts kiểm rules tái chạy được ở [tool/firestore_rules_test.cjs](../tool/firestore_rules_test.cjs); hướng dẫn manual tại [Firestore workspace](firestore-workspace.md). Chưa commit/push lượt Auth/foundation/workspace.

Audit cuối25 Markdown: local links/fences/portability sạch,93 roadmap IDs/196 checklist IDs unique,17 AI entries thật. Candidate scan132 files không phát hiện private/provider/admin/OAuth secrets theo patterns đã kiểm;3 Firebase client key occurrences chỉ ở config cho phép.104 runtime hashes được giữ qua audit docs cuối. Không phải audit toàn lịch sử Git hoặc AI PR review.

## Coverage tại scaffold19–20/10 (lịch sử)

| Suite | Tests | Kiểm tra |
|---|---:|---|
| calculator_test.dart |7| Totals/coverage, null-vs-zero, period/account filter, USD parser, JSON, quota stale, seed đầu tháng |
| ledger_viewmodel_test.dart |4| Usage persistence/idempotency, save failure, archive/delete guards, account CRUD/reload |
| widget_test.dart |5| Demo/navigation/layout360/412/768/1440dp và usage form validation/save |

Tổng16 tests. Lượt verification trước cleanup đã pass format/analyzer/tests; web release build scaffold cũng thành công. Raw logs và ảnh inspector đã loại khỏi repo theo yêu cầu dọn source. Kết quả CLI tiếp theo được ghi bằng summary tại cuối tài liệu này, không tạo script hoặc compiled artifacts trong Git.

## Các lỗi đã xử lý ở lượt scaffold

- Sửa test expectation306k về tổng seed thực286k.
- Sửa logo/sidebar text overflow bằng Flexible/Expanded.
- Helper/error text cho nhiều dòng; zero-value bar không có height giả.
- Chưa có budget thì hiển thị Chưa đặt ngân sách.

## Cleanup verification

Thay đổi packaging: bỏ directory assets/brand khỏi Flutter asset bundle. Logo UI dùng CustomPainter, launcher PNG ở platform source; font Inter vẫn được bundle.

Cần clean build rồi chạy pub get, format/analyze/test và web release build để xác minh không có asset reference bị hỏng. Build/cache sinh ra được gitignore và dọn sau verification.

## Chưa làm

Google Auth/Firestore/rules/FCM/Remote Config/Crashlytics/DebugView, PDF cloud, provider sync,10 MobAI scripts/healing/bug exercise, AI PR review, Android APK/device tests và full Figma fidelity/accessibility.

Kết quả clean verification20/10/2026: pub get thành công; format28 files không thay đổi; analyzer No issues found;16/16 tests pass; web release build thành công sau khi bỏ brand directory khỏi bundle. Đã xác minh output không có assets/brand, font Inter vẫn hiện diện. Sau verification chạy Flutter clean để bỏ output/cache local. Không commit artifacts sinh từ compile.

## Local form safety — 21/10/2026

Môi trường thực kiểm tra: Windows10, Flutter3.47.4 / Dart3.13.3 (khác phiên bản lịch sử20/10), Android SDK build-tools36.0.0, JBR25 từ Android Studio. `flutter doctor -v`: No issues found, licenses accepted. `ANDROID_HOME` của shell cũ trỏ đường dẫn không tồn tại, nhưng Flutter tìm được SDK hợp lệ; lệnh Android trong lượt này dùng SDK đã tìm thấy, không đổi biến môi trường hệ thống.

`flutter pub get` thành công, không nâng dependency; `flutter analyze --no-pub`: No issues found. `flutter test --no-pub --reporter expanded`: **38/38 pass**, gồm7 calculator,5 VM,5 widget/navigation,21 form safety. Đây là lần chạy mới21/10, không sửa thời gian của kết quả cũ.

Coverage mới: ba form account/usage/quota có clean/dirty Back, continue/discard và system Back ở widget binding; save failure giữ draft, retry và blocking khi pending; account/usage retry cùng ID; quota retry giữ cùng account; archived usage edit nhưng chặn new/move; purpose round trip; long alias;12 tổ hợp form×width360/412×text scale1/2 với keyboard inset300dp trên viewport800dp. Footer được assert nằm trên keyboard và cao>=48dp. Widget keyboard inset là mô phỏng, không thay kiểm bàn phím native.

Lượt test đầu phát hiện billing dropdown overflow360dp; đã sửa và rerun pass. Test form safety đầu19/19 pass, sau đó bổ sung quota retry/long alias và chạy full38/38. Không có MobAI/Firebase/rules tests trong lượt này.

### Android build và giới hạn native — 21/10/2026

- `flutter build apk --debug`: thành công, Gradle assembleDebug707 giây. Lần build đầu tự cài SDK Platform35/36 và CMake3.22.1 theo dependency requirements/licenses sẵn có; không chỉnh SDK/vendor source.
- Output local `build/app/outputs/flutter-apk/app-debug.apk`,157.209.241 bytes; SHA256 `03B1BCB4E4ADD43620A8701C8652910CFA78A8D06552B32C2E8086FB6C4080E6`. Build/cache được ignore, gồm cache `android/.kotlin/` phát sinh lần build Android đầu.
- AVD Pixel7/API34 có sẵn bị SettingsProvider crash vì `settings_global.xml` không có fallback, reboot loop; không wipe/sửa dữ liệu AVD gốc.
- Thử AVD QA riêng bằng system image API34/x86_64 đã cài, cold boot/software GPU và ADB reconnect/loopback; vẫn offline. Ổ C thiếu chỗ cho partition mặc định, đã thử QA trên ổ D; không claim cài/chạy app thành công.
- **Chưa đạt native smoke:** install/launch, CRUD/restart persistence và bàn phím thật còn cần thiết bị Android kết nối hoặc AVD hoạt động. Không có thiết bị vật lý trong lượt này. SDK có sẵn không đồng nghĩa emulator/native test pass.
- Đã xem ảnh widget render360×800 bằng font Inter/MaterialIcons thật cho usage form với keyboard inset và discard dialog. Script/ảnh QA chỉ nằm trong build/`.taste-skill/` bị ignore, không phải ảnh native/browser hoặc full Figma fidelity. Format30 files không đổi, diff whitespace sạch; không chạy lại web release vì không thay dependency/assets/bootstrap.

## B03–B07 — kết quả cuối và audit21/10/2026

Môi trường: cùng Flutter3.47.4/Dart3.13.3 trên Windows; không chạy emulator theo yêu cầu người dùng. Tăng từ38 lên106 tests,30 lib source files và8 test files. Chỉ bổ sung dependency trực tiếp characters1.4.1 vốn đã có trong lockfile, không nâng dependency/SDK.

| Suite | Tests | Scope |
|---|---:|---|
| calculator_test.dart |8| Totals/null/zero/period/parser/JSON/quota/seed và UTC→local display |
| ledger_viewmodel_test.dart |5| CRUD/persistence/save fail/archive/history |
| widget_test.dart |5| Navigation360/412/768/1440 và usage form |
| form_safety_test.dart |21| Ba form, draft/Back/save retry/keyboard/text scale/long alias |
| ledger_stability_test.dart |24| VM validation/bounds/Unicode, quota bypass, archived mutations, UUID/concurrency/reload/dispose |
| local_repository_test.dart |27| JSON/schema/type/date/enum/references/duplicates, init/read/write failures, backup/recovery, UTC/zero/null round trip |
| live_clock_test.dart |10| Clock boundaries, exact reset, pause/resume/timer disposal, UTC/local calendar/edit and budget null/0/overrun |
| local_flows_test.dart |6| Archived list/detail/history/edit/delete/restore360/412, recovery Retry/cancel/confirm/fail, double tap/forced route removal |

Final checks thực chạy: `flutter pub get` thành công; `dart format --output=none --set-exit-if-changed lib test`:38 files,0 changed; `flutter analyze --no-pub`:No issues found; `flutter test --no-pub --reporter expanded`:**106/106 pass**; `flutter build web --release --no-wasm-dry-run`:Built build/web (JS compile41,6s). Các lượt trung gian phát hiện/correct timer lifetime, lifecycle fixture transitions và scroll fixture chọn nhầm TextField scrollable; kết quả cuối đã rerun toàn suite.

Audit bổ sung: sửa action archived bị ẩn trong sheet; bảo vệ lỗi mở SharedPreferences trước render; chặn saveAccount bypass quota time; dừng timer/projections khi unused; kiểm UTC/local date và year đúng cả khi edit; giữ integer micros chính xác và Unicode grapheme limits đúng Flutter. Không có schema migration: schemaVersion1/key chính giữ nguyên, valid data round trip; unreadable data chỉ được thay sau confirmation và backup raw thành công.

Web preview `http://127.0.0.1:4191/?demo=1`:server chạy, HTTP200 và flutter_bootstrap.js hiện diện. Browser inventory chỉ có MCP Apps, không có Chrome/IAB để điều khiển, nên chưa có browser interaction/console verification. Render QA riêng màn recovery360/412×800 với font Inter/MaterialIcons thật đã xem ảnh, không overflow/clipping thấy được;2 render checks tạm không tính vào106 tests. Script/ảnh/log ở build/`.taste-skill/`, không commit.

Không rebuild APK ở lượt B03–B07; APK ở phần lịch sử phía trên thuộc source trước các thay đổi này. Native/MobAI/Firebase/Figma fidelity không được suy từ web/widget checks. Chưa test multi-window writes, IANA/custom cycles hoặc cloud backup vì ngoài local scope; snapshot persistence vẫn có giới hạn này.


## B08–B10 final audit —21/10/2026

Môi trường: Windows, Flutter3.47.4 stable/Dart3.13.3; local SharedPreferences contract/repository fixtures. Không chạy emulator, thiết bị Android, Chrome/IAB, MobAI hoặc Firebase. Lượt này không nâng dependencies/thêm runtime assets. Build APK trước đây không đại diện source UI mới.

| Check | Kết quả thực |
|---|---|
| dart format --output=none --set-exit-if-changed lib test |40 files,0 changed |
| flutter analyze --no-pub | No issues found |
| flutter test --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true --reporter expanded |142/142 pass, khoảng65s; chạy tuần tự để giảm RAM |
| flutter build web --release --no-wasm-dry-run | Built build/web, JS compile38.2s; dependency resolution thành công, không upgrade lockfile |

10 suites: calculator8, ledger VM5, navigation/widget5, form safety21, stability24, local repository27, live clock10, local flows6, UI audit30, component audit6.106 tests trước giữ regression;36 tests mới có scope theo [fidelity draft](fidelity-check.md).

UI audit:24 cases×12 màn=288 screen instances, thêm24 usage sheets;4 viewport360/412/768/1440×800 logical px, DPR1, scale1/1.3/2, SafeArea24dp, seed và stress data hợp lệ.6 keyboard cases chạy3 forms=18 scenarios, inset300dp, focus field cuối và CTA không bị che.6 gallery cases kiểm9 families/selected/pressed/focus/filled/error/disabled/loading/dialog và targets48/52. Tests tải Inter/MaterialIcons thật; xuất và xem ảnh12 màn tại360/412/1440, stress360 chữ2.0, gallery360/412. Artifacts/logs local ignored dưới .taste-skill/b08-b10, không commit.

Các vấn đề tìm và sửa: bar chart overflow chữ2; sidebar desktop overflow1.3/2; legend số tiền lớn; donut caption không vừa; AppBar title cắt trên dù không RenderFlex; helper/error3 dòng cắt hướng dẫn. Title bounds assertion tiếp tục bắt font rounding1.3 thiếu0.4px, đã thêm4dp khoảng thở và rerun full pass. Không bỏ assertion hoặc giảm text scale. Các lỗi fixture riêng: alias ban đầu vượt80 được thay bằng80 hợp lệ; finder `.last` thay đổi khi lazy scroll được thay bằng field keys; gallery dialog được cuộn giữa viewport trước tap.

B08 đối chiếu mapping/token/spec đã lưu trong repo. Sibling Lab2/bộ ảnh gốc/skill UI không có trong checkout; chưa kiểm8 ảnh gốc hoặc cập nhật live Figma. Ảnh là Flutter test-engine render, không phải screenshot CanvasKit/Android; simulated keyboard không thay native IME evidence. B11 accessibility đầy đủ, B12 flow states đầy đủ, B13 Figma/brand và F11–F13 final fidelity vẫn pending. Firebase/FCM/PDF/Notifications/Reports vẫn pending. Chưa commit/push.

## B11–B13 final audit —21/10/2026

Môi trường Windows/Flutter3.47.4 stable/Dart3.13.3, Inter/MaterialIcons thật trong UI tests; local repository fixtures. Không emulator/Android/MobAI/Firebase/Chrome/IAB run trong lượt này. Không thêm package hoặc runtime assets, không upgrade dependencies. Source31 lib/12 test files;43 Dart files format.

Bộ mới: accessibility_states_test.dart23 cases và brand_audit_test.dart3 cases, thêm26 vào142 regression trước =168. Bao gồm numeric contrast pairs, Flutter androidTapTargetGuideline/labeledTapTargetGuideline/textContrastGuideline trên Purpose/4 tab360/412, Tab+Enter/selected/focus outline, chart dates/USD/single semantics, dynamic disableAnimations giữ scroll/search/metric, route/dialog noAnimation, busy tĩnh không công bố50%, saving focus lock. State tests: cold load/error/Retry, reload5 forms/screens giữ draft/search, dirty Back khi load error, not-found account/session/disabled/empty, reset/clear cancel/fail/pending/retry/success360/412, confirmed action double tap/fail/retry/dispose. Existing archived usage/recovery/validation/money/time tests giữ nguyên assertion, restore confirmation test chọn action label rõ nghĩa mới.

Brand: SVG contract/canonical painter probes, premultiplied raster diff<8/255 với5 Android densities/favicon/PWA192/512; maskable alpha/safe circle/top glyph position, grapheme initials và semantics không phải official provider logo. Dung sai antialias không phải pixel-perfect claim. Xem assets/brand/README.md.

Rà lại tìm và sửa: RangePicker regular text không đạt pixel contrast guideline (đã dùng label semibold); custom rows thiếu button/selected/focus; retry visual chưa disabled lúc recovery; route cold/reload requireValue; uncontrolled search reset khi Retry; saving chỉ chặn pointer còn keyboard; repeated confirmations/dispose; stale edit có thể resurrect phiên đã xóa. Rà semantics thêm phát hiện busy static50% có thể bị đọc nhầm là completion progress, đã exclude indicator semantics và kiểm value trống. Các lỗi fixture được sửa riêng: SemanticsHandle dispose trước Flutter end-of-test verification, generic SegmentedButton finder, reset Navigator giữa screen fixtures. Không bỏ assertion/giảm scale hoặc tạo dữ liệu giả để qua gate.

Figma live evidence: đọc page1:3, xem8 final360, annotate nodes59:2/49/78/121/160/202/236/279; tạo page233:2/board233:3,16 auto-layout handoff cards,52 created IDs trả về. Đã xem screenshot board840×2402, không có clipping. [Link Figma](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3), từng frame/node ở fidelity-check.md. Original StudentPay geometry/text giữ nguyên; annotations không thay bộ mockup TokenLedger/final fidelity hoặc giảng viên approval.

Local images đã xuất bằng full suite với UI_AUDIT_IMAGES=true/UI_AUDIT_OUTPUT=.taste-skill/b11-b13 và xem ảnh mobile/desktop/gallery; sau đó chỉ chỉnh semantics busy/transition delegate không đổi pixels Android và rerun full final. Full UI matrix288 screen instances + usage sheets/keyboard giữ từ B10. Logs .taste-skill/b11-b13-*.log và images ignored. Không dùng ảnh Flutter engine làm browser/native screenshot. Kết quả cuối bên dưới áp dụng source sau rà semantics quota/budget.


### Kết quả cuối B11–B13

| Check | Kết quả thực trên source cuối |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` |43 files,0 changed |
| `flutter analyze --no-pub` | No issues found,15.6s |
| `flutter test --no-pub --concurrency=1 --reporter expanded` |168/168 pass,108s; log b11-b13-verified.log |
| `flutter build web --release --no-wasm-dry-run` | Built build/web, JS compile51.4s; log b11-b13-web-final.log |
| Docs/Git checks | Local Markdown links0 thiếu;93 task IDs không trùng; diff --check sạch |

Rà cuối bổ sung semantic value cho quota thiếu/quá reset và budget chưa đặt để không đọc thành measured0%;23 accessibility/state tests gồm regression này. Không đổi quota/budget/cost data. Full suite12 files: calculator8 + ledger VM5 + navigation5 + form safety21 + stability24 + repository27 + clock10 + local flows6 + UI audit30 + component6 + accessibility/states23 + brand3 =168. Browser/native/MobAI/Firebase không được suy ra từ các kết quả trên; không emulator, không commit/push.

## A03–A06 — audit tài liệu ngày21/10/2026

Môi trường: Windows/PowerShell, repo hiện tại; Codex đọc docs/source/tests và Git thực. Không thay Dart/assets/dependencies/platform runtime; không chạy Flutter/test/build hoặc emulator ở lượt này. Kết quả168 tests/analyzer/web build ở mục B11–B13 vẫn là evidence lịch sử gần nhất, không phải kết quả tạo mới.

- 20 Markdown dự án (docs, root, agent và brand): local links không hỏng, code fences cân bằng, không có absolute machine paths trong nội dung hướng dẫn.
- 93 roadmap IDs và196 checklist IDs không trùng; A03–A06 tick, A01/A02/A07 vẫn chưa tick; HG01–HG10 giữ nghĩa gốc và có resolution/verification pending.
- AI log có10 prompt nguồn thực; thêm đúng một Entry10 cho yêu cầu A03–A06. Việc đáp ứng chất lượng rubric vẫn cần đối chiếu.
- SHA256 của79 file runtime (lib/test/platform/assets/pubspec, bỏ Markdown/build/cache) không đổi so với đầu lượt; không ghi đè các thay đổi B01–B13 chưa commit.
- `git diff --check` exit0. Audit scripts/baseline chỉ ở tooling local ignored, không phải source sản phẩm hoặc evidence nộp đã publish.
- `git ls-remote --heads origin` thành công: remote main4aeb7b719b95c0b4aa21f02bc0f05329b909cdf2, cùng HEAD/local main; branch thực codex/local-form-safety. Chưa commit/push B/A; không suy quyền người chấm hoặc reviewed PR từ kết quả refs.

Đã sửa các thiếu sót tài liệu: file có sẵn nhưng checkbox còn “tạo”, gate ghi “chưa thực hiện” dù đã có local, task checked gộp donut slice/multi-window/source/realtime chưa implement, context còn SDK thiếu/Git trống/16 tests/Figma pending, và checklist gaps thiếu mã HG gốc. SD01–SD08 giữ P0 còn thiếu cùng quyết định/lý do/test dự kiến; không thêm pricing engine hoặc giả backend. A03–A06 đạt phạm vi quyết định/chuẩn hóa; toàn A và G0–G9 chưa đạt nghiệm thu.

## P0 local sau A04 — verification cuối21/10/2026

Scope: thực hiện bốn bước model/migration → form/quota → cycle/timezone → analytics/history theo yêu cầu “làm cho tôi.”. Windows/PowerShell, Flutter3.47.4/Dart3.13.3;33 lib/14 test files. Không chạy emulator/native/Firebase/MobAI. Branch codex/local-form-safety, toàn bộ thay đổi vẫn working tree, chưa commit/push; không gán SHA nền cho source mới.

- `flutter pub add timezone`, rồi `flutter pub get`: thành công; timezone0.11.2 + http1.6.0/http_parser4.1.2 transitive, không nâng dependency cũ. App chỉ import database Dart offline/calendar; không gọi HTTP/provider API.
- `flutter analyze`: No issues found, lượt cuối8.3s. `dart format --output=none --set-exit-if-changed lib test`:47 files0 changed, exit0.
- `flutter test --no-pub --concurrency=1 --reporter expanded`: **200/200 pass140s**, exit0 trên source cuối.20 schema_v2 cases +12 scope_forms cases mới;168 regressions cũ giữ ý nghĩa, cập nhật fixture/schema/unit/UTC/source/nhãn kỳ khi contract đã thay đổi.
- Full199 trước case mặc định account theo nguồn: pass175s với `UI_AUDIT_IMAGES=true`, xuất ảnh vào tooling local ignored. Đã xem ảnh Flutter thật: analytics360, account detail412, history360, dashboard1440 và account form360 chữ2; glyph mũi tên Inter thiếu đã sửa thành Material icon trước lượt199 có ảnh này. Full200 sau đó giữ cùng ma trận nhưng không xuất ảnh lặp.
- Ma trận24 scenarios:360/412/768/1440×800 ×scale1/1.3/2 ×seed/stress, thêm6 form keyboard/SafeArea cases; gallery/accessibility/state/brand suites tiếp tục pass. Đây là Flutter-engine render/guidelines, không phải browser, Android TalkBack/IME, MobAI hay final Figma fidelity.

Coverage mới: backup-first v1→v2, corrupt/future version không seed/overwrite, backup/replace fail+Retry, concurrent reload/migration/save ordering; UTC/native instant và immutable createdAt/retry clock; null/known0/source/cost-basis/immutable collections/model/defaults/clear/dirty Back. Quota upsert theo key/tên/rename giữ key, nhiều windows0/100/stale độc lập/source/note/delete/not-found. IANA/UTC/device, cycle31/leap/year/DST23h/25h, cycle history/combined filters khớp budget. Demo/manual/legacy isolation cả metadata budget, reset/clear giữ dữ liệu khác/collision IDs, provider/day-group/timezone/settings retry/donut/initial metric và default account tránh ghi nhầm seed; form fail/retry360/412 giữ fields.

Lượt thử đầu có14 failures: assertions cũ so representation DateTime thay vì instant, fixture one-window/source/schema cũ, vertical-scroll finder và lỗi clearDemo sync-Future contract. Đã sửa đúng contract/implementation, không xóa assertion để che lỗi. Các test mới tiếp tục bắt UTC alias, TZDateTime.toLocal theo tz.local, metadata budget/source, createdAt và account suggestion; đã có fixes/regression. Một số lượt full đang chạy được dừng khi audit còn thay đổi source, không tính là pass; chỉ các lượt đã hoàn tất ở trên được báo đạt.

Logs/scripts/images/fingerprint ở .taste-skill ignored; không commit output inspector/compiled tooling hoặc source PDF/Lab2 copies. Final Figma chưa cập nhật field mới; Google/Firestore/services/PDF/reports/auth routes và Android/MobAI/submission vẫn pending theo scope. Pricing estimates/numeric quota allowances không được làm giả.

Web final: `flutter build web --release --no-pub --no-wasm-dry-run` exit0, JS compile57.7s, Built build/web. Kiểm bundling timezone/database/font/icons thành công; không phải browser interaction/console audit, Wasm hoặc Android evidence. SHA25683 file runtime không đổi so với fingerprint trước full200, kể cả sau web build. Kiểm21 Markdown:0 local links hỏng, fences cân bằng, không machine paths;93 roadmap IDs/196 checklist IDs không trùng; AI log11 entries thật. `git diff --check` exit0. Runtime và docs đã được rà lại; không có requirement Firebase/native/final fidelity nào được tick theo kết quả local.

## Audit checkpoint local —21/10/2026

Git/docs-only, không sửa runtime. Candidate102 files,91 text files: secret-pattern/machine-path scan không phát hiện; không file cấm hoặc file>2MB. Ignore probes xác nhận tooling/build/local.properties/generated registrant/credentials bị loại.83 runtime hashes khớp bộ200 tests/analyzer/format/web JS build đã ghi ở trên; không chạy lại Flutter. Markdown hiện có12 AI entries (entry12 Git-only); kiểm links/fences/IDs/portability và staged diff whitespace trước commit. Commit local trên codex/local-form-safety, chưa push; SHA dùng git log -1 --oneline. Không claim audit toàn bộ history, reviewed PR hoặc native/backend evidence.

## Bước2 — live visual evidence21/10

Không thay runtime; không chạy Flutter lại.83 file hashes đối chiếu manifest của full200 pass/analyzer/format/web build không đổi. Xem đủ8 QA412 và2 Lab2 component/state boards, app8 core screens360/412 +component gallery360/412 từ ảnh Flutter đã có. Tạo Figma page237:2:16 core screens,3 continuations,6 feedback specimens;7 main components/120 instances/455 text nodes/0 image fills. View ảnh từng review board và hậu sửa, sync8 original annotations và8 B13 notes. [Visual handoff](visual-handoff-21-10.md) ghi môi trường/matrix/links/sai khác; không đo similarity hoặc claim pixel/native/backend acceptance. Markdown hiện22 files/13 AI entries; kiểm links/fences/IDs/portability/diff whitespace. Không emulator/push/PR review.

## Firebase Auth C01–C03 —21/10/2026

User cung cấp project tokenledger-lab3/config Android/web, cho phép tiếp tục Core/Auth/Google/guard/Profile. Code39 lib/18 test Dart files (1 support helper); SDK firebase_core5.0.0/firebase_auth7.0.0/google_sign_in7.2.0. Pub add/get thành công; format57 files0 changed; analyzer No issues found11.9s; full239/239 tests pass140s; web release JS build45.3s (`--no-pub --no-wasm-dry-run`), exit0.

39 tests mới: auth_service_test19 (bootstrap shared/retry, native token exchange/missing token/cancel/config/ordering/concurrency/signout, web popup synchronous/typed sanitization); auth_viewmodel_test5 (listener lifecycle/busy/retry/no fake success/dispose/signout failure); auth_gate_test15 (restore/timeout/deep link/UID-stack removal/Profile refresh/logout failure/demo isolation và6 UI matrix360/412/1440×800 text1/2). Các lỗi lượt đầu là fixtures: Riverpod stream cần listener sống khi await future, lazy Profile footer phải cuộn trước tìm, identity phía trên có thể unmount khi cuộn, xuất ảnh phải tester.runAsync. Đã sửa fixture, giữ assertions no-data-read/no-fake-user; không ghi các run bị dừng/fail là pass. Timeout bootstrap20 giây được thêm để mạng treo vẫn có Retry/demo.

Config thực: CLI SHA list khớp debug SHA người dùng; GET Auth config/provider enabled=true, localhost được phép. Không in/lưu credential CLI, client secret hoặc ID token vào docs/logs. Gradle :app:processDebugGoogleServices pass112s với1 worker/heap1536MB; generated project/default_web_client_id khớp client config. Không build/install APK; không emulator/ADB/native login. Gradle cảnh báo Kotlin/newDsl template deprecated, chưa xử lý migration vendor/Gradle10 ngoài scope.

Web release static server localhost trả HTTP200/có flutter_bootstrap.js rồi dừng server do task tạo. Môi trường CUA chỉ có MCP Apps, thử IAB trả Browser is not available; không claim browser JS/console/popup interaction. Đã xem ảnh Flutter Login360/Profile360/412; identity trong ảnh là fixture example.test, không phải user Google thật. Ảnh/log `.taste-skill/c01-c03/` ignored. Live Google account round trip, Play services/cert signing variants, native Back/TalkBack/IME, full C04–C15/GATE-01 vẫn pending; main chưa commit/push lượt Auth. Chi tiết [Auth setup](firebase-auth-setup.md).
