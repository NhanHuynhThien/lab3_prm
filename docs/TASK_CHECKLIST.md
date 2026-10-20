# TokenLedger — Checklist triển khai Lab 3

Ngày 19/10/2026. Đọc cùng [Implementation plan](IMPLEMENTATION_PLAN.md). Checklist này là backlog, **đã cập nhật những task local scaffold hoàn thành; các gate Firebase và bài nộp vẫn pending**. Người dùng đã cho phép đổi chức năng theo chủ đề quản lý token; việc chấp nhận theo rubric vẫn cần xác nhận với giảng viên.

## Cập nhật scaffold 19/10/2026

Đã tạo Flutter Android/web, MVVM/Riverpod, logo và local CRUD/dashboard/animation. Firebase pending theo yêu cầu; checkbox hoàn thành chỉ xác nhận phạm vi local, không chứng minh Firestore/Auth/evidence Lab3. Chi tiết ở `build-status.md`, `test-report.md` và `firebase-pending.md`. Các gate G1/G3/G6 chưa đạt vì cần Firebase thật.

## Cập nhật docs/agent 20/10/2026

Đã thêm root AGENTS.md, `.agents/` context/workflows, docs index/architecture và bộ Lab2 reference độc lập. Bộ snapshot được tạo ở lượt trước, sau đó bỏ khỏi Git theo yêu cầu cleanup; DESIGN-02 hiện dùng bảng mapping/tokens và Figma reference. Không đánh RELEASE-13 hoặc PR-review tasks done chỉ vì initial push: chưa có PR/review/merge hay Firebase evidence.

## Quy tắc thực hiện

- Làm P0 theo G0 → G9. P1/P2 chỉ bắt đầu sau khi các gate P0 đạt.
- Mỗi task có ID để dùng trong commit/PR; cập nhật `[x]` khi có kết quả kiểm chứng, không chỉ vì đã sinh code.
- Mỗi gate ghi commit SHA, ngày, người kiểm tra và đường dẫn evidence thật trong bảng cuối file.
- Task cần account/configuration bên ngoài có thể để chờ và tiếp tục phần độc lập; không đánh dấu đã deploy/test nếu chỉ chạy mock.
- Giữ artifacts thiết kế Lab2 gốc để đối chiếu; không ghi đè nguồn thiết kế lịch sử.
- Không tạo `.mob` giả hoặc bịa prompt/ảnh console/kết quả AI review. Giữ prompt thực từ lúc làm.

## G0 — Chốt scope, yêu cầu và thiết kế (P0)

Dependency: tài liệu plan hiện tại. Exit gate: mapping đủ 8 màn / 3 flow, gap/change log có trạng thái thật, phạm vi nộp được làm rõ.

- [ ] SCOPE-01 Đọc lại PDF17 trang và đánh dấu yêu cầu theo bảng rubric mục12 của plan.
- [ ] SCOPE-02 Xác nhận cá nhân hay nhóm, StudentID/repo name, deadline và số commit/ngày `[N]` với giảng viên.
- [ ] SCOPE-03 Trình mapping StudentPay → TokenLedger cho giảng viên; lưu phản hồi thật về đổi chủ đề/nghiệp vụ.
- [ ] SCOPE-04 Chốt P0: manual usage/quota, account metadata; P1 import; P2 provider sync.
- [ ] SCOPE-05 Chốt terminology account/provider/product/model/session/quota/auth token và dùng nhất quán.
- [ ] SCOPE-06 Xác nhận USD là currency P0; VND/FX để P1 nếu có nhu cầu.
- [ ] DESIGN-01 Xem đủ 8 final360,8 QA 412 và state/component PNG trong Lab2; ghi nguồn/version.
- [x] DESIGN-02 Đối chiếu core Lab2, giữ mapping/tokens trong `docs/lab2-ui-reference.md`; không bundle tài liệu/ảnh nguồn copy hoặc tooling vào app.
- [ ] DESIGN-03 Tạo `docs/handoff-gaps.md` từ HG01–HG10, mỗi gap có resolution và verification còn thiếu.
- [ ] DESIGN-04 Tạo `docs/design-change-log.md` ghi thay chủ đề, flow, tab labels, form fields, login/profile/FCM/export và khác biệt Android.
- [ ] DESIGN-05 Chuẩn bị annotated mockup8 màn TokenLedger từ core Lab2; không redesign palette/font/layout tùy ý.
- [ ] DESIGN-06 Cập nhật hoặc annotate Figma, lưu link/node/screenshot thật trong change log.
- [ ] DESIGN-07 Bổ sung thiết kế S09–S14 theo component cũ; trạng thái loading/empty/error, form keyboard và Back.
- [ ] DESIGN-08 Duyệt screen/route map4 tab,3 flow và nhánh error/recovery theo mục4 plan.
- [ ] DOC-01 Bắt đầu `docs/implementation-ai-log.md`; ghi entry thật từ các lượt AI sử dụng, không dựng lại lịch sử.
- [ ] GATE-00 Commit docs/scope/design mapping; ghi rõ quyết định nào còn chờ giảng viên.

