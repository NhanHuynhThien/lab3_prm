# TokenLedger — Checklist triển khai Lab 3

## Analytics/Remote Config và manual web checks —21/10/2026

Người dùng xác nhận toàn bộ đợt manual web1–7 đạt: account edit/budget, usage totals/purpose drilldown, unknown data, validation/Back draft, archive/restore/history guard, empty-account delete, multi-quota/bounds; trước đó đã xác nhận reload/A-B isolation và offline/Retry. Đây là user-reported web evidence, không phải Android/ARTEMIS/concurrency stress hoặc console do agent kiểm.

Đã thêm Analytics13.0.0 và RemoteConfig7.0.0, typed/noPII event allowlist, UID-serialized lifecycle/dedupe/success-only cloud mutations và tab/account/usage detail events; demo no-op. Remote Config defaults overview_recent_limit3/budget_warning_percent80, parse/clamp/cache/fallback/retry/single-flight; dashboard recent rows/warning thực thay đổi qua projections, không cắt dataset hoặc đổi tiền/token. Profile có effective values/source/check time/refresh và Analytics SDK status; Crashlytics vẫn chưa nối. Đọc [plan Analytics](analytics-plan.md) và [implementation/manual guide](analytics-remote-config.md).

Verification cuối xem test-report; không coi SDK state hoặc fake tests là DebugView/console evidence. Remote Config publish→app before-after, DebugView mỗi event, Android/ARTEMIS vẫn pending; PDF export/upload events chỉ planned. FCM/Crash/PDF và Final modules chưa làm. Không Android emulator/billing/deploy hoặc push trong lượt này. Các câu SDK Analytics/RC còn pending ở checkpoint dưới đây đã được cập nhật implementation mới; giữ history/results đúng thời điểm.


## Baseline đề mới và việc làm tiếp —21/10/2026

**Đọc [Yêu cầu Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md) trước khi dùng backlog này.** Đã đối chiếu L3 18 trang/Final9 trang; giảng viên chấp thuận TokenLedger theo xác nhận người dùng21/10. Các checkpoint chưa được duyệt chủ đề/MobAI/Cloudinary/3 findings/report5–10p/video3–5m bên dưới là lịch sử hoặc đã bị baseline mới thay thế, không phải yêu cầu hiện hành.

Lab3: ARTEMIS pytest ≥10 cases×3 runs, native/error/analytics case và exploratory Pro15–30m; AI review ≥5 findings/≥2 kinds/≥3 fixes ở3 commits; report8–12p/slides12–15/video5–10m. Final: web admin/roles/shared core/cross-role/Gemini/App Check, Emulator role tests, report10–15p/slides12–15/video8–12m. Lab3 Storage upload và Final device PDF khác nhau, cần xác nhận riêng; không coi chấp thuận chủ đề là miễn trừ dịch vụ.

Auth/Firestore code/rules/indexes đã có trên main484cc41;299 Flutter tests/142 Rules API cases là evidence cũ, không thay Android/ARTEMIS/Emulator/console mới. Không chạy máy ảo Android. File yêu cầu mới ghi chi tiết toàn bộ scope, gaps, evidence, dependencies và deliverables; các mục còn mở không tự được tick từ lượt docs này.


## Cloud workspace/rules —21/10/2026, mục3–5

Đã nối4 tab với Firestore theo UID, CloudLedgerViewModel dùng4 streams ghép nhất quán, full-dataset reporting, CRUD/quota/settings atomic, revision từ lúc mở form, last-good/cache/pending/error/retry giữ draft/filter. Mỗi UID/demo có ProviderContainer/Navigator riêng, root auth action coordinator dùng chung; logout/change UID dọn state/listeners/routes, không seed/upload local vào cloud. Factory tắt Firestore disk persistence. [Workspace hướng dẫn](firestore-workspace.md) ghi thiết kế và manual checks.

Rules default deny/owner/schema/relations/counters/quota labels/receipts đã code và deploy với5 indexes vào tokenledger-lab3/(default), Standard/asia-southeast1. Rules Test API142 cases pass (mocks trước/sau, không emulator/doc writes), live source hash khớp local và unauth GET403. Index readiness xem test-report, không suy deploy accepted thành READY. Full299 Flutter tests pass162s, analyzer sạch, web release48.3s;46 lib/22 test Dart files (2 helpers).25 tests VM/workspace mới;15 Auth tests cập nhật giữ assertions. Native/A-B thật/SDK transactions qua mạng/F1–F3 manual gates vẫn cần nghiệm thu. FCM/RC/Crash/Analytics SDK/PDF/Figma sync chưa làm. Không emulator/billing/commit/push.


## Firestore foundation —21/10/2026, mục1–2

Đã thêm cloud_firestore7.0.0, thiết kế envelope/paths theo UID, CloudLedgerRepository streams/atomic CRUD và SDK adapter cho account/usage/quota. Counters/revisions/quota label reservations và operation receipts commit cùng transaction, không upload snapshot local.35 tests repository mới pass; full regression274 tests pass138s trước lần siết receipt/path validation cuối, sau đó35 tests liên quan pass lại; analyzer sạch và web build xem test-report. Source44 lib/20 test Dart files, gồm2 support helpers. [Data contract](firestore-data-contract.md) ghi mapping/invariants/query/indexes và lifecycle. Chưa nối UI/VM, chưa viết/deploy rules/indexes hoặc kiểm database thật; các backend gates còn pending. Không emulator, billing, telemetry hoặc publication.

Người dùng báo Google web login/reload/logout và Authentication Users đã thành công, đồng thời đã tạo Firestore. Đây là xác nhận người dùng; native/Play services/release cert và Firestore integration chưa được kiểm bởi agent.


## Firebase/Auth C01–C03 —21/10/2026

