# TokenLedger — Công việc còn lại để hoàn thành app Flutter và Lab3

Ngày tổng hợp: **20/10/2026**. Đây là danh sách hành động hợp nhất từ toàn bộ Markdown của dự án, dùng để theo dõi phần còn lại mà không phải đọc lại nhiều backlog trùng nhau.

**Kết luận hiện trạng:** app đã có nền tảng Flutter và nghiệp vụ local; chưa hoàn thành bản Lab3 có Firebase, kiểm thử Android và hồ sơ nghiệm thu. Không cần dựng lại app từ đầu. Cần hoàn thiện trải nghiệm, nối backend đúng kiến trúc, kiểm chứng các tích hợp rồi hoàn tất bài nộp.

**Firebase vẫn đang pending theo yêu cầu trước đó.** Việc lập roadmap này không phải yêu cầu bật Firebase, tạo project, deploy hoặc thu thập telemetry. Các công việc phụ thuộc Firebase chỉ triển khai khi người dùng yêu cầu tiếp tục phần đó. Có thể làm trước các công việc local, thiết kế, chuẩn bị Android và đặc tả.

**Cập nhật sau A04 ngày21/10:** đã code [local P0 upgrade](local-p0-upgrade.md): SD01–SD05 và analytics/history local SD08. Model/migration2/form/quota windows/cycle/IANA/provenance/source isolation/provider/day grouping/drilldown có implementation; backend trong C/D/E và full nghiệm thu vẫn pending. Không tick D tasks backend chỉ vì phần local đã làm.

## 1. Phạm vi, nguồn và cách theo dõi

Đã đọc 17 Markdown thuộc dự án trước khi tạo file này:

- [README](../README.md), [AGENTS](../AGENTS.md).
- [Mục lục docs](README.md), [Implementation plan](IMPLEMENTATION_PLAN.md), [Task checklist](TASK_CHECKLIST.md).
- [Architecture](architecture.md), [Build status](build-status.md), [Test report](test-report.md).
- [Lab2 reference](lab2-ui-reference.md), [Design change log](design-change-log.md), [Handoff gaps](handoff-gaps.md).
- [Firebase pending](firebase-pending.md), [AI implementation log](implementation-ai-log.md).
- [Agent workspace](../.agents/README.md), [Project context](../.agents/project-context.md), [Workflows](../.agents/workflows.md).
- [Logo source](../assets/brand/README.md).

Không gộp Markdown của bộ skill bên thứ ba trong `.agents/skills/` vào yêu cầu sản phẩm. Đó là tooling local được gitignore, không phải tài liệu đặc tả app.

Đã đối chiếu thêm models, repository, mutation/reporting ViewModels, usage form, các tests hiện có, pubspec và Android build configuration. Đây không phải audit toàn bộ source, một lần chạy test mới hoặc xác nhận tình trạng GitHub/Firebase hiện tại. Các yêu cầu rubric dưới đây được tổng hợp từ plan/checklist đang có; PDF gốc đã bỏ khỏi repo nên cần đối chiếu lại với đề/giảng viên trước chốt nộp.

Quy ước:

- Checkbox bên dưới đều là **công việc còn phải hoàn thành hoặc kiểm chứng**, không phủ nhận phần local đã có.
- Chỉ tick khi có kết quả và bằng chứng đúng phạm vi. Local CRUD không thay Firestore CRUD; widget tests không thay Android/MobAI.
- Các mục **chốt scope** là quyết định còn thiếu; các mục **đề xuất** không tự trở thành yêu cầu bắt buộc của đề.
- Mỗi mục khi hoàn thành ghi commit, ngày, môi trường, kết quả và link evidence vào bảng cuối file.
- Tài liệu này hợp nhất công việc; tài liệu nguồn tiếp tục giữ chi tiết thiết kế, schema, lịch sử và kết quả kiểm chứng. Không xóa chúng.

## 2. Nền tảng tại lúc tạo roadmap 20/10 — lịch sử

Hiện trạng21/10:31 lib/12 test files,168 tests; draft/recovery/clock/layout/accessibility đã bổ sung; live Figma đã annotate. Android SDK/licenses có, APK cũ trước B03–B13; native hoãn. Đọc [build status](build-status.md) và [quyết định A03–A06](scope-decisions.md) cho trạng thái hiện hành.

| Hạng mục | Đã có | Phần chưa đủ để coi là hoàn tất |
|---|---|---|
| Flutter/platform | Source Android/web, package `token_ledger`, application ID `com.tokenledger.token_ledger` | Chưa có bằng chứng APK/device; SDK từng thiếu ở lần kiểm tra 19/10 |
| Kiến trúc | MVVM + Riverpod; calculator và reporting projections tách khỏi Views | Repository còn snapshot `load/save`, chưa có owner scope, streams và atomic backend CRUD |
| Điều hướng | 4 tab, sidebar desktop, IndexedStack; Navigator và sheets | Chưa có auth guard/deep links đầy đủ, chưa xác nhận bỏ draft khi Back |
| Account | Local CRUD, archive/restore, xóa account rỗng | Chưa Firestore, rules, realtime, isolation, counters và race tests |
| Usage | Local CRUD, 9 purposes, token/cost nullable, giữ usage ID khi retry | Chưa server confirmation, auth lifecycle và network recovery đầy đủ |
| Budget/analytics | USD integer micros; summary, chart, coverage, filters, drilldown | Chưa backend dataset, query errors/pagination và audit biên kỳ đầy đủ |
| Quota | Một snapshot/account; observedAt/resetAt, stale | Chưa nhiều windows, nguồn dữ liệu/schema backend và vòng đời refresh đã kiểm chứng |
| UI/brand | Inter, tokens Lab2, logo SVG/painter/icons, motion hỗ trợ reduced motion | Chưa Figma annotations, full fidelity, accessibility/keyboard trên Android |
| Persistence | SharedPreferences JSON schemaVersion 1; demo reset/clear | Không có UID, encryption hoặc multi-device conflict resolution; không dùng cho credential |
| Verification | Tài liệu ghi 16 tests, analyzer sạch và web release build pass ngày 20/10 | Chưa Firebase/rules/MobAI/native tests; lượt tổng hợp này không chạy lại |

Seed hiện tại: **3 accounts, 12 sessions, 286.000 known tokens, $12,84 known cost**, một phiên thiếu cả token/cost. Chi phí giả định, không phải bảng giá provider. Không dùng seed để chứng minh provider integration.

## 3. Những nguyên tắc phải giữ trong mọi giai đoạn