## G1 — Flutter, Firebase và vertical slice đăng nhập (P0)

Dependency: scope/design direction; cần Google test account và Firebase project riêng. Exit gate: app Android chạy, Google Sign-In vào app rỗng và sign-out thật.

- [ ] SETUP-01 Kiểm tra Flutter/Dart/Android SDK/JDK/toolchain bằng `flutter doctor`; ghi version và lỗi cần sửa.
- [x] SETUP-02 Tạo Flutter Android project trong Lab3, không thay đổi repo Lab2; chọn applicationId ổn định.
- [ ] SETUP-03 Tạo branch `codex/tokenledger-lab3`; giữ lịch sử commit theo từng stage.
- [x] SETUP-04 Xác minh package versions tương thích; chọn Riverpod duy nhất, commit lockfile.
- [x] SETUP-05 Tạo skeleton MVVM theo mục7, conventions model/service/ViewModel/view và typed failures.
- [ ] SETUP-06 Tạo Firebase project riêng và bật Analytics; đăng ký Android app đúng package.
- [ ] SETUP-07 Chạy FlutterFire configuration; kiểm tra `firebase_options.dart`/`google-services.json` đúng project.
- [ ] SETUP-08 Bật Google provider, thêm debug SHA-1; cấu hình signing certificate bổ sung nếu cần APK khác.
- [ ] SETUP-09 Chạy emulator có Google Play services hoặc thiết bị Android thật; kiểm tra kết nối.
- [ ] SETUP-10 Tạo Google test account riêng, không ghi credentials vào code/docs/logs.
- [ ] AUTH-01 Viết AuthService, auth state provider và LoginViewModel; SDK calls chỉ ở service.
- [ ] AUTH-02 Làm Login UI theo tokens, loading/cancel/error/retry thật.
- [ ] AUTH-03 Auth guard chặn mọi route/data khi chưa login; deep link không bypass guard.
- [ ] AUTH-04 Tạo/update user profile tối thiểu; Profile đọc tên/email/avatar thật.
- [ ] AUTH-05 Logout hủy listeners/state/draft và xử lý FCM device binding trước khi về Login.
- [ ] AUTH-06 Test Google success/cancel, offline lỗi, logout/Back và sign-in user B không thấy cache A.
- [ ] SPIKE-01 Thử upload1 PDF nhỏ lên storage dự kiến và mở URL trên Android; lưu kết quả/cấu hình không secret.
- [ ] SPIKE-02 Cài/thử MobAI nhận emulator sớm; nếu không dùng được, ghi blocker và báo giảng viên trước đổi công cụ.
- [ ] GATE-01 App chạy project Firebase thật, login/logout đạt; commit setup/auth và ghi evidence.

## G2 — Design system và navigation (P0)

Dependency: G1. Exit gate: component gallery và8 screen shells đúng core Lab2 ở360/412dp.