Người dùng đã cho phép tiếp tục Firebase và cung cấp config project `tokenledger-lab3`. Core/Auth/Google SDK, service/VM, loading/cancel/error/Retry, auth guard/Profile và sandbox demo đã có code. Google provider/localhost và debug SHA được kiểm trực tiếp qua API/CLI; không gọi ledger trước auth hoặc đưa seed vào dữ liệu cloud. Profile authenticated hiện identity thật từ SDK, dữ liệu Firestore chưa nối. Full239 tests pass140s, analyzer sạch, web JS build45.3s; Gradle processDebugGoogleServices pass112s, không build APK/chạy máy ảo. [Auth setup](firebase-auth-setup.md) ghi source/flows/config/evidence và manual OAuth/native còn cần kiểm; GATE-01 chưa đạt. Không đổi billing, bật Analytics SDK hoặc các services ngoài Auth. Làm trên main sau PR#1; lượt này chưa commit/push.

## Checkpoint local —21/10/2026

Theo yêu cầu “bước 1. bắt đầu làm”, checkpoint chứa B01–B13/A03–A06 và P0 local trên branch `codex/local-form-safety`; xem SHA bằng `git log -1 --oneline`. Đây là commit local, chưa push. Các đoạn “chưa commit” bên dưới ghi trạng thái ở lần thực hiện trước checkpoint.

Audit candidate102 files: không phát hiện secret theo các pattern đã kiểm, file cấm hoặc file lớn hơn2MB; build/cache, local properties, generated registrant và tooling vẫn ignored.83 file runtime khớp fingerprint của full200 tests/analyzer/format/web JS build gần nhất, nên không chạy lại Flutter chỉ để commit. Đây không phải secret audit toàn bộ lịch sử Git hoặc AI PR review. Firebase, native/MobAI và final fidelity vẫn pending; không chạy emulator.

Cập nhật21/10/2026. Đọc cùng [Implementation plan](IMPLEMENTATION_PLAN.md). Checklist này là backlog, **đã cập nhật những task local scaffold hoàn thành; các gate Firebase và bài nộp vẫn pending**. Người dùng đã cho phép đổi chức năng theo chủ đề quản lý token; giảng viên đã chấp thuận chủ đề theo người dùng21/10; nghiệm thu các tiêu chí khác vẫn cần evidence.

## Hiện trạng A03–A06 ngày21/10

[Scope decisions](scope-decisions.md) chốt manual/USD/P1/P2, thuật ngữ và gaps SD01–SD08. B01–B14 đã đạt local/annotation scope,168 tests baseline B11–B13; bộ200 tests sau A04 xem test-report; Firebase/native/MobAI/final fidelity/submission vẫn chưa đạt. Các mục gộp local/backend giữ chưa tick nếu phần bắt buộc còn thiếu. Gate table cuối file ghi phần đã có và còn pending; chưa commit/push lượt B/A.

## P0 local sau A04 —21/10

[Upgrade](local-p0-upgrade.md): SD01–SD05 và phần local SD08 đã code: schema2/migration backup/retry, model/defaults/multi-quota/source/cost basis/cycle/IANA, source isolation và demo-safe reset, provider/donut/history/day grouping. Task có backend/counters/server/rules vẫn chưa tick; local fields không thay G3–G6. Full suite/analyzer/web kết quả thực ở test-report. Figma mới chưa annotate field này; final fidelity/native/MobAI vẫn pending.

## Bước2 — visual handoff P0,21/10/2026

Đã cập nhật live Figma theo source checkpoint `d4b6167`:8 màn360/412,3 phần cuộn P0,6 feedback specimens và provider/cost-basis continuation;7 local components,455 text nodes/120 instances,0 image fills.8 original annotations và8 notes trang07 đã sync. Đã xem QA412/component states Lab2, app renders360/412 và ảnh Figma sau fixes. [Visual handoff](visual-handoff-21-10.md) giữ bảng3 phía, node links, môi trường, sai khác và giới hạn. Audit local F11–F13 đã có evidence; chưa pixel-perfect/sign-off/GATE-08/native/backend/submission. Lượt này không sửa Flutter hoặc chạy lại tests/build;83 runtime hashes giữ nguyên. Không emulator/Firebase/push.

## Lịch sử scaffold 19/10/2026

Đã tạo Flutter Android/web, MVVM/Riverpod, logo và local CRUD/dashboard/animation. Firebase pending theo yêu cầu; checkbox hoàn thành chỉ xác nhận phạm vi local, không chứng minh Firestore/Auth/evidence Lab3. Chi tiết ở `build-status.md`, `test-report.md` và `firebase-pending.md`. Các gate G1/G3/G6 chưa đạt vì cần Firebase thật.

## Cập nhật docs/agent 20/10/2026

Đã thêm root AGENTS.md, `.agents/` context/workflows, docs index/architecture và bộ Lab2 reference độc lập. Bộ snapshot được tạo ở lượt trước, sau đó bỏ khỏi Git theo yêu cầu cleanup; DESIGN-02 hiện dùng bảng mapping/tokens và Figma reference. Không đánh RELEASE-13 hoặc PR-review tasks done chỉ vì initial push: chưa có PR/review/merge hay Firebase evidence.

## Quy tắc thực hiện

- Làm P0 theo G0 → G9. P1/P2 chỉ bắt đầu sau khi các gate P0 đạt.
- Mỗi task có ID để dùng trong commit/PR; cập nhật `[x]` khi có kết quả kiểm chứng, không chỉ vì đã sinh code.
- Mỗi gate ghi commit SHA, ngày, người kiểm tra và đường dẫn evidence thật trong bảng cuối file.
- Task cần account/configuration bên ngoài có thể để chờ và tiếp tục phần độc lập; không đánh dấu đã deploy/test nếu chỉ chạy mock.
- Giữ artifacts thiết kế Lab2 gốc để đối chiếu; không ghi đè nguồn thiết kế lịch sử.
- Không tạo ARTEMIS traces/results, findings, prompt hoặc ảnh console giả. MobAI/.mob không phải deliverable đề mới. Giữ prompt thực từ lúc làm.