1. Android là đích Lab3; web là preview/test bổ sung. Giữ core UI StudentPay Lab2 khi đổi nghiệp vụ sang quản lý AI accounts/usage/purpose/quota.
2. Riverpod là state/dependency framework duy nhất. Models Dart thuần; SDK/persistence trong services; VM validate/orchestrate; widgets render và gửi intents.
3. Tiền lưu USD integer micros, `1 USD = 1.000.000 micros`. Null là chưa biết, không thay bằng 0 để làm đẹp tổng/coverage. Không cộng khác currency.
4. Input/output token cùng biết hoặc cùng trống. Tổng token chỉ là volume đã ghi, không phải quota thuê bao. Budget tự đặt không phải provider balance.
5. Quota từng window có observedAt/resetAt/source; stale sau reset, không tự hiện remaining 100%. Không cộng quota% giữa accounts hoặc suy quota từ usage.
6. Usage đã lưu không đổi accountId. Account có lịch sử giữ bằng archive; account rỗng mới được hard-delete. Archive chặn tạo usage mới.
7. Save fail giữ dữ liệu/draft; retry cùng operation ID; guard double tap và concurrent writes. Không báo saved trước kết quả persistence phù hợp.
8. Giữ Inter, primary `#006C49`, background `#FAF8FF`, mint `#E8F7EF`, card radius 20, control 12, spacing 4/8/12/16/24/32, touch tối thiểu 48dp, CTA 52dp. Giữ 4 destinations và reduced motion.
9. Không thu password/API key/access token/cookie provider trong demo; không thêm chat, payment, scraping hoặc login/integration giả.
10. Không làm giả `.mob`, findings, prompt logs, console screenshots, thời gian chạy hoặc commit history. Không đưa vendor skills, build/cache, bản copy Lab2/PDF nguồn và secrets trở lại Git.

## 4. Thứ tự triển khai và điều kiện phụ thuộc

| Giai đoạn hợp nhất | Làm gì | Điều kiện bắt đầu | Kết quả cần đạt | Đối chiếu checklist cũ |
|---|---|---|---|---|
| A | Chốt scope/rubric và chuẩn hóa trạng thái tài liệu | Làm ngay | Phạm vi, mapping, quyết định còn chờ rõ ràng | G0 |
| B | Hoàn thiện local UI/domain và chuẩn bị Android | Làm ngay, giữ Firebase pending | Local flows ổn định, Android toolchain/device baseline | Phần local G1–G5 |
| C | Auth, owner-scoped repository, Firestore/rules | Người dùng yêu cầu tiếp tục Firebase; có project/test account | Login và data isolation thật; CRUD backend an toàn | G1, G3–G4 |
| D | Hoàn chỉnh 3 flows, analytics và quota trên backend | Nền C hoạt động | F1/F2/F3 và recovery đúng cùng dữ liệu | G2–G5 |
| E | PDF, FCM, RC, Crashlytics, Analytics | Auth/data lifecycle ổn định; spike storage khả dụng | Từng service có hành vi và evidence thật | G6 |
| F | Regression, MobAI, AI review, fidelity | Các flows/tích hợp cần test đã hoạt động | Tests/fixes/review/visual audit có bằng chứng | G7–G8 |
| G | Release Android và hồ sơ nộp | Các tiêu chí bắt buộc đã kiểm chứng | APK, docs, report/video, PR/access/submission | G9 |

Có thể chuẩn bị đặc tả tests/events/PDF/Figma và thử khả năng công cụ sớm để phát hiện blocker. Không cần chờ tích hợp xong mới bắt đầu ghi tài liệu/evidence. P1/P2 không nằm trên đường hoàn thành P0.

## 5. A — Chốt phạm vi và sửa cách theo dõi

A03–A06 hoàn tất21/10 trong [scope decisions](scope-decisions.md): SD01–SD08 giữ rõ P0 còn thiếu, không coi tick quyết định là đã implement. A01/A02/A07 chưa hoàn tất.

- [ ] **A01 — Chốt yêu cầu với giảng viên:** cá nhân/nhóm, StudentID, deadline, quy định số commit/ngày còn placeholder, đổi chủ đề StudentPay → TokenLedger có được chấp nhận hay không. Lưu phản hồi thật.
- [ ] **A02 — Đối chiếu đề gốc:** xác nhận tối thiểu 8 màn/3 flows, các Firebase services, storage được phép, yêu cầu MobAI/AI review, tên repo và hồ sơ nộp. Mapping điểm trong plan là tham khảo, chưa phải điểm đã đạt.
- [x] **A03 — Chốt phạm vi dữ liệu P0:** manual usage/quota, USD, account metadata; thống nhất account/provider/product/model/session/auth token. CSV là P1, provider sync là P2.
- [x] **A04 — Chốt khoảng cách plan/source:** modelId, default purposes, nhiều quota windows, cycle/timezone, source/costBasis và pricing estimates hiện chưa đủ trong source. Quyết định trường nào phải làm P0; mục nào bỏ/hoãn phải có lý do và được chấp nhận khi ảnh hưởng rubric. Không tự thêm pricing engine chỉ vì plan có công thức ước tính.
- [x] **A05 — Đồng bộ checklist:** các file gaps/change log/AI log đã tồn tại, không tạo lại; cập nhật trạng thái phần có sẵn và phần chưa hoàn thiện. Thay cách ghi gate chung chung bằng “đã có local/chưa đạt nghiệm thu đầy đủ” khi đúng thực tế; không tick backend tasks theo local tests.
- [x] **A06 — Chuẩn hóa lịch sử docs:** giữ ghi chú snapshot Lab2 là lịch sử và xác nhận đã cleanup; dùng reference/Figma hiện hành. Cập nhật context Git từ lệnh thực khi cần, không dùng đoạn “repo trống/local chưa có Git” làm hiện trạng.
- [ ] **A07 — Chốt nơi lưu evidence:** artifacts inspector/build/reference vẫn local và gitignored; báo cáo/evidence nộp bài dùng nơi lưu được phép, có link và quyền truy cập. Nếu cần đưa evidence chọn lọc vào Git, quyết định rõ trước vì `assets/evidence/` hiện bị ignore.

**Điều kiện xong A:** scope và quyết định chưa có câu trả lời được ghi rõ; không có tuyên bố đã được giảng viên duyệt hoặc đã đạt gate khi chưa có evidence.

## 6. B — Công việc làm được khi Firebase còn pending

### B1. Form, lỗi và dữ liệu local