- [ ] UI-01 Tạo `lib/theme/` chứa đủ semantic colors cuối trong Lab2 `design/DESIGN.md`.
- [x] UI-02 Bundle/cấu hình Inter có tiếng Việt; map6 text styles, min text14sp.
- [x] UI-03 Tạo spacing/radius/elevation/touch/CTA size tokens; chỉ thêm extension có design log.
- [ ] UI-04 Build AppButton variants default/pressed/disabled/loading, CTA52dp, target>= 48dp.
- [ ] UI-05 Build AppTextField/AmountField default/focused/filled/error/disabled, helper text có semantics.
- [x] UI-06 Build SummaryCard/ProgressCard và list row dùng icon/title/subtitle/trailing metric.
- [x] UI-07 Build header/back,4 tab bottom nav, giữ selected state và tab stacks.
- [x] UI-08 Build Dialog/Spinner/Empty/Error feedback variants; Retry giữ context/draft.
- [x] UI-09 Build PurposeTile grid3 cột và selectable row kế thừa Category/Member layout.
- [ ] UI-10 Thêm component gallery để kiểm tra9 families và variants; không dùng gallery thay screens thật.
- [ ] UI-11 Tạo router S01–S10 cùng sheet/detail routes S11–S14, auth guard và not-found fallback.
- [ ] UI-12 Dùng SafeArea/system bars Android; content cuộn, không vẽ status bar iOS trong app.
- [ ] UI-13 Test keyboard/inset, text scale1.3/2.0, chuỗi dài, tiền lớn, target48dp ở360/412dp.
- [ ] UI-14 Chụp baseline theme/component/screens; ghi ngoại lệ layout/platform vào fidelity draft.
- [ ] GATE-02 Không import Firebase trong screens/widgets; token/component audit đạt; commit UI foundation.

## G3 — Account, quota và Firestore protection (P0)

Dependency: G2 + Firestore project. Exit gate: F3 CRUD/query/realtime thật, quota đúng đơn vị và rules bảo vệ ownership.

- [ ] DATA-01 Viết model AIAccount/UsageSession/QuotaWindow/User/Report/Notification/Device và Firestore converters.
- [ ] DATA-02 Chốt field allowlists/enums/null semantics/schemaVersion và validation bounds theo plan.
- [ ] DATA-03 Implement FirestoreService/AccountService/QuotaService; không truy cập SDK từ ViewModel/view.
- [ ] DATA-04 Tạo accounts/usage_sessions/quota_windows/report/notification/device paths dưới UID.
- [ ] DATA-05 Query active accounts sorted updatedAt; realtime listener và auto-dispose theo UID.
- [ ] DATA-06 Viết account usageCount transaction contract; chặn counter thay đổi độc lập.
- [ ] RULE-01 Viết `firebase/firestore.rules`: default deny, auth/owner cho từng collection.
- [ ] RULE-02 Validate create/update types/range/allowed keys; owner/createdAt immutable, account relation hợp lệ.
- [ ] RULE-03 Dùng transaction/getAfter kiểm tra create/delete usage và account usageCount nhất quán.
- [ ] RULE-04 Hard delete chỉ cho account rỗng, test race create usage vs delete account không để orphan.
- [ ] RULE-05 Emulator tests owner A/B, unauth, field sai, số âm, đổi owner/accountId, reference sai và counter tamper.
- [ ] RULE-06 Deploy rules/indexes project thật; lưu output/ảnh console không secret.
- [ ] ACCOUNT-01 S06: list, summary, empty CTA, realtime, error/retry; không cộng% quota giữa account.
- [ ] ACCOUNT-02 S07: provider/product/alias/plan/budget/cycle/default purposes, validation và saving state.
- [ ] ACCOUNT-03 S08: detail, purpose summary placeholder theo data thật, budget/quota sections và thao tác edit/archive.
- [ ] ACCOUNT-04 Account create/update/list/detail thật; reload app vẫn có dữ liệu; delete account rỗng thật.
- [ ] ACCOUNT-05 Account có usage chỉ archive trong luồng mặc định; hard delete yêu cầu xử lý usage trước.
- [ ] QUOTA-01 S12 nhập snapshot theo window/unit, observedAt/resetAt/source; không yêu cầu token nếu chỉ biết%.
- [x] QUOTA-02 Hiển thị unknown/stale/vượt ngân sách bằng chữ+icon; reset qua thời điểm không tự hiện100%.
- [ ] QUOTA-03 Cập nhật snapshot cùng window thay current value, không cộng snapshot; giữ các window độc lập.
- [ ] ACCOUNT-06 Test alias dài, account trùng provider, budget0/null/âm, cycle invalid, quota 0/100/null/stale.
- [ ] GATE-03 F3 đạt với user A/B, console data/rules evidence thật; commit accounts/quota/rules.