## G0 — Chốt scope, yêu cầu và thiết kế (P0)

Dependency: tài liệu plan hiện tại. Exit gate: mapping đủ 8 màn / 3 flow, gap/change log có trạng thái thật, phạm vi nộp được làm rõ.

- [x] SCOPE-01 Đã đọc/đối chiếu L3 18 trang và Final9 trang ngày21/10; baseline và rubric trong ASSIGNMENT_REQUIREMENTS.md, không dùng đề17 trang hoặc bảng điểm cũ.
- [ ] SCOPE-02 Xác nhận cá nhân hay nhóm, StudentID/repo name, deadline và số commit/ngày `[N]` với giảng viên.
- [x] SCOPE-03 Giảng viên đã chấp thuận StudentPay → TokenLedger theo xác nhận người dùng21/10; ghi provenance trong scope-decisions.md. Không suy thành duyệt roles Final hoặc miễn Storage/tests.
- [x] SCOPE-04 Chốt P0: manual usage/quota, account metadata; P1 import; P2 provider sync. Xem scope-decisions.md; không loại Firebase P0 khỏi kế hoạch.
- [x] SCOPE-05 Chốt terminology account/provider/product/model/session/quota/auth token; định nghĩa trong scope-decisions.md. Model/provenance đã có ở schema2 sau A04; không suy model từ tên provider.
- [x] SCOPE-06 Xác nhận USD là currency P0; VND/FX để P1 nếu có nhu cầu.
- [x] DESIGN-01 Xem đủ 8 final360,8 QA 412 và state/component PNG trong Lab2; ghi nguồn/version.
- [x] DESIGN-02 Đối chiếu core Lab2, giữ mapping/tokens trong `docs/lab2-ui-reference.md`; không bundle tài liệu/ảnh nguồn copy hoặc tooling vào app.
- [x] DESIGN-03 Tạo `docs/handoff-gaps.md` từ HG01–HG10, mỗi gap có resolution và verification còn thiếu.
- [x] DESIGN-04 Đã có `docs/design-change-log.md`: thay chủ đề/flow/tab/form/login demo/profile/platform; FCM/export chưa implement và còn trong plan/firebase-pending, không claim thiết kế cuối đã xong.
- [x] DESIGN-05 Chuẩn bị annotated mockup8 màn TokenLedger từ core Lab2; không redesign palette/font/layout tùy ý.
- [x] DESIGN-06 Cập nhật hoặc annotate Figma, lưu link/node/screenshot thật trong change log.
- [ ] DESIGN-07 Bổ sung thiết kế S09–S14 theo component cũ; trạng thái loading/empty/error, form keyboard và Back.
- [ ] DESIGN-08 Duyệt screen/route map4 tab,3 flow và nhánh error/recovery theo mục4 plan.
- [x] DOC-01 Bắt đầu `docs/implementation-ai-log.md`; ghi entry thật từ các lượt AI sử dụng, không dựng lại lịch sử.
- [ ] GATE-00 Commit docs/scope/design mapping; ghi rõ quyết định nào còn chờ giảng viên.

## G1 — Flutter, Firebase và vertical slice đăng nhập (P0)

Dependency: scope/design direction; cần Google test account và Firebase project riêng. Exit gate: app Android chạy, Google Sign-In vào app rỗng và sign-out thật.

- [x] SETUP-01 Đã kiểm `flutter doctor -v`21/10: Flutter3.47.4/Dart3.13.3, Android SDK/licenses hợp lệ; evidence lịch sử trong test-report.md. Không chạy lại ở lượt docs.
- [x] SETUP-02 Tạo Flutter Android project trong Lab3, không thay đổi repo Lab2; chọn applicationId ổn định.
- [ ] SETUP-03 Giữ lịch sử commit theo từng stage. Nhánh thực `codex/local-form-safety` (quy ước codex/); tên `codex/tokenledger-lab3` trước đây chỉ là dự kiến. B01–B13/A03–A06 chưa commit, chưa đủ stage history.
- [x] SETUP-04 Xác minh package versions tương thích; chọn Riverpod duy nhất, commit lockfile.
- [x] SETUP-05 Tạo skeleton MVVM theo mục7, conventions model/service/ViewModel/view và typed failures.
- [ ] SETUP-06 Firebase project/Android registration đã có; Analytics SDK/DebugView chưa triển khai hoặc nghiệm thu. Không tick toàn task từ việc tạo project.
- [x] SETUP-07 Chạy FlutterFire configuration; kiểm tra `firebase_options.dart`/`google-services.json` đúng project.
- [x] SETUP-08 Bật Google provider, thêm debug SHA-1; cấu hình signing certificate bổ sung nếu cần APK khác.
- [ ] SETUP-09 Khi có thiết bị Android thật, kiểm tra kết nối/Google Play services. Native hoãn theo yêu cầu; không chạy/tạo/sửa emulator.
- [ ] SETUP-10 Tạo Google test account riêng, không ghi credentials vào code/docs/logs.
- [x] AUTH-01 Viết AuthService, auth state provider và LoginViewModel; SDK calls chỉ ở service.
- [x] AUTH-02 Làm Login UI theo tokens, loading/cancel/error/retry thật.
- [x] AUTH-03 Auth guard chặn mọi route/data khi chưa login; deep link không bypass guard.
- [ ] AUTH-04 Tạo/update user profile tối thiểu; Profile đọc tên/email/avatar thật.
- [ ] AUTH-05 Logout hủy listeners/state/draft và xử lý FCM device binding trước khi về Login.
- [ ] AUTH-06 Test Google success/cancel, offline lỗi, logout/Back và sign-in user B không thấy cache A.
- [ ] SPIKE-01 Thử upload1 PDF nhỏ lên storage dự kiến và mở URL trên Android; lưu kết quả/cấu hình không secret.
- [ ] SPIKE-02 Chuẩn bị ARTEMIS Python3.12+/uv/ADB/model env/commit pin và Android thật; không bật máy ảo. Ghi blocker thật nếu có; Firebase Emulator rules Final cần môi trường riêng được thống nhất.
- [ ] GATE-01 App chạy project Firebase thật, login/logout đạt; commit setup/auth và ghi evidence.