- [x] **B01 — Bảo vệ draft:** thêm xác nhận tiếp tục sửa/bỏ thay đổi khi Back khỏi account/usage/quota form có sửa; xử lý cả appbar và Android system Back. Không hỏi khi form chưa thay đổi hoặc vừa lưu thành công.
- [x] **B02 — Recovery form:** kiểm chứng save fail giữ toàn bộ fields, focus/error dễ hiểu, retry cùng usage ID tạo đúng một record; khóa thao tác liên quan khi saving. Không chỉ dựa vào test `clearDemo` thất bại để kết luận form recovery đã đủ.
- [x] **B03 — Đồng nhất validation:** title/alias/note, token integer, cặp input/output, USD parser, số lớn/paste, ngày hợp lệ, quota 0–100/reset. Đặt ràng buộc nghiệp vụ ở VM/service để không bypass bằng đường gọi khác; xác định rõ policy token 0 thay vì áp dụng mâu thuẫn giữa plan và null-vs-zero invariant.
- [x] **B04 — Account archived:** kiểm thử history/detail/edit/delete session liên quan account archived. Policy đã triển khai: account archived cho sửa/xóa phiên cũ, chặn phiên mới và giữ accountId immutable. Hiển thị đường xử lý hợp lệ, tránh dropdown chứa ID không có trong items.
- [x] **B05 — Corrupt storage/schema:** kiểm thử JSON hỏng, version không hỗ trợ và lỗi read/write; giữ blob cũ, error/retry và reset có confirmation. Nếu đổi schema, có migration/backup và tests dữ liệu cũ trước khi phát hành.
- [x] **B06 — ID và concurrent writes:** kiểm tra chiến lược ID timestamp hiện tại khi tạo gần nhau; chọn ID phù hợp khi mở rộng backend. Thử double tap, mutation chồng nhau, route đóng khi đang await và retry; không kết luận `_writing` một VM là đủ cho nhiều thiết bị.
- [x] **B07 — Thời gian sống của báo cáo/quota:** kiểm thử app mở qua nửa đêm, đổi tháng, quota reset và resume từ background; nếu clock-derived providers không refresh đúng thì bổ sung trigger có kiểm soát. Test bằng clock cố định, không tự tạo quota mới sau reset.

### B2. UI, thiết kế và accessibility

- [x] **B08 — Audit đủ màn:** đối chiếu 8 màn Lab2 với Dashboard, Usage form, Purpose, Analytics, History, Accounts, Account form, Account detail; thêm Login/Profile/Usage detail/Quota/Notifications/Reports theo scope. Ghi khác biệt nghiệp vụ/platform, không báo giữ nguyên mọi flow.
- [x] **B09 — Component audit:** rà 9 families Button/Textfield/Card/Navigation/Appbar/Dialog/Loading/Empty/Error và các states cần dùng. Hoàn thiện tokens/variants thiếu, dùng lại components; component gallery là công cụ QA theo checklist, không thay màn app.
- [x] **B10 — Kiểm tra layout thật:** 360×800dp, 412×800dp, tablet/desktop khi liên quan; text scale 1.3/2.0, keyboard/insets/SafeArea, tên dài/số lớn, scrolling và CTA không bị che. Đã thêm ma trận800dp tại DPR1; simulated keyboard/SafeArea, giới hạn native/Figma ghi ở audit cuối.
- [x] **B11 — Accessibility/motion:** contrast, touch ≥48dp, icon semantic labels, chart có text/legend; focus/read order khi phù hợp. Kiểm tra system disableAnimations, giữ IndexedStack/filter/scroll; không thêm loop trang trí.
- [x] **B12 — States và xác nhận:** loading/empty/error/retry/not-found/disabled trên các màn liên quan; reset/clear/delete/archive có thông điệp đúng hậu quả, không xóa draft do lỗi.
- [x] **B13 — Figma và brand:** annotate 8 màn chuyển đổi cùng các màn bổ sung, link/node thật; giữ geometry SVG/painter/icons nhất quán và phân biệt provider initials với logo chính thức. Đọc skill UI áp dụng trước lúc sửa UI; ghi ngoại lệ do kế thừa Lab2.

### B3. Android và baseline kiểm chứng

- [x] **B14 — Kiểm tra toolchain hiện tại:** `flutter doctor -v`, Flutter/Dart, JDK/Android SDK/licenses, `flutter devices`; ghi môi trường thật. Không kết luận SDK vẫn thiếu chỉ từ report 19/10.
- [ ] **B15 — Chạy app local trên Android:** hoãn theo yêu cầu21/10; không chạy emulator trên máy yếu, native test trên thiết bị thật để sau; kiểm tra launch/demo, 4 tab, Back, forms/keyboard, CRUD, persistence sau restart và icons. Ghi rõ emulator hay máy thật, OS/device/version.
- [ ] **B16 — APK baseline:** đã có build debug APK ở lượt trước; install/smoke hoãn theo yêu cầu21/10, không xử lý emulator. Android release hiện dùng debug signing trong Gradle; xác định signing phù hợp cho bản nộp/phát hành, đăng ký SHA tương ứng khi bật Auth, không commit key/password.
- [ ] **B17 — Mở rộng tests có giá trị:** save fail/retry ở usage form, concurrency, accountId immutable, archived edit path, null/zero, budget 0/null/overrun, biên kỳ/reset, draft Back và filter/scroll khi đổi tab. Test bảo vệ hành vi, tránh chỉ lặp implementation.
- [ ] **B18 — Chạy checks sau thay đổi:** format/analyze/tests; full tests cho model/VM/theme/navigation dùng chung. Thay assets/dependency/bootstrap thì pub get và web build phù hợp. Ghi kết quả mới đúng ngày, không sửa ngày evidence cũ.

**Điều kiện xong B:** demo local ổn định trên Android ở scope đã kiểm tra; UI/form/recovery có bằng chứng; Firebase vẫn được hiển thị pending cho đến khi C được cho phép triển khai.

## 7. C — Firebase Auth và nền dữ liệu an toàn

**Phụ thuộc:** người dùng yêu cầu tiếp tục Firebase, có project/config và Google test account phù hợp. Các thao tác deploy/console tuân theo phạm vi được cho phép tại lúc làm.

### C1. Setup, Auth và vòng đời phiên

- [ ] **C01 — Setup thật:** Firebase project riêng, Android package đúng, Analytics/provider và FlutterFire configuration; kiểm tra dependency/API hiện hành trước code. Không sao chép config từ dự án khác, không nhúng admin/service-account secrets.
- [ ] **C02 — Google Sign-In:** AuthService + auth provider/VM; loading/cancel/network/config error/retry thật; test Google Play services và SHA debug/release tương ứng.
- [ ] **C03 — Auth guard/Profile:** chờ auth ready rồi vào route hợp lệ; tên/email/avatar từ user thật; chưa auth không đọc data. `/?demo=1` chỉ vào sandbox local, không bypass backend authorization.
- [ ] **C04 — Logout/change user:** hủy listeners, invalidate data/cache/drafts nhạy cảm, xử lý device token binding; chặn Back/deep link vào data cũ. Test A → logout → B trên cùng thiết bị.
- [ ] **C05 — Demo isolation:** user mới thấy empty; import/seed demo là thao tác rõ ràng. Không tự upload snapshot SharedPreferences sang Firestore hoặc trộn demo với dữ liệu thật.