## G4 — Usage và tính toán (P0)

Dependency: G3. Exit gate: F1 tạo/sửa/xóa usage và tổng đúng, kể cả lỗi/retry.

- [ ] CALC-01 Implement UsageCalculator thuần, normalize input/output/cache không double count.
- [ ] CALC-02 Phân biệt tokens0/null và cost actual/estimated/unknown; không dùng0 thay mọi null.
- [ ] CALC-03 Tiền integer micros; pricing snapshot; rounding một lần mỗi usage; reported ưu tiên estimate.
- [ ] CALC-04 Period `[start,end)` UTC quy đổi timezone; used/remaining/excess, không clamp mất số vượt.
- [ ] CALC-05 Coverage: known token/cost count và unknown count; quota snapshots không suy từ usage logs.
- [ ] CALC-06 Unit tests null/zero, precedence, rounding, overrun, percent/window, date boundaries, chart denominator0.
- [ ] USAGE-01 Implement UsageService transaction create/delete + counter, update hợp lệ, stable client operation ID.
- [x] USAGE-02 Khóa accountId khi edit P0; error validation nếu cố đổi; không làm lệch account counters.
- [ ] USAGE-03 S02: account/workTitle/purpose/model/date/note, token/cost modes, preview nguồn số liệu.
- [x] USAGE-04 S03:9 purposes, selected state, Back không mất draft; default chỉ là gợi ý có thể đổi.
- [ ] USAGE-05 Validation cả paste: title bắt buộc, token integer không âm, USD decimal hợp lệ, ngày theo policy.
- [x] USAGE-06 Chưa có account → tạo account → quay form với draft và account mới được chọn.
- [ ] USAGE-07 Save có validating/saving/pendingSync/saved/failed; chỉ server-confirmed mới thông báo saved.
- [ ] USAGE-08 Double tap/retry/timeout dùng cùng ID, không có phiên trùng; pending network không bị báo fail/success sai.
- [ ] USAGE-09 Back khi form đổi có xác nhận bỏ draft; chọn purpose xong giữ input/model/date/note.
- [x] USAGE-10 S01: card ngân sách, progress, latest rows, CTA; unknown coverage rõ, không có “token tổng còn lại” giả.
- [ ] USAGE-11 S05: lịch sử nhóm ngày, filter account/purpose/time, list pagination không ảnh hưởng tổng kỳ.
- [x] USAGE-12 S11: detail nguồn/cost/tokens + Edit/Delete, confirm delete và phản ánh realtime.
- [ ] USAGE-13 VM tests save fail/retry/draft/pending; lỗi permission/network giữ dữ liệu form.
- [ ] SEED-01 Tạo seed versioned đúng mục9; đối chiếu baseline hiện tại Claude121k/$5.68, Codex141k/$5.86, Gemini24k/$1.30; bổ sung owner/version khi nối Firebase.
- [ ] SEED-02 Seed account unknown1 phiên, account rỗng CRUD Test, user B dataset khác; isolate isDemo.
- [ ] SEED-03 Reset chỉ xóa demo thuộc UID, cập nhật counters đúng; seed lặp không nhân đôi và không xóa real data.
- [ ] USAGE-14 Kiểm chứng thêm10k/$0.05 → known296k/$12.89, sửa thành$0.07 →$12.91, xóa → baseline286k/$12.84.
- [ ] GATE-04 F1 happy/error/recovery + usage CRUD đạt trên Firestore thật; commit flow/calculator/tests.