## G2 — Design system và navigation (P0)

Dependency: G1. Exit gate: component gallery và8 screen shells đúng core Lab2 ở360/412dp.

- [ ] UI-01 Tạo `lib/theme/` chứa đủ semantic colors cuối trong Lab2 `design/DESIGN.md`.
- [x] UI-02 Bundle/cấu hình Inter có tiếng Việt; map6 text styles, min text14sp.
- [x] UI-03 Tạo spacing/radius/elevation/touch/CTA size tokens; chỉ thêm extension có design log.
- [x] UI-04 Build AppButton variants default/pressed/disabled/loading, CTA52dp, target>= 48dp.
- [x] UI-05 Build AppTextField/AmountField default/focused/filled/error/disabled, helper text có semantics.
- [x] UI-06 Build SummaryCard/ProgressCard và list row dùng icon/title/subtitle/trailing metric.
- [x] UI-07 Build header/back,4 tab bottom nav, giữ selected/tab state bằng IndexedStack. Full router/auth/deep links còn UI-11.
- [x] UI-08 Build Dialog/Spinner/Empty/Error feedback variants; Retry giữ context/draft.
- [x] UI-09 Build PurposeTile grid3 cột và selectable row kế thừa Category/Member layout.
- [x] UI-10 Thêm component gallery để kiểm tra9 families và variants; không dùng gallery thay screens thật.
- [ ] UI-11 Tạo router S01–S10 cùng sheet/detail routes S11–S14, auth guard và not-found fallback.
- [x] UI-12 Dùng SafeArea/system bars Android; content cuộn, không vẽ status bar iOS trong app.
- [x] UI-13 Test keyboard/inset, text scale1.3/2.0, chuỗi dài, tiền lớn, target48dp ở360/412dp.
- [x] UI-14 Chụp baseline theme/component/screens; ghi ngoại lệ layout/platform vào fidelity draft.
- [ ] GATE-02 Không import Firebase trong screens/widgets; token/component audit đạt; commit UI foundation.

## G3 — Account, quota và Firestore protection (P0)

Dependency: G2 + Firestore project. Exit gate: F3 CRUD/query/realtime thật, quota đúng đơn vị và rules bảo vệ ownership.

- [ ] DATA-01 Viết model AIAccount/UsageSession/QuotaWindow/User/Report/Notification/Device và Firestore converters.
- [ ] DATA-02 Chốt field allowlists/enums/null semantics/schemaVersion và validation bounds theo plan.
- [x] DATA-03 Implement FirestoreService/AccountService/QuotaService; không truy cập SDK từ ViewModel/view.
- [ ] DATA-04 Tạo accounts/usage_sessions/quota_windows/report/notification/device paths dưới UID.
- [x] DATA-05 Query active accounts sorted updatedAt; realtime listener và auto-dispose theo UID.
- [x] DATA-06 Viết account usageCount transaction contract; repository không expose counter setter, child/counter/receipt atomic. Rules getAfter/counter/receipt đã thêm và được Rules Test API kiểm; MVCC fake races riêng không thay server contention test. RULE-05 emulator và GATE-03 manual vẫn chưa đạt.
- [x] RULE-01 Viết `firebase/firestore.rules`: default deny, auth/owner cho từng collection.
- [x] RULE-02 Validate create/update types/range/allowed keys; owner/createdAt immutable, account relation hợp lệ.
- [x] RULE-03 Dùng transaction/getAfter kiểm tra create/delete usage và account usageCount nhất quán.
- [x] RULE-04 Hard delete chỉ cho account rỗng, test race create usage vs delete account không để orphan.
- [ ] RULE-05 Emulator tests owner A/B, unauth, field sai, số âm, đổi owner/accountId, reference sai và counter tamper.
- [x] RULE-06 Deploy rules/indexes project thật; lưu output/ảnh console không secret.
- [x] ACCOUNT-01 S06: list, summary, empty CTA, realtime, error/retry; không cộng% quota giữa account.
- [x] ACCOUNT-02 S07: provider/product/alias/plan/budget/cycle/default purposes, validation và saving state. Local fields/model/timezone sau A04 được dùng lại với cloud CRUD và form revisions; manual acceptance còn chờ.
- [x] ACCOUNT-03 S08: detail, purpose summary placeholder theo data thật, budget/quota sections và thao tác edit/archive.
- [ ] ACCOUNT-04 Account create/update/list/detail thật; reload app vẫn có dữ liệu; delete account rỗng thật.
- [x] ACCOUNT-05 Account có usage chỉ archive trong luồng mặc định; hard delete yêu cầu xử lý usage trước.
- [x] QUOTA-01 S12 nhập snapshot theo window/unit, observedAt/resetAt/source; không yêu cầu token nếu chỉ biết%.
- [x] QUOTA-02 Hiển thị unknown/stale/vượt ngân sách bằng chữ+icon; reset qua thời điểm không tự hiện100%.
- [x] QUOTA-03 Local schema2: cập nhật snapshot cùng window thay current value, giữ key khi rename, source/note và windows độc lập; xóa đúng window và chặn resurrect từ form cũ. Backend ledger converter/owner path đã nối; các entity khác trong DATA-04 còn pending.
- [ ] ACCOUNT-06 Test alias dài, account trùng provider, budget0/null/âm, cycle invalid, quota 0/100/null/stale.
- [ ] GATE-03 F3 đạt với user A/B, console data/rules evidence thật; commit accounts/quota/rules.