### C2. Models, repository và query

- [ ] **C06 — Contract mới:** thiết kế owner-scoped streams và atomic CRUD theo operation; typed failures và state loading/empty/data/error. Không thay `save(snapshot)` bằng một lần ghi toàn snapshot backend.
- [ ] **C07 — Models/converters:** bổ sung User/Report/Notification/Device, ownerId, timestamps/schema/source theo nhu cầu; xác định mapping local → backend và migration nếu có. Giữ VM/calculator độc lập SDK và bảo toàn null semantics.
- [ ] **C08 — Owner paths:** `users/{uid}/accounts`, `usage_sessions`, `quota_windows`, `reports`, `notifications`, `devices`; không query global rồi lọc UID trong widget.
- [ ] **C09 — Query/indexes:** accounts active/order, usage theo kỳ `[start,end)`, account/purpose filters, reports/notifications ordering; tạo indexes theo query thực tế. Totals tính từ dataset đủ kỳ, không lấy một trang history để tính tổng.
- [ ] **C10 — Cache/pending/error:** phân biệt last good/cache/pending/server; query fail có retry giữ context. Nếu dùng transaction, offline có thể fail và cần retry; không hứa tự queue. Chỉ thêm “chờ đồng bộ” khi có thiết kế queued-write thật.
- [ ] **C11 — Retry/concurrency:** operation IDs ổn định, cùng ID không sinh duplicate; xử lý timeout chưa rõ kết quả, account bị archive/delete giữa lúc form mở và mutation; backend là nguồn xác nhận.

### C3. Transactions, rules và deployment

- [ ] **C12 — Usage/account relation:** create/delete usage và usageCount trong transaction; accountId immutable khi edit; hard delete chỉ account rỗng. Dùng mutation relation/getAfter hoặc thiết kế tương đương kiểm chứng được, không chỉ kiểm count ≥0.
- [ ] **C13 — Rules:** default deny, UID path/owner, field allowlists/type/enum/length/bounds, owner/createdAt immutable; account relation hợp lệ/active lúc create. Reports/quota/notifications/devices không được chuyển owner.
- [ ] **C14 — Emulator tests:** unauth deny; A đọc/ghi A pass, A đọc/ghi B deny; invalid type/field/number/owner/reference deny; counter tamper deny; race create usage ↔ delete account không orphan; edit không đổi account.
- [ ] **C15 — Deploy và integration:** rules/indexes vào đúng project, kiểm console và app thật. Không dùng rules test mode. Ghi evidence deploy và A/B isolation; emulator tests không thay console evidence.

**Điều kiện xong C:** Google login/logout thật, user isolation gồm cache đúng, repository không ghi đè snapshot, rules/transactions bảo vệ quan hệ dữ liệu và đã kiểm chứng trên project đích.

## 8. D — Hoàn chỉnh ba flows chính trên dữ liệu backend

### D1. F1 — Ghi và quản lý usage

- [ ] **D01 — Form đầy đủ theo scope A04:** account active, work title, purpose, occurredAt, note; model/source/cost basis theo SD01/SD05 đã chốt (chưa implement). Không ép người dùng nhập token/cost giả để lưu công việc.
- [ ] **D02 — Save thật:** validating/saving/error/success đúng backend; save thành công list/detail/totals đổi và reload còn dữ liệu. Edit/delete có confirmation và tổng cập nhật; retry/double tap không duplicate.
- [ ] **D03 — Error/recovery:** invalid input, permission/network/account mất hoặc archived; giữ draft, focus/message hợp lý và retry hợp lệ. Chọn purpose/thêm account rồi quay về giữ fields và chọn đúng account mới.
- [ ] **D04 — History:** search/time/account/purpose, nhóm ngày/detail, Back giữ filter/scroll, pagination khi cần; không làm mất completeness của summary.

### D2. F2 — Analytics và drilldown

- [ ] **D05 — Shared projections:** Dashboard/Analytics/Account detail dùng cùng normalized dataset và calculator. Chọn kỳ/metric cost-token-session; group purpose/account/provider theo scope đã chốt; period filters có kiểm thử biên.
- [ ] **D06 — Chart integrity:** tổng legend = summary đúng tập đủ điều kiện; missing coverage rõ; denominator 0 là empty; drilldown mở đúng dataset/filter/time/account. Không vẽ zero bar cao giả hoặc coi unknown là measured zero.
- [ ] **D07 — Budget:** monthly budget tách selected-period KPI, không nhầm 7 ngày với tháng; budget null/0, âm remaining/overrun và archive có policy rõ. Không gọi ngân sách còn lại là provider balance.
- [ ] **D08 — Cost semantics:** giữ manual/actual/estimated/unknown/source rõ nếu dùng; không cộng reported+estimated cùng phiên, subscription fees không cộng lặp vào usage. Nếu làm estimates, phải có pricing snapshot/source/effectiveAt và rounding tests; nếu hoãn thì bỏ lời hứa estimate khỏi UI/docs scope.

### D3. F3 — Account và quota

- [ ] **D09 — Account CRUD backend:** list/detail/create/edit/delete rỗng, archive/restore account có lịch sử, realtime/reload; alias/provider/product/plan/billing/budget và fields mở rộng đã chốt có validation.
- [ ] **D10 — Quota:** nhiều windows riêng theo SD03 thuộc P0; update thay snapshot đúng window, không cộng snapshots. observedAt/resetAt/source rõ, unknown/stale/0/100% đúng; không suy quota từ sessions.
- [ ] **D11 — Timezone/cycle:** source local dùng timezone thiết bị/tháng dương lịch, plan đề xuất UTC và Asia/Ho_Chi_Minh. Khi chuyển phải thống nhất kỳ, lưu/query/hiển thị và test đầu/cuối tháng, ngày nhuận, reset boundary; không âm thầm đổi công thức lịch sử.
- [ ] **D12 — Seed backend/test fixtures:** owner-scoped/versioned/isDemo, account rỗng CRUD Test và user B dataset riêng; reset chỉ demo đúng UID, counters đúng; seed lặp không nhân đôi/xóa real data. Freeze clock để fixture không stale ngoài ý muốn.

**Dataset nghiệm thu chuẩn:**

| Thao tác trên seed chuẩn | Known tokens toàn dataset | Known cost toàn dataset | Kiểm tra thêm |
|---|---:|---:|---|
| Baseline | 286.000 | $12,84 | Codex 141.000 / $5,86 |
| Thêm phiên Codex Test 10.000 token / $0,05 | 296.000 | $12,89 | Codex 151.000 / $5,91 |
| Sửa cost phiên mới thành $0,07 | 296.000 | $12,91 | Không tạo phiên thứ hai |
| Xóa phiên mới | 286.000 | $12,84 | Quay baseline |