## G5 — Phân tích theo account và công việc (P0)

Dependency: G4. Exit gate: F2 drilldown đúng tập dữ liệu, shared totals và coverage.

- [ ] ANALYSIS-01 S04 chọn kỳ và metric cost/token/session; cùng nguồn normalized dataset với S01/S08.
- [ ] ANALYSIS-02 Group theo purpose/account/provider, không gộp khác đơn vị hoặc actual+estimated thành 2 lần chi phí.
- [x] ANALYSIS-03 Donut và legend giữ style Lab2, có text/value/unit/coverage; denominator0 ra Empty.
- [x] ANALYSIS-04 Tap slice/legend mở S05 đúng filter/time/account; Back giữ filter và scroll context.
- [x] ANALYSIS-05 S08 cho biết account dùng purpose nào, số phiên, token đã biết, cost đã biết, remaining và quota windows.
- [x] ANALYSIS-06 Kết luận mô tả chỉ từ usage đã ghi; không khẳng định năng lực agent/tiết kiệm chi phí khi thiếu dữ liệu.
- [ ] ANALYSIS-07 Month empty → CTA ghi usage; loading/network error có retry giữ filter.
- [x] ANALYSIS-08 Test legend total bằng summary; filter boundary; unknown excludes khỏi denominator đúng cách.
- [ ] GATE-05 F2 chạy data thật, screenshot đủ chart/list/detail; commit analytics flow.

## G6 — Firebase bổ sung và PDF (P0)

Dependency: G3–G5; spike storage/MobAI nên xong từ G1. Exit gate: tất cả service có hành vi thật và evidence.

### FCM

- [ ] FCM-01 NotificationService: permission Android13+, token refresh và per-user device binding lifecycle.
- [ ] FCM-02 Foreground handler → Center+banner; không expose server key trong app.
- [ ] FCM-03 Background handler đúng entry point/runtime, không cập nhật UI từ background isolate.
- [ ] FCM-04 Tap background/cold start xử lý intent sau auth ready; allowlist routes, owner check/fallback.
- [ ] FCM-05 Center trong Profile có read/unread, persist dưới UID và dedupe messageId/eventId.
- [ ] FCM-06 Test Console foreground/background/tap, permission denied, target missing, logout/user change.
- [ ] FCM-07 Ghi giới hạn background delivery/inbox khi notification không được mở; không claim mọi tin đều persist tức thì.

### Remote Config

- [ ] RC-01 Defaults recent_limit3, warning_percent80, optional export_enabledtrue; typed parsing/clamp an toàn.
- [ ] RC-02 Recent_limit thay số recent rows thật; warning_percent đổi banner thật, không đổi dataset tính tổng.
- [ ] RC-03 Profile hiển thị effective values/source/fetch time và refresh; ghi dev/prod fetch policy.
- [ ] RC-04 Publish console rồi refresh quan sát app đổi, chụp trước/sau và test defaults khi fetch fail.

### Crashlytics và Analytics

- [ ] CRASH-01 Wiring Flutter và async error hooks, không ghi thông tin nhạy cảm.
- [ ] CRASH-02 Profile demo control record handled exception và test crash có chủ đích; không làm mất dữ liệu draft.
- [ ] CRASH-03 Restart/send và xác nhận cả 2 xuất hiện dashboard; lưu evidence, giới hạn demo controls đúng cấu hình.
- [ ] EVENT-01 Tạo `docs/analytics-plan.md` theo event table trong plan, params/trigger/flow/noPII.
- [ ] EVENT-02 Implement login/logout/screen_view/view-account/accountCRUD/usage actions/export + custom purpose/drilldown/quota.
- [ ] EVENT-03 Events chỉ phát sau kết quả phù hợp, không duplicate do rebuild/retry/listener.
- [ ] EVENT-04 DebugView thật hiển thị event/params; chụp screenshots đủ cho báo cáo.