RULE-01–04/06 tick phần code/rules simulations/deploy; RULE-04 race là MVCC fake + rules state validation, chưa phải server race thật. RULE-05 giữ pending vì không emulator;142 Rules Test API cases là evidence thay thế riêng, không giả mạo emulator. ACCOUNT-01–03/05/QUOTA-01 và USAGE-13 có cloud UI/service tests; ACCOUNT-04/GATE-03/04 cần manual user CRUD/reload/A-B. Xem firestore-workspace.md/test-report.md.

## G4 — Usage và tính toán (P0)

Dependency: G3. Exit gate: F1 tạo/sửa/xóa usage và tổng đúng, kể cả lỗi/retry.

- [ ] CALC-01 Implement UsageCalculator thuần, normalize input/output/cache không double count.
- [ ] CALC-02 Phân biệt tokens0/null và cost actual/estimated/unknown; không dùng0 thay mọi null.
- [ ] CALC-03 Tiền integer micros; pricing snapshot; rounding một lần mỗi usage; reported ưu tiên estimate.
- [ ] CALC-04 Period `[start,end)` UTC quy đổi timezone; used/remaining/excess, không clamp mất số vượt. Local IANA/cycle/DST/budget đã có sau A04; query backend còn pending.
- [ ] CALC-05 Coverage: known token/cost count và unknown count; quota snapshots không suy từ usage logs.
- [ ] CALC-06 Unit tests null/zero, precedence, rounding, overrun, percent/window, date boundaries, chart denominator0.
- [x] USAGE-01 Service implementation: FirestoreLedgerRepository transaction create/delete usage + counter, update immutable accountId, stable operation ID/receipt và revision checks.35 service tests mới; UI/rules/project integration còn pending.
- [x] USAGE-02 Khóa accountId khi edit P0; error validation nếu cố đổi. Local VM/storage đã kiểm; backend counters còn USAGE-01/C12.
- [ ] USAGE-03 S02: account/workTitle/purpose/model/date/note, token/cost modes, preview nguồn số liệu. Local form/model/source/basis đã có; backend confirmation còn USAGE-07.
- [x] USAGE-04 S03 local:9 purposes, selected state, Back không mất draft. Default purposes/model theo account đã có sau A04, chỉ gợi ý và được đổi; không viết lại phiên cũ.
- [ ] USAGE-05 Validation cả paste: title bắt buộc, token integer không âm, USD decimal hợp lệ, ngày theo policy.
- [x] USAGE-06 Chưa có account → tạo account → quay form với draft và account mới được chọn.
- [ ] USAGE-07 Save có validating/saving/pendingSync/saved/failed; chỉ server-confirmed mới thông báo saved.
- [ ] USAGE-08 Double tap/retry/timeout dùng cùng ID, không có phiên trùng; pending network không bị báo fail/success sai.
- [ ] USAGE-09 Back khi form đổi có xác nhận bỏ draft; chọn purpose xong giữ input/model/date/note. Local21/10: account/usage/quota guard và purpose round trip đã test; Model/defaults đã bổ sung sau A04; backend còn theo scope kế hoạch.
- [x] USAGE-10 S01: card ngân sách, progress, latest rows, CTA; unknown coverage rõ, không có “token tổng còn lại” giả.
- [ ] USAGE-11 S05: lịch sử nhóm ngày, filter account/purpose/time, list pagination không ảnh hưởng tổng kỳ.
- [ ] USAGE-12 S11: detail nguồn/cost/tokens + Edit/Delete, confirm delete và phản ánh realtime. Local detail/CRUD/confirmation/provenance SD05 đã có; Firestore realtime còn thiếu.
- [x] USAGE-13 VM tests save fail/retry/draft/pending; lỗi permission/network giữ dữ liệu form.
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
- [x] ANALYSIS-04 Local: sector donut/legend/account/provider mở đúng history/filter/time/source; Back giữ context. Có widget regression sector/provider, backend gate chưa đạt.
- [x] ANALYSIS-05 Local S08: purpose/session/known token/cost/remaining cùng cycle account và nhiều quota windows/source/note/stale độc lập. Firestore realtime/backend còn G3.
- [x] ANALYSIS-06 Kết luận mô tả chỉ từ usage đã ghi; không khẳng định năng lực agent/tiết kiệm chi phí khi thiếu dữ liệu.
- [ ] ANALYSIS-07 Month empty → CTA ghi usage; loading/network error có retry giữ filter.
- [x] ANALYSIS-08 Test legend total bằng summary; filter boundary; unknown excludes khỏi denominator đúng cách.
- [ ] GATE-05 F2 chạy data thật, screenshot đủ chart/list/detail; commit analytics flow.

## G6 — Firebase bổ sung và PDF (P0)

Dependency: G3–G5; spike storage/ARTEMIS nên xong từ G1. Exit gate: tất cả service có hành vi thật và evidence.

### FCM

- [ ] FCM-01 NotificationService: permission Android13+, token refresh và per-user device binding lifecycle.
- [ ] FCM-02 Foreground handler → Center+banner; không expose server key trong app.
- [ ] FCM-03 Background handler đúng entry point/runtime, không cập nhật UI từ background isolate.
- [ ] FCM-04 Tap background/cold start xử lý intent sau auth ready; allowlist routes, owner check/fallback.
- [ ] FCM-05 Center trong Profile có read/unread, persist dưới UID và dedupe messageId/eventId.
- [ ] FCM-06 Test Console foreground/background/tap, permission denied, target missing, logout/user change.
- [ ] FCM-07 Ghi giới hạn background delivery/inbox khi notification không được mở; không claim mọi tin đều persist tức thì.