Quota Codex vẫn 40% used nếu không có snapshot mới. Các tổng chỉ gồm giá trị đã biết; test setup phải đặt các phiên trong cùng kỳ phù hợp.

**Điều kiện xong D:** F1 create/edit/delete, F2 filters/drilldown và F3 account/quota đều chạy với backend thật; mỗi flow có happy path, lỗi và recovery đã kiểm chứng.

## 9. E — Tích hợp services và xuất báo cáo

### E1. PDF và storage

- [ ] **E01 — Spike storage sớm:** xác minh PDF upload/delivery và mở URL trên Android; Cloudinary unsigned preset là hướng đề xuất, không mặc định chắc chắn khả dụng. Giới hạn MIME/extension/size (5MB là đề xuất), kiểm billing/tier. Phương án thay thế theo điều kiện đề/giảng viên.
- [ ] **E02 — Generate PDF:** snapshot dataset theo filter; màu/font Lab2, tiếng Việt, kỳ/account/purpose/summary/table/source/coverage; test nhiều trang, long text, zero/unknown. Render kiểm tra trước bàn giao.
- [ ] **E03 — Upload lifecycle:** progress/error/timeout/cancel khi cần, HTTPS URL/host hợp lệ; metadata owner/file/time/size/filter/count/status. Chỉ ready sau upload và metadata thành công.
- [ ] **E04 — Partial failure:** upload thành công nhưng metadata fail thì retry cùng export ID/URL, không upload duplicate; có cách theo dõi orphan files. Kiểm không ghi record ready giả.
- [ ] **E05 — Reports UI:** Profile/report list, export filter, kết quả/Open URL trên Android; chỉ đúng UID. Ghi rõ unsigned demo URL có thể truy cập bởi người có link; private reports thực tế cần authenticated delivery riêng.

### E2. FCM và Notification Center

- [ ] **E06 — Permission/device:** Android 13+ permission, denied vẫn dùng app; token refresh, per-user binding và logout/rebind không gửi nhầm user.
- [ ] **E07 — Receive:** foreground → Center/banner; background handler đúng entry point/runtime, không điều khiển UI từ isolate; background tap/cold start chờ auth ready.
- [ ] **E08 — Route safety:** allowlist routes, owner/account tồn tại, logout/not-found fallback; dedupe messageId/eventId; read/unread persist theo UID.
- [ ] **E09 — Console test:** foreground/background/tap/cold start, denied, missing target, user change. Ghi giới hạn inbox khi notification không được tap; inbox đầy đủ mọi trạng thái cần sender tạo document, không hứa Console push tự làm được.

### E3. Remote Config

- [ ] **E10 — Typed defaults:** `overview_recent_limit=3` clamp 1–10; `budget_warning_percent=80` clamp 1–100; `report_export_enabled=true` là optional. Dùng tên canonical thống nhất giữa plan, console, code và tests.
- [ ] **E11 — Behavior thật:** recent limit đổi số rows, không đổi dataset tổng; warning đổi banner; budget null/0 an toàn; export flag không dùng làm security authorization.
- [ ] **E12 — Demo publish/fetch:** Profile hiển thị effective values/source/fetch status/time và refresh; chính sách dev/prod rõ. Evidence trước/sau console publish và fallback khi fetch fail.

### E4. Crashlytics và Analytics

- [ ] **E13 — Crash hooks:** Flutter + async error hooks, redaction, handled exception và intentional crash controls chỉ cấu hình phù hợp. Không làm mất draft ngoài ý muốn.
- [ ] **E14 — Crash evidence:** restart/upload và xác nhận cả handled/nonfatal và crash có mặt trên dashboard; ghi thời gian/độ trễ thật.
- [ ] **E15 — Analytics plan:** tạo `docs/analytics-plan.md`: event/params/trigger/flow/noPII. Bao gồm login/logout/screen_view/view_account/account CRUD/archive/usage actions/select_purpose/drilldown/quota/export/notification theo behavior thực.
- [ ] **E16 — Events đúng thời điểm:** sau kết quả nghiệp vụ phù hợp, screen chỉ một nguồn; không duplicate do rebuild/retry/listeners. Không gửi work title/note/email/prompt/credential/FCM token.
- [ ] **E17 — DebugView:** thực chạy các flows, xác minh events/params trên project thật, lưu evidence đủ cho report/video.

**Điều kiện xong E:** PDF URL mở được và metadata đúng; FCM/RC/Crashlytics/Analytics đều có kết quả quan sát được, không chỉ package imports hoặc nút demo.

## 10. F — Kiểm thử, AI review và fidelity

### F1. Regression và MobAI

- [ ] **F01 — Test plan:** environment, fixture/clock/seed/reset/cleanup, expected outcomes và retry policy riêng; scripts không ngầm phụ thuộc thứ tự chạy. Thử sớm MobAI nhận thiết bị; nếu bị chặn, ghi blocker và xác nhận phương án với giảng viên.
- [ ] **F02 — Unit/VM/widget/rules:** chạy các tests trọng yếu B/C/D/E; bổ sung auth dispose, transaction races, cache/pending, upload-success/metadata-fail, notifications/RC mapping và biên thời gian theo thay đổi thật.
- [ ] **F03 — Tạo và tự review 10 scripts thật** theo bảng sau, lưu một `.mob`/scenario trong `mobai_tests/`; assertions kiểm kết quả dữ liệu, không chỉ tap/toast.

| Script | Starting state | Outcome bắt buộc kiểm |
|---|---|---|
| M01 Google login | Logged out; Google test account riêng | Overview/Profile đúng user |
| M02 Usage flow | Logged in; baseline seed | Record tồn tại sau reload, totals tăng đúng |
| M03 Analytics flow | Fixture độc lập | Filter/list/summary đúng và Back giữ context |
| M04 Account/quota flow | Không có account test | Create/detail/budget/quota/source đúng |
| M05 Error/recovery | Draft + lỗi có kiểm soát | Error thật, draft giữ, retry đúng một record |
| M06 Account CRUD | Account rỗng riêng | Create/read/edit/delete thay dữ liệu thật |
| M07 Navigation | Fixture/states đã mô tả | 4 tab/Back/state preservation; states được kích hoạt rõ |
| M08 Profile/RC | Remote values đã publish | User/effective values đúng và UI thực đổi |
| M09 PDF export | Storage khả dụng; baseline | URL mở được, report item và metadata đúng |
| M10 Logout | Logged in | Login và Back/deep link không truy cập data |