### PDF và storage

- [ ] PDF-01 Chốt storage sau spike; Cloudinary preset hạn PDF/size và delivery khả dụng, không API secret.
- [ ] PDF-02 Snapshot dataset theo filter, generate PDF nhận diện Lab2 có summary/purpose/table/source/coverage.
- [ ] PDF-03 Render kiểm tra PDF tiếng Việt, font/line wrap, nhiều trang, zero/unknown data, không lộ credential.
- [ ] PDF-04 Upload progress/error/timeout, result HTTPS URL và metadata filename/owner/time/size/filter/count.
- [ ] PDF-05 Upload-success/metadata-fail retry cùng exportID/URL; không tạo report ready giả hay duplicate upload.
- [ ] PDF-06 S14/Profile report list/Open action; verify URL trên Android, Firestore metadata đúng UID.
- [ ] PDF-07 Ghi đặc tính access của URL unsigned demo; nếu cần private report, thiết kế authenticated delivery riêng.
- [ ] GATE-06 Console notifications/RC/Crash/DebugView và PDF URL thật đầy đủ; commit integrations/evidence.

## G7 — Kiểm thử MobAI và regression (P0)

Dependency: G6 + dedicated Google test account + documented seed reset. Exit gate:10 scripts reviewed, full run và2 exercises có evidence thật.

- [ ] TEST-01 Chuẩn hóa starting state riêng từng test, clock/window fixture, seed version, cleanup sau test và retry policy.
- [ ] TEST-02 M01 Google Sign-In → assert main screen/profile đúng; document manual Google screen nếu cần.
- [ ] TEST-03 M02 F1 ghi usage → assert record + tổng đúng sau reload, không chỉ toast.
- [ ] TEST-04 M03 F2 analytics → assert filtered list và tổng đúng.
- [ ] TEST-05 M04 F3 account/quota → assert detail/budget/window/source.
- [ ] TEST-06 M05 error/recovery → assert error, draft giữ, retry tạo đúng 1 record.
- [ ] TEST-07 M06 main entity CRUD → assert create/read/edit/delete list+detail account rỗng.
- [ ] TEST-08 M07 navigation4 tab/Back + state fixtures → assert nội dung từng đích.
- [ ] TEST-09 M08 Profile+RC → assert values và hành vi UI thực đổi.
- [ ] TEST-10 M09 PDF → assert upload URL/open action/report item, không chỉ nút đã tap.
- [ ] TEST-11 M10 logout → assert Login và route guard.
- [ ] TEST-12 Lưu1 `.mob` mỗi scenario vào `mobai_tests/`; tự đọc/sửa assertions và ghi lý do sửa.
- [ ] TEST-13 Chạy full suite từ clean state, lưu log/video/screenshot và bảng pass/fail từng test.
- [ ] TEST-14 Healing: đổi label, capture failure, MobAI patch, diff và đánh giá assertion có còn kiểm đúng outcome.
- [ ] TEST-15 Bug-catching: inject save-no-op, capture fail thật, revert, rerun pass; không merge bug.
- [ ] TEST-16 Test thêm usage edit/delete, archive/history, A/B isolation, rules race và cache/pending semantics.
- [ ] TEST-17 Test notification foreground/background/cold start, stale/reset quota và PDF network failure.
- [ ] TEST-18 Accessibility thực: contrast,48dp,360/412dp, large text/keyboard/long names, icon semantic labels.
- [ ] TEST-19 Hoàn thiện `docs/test-report.md`: environment, start state, scripts, outcomes, exercises, manual limits.
- [ ] GATE-07 Regression pass, bug removed, không kết quả giả; commit tests/fixes/report.