### Remote Config

- [x] RC-01 Defaults overview_recent_limit3/budget_warning_percent80 đã có model/SDK/JSON; strict parsing/clamp1–10/1–100 và fallback tests. export_enabled optional chưa làm vì PDF chưa có.
- [x] RC-02 Recent rows và warning banner đổi behaviour trong projection/widgets; tests thay config xác nhận dataset/totals không đổi. Console publish→app vẫn nằm RC-04.
- [x] RC-03 Profile có effective values/source/check time/refresh/error; debug fetch interval0, release12h, fetchTimeout15s; single-flight/cached/default fallback và docs. Thời gian check không tự chứng minh fetch mạng mới.
- [ ] RC-04 Publish console rồi refresh quan sát app đổi, chụp trước/sau và test defaults khi fetch fail.

### Crashlytics và Analytics

- [ ] CRASH-01 Wiring Flutter và async error hooks, không ghi thông tin nhạy cảm.
- [ ] CRASH-02 Non-fatal từ error path thật + deliberate test crash; user ID và ≥1 custom key, clear identity khi logout; không mất draft hoặc log PII.
- [ ] CRASH-03 Restart/send và xác nhận cả 2 xuất hiện dashboard; lưu evidence, giới hạn demo controls đúng cấu hình.
- [x] EVENT-01 analytics-plan.md viết trước tracking, ≥7events/questions/typed params/flows/noPII; export/upload planned phải nối khi có PDF feature.
- [ ] EVENT-02 Implement login/logout/screen_view/view-account/accountCRUD/usage actions/export + custom purpose/drilldown/quota.
- [x] EVENT-03 Events sau repository success, operation-ID dedupe trong app session, owner queue/stale guard; tab/detail không do rebuild. Fake tests pass scope client, không claim exactly-once toàn reload hoặc console.
- [ ] EVENT-04 DebugView mỗi event+params; set userID sau login/clear logout; ≥1 ARTEMIS test kiểm event qua Logcat/DebugView, lưu evidence.

### PDF và storage

- [ ] PDF-01 Chốt REQ-SCOPE-04: L3 yêu cầu Cloud Storage owner path/rules; Final device save/share+Firestore metadata. Cloudinary không còn là mặc định được đề mới chấp nhận.
- [ ] PDF-02 Snapshot dataset theo filter, generate PDF nhận diện Lab2 có summary/purpose/table/source/coverage.
- [ ] PDF-03 Render kiểm tra PDF tiếng Việt, font/line wrap, nhiều trang, zero/unknown data, không lộ credential.
- [ ] PDF-04 Upload progress/error/timeout, result HTTPS URL và metadata filename/owner/time/size/filter/count.
- [ ] PDF-05 Upload-success/metadata-fail retry cùng exportID/URL; không tạo report ready giả hay duplicate upload.
- [ ] PDF-06 S14/Profile report list/Open action; verify URL trên Android, Firestore metadata đúng UID.
- [ ] PDF-07 L3 storage.rules owner-only read/write, kiểm unauth/user khác denied và URL access; Final không Cloud Storage/Cloudinary, save/share device. Không tự bật billing.
- [ ] GATE-06 Console notifications/RC/Crash/DebugView và PDF URL thật đầy đủ; commit integrations/evidence.

## G7 — Kiểm thử ARTEMIS và regression (P0)

Dependency: G6 + dedicated Google test account + documented seed reset. Exit gate:≥10 pytest cases×3 runs, structured assertions, native/error/analytics và exploratory Pro có evidence thật.

- [ ] TEST-01 Chuẩn hóa starting state riêng từng test, clock/window fixture, seed version, cleanup sau test và retry policy.
- [ ] TEST-02 TC-01 Google Sign-In → assert main screen/profile đúng; document manual Google screen nếu cần.
- [ ] TEST-03 TC-02 F1 ghi usage → assert record + tổng đúng sau reload, không chỉ toast.
- [ ] TEST-04 TC-03 F2 analytics → assert filtered list và tổng đúng.
- [ ] TEST-05 TC-04 F3 account/quota → assert detail/budget/window/source.
- [ ] TEST-06 TC-05 error/recovery → assert error, draft giữ, retry tạo đúng 1 record.
- [ ] TEST-07 TC-06 main entity CRUD → assert create/read/edit/delete list+detail account rỗng.
- [ ] TEST-08 TC-07 navigation4 tab/Back + state fixtures → assert nội dung từng đích.
- [ ] TEST-09 TC-08 Profile+RC → assert values và hành vi UI thực đổi.
- [ ] TEST-10 TC-09 PDF → assert upload URL/open action/report item, không chỉ nút đã tap.
- [ ] TEST-11 TC-10 logout → assert Login và route guard.
- [ ] TEST-12 e2e_test/ chứa conftest.py, pyproject.toml, pytest feature groups dùng ArtemisClient; pin commit. Assert structured values so expected, không SUCCESS-only.
- [ ] TEST-13 Mỗi ARTEMIS case ≥3 runs, bảng runs/pass rate/average time; command/trace ID/screenshots hoặc replay mỗi run; giải thích mọi failed/flaky/skipped và rerun sau fix.
- [ ] TEST-14 Exploratory ARTEMIS Pro15–30 phút unscripted; lưu issues/triage/fixes thật. Regression dùng Flash; không thay bằng healing exercise của plan cũ.
- [ ] TEST-15 Ít nhất1 native interaction,1 error case và1 analytics assertion; tests độc lập/dedicated Google test account. Bug-injection/healing chỉ optional, không thay yêu cầu đề mới.
- [ ] TEST-16 Test thêm usage edit/delete, archive/history, A/B isolation, rules race và cache/pending semantics.
- [ ] TEST-17 Test notification foreground/background/cold start, stale/reset quota và PDF network failure.
- [ ] TEST-18 Accessibility thực: contrast,48dp,360/412dp, large text/keyboard/long names, icon semantic labels.
- [ ] TEST-19 test-plan.md/test-report.md: critical flows/screens, ≥10 cases và precondition/instruction/expected/type, env/commands/results/3 runs/flaky/exploratory/manual limits.
- [ ] GATE-07 Regression pass, bug removed, không kết quả giả; commit tests/fixes/report.