- [ ] **F04 — Full run:** clean start, bảng pass/fail từng script, logs/video/screenshots thật; ghi manual Google steps nếu có. Test thêm usage edit/delete, archive/history, A/B, stale quota, native keyboard và PDF/network errors ngoài 10 scripts khi cần.
- [ ] **F05 — Healing:** đổi label có kiểm soát → capture failure → MobAI patch/diff → đánh giá assertion vẫn kiểm đúng outcome → rerun.
- [ ] **F06 — Bug-catching:** tạm inject save-no-op → test fail vì record/tổng sai → revert defect → rerun pass. Không merge bug hoặc dựng kết quả giả.
- [ ] **F07 — Test report hoàn chỉnh:** environment/build/starting state/script results/exercises/manual limits/remaining risks. Bộ unit/widget tests local hiện hành trong test-report không thể thay phần này.

### F2. AI PR review

- [ ] **F08 — PR review:** feature branch prefix `codex/`, PR vào main, mô tả final behavior và validation thật; review code app và `firebase/firestore.rules` bằng AI tool khi chúng đã có.
- [ ] **F09 — Findings:** theo tài liệu hiện có cần ≥3 findings thật, ≥1 security/robustness; file/line/severity, tool output, accepted/modified/rejected + lý do. Không tạo findings để đủ số lượng.
- [ ] **F10 — Fix/verify:** fix accepted findings, link commit/before-after, rerun relevant checks. Tạo `docs/code-review.md`; chưa review thì không dùng architecture làm evidence thay thế.

### F3. Fidelity cuối

- [ ] **F11 — So sánh 8 màn:** Lab2 → TokenLedger annotated → app 360×800dp, thêm 412dp và loading/empty/error; ghi viewport/density/insets và mọi khác biệt có lý do.
- [ ] **F12 — Final token/component audit:** colors/fonts/spacing/radius hard-coded, 9 families/states, touch/contrast/keyboard/text scale, logo/motion; ghi ngoại lệ và hạn chế, không claim perfect match vì chỉ cùng palette.
- [ ] **F13 — Đồng bộ Figma/docs:** annotations theo app cuối, change log, gaps resolutions; hoàn thiện `docs/fidelity-check.md` đã có, link evidence truy cập được. Chỉ báo Figma đã cập nhật sau khi có thao tác thật.

**Điều kiện xong F:** regression cần thiết pass; defect thử đã revert; scripts/findings/fidelity có evidence thật và giới hạn được ghi rõ.

## 11. G — Release Android, tài liệu và hồ sơ nộp

- [ ] **G01 — Final checks:** format sạch, analyze không lỗi, unit/widget/rules/integration/MobAI checks phù hợp pass trên commit nộp. Dependency/assets thay đổi phải kiểm bundling; web build bổ sung, không thay Android.
- [ ] **G02 — APK bản nộp:** build/install trên Android, smoke login/F1/F2/F3/PDF/logout; ghi version/build/commit/device/signing scope. Giữ key/password ngoài Git và docs.
- [ ] **G03 — Fresh clone:** làm theo README trên môi trường sạch; dependencies/config/setup/rules/indexes/storage/seed/test account và limitations đủ để chạy, không phụ thuộc skills/Node/sibling Lab2.
- [ ] **G04 — Đồng bộ tài liệu cuối:** README, architecture, build-status, test-report, checklist, gaps/change log, `.agents` context phản ánh app thực. Không để final README vẫn mô tả chỉ demo local nếu backend đã hoàn tất.
- [ ] **G05 — AI log:** ít nhất 6 entries thật theo rubric đang ghi; prompt nguyên văn/output/verification/decision/lý do và tools. Hiện có12 prompt nguồn thực (entry12 Git-only); entry docs không tự được tính thay entry implementation nếu rubric không chấp nhận.
- [ ] **G06 — Report 5–10 trang:** đủ mục đề, thiết kế/kiến trúc/flows/Firebase/tests/review/gaps/AI usage/limitations; screenshots rõ, dữ liệu và kết quả thật.
- [ ] **G07 — Video 3–5 phút:** login/profile, 3 flows + recovery, CRUD/Firestore, PDF URL, FCM, RC publish/react, Crashlytics hai loại, DebugView, MobAI/healing/bug-catching/review và logout theo yêu cầu đã đối chiếu. Tua nhanh có chú thích, không che fail để giả pass.
- [ ] **G08 — Git hygiene:** inspect remote refs/staged diff/ignore/secrets trước push; giữ lockfile/source/platform/font assets cần thiết, loại build/cache/tooling/evidence local bị cấm. Không force push hoặc giả lịch sử.
- [ ] **G09 — Repo/access:** hiện dùng repo `lab3_prm`; xác nhận yêu cầu tên `PRM393_Lab03_<StudentID>` trước đổi tên. Repo được docs ghi private: giải quyết quyền người chấm đúng lúc, kiểm quyền Figma/report/video; không tự đổi visibility/mời người khác.
- [ ] **G10 — PR/commit nộp:** ít nhất một PR đã review và merge theo tài liệu đề; xử lý merge trong phạm vi được cho phép. Ghi submission commit/tag thật, xác minh remote và working tree; initial push không thay reviewed PR.
- [ ] **G11 — Oral review:** chuẩn bị giải thích một VM, một service, rules và phép tính, làm thay đổi nhỏ trực tiếp trong 5–10 phút theo yêu cầu đã xác nhận.

### Deliverables phải kiểm trước khi nộp

| Deliverable | Hiện trạng21/10 | Việc phải hoàn thiện |
|---|---|---|
| `README.md` | Có | Hướng dẫn bản cuối và scope thật |
| `docs/handoff-gaps.md` | Có | Resolution/evidence/remaining limits |
| `docs/design-change-log.md` | Có | Toàn bộ thay đổi cuối + Figma |
| `docs/implementation-ai-log.md` | Có,12 prompt nguồn thực (entry12 Git-only) | Đủ entries implementation thật hợp rubric |
| `docs/test-report.md` | Có, local tests | Firebase/Android/MobAI và exercises |
| `docs/analytics-plan.md` | Chưa có | Events/params/triggers/privacy |
| `docs/fidelity-check.md` | Có draft B08–B13 + live annotations | Final source/Figma/accessibility audit F11–F13 còn lại |
| `docs/code-review.md` | Chưa có | Findings/decisions/fixes/verification |
| `firebase/firestore.rules` và indexes | Chưa có | Implement/test/deploy đúng project |
| `mobai_tests/` với 10 `.mob` | Chưa có | Scripts chạy thật và assertions reviewed |
| APK + report 5–10 trang + video 3–5 phút | Chưa có bằng chứng hoàn tất trong docs | Tạo/kiểm/access/link submission |
| PR review/merge và submission commit | Chưa có bằng chứng trong docs | Kiểm GitHub thực và hoàn tất |

“7 tài liệu trong docs” của checklist là gaps/change log/fidelity/analytics/AI log/test report/code review; các tài liệu architecture/build-status/plan vẫn giữ vai trò bổ sung. Không dùng file roadmap này thay các deliverables đó.