## G8 — AI review và fidelity cuối (P0)

Dependency: G7. Exit gate: review trên PR, >= 3 findings thật và visual audit có ảnh.

- [ ] REVIEW-01 Mở PR từ feature branch vào main với mô tả final behavior và validation thật.
- [ ] REVIEW-02 Chạy AI review tool trên code app và `firebase/firestore.rules`; giữ screenshots/output thật.
- [ ] REVIEW-03 Ghi >= 3 findings cụ thể, >= 1 security/robustness, file/line, severity tự đánh giá.
- [ ] REVIEW-04 Với mỗi finding: accepted/modified/rejected + lý do; fix accepted và link commit/before-after.
- [ ] REVIEW-05 Rerun checks phù hợp sau fixes, không để review fix phá ownership/counters/totals.
- [ ] REVIEW-06 Hoàn thiện `docs/code-review.md`; không bịa findings nếu tool chưa trả đủ.
- [ ] FIDELITY-01 Ảnh8 Lab2 + annotated TokenLedger + app360×800dp, liệt kê mọi khác biệt với lý do.
- [ ] FIDELITY-02 Ảnh412dp và trạng thái loading/empty/error thật; ghi density/insets khi đối chiếu.
- [ ] FIDELITY-03 Audit hard-coded colors/fonts/sizes ngoài theme, liệt kê ngoại lệ có lý do.
- [ ] FIDELITY-04 Audit9 component families và states, screens tái sử dụng thay vì duplicate.
- [ ] FIDELITY-05 Cập nhật Figma annotations theo app cuối, design-change-log và handoff-gaps resolutions.
- [ ] FIDELITY-06 Hoàn thiện `docs/fidelity-check.md`, báo thật hạn chế còn lại, không claim perfect match.
- [ ] GATE-08 Review/fidelity đạt, commit fixes và chuẩn bị PR merge sau release checks.

## G9 — Hồ sơ nộp và release (P0)

Dependency: G8. Exit gate: fresh run/build, repo access, report/video, PR merged.

- [ ] RELEASE-01 `dart format` sạch, `flutter analyze` không lỗi và unit/widget/rules/regression checks cần thiết pass.
- [ ] RELEASE-02 Build/install Android APK và smoke test login/F1/F2/F3/export/logout trên bản nộp.
- [ ] RELEASE-03 Fresh clone chạy theo README; config Firebase/storage/rules/indexes và seed được mô tả đủ.
- [ ] RELEASE-04 Repo đúng `PRM393_Lab03_<StudentID>`, README có topic/Figma/handoff/run/setup/account-data limitations.
- [ ] RELEASE-05 Kiểm tra secrets trong tracked files/history/artifacts; phân biệt Firebase identifiers với API/admin/service-account secrets.
- [ ] RELEASE-06 Rules deployed không test mode; project có real users/data/events và evidence service đầy đủ.
- [ ] RELEASE-07 AI log >= 6 entries thật khác phần app, prompt nguyên văn + verify + quyết định và lý do; liệt kê mọi tool đã dùng.
- [ ] RELEASE-08 Đủ7 tài liệu đề yêu cầu trong `docs/`,10 `.mob`, rules/indexes và assets cần chạy app.
- [ ] RELEASE-09 Viết report5–10 trang đủ các phần PDF; screenshots rõ, không thay kết quả thật bằng mock.
- [ ] RELEASE-10 Quay video3–5 phút đủ login/logout,3 flow+recovery,CRUD/Firestore,PDF,FCM,RC,Crash,DebugView,MobAI,review.
- [ ] RELEASE-11 Tua nhanh test run có chú thích nếu dùng; không che thất bại hoặc cắt để giả full run pass.
- [ ] RELEASE-12 Kiểm tra repo mở từ private browser window; quyền xem Figma/report/video đúng người chấm.
- [ ] RELEASE-13 Merge ít nhất1 PR đã review, ghi submission commit/tag; git history có tiến trình thật theo yêu cầu giảng viên.
- [ ] RELEASE-14 Tập explain1 VM/1 service/rules/calculation và thay đổi nhỏ trực tiếp cho oral review5–10 phút.
- [ ] GATE-09 Chỉ đánh dấu hoàn thành khi toàn bộ yêu cầu P0 có evidence; ghi limitations còn lại trung thực.