## G8 — AI review và fidelity cuối (P0)

Dependency: G7. Exit gate: review trên PR, ≥5 findings/≥2 kinds, ≥3 separate fix commits và visual audit có ảnh.

- [ ] REVIEW-01 Mở PR từ feature branch vào main với mô tả final behavior và validation thật.
- [ ] REVIEW-02 Chạy AI review tool trên code app và `firebase/firestore.rules`; giữ screenshots/output thật.
- [ ] REVIEW-03 Ghi ≥5 findings thật có file:line, ≥2 kinds (bug/security/architecture/performance/test gap/maintainability), raw tool output. Không tạo findings cho đủ số.
- [ ] REVIEW-04 Mỗi finding accepted/modified/rejected+reason gắn requirement/constraint/effect; ≥3 accepted fixes, mỗi finding1 commit riêng có findingID, link verification.
- [ ] REVIEW-05 Rerun checks phù hợp sau fixes, không để review fix phá ownership/counters/totals.
- [ ] REVIEW-06 Hoàn thiện `docs/code-review.md`; không bịa findings nếu tool chưa trả đủ.
- [x] FIDELITY-01 Ảnh8 Lab2 + annotated TokenLedger + app360×800dp, liệt kê mọi khác biệt với lý do.
- [x] FIDELITY-02 Ảnh412dp và trạng thái loading/empty/error thật; ghi density/insets khi đối chiếu.
- [x] FIDELITY-03 Audit hard-coded colors/fonts/sizes ngoài theme, liệt kê ngoại lệ có lý do.
- [x] FIDELITY-04 Audit9 component families và states, screens tái sử dụng thay vì duplicate.
- [x] FIDELITY-05 Cập nhật Figma annotations theo app cuối, design-change-log và handoff-gaps resolutions.
- [x] FIDELITY-06 Hoàn thiện `docs/fidelity-check.md`, báo thật hạn chế còn lại, không claim perfect match.
- [ ] GATE-08 Review/fidelity đạt, commit fixes và chuẩn bị PR merge sau release checks.

## G9 — Hồ sơ nộp và release (P0)

Dependency: G8. Exit gate: fresh run/build, repo access, report/video, PR merged.

- [ ] RELEASE-01 `dart format` sạch, `flutter analyze` không lỗi và unit/widget/rules/regression checks cần thiết pass.
- [ ] RELEASE-02 Build/install Android APK và smoke test login/F1/F2/F3/export/logout trên bản nộp.
- [ ] RELEASE-03 Fresh clone chạy theo README; config Firebase/storage/rules/indexes và seed được mô tả đủ.
- [ ] RELEASE-04 Repo đúng `PRM393_Lab03_<StudentID>`, README có topic/Figma/handoff/run/setup/account-data limitations.
- [ ] RELEASE-05 Kiểm tra secrets trong tracked files/history/artifacts; phân biệt Firebase identifiers với API/admin/service-account secrets.
- [ ] RELEASE-06 Rules deployed không test mode; project có real users/data/events và evidence service đầy đủ.
- [ ] RELEASE-07 Disclose mọi AI tool/purpose, giữ prompt log thật; đề mới không quy định ≥6 entries thành gate riêng, log không thay AI review.
- [ ] RELEASE-08 Đủ design-traceability/architecture/analytics-plan/test-plan/code-review; e2e_test suite, firebase/storage.rules+remote-config-defaults.json, Firestore rules/indexes, evidence/ và runtime assets.
- [ ] RELEASE-09 Report8–12 trang: report/Lab03_<StudentID>.pdf đủ nội dung REQ-L3-41, mỗi works claim có evidence.
- [ ] RELEASE-10 Video5–10 phút live Android: login/3flows+errors/export-upload/push/RC-no-rebuild/Crash/ARTEMIS/review finding-fix; slides12–15 PDF riêng. Xem REQ-L3-42–43.
- [ ] RELEASE-11 Tua nhanh test run có chú thích nếu dùng; không che thất bại hoặc cắt để giả full run pass.
- [ ] RELEASE-12 Kiểm tra repo mở từ private browser window; quyền xem Figma/report/video đúng người chấm.
- [ ] RELEASE-13 PR AI review thật/fix commits và submission commit/tag theo stages; PR#1 đã merge chưa thay AI review mới. Đề mới không yêu cầu tự bịa thêm gate ≥1 PR merged.
- [ ] RELEASE-14 Oral review L3 khoảng5 phút: chạy1 ARTEMIS test, đổi1 RC live, giải thích1 VM/1 review decision; Final khoảng10 phút cross-role/RC/rule/AI.
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

Cập nhật21/10 từ source/docs/log đã có; kiểm bởi Codex trong lượt A03–A06. Không gate nào đã nghiệm thu đầy đủ. Cột commit không gán SHA nền4aeb7b7 cho source chưa commit; evidence local xem test-report/fidelity/scope decisions. Không chạy lại tests/build ở lượt docs.