**Điều kiện hoàn thành app/Lab3:** toàn bộ yêu cầu bắt buộc đã xác nhận có implementation và evidence trên bản Android cuối; hồ sơ truy cập được; các mục còn thiếu được giải quyết hoặc có chấp thuận ngoại lệ rõ ràng. Không tự chấm điểm rubric dựa trên số màn hoặc số checkbox.

## 12. P1/P2 — Để sau P0, không làm chậm bản hoàn thành

| Mức | Công việc tùy chọn | Điều kiện trước khi làm |
|---|---|---|
| P1 | CSV template/preview/mapping/validation, size/row limits, dedupe/idempotency, partial retry và batch rollback | P0 ổn định; không double count snapshot và usage |
| P1 | Work templates, so sánh theo purpose/cùng kỳ, outcome do user xác nhận, forecast/alerts có nhãn ước tính | Có sample/coverage/source đủ; không suy năng lực từ tên model |
| P1 | VND/currency/FX snapshots | Thiết kế currency riêng, rounding/conversion tests; không cộng USD/VND trực tiếp |
| P2 | Claude/Codex/provider API sync | Capability matrix theo product/plan/scope/metrics/reset/delay, docs chính thức hiện hành và quyền truy cập hợp lệ |
| P2 | Trusted backend/secret manager, consent/revoke, sync cursor/backfill/rate limits/reconciliation | Chốt bảo mật/chi phí/phạm vi; không để secrets trong APK/Firestore client-readable |
| P2 | Scheduled push/inbox đầy đủ, private authenticated reports | Trusted sender/storage delivery thật; không dùng server key client hoặc unsigned URL làm private access |

Google login TokenLedger không tự cấp quyền đọc Claude/Codex. Đồng bộ provider không phải điều kiện để hoàn thành bản manual P0 đã đề xuất.

## 13. Lệnh kiểm tra khi triển khai

Chạy đúng phạm vi thay đổi; lượt tạo roadmap chỉ thay docs nên không cần build Flutter mới.

```sh
flutter doctor -v
flutter devices
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
flutter build web --release
flutter build apk --debug
```

Rules emulator, integration và MobAI commands bổ sung sau khi có cấu hình thật; không ghi lệnh giả chưa tồn tại. Lưu summary kết quả/môi trường/commit; build outputs không commit.

## 14. Bảng theo dõi hoàn thành

Trạng thái dưới đây gồm tiến độ cập nhật21/10; các bằng chứng local nằm trong test-report, không thay việc nghiệm thu các giai đoạn tích hợp.

| Giai đoạn | Trạng thái hiện hành | Commit | Verification/evidence | Ngày/môi trường |
|---|---|---|---|---|
| A — Scope và trạng thái docs | A03–A06 hoàn tất kỹ thuật; A01/A02/A07 pending | Chưa commit | [Scope decisions](scope-decisions.md), checklist/gaps/context đồng bộ |21/10/2026, docs/source audit |
| B — Local polish/Android | B01–B14 đạt local/annotation scope; native hoãn theo user | Chưa commit | test-report;168 tests/web build, Figma233:3 |21/10/2026, Windows/Flutter |
| C — Auth/data/rules | Chờ yêu cầu tiếp tục Firebase | — | — | — |
| D — 3 flows backend | Local SD01–SD05/SD08 đã mở rộng; chờ C/backend verification | — | — | — |
| E — Services/PDF | Chưa tích hợp | — | — | — |
| F — Tests/review/fidelity | Có local tests; thiếu integration/MobAI/review/fidelity đầy đủ | — | — | — |
| G — Android release/submission | Chưa đủ điều kiện | — | — | — |

Ưu tiên tiếp theo khi Firebase vẫn pending: **A01/A02/A07 / các phần F-G không phụ thuộc Firebase (B01–B14 đã có local/annotation verification; B15/B16 native hoãn)**, đồng thời chuẩn bị mapping/Figma/accessibility và test cases. Khi Firebase được yêu cầu tiếp tục: **C → D → E → F → G**; ghi docs/evidence ngay trong từng bước.

### Lịch sử tiến độ 21/10/2026 — local form safety

B01/B02 đã có implementation và widget verification: ba form bảo vệ draft/Back, block khi saving, lỗi lưu có feedback và retry; usage/account giữ ID ổn định. B14 đã kiểm doctor/devices thực: Android SDK/licenses hợp lệ, chưa có thiết bị vật lý. B04 đã sửa archived usage edit và có VM/widget tests; full history/detail/delete audit vẫn cần nên chưa tick toàn mục. B10 mới có layout/keyboard simulated tests, chưa tương đương full native accessibility/fidelity.

Validation: analyzer sạch, full38/38 unit/widget tests pass. Xem test-report cho APK/emulator results và giới hạn sau cùng. Không tick B15/B16 hoặc gate Android chỉ vì doctor/tests pass. Firebase tiếp tục pending; chưa commit/push.

B16 đã build debug APK thành công21/10; install/smoke vẫn chưa đạt vì AVD gốc lỗi SettingsProvider và AVD QA vẫn ADB offline. B15/B16 giữ chưa tick cho đến khi chạy trên Android được. Đã xem ảnh render widget360×800 với font thật, không dùng ảnh đó làm native evidence. Branch `codex/local-form-safety`; chưa commit/push.


### Hoàn tất và rà soát B03–B07 — 21/10/2026

Đã rà lại từng yêu cầu và bổ sung code/tests trước khi tick. Scope là local demo theo kiến trúc hiện có; không bắt đầu Firebase hoặc provider sync.

| Mục | Code/kết quả cuối | Evidence kiểm chứng |
|---|---|---|
| B03 | LedgerValidation dùng chung form/VM/repository; độ dài Unicode, required/enums, token cặp/0/null, USD micros/bounds, date/quota validation; không bypass qua saveAccount | ledger_stability_test.dart:24 tests; local_repository_test.dart kiểm payload/schema sai; form safety regression |
| B04 | Nút sửa phiên archived có trong detail sheet; xem/sửa/xóa lịch sử, hủy delete, chặn new usage/accountId move/hard delete khi còn lịch sử; restore mở lại new usage | local_flows_test.dart chạy đầy đủ tại360/412dp; VM tests và totals cost/token sau delete |
| B05 | Storage mở lazy để init error hiện được UI; typed errors/Retry; load không seed đè blob lỗi; explicit recovery có confirmation và backup raw trước replace, lỗi backup/replace giữ error | local_repository_test.dart:27 tests; recovery UI Retry/cancel/confirm/failure/retry trong local_flows_test.dart |
| B06 | UUIDv4 Random.secure; form giữ operation ID; guard overlapping mutations, reload chờ write, mounted/epoch guard khi dispose/rebuild | fixed/backward clock và2 VM với2000 IDs; pending/retry/idempotency/dispose/reload tests; double tap và forced route removal UI |
| B07 | nowProvider reactive, một timer tới phút/reset gần nhất; pause/resume và dispose; projections/UTC-local/date labels/formatters dùng cùng lịch thiết bị; quota stale không tự reset, không ghi lại seed | live_clock_test.dart:10 tests, calculator8; biên năm/tháng/ngày nhuận, UTC chart+history+edit, budget null/0/overrun, exact reset và lifecycle |