## P1 — Mở rộng sau bản nộp hoạt động ổn định

Dependency: G9 hoặc P0 gates đã đạt và lịch cho phép. Các mục này không phải yêu cầu bắt buộc nguyên văn của đề.

- [ ] EXT-01 Chốt CSV schema/template, file size/row limits và nguồn dữ liệu hỗ trợ.
- [ ] EXT-02 Chọn file, preview/map account/purpose, highlight invalid rows trước commit.
- [ ] EXT-03 Import batch có idempotency/dedupe, retry partial failure, rollback chỉ batch được chọn.
- [ ] EXT-04 Test không double count snapshot tổng và usage chi tiết; giữ manual/source badges.
- [ ] EXT-05 Work templates gợi ý account/purpose, không bịa token/cost.
- [ ] EXT-06 Compare cùng purpose/kỳ, actual-vs-estimated và sample/coverage rõ; outcome optional do người dùng xác nhận.
- [ ] EXT-07 Forecast/alerts trong app có nhãn ước tính, budget/quota stale không khẳng định số dư thật.
- [ ] EXT-08 Nếu thêm VND: currency/FX snapshot và báo cáo tách đơn vị, test rounding và conversion.
- [ ] EXT-09 Cập nhật Figma/design log/tests/docs cho mọi extension thực sự triển khai.

## P2 — Đồng bộ provider và tự động hóa

Dependency: capability discovery + thiết kế bảo mật + phạm vi giảng viên/chi phí đã được xác nhận. Không đưa P2 vào cam kết MVP.

- [ ] SYNC-01 Lập matrix Claude/Codex/Khác theo product/plan/API/scope/metrics/reset/delay, dùng docs chính thức hiện hành.
- [ ] SYNC-02 Xác minh Google login app không cấp quyền provider; thiết kế consent/link thật nếu provider hỗ trợ.
- [ ] SYNC-03 Quyết định trusted backend/secret manager; không để API/admin secrets trong APK hoặc Firestore client-readable.
- [ ] SYNC-04 Adapter normalization/token buckets/cost basis/identity mapping và source timestamps.
- [ ] SYNC-05 Sync cursor/idempotency/backfill/rate-limit/retry và reconciliation manual/CSV/API không double count.
- [ ] SYNC-06 Scheduled budget/quota alerts qua trusted sender; inbox documents + push lifecycle đầy đủ.
- [ ] SYNC-07 Thiết kế report storage owner-authenticated nếu xử lý dữ liệu riêng tư thực tế.
- [ ] SYNC-08 Test integration với account được phép, log redaction/revoke/expiry; UI không hứa metric API không cung cấp.

## Bảng theo dõi gate

Điền khi làm; dấu `—` nghĩa là chưa có evidence, không phải pass.

| Gate | Trạng thái | Commit | Evidence | Người kiểm / ngày |
|---|---|---|---|---|
| G0 Scope/design | Chưa thực hiện | — | — | — |
| G1 Setup/Auth | Chưa thực hiện | — | — | — |
| G2 Core UI | Chưa thực hiện | — | — | — |
| G3 Accounts/quota/rules | Chưa thực hiện | — | — | — |
| G4 Usage/calculator | Chưa thực hiện | — | — | — |
| G5 Analytics | Chưa thực hiện | — | — | — |
| G6 Firebase/PDF | Chưa thực hiện | — | — | — |
| G7 MobAI/regression | Chưa thực hiện | — | — | — |
| G8 Review/fidelity | Chưa thực hiện | — | — | — |
| G9 Submission | Chưa thực hiện | — | — | — |