| Gate | Trạng thái | Commit | Evidence | Người kiểm / ngày |
|---|---|---|---|---|
| G0 Scope/design | A03–A06/mapping/log/annotation đã có; lecturer scope/full mockups chưa đạt | Chưa commit giai đoạn | scope-decisions.md; handoff-gaps.md; fidelity-check.md | Codex /21/10/2026 |
| G1 Setup/Auth | Toolchain/skeleton local đã có; Auth/Firebase pending | Chưa commit giai đoạn | test-report.md; firebase-pending.md | Codex /21/10/2026 |
| G2 Core UI | Local tokens/components/layout/states đã kiểm; router/auth/full fidelity chưa đủ | Chưa commit giai đoạn | fidelity-check.md; test-report.md | Codex /21/10/2026 |
| G3 Accounts/quota/rules | Local CRUD/archive/multi-window/source/cycle; Firestore/rules pending | Chưa commit giai đoạn | architecture.md; scope-decisions.md SD03/SD07 | Codex /21/10/2026 |
| G4 Usage/calculator | Local schema2/CRUD/validation/retry/calculator/source isolation đã có; transactions/UID pending | Chưa commit giai đoạn | test-report.md; scope-decisions.md SD01/04/05 | Codex /21/10/2026 |
| G5 Analytics | Local totals/coverage/filter/provider/day-group/cycle/drilldown có; backend chưa đủ | Chưa commit giai đoạn | architecture.md; scope-decisions.md SD08 | Codex /21/10/2026 |
| G6 Firebase/PDF | Chưa tích hợp; pending theo yêu cầu | Chưa commit giai đoạn | firebase-pending.md | Codex /21/10/2026 |
| G7 ARTEMIS/regression |299 Flutter/142 Rules API đã có; ARTEMIS/native/manual/Final Emulator chưa thực hiện | Chưa commit giai đoạn | test-report.md | Codex /21/10/2026 |
| G8 Review/fidelity | Local audit/annotation có; AI PR review/full fidelity chưa đạt | Chưa commit giai đoạn | fidelity-check.md; design-change-log.md | Codex /21/10/2026 |
| G9 Submission | Chưa đủ P0, current APK/access/report/video/PR chưa đạt | Chưa commit giai đoạn | APP_COMPLETION_ROADMAP.md mục G | Codex /21/10/2026 |

## Lịch sử B03–B07 local stability —21/10/2026

Theo yêu cầu người dùng: B03–B07 trong [roadmap hợp nhất](APP_COMPLETION_ROADMAP.md) đã code và audit lại đủ local scope. Validation/Unicode/micros/date, archived history UI, corrupt storage/recovery backup, UUID/concurrency/reload/dispose và reactive clock/resume đã có regression coverage. Format/analyzer sạch,106/106 tests pass, web release JS build pass. Không tick các task Firestore/rules/Firebase hoặc gates submission theo kết quả local.

Không chạy emulator vì cấu hình máy theo yêu cầu mới; native/device test hoãn, không phải blocker để tiếp tục local UI/tests. Firebase vẫn pending. B08–B13 và các yêu cầu giảng viên/backend còn tiếp tục theo dependencies.


## Lịch sử B08–B10 local audit —21/10/2026

UI-04/UI-05 dùng Material themes và SaveButton/InputDecorationTheme + validators chung thay vì tạo facade chỉ đổi tên AppButton/AmountField; states có trong form thật và gallery QA. UI-10 gallery9 families nằm trong test/component_audit_test.dart, không phải màn sản phẩm. UI-12/UI-13/UI-14 đã kiểm phạm vi Flutter engine: SafeArea24dp, keyboard300dp,360/412×800, text1/1.3/2, long names/max values và ảnh hiện hành; không tick thay native, screen-reader hoặc full fidelity gates. Tại lượt B08–B10, DESIGN-01/05/06 và F11–F13 còn chờ; B13 sau đó hoàn tất DESIGN-06 annotation, chưa full QA412/mockup/final acceptance.

B08–B10 có mapping8 màn + màn phụ theo scope trong fidelity-check.md. Full142/142 tests pass; analyzer/format sạch. Các thiếu sót quan sát được ở chart/sidebar/legend/donut/appbar/helper đã sửa và có regression. Firebase pending, Notifications/Reports chưa implement, không tạo placeholder integration giả; không chạy emulator theo user. B11–B13 còn lại.


## B11–B13 local/annotation audit —21/10/2026

B11/B12 có implementation và automated accessibility/state tests; semantics/Tab+Enter/focus/contrast/targets, reduced motion giữ tab/filter/scroll, reload errors/Retry giữ draft/search, not-found/disabled và destructive confirmations. B13/ DESIGN-06: đã dùng Figma Plugin API annotate8 final360 và tạo trang handoff16 cards có link/node thật trong fidelity-check.md. Không thay original StudentPay visuals. Source Lab2 ảnh final360 đã xem trực tiếp qua Figma, QA412 mới đọc metadata; DESIGN-01 vẫn chờ toàn bộ QA412/state/component images, DESIGN-05 chưa có8 mockup TokenLedger hoàn chỉnh.

168 tests gồm26 tests mới (accessibility/states23, brand3); không dùng kết quả local để tick Firebase/native/MobAI hoặc final fidelity GATE/F11–F13. Giữ ngoại lệ kế thừa Lab2 palette/Inter/radius; Notifications/Reports pending không tạo trạng thái giả. Native TalkBack/IME hoãn theo user, không emulator/commit/push.

## Final — P0 riêng sau Lab3

Theo [baseline mới](ASSIGNMENT_REQUIREMENTS.md), FIN-01–FIN-36 là backlog Final đầy đủ: roles/data model/security/AppCheck, shared core/mobile/admin/Hosting/inbox/cross-role, Gemini/RC/privacy/fallback, Emulator role matrix/ARTEMIS/web checklist/review và hồ sơ. Các task này chưa implement; không tick từ preview desktop/owner-only rules. IDs REQ-L3 bổ sung các chi tiết đề mới không được tách đủ trong G0–G9; kiểm cả hai danh sách trước đóng gate.