Các chỗ thiếu phát hiện và đã sửa khi rà: Edit action archived bị ẩn; lỗi mở plugin trước runApp; saveAccount có thể bypass quota-time validation; reporting providers giữ timer khi không còn màn; UTC date/year trong history/form có thể khác kỳ tổng hợp; Unicode length và micros round trip chưa nhất quán. Các sửa này đã có regression tests.

Verification cuối: pub get thành công (characters1.4.1 chuyển từ transitive sang direct, không nâng version); format38 files không đổi; analyzer No issues found; full106/106 tests pass; web release JS build pass với `--no-wasm-dry-run`. Web server localhost phản hồiHTTP200/có bootstrap. Không có Chrome/IAB điều khiển được trong phiên, nên không claim browser interaction/console audit. Đã xem ảnh render recovery360/412dp bằng Inter/MaterialIcons thật, artifacts local ignored.

Giới hạn giữ nguyên: snapshot repository chưa xử lý ghi từ nhiều cửa sổ/thiết bị; backup recovery là1 bản raw local, chưa có restore/import UI; timezone thiết bị/tháng dương lịch, chưa IANA/custom cycle; Firebase pending. Theo yêu cầu người dùng, **không chạy/tạo/sửa emulator**; native verification hoãn, không còn là blocker cần xử lý ở lượt này. B08–B13 và các gates backend/submission vẫn chưa hoàn tất.


### Hoàn tất và rà lại B08–B10 —21/10/2026

| Mục | Kết quả local | Bằng chứng / giới hạn |
|---|---|---|
| B08 | Audit mapping8 màn Lab2 và Login/Profile/Usage sheet/Quota; Notifications/Reports chưa implement do Firebase/PDF pending, không thêm trang giả | fidelity-check.md có mapping/core UI/khác biệt;12 màn + sheet trong UI tests/ảnh Flutter. Chưa so pixel8 ảnh gốc hoặc annotate Figma; F11–F13 giữ pending |
| B09 |9 component families/states, Material themes min48/CTA52, SaveButton/LoadingFeedback dùng chung, gallery QA trong tests | component_audit_test.dart:6 cases360/412×scale1/1.3/2, pressed/focus/filled/disabled/loading/dialog/selection/empty/error; không thêm route gallery vào app |
| B10 |4 viewport×3 scales×2 datasets, keyboard/SafeArea3 form, long names/max money/token, scroll/CTA/title bounds | ui_audit_test.dart:30 cases,288 screen instances +24 usage sheets +18 form keyboard scenarios; ảnh thật Inter/MaterialIcons. Flutter engine simulated insets, không Android/browser evidence |

Rà lại đã sửa chart overflow, desktop sidebar, long legend/usage rows, donut caption, appbar clipping/font rounding và helper/error clipping; account list tái sử dụng budget projection. Không giảm text scaling để giấu lỗi. Palette/Inter/radius/core navigation Lab2 giữ nguyên. Xem fidelity-check/test-report/design-change-log cho chi tiết và giới hạn nguồn.

Final full suite142/142 pass, format40 files không đổi và analyzer sạch. B11–B13 là phần local tiếp theo; native hoãn theo user, Firebase vẫn pending. Không dùng subagent, không commit/push.


### Hoàn tất và rà B11–B13 —21/10/2026

| Mục | Implementation / kết quả | Evidence và giới hạn |
|---|---|---|
| B11 | ActionSurface semantics/min48/Tab+Enter/focus outline, chart date/USD/final values, outline/text contrast; reduced routes/dialog/sheet/busy/data motion, giữ IndexedStack/filter/scroll; ExcludeFocus khi saving | accessibility_states_test.dart: contrast pairs và3 Flutter guidelines trên Purpose/4 tab360/412, keyboard/selected/focus, dynamic disableAnimations, static busy không nói phần trăm giả. Chưa native TalkBack/IME |
| B12 | ledgerFeedback ở shell routes/forms/sheet; cold load/error/Retry không requireValue crash, search/draft giữ; not-found account/session, disabled controls; confirmed mutation guard và Profile busy/leave guard | Reload errors5 screens/forms, dirty Back khi error, removed session, empty/missing/Google disabled, reset/clear cancel/fail/retry/pending/success360/412, double confirmation/failure/dispose; regression trước vẫn giữ |
| B13 | Đã xem8 live final360, annotate8 original frames; tạo16 cards trên trang07 gồm8 mapping,4 màn bổ sung,2 pending và2 notes; brand SVG/painter/launcher geometry/initials audit | Figma original59:2…59:279; page233:2/board233:3 screenshot kiểm thật, link từng node ở fidelity-check.md. Brand3 tests; giữ Lab2. Chưa có bộ mockup TokenLedger hoàn chỉnh/final F11–F13 |

Rà thiếu đã sửa thêm: icon/row không có role/focus, outline button contrast yếu, RangePicker chữ mảnh không đạt pixel guideline, retry trông enabled khi busy, keyboard vẫn focus trong form saving, cold usage route đọc state chưa sẵn sàng, route reload error mất form/search controls, nguy cơ resurrect phiên đã xóa, double confirmation và dispose sau await. Busy indicator tĩnh chỉ là hình phản hồi, semantics không công bố50% tiến độ không biết.

Core Lab2/Riverpod/integer USD/null/archived history không đổi. Không thêm backend/provider sync/route QA, không chạy emulator, không delegate/commit/push. Native verification hoãn theo user; Firebase pending. B01–B14 đạt scope local/annotation; F11–F13 và các gates backend/submission không tự tick theo kết quả này. Kết quả final ở test-report; fidelity-check chứa links Figma thật.

B11–B13 verification cuối:168/168 tests pass (26 mới), analyzer sạch, format43 files0 changed, web JS release build pass51.4s. Local links0 thiếu,93 task IDs không trùng, diff sạch. Xem test-report/fidelity-check cho scope và giới hạn.

### Hoàn tất P0 local sau A04 —21/10/2026

SD01–SD05 và phần analytics/history local SD08 đã code/audit theo local-p0-upgrade.md. Final200 tests pass/analyzer/format/web JS build đạt, chi tiết test-report. Giữ C/D/E backend và F/G full acceptance pending; không tự tick Firebase/Auth/MobAI/native hoặc final fidelity. A01/A02/A07 còn việc ngoài phạm vi lượt code; không emulator, commit/push.
