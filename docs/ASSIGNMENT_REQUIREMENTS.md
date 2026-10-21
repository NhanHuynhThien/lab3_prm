# TokenLedger — Yêu cầu và công việc còn lại: Lab3 + Final

## Analytics/Remote Config và manual web checks —21/10/2026

Người dùng xác nhận toàn bộ đợt manual web1–7 đạt: account edit/budget, usage totals/purpose drilldown, unknown data, validation/Back draft, archive/restore/history guard, empty-account delete, multi-quota/bounds; trước đó đã xác nhận reload/A-B isolation và offline/Retry. Đây là user-reported web evidence, không phải Android/ARTEMIS/concurrency stress hoặc console do agent kiểm.

Đã thêm Analytics13.0.0 và RemoteConfig7.0.0, typed/noPII event allowlist, UID-serialized lifecycle/dedupe/success-only cloud mutations và tab/account/usage detail events; demo no-op. Remote Config defaults overview_recent_limit3/budget_warning_percent80, parse/clamp/cache/fallback/retry/single-flight; dashboard recent rows/warning thực thay đổi qua projections, không cắt dataset hoặc đổi tiền/token. Profile có effective values/source/check time/refresh và Analytics SDK status; Crashlytics vẫn chưa nối. Đọc [plan Analytics](analytics-plan.md) và [implementation/manual guide](analytics-remote-config.md).

Verification cuối xem test-report; không coi SDK state hoặc fake tests là DebugView/console evidence. Remote Config publish→app before-after, DebugView mỗi event, Android/ARTEMIS vẫn pending; PDF export/upload events chỉ planned. FCM/Crash/PDF và Final modules chưa làm. Không Android emulator/billing/deploy hoặc push trong lượt này. Các câu SDK Analytics/RC còn pending ở checkpoint dưới đây đã được cập nhật implementation mới; giữ history/results đúng thời điểm.


Cập nhật 21/10/2026 sau khi đọc đủ hai đề mới và người dùng xác nhận: **giảng viên đã chấp thuận đổi StudentPay sang TokenLedger**. Đây là xác nhận do người dùng cung cấp trong hội thoại, không phải biên bản/phản hồi trực tiếp do agent thu thập. Không tiếp tục để việc duyệt chủ đề thành blocker; không suy rộng thành duyệt vai trò Final, miễn Storage hoặc miễn kiểm thử.

## 1. Nguồn, thứ tự ưu tiên và trạng thái

- **L3:** `PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf`, nội dung đề ngày 21/10/2026, **18 trang**. Tên file/footer còn Patrol; nội dung mục 7 và rubric yêu cầu **Google ARTEMIS**.
- **FA:** `PRM393 - Final Assignment One Complete System on Firebase.pdf`, ngày 21/10/2026, **9 trang**.
- Hai PDF được người dùng cung cấp ngoài repo. Không copy chúng hoặc text/ảnh trích xuất vào source. Số trang dưới đây là trang PDF, không phải mục tài liệu.
- File này là baseline yêu cầu hiện hành, ưu tiên hơn ngưỡng MobAI/Cloudinary/3 findings/report 5–10 trang/video 3–5 phút trong plan cũ. Không áp dụng ngưỡng Final để giảm yêu cầu bài Lab3 riêng.
- [Roadmap](APP_COMPLETION_ROADMAP.md) giữ IDs A–G và thứ tự công việc; [checklist](TASK_CHECKLIST.md) giữ IDs kỹ thuật; file này bổ sung yêu cầu mới với IDs `REQ-*` và `FIN-*`. Khi một yêu cầu trùng backlog cũ, cùng dùng một implementation/evidence, không làm hai lần.
- `[x]` chỉ xác nhận phạm vi ghi ngay trong mục. `[ ]` là còn việc hoặc chưa có evidence đủ, kể cả đã có code một phần. Trạng thái này không phải tự chấm điểm.

### Baseline implementation đã có

Source trên main tại `484cc41445710ef6f5c574c6efcd1ba6b20030e3`: MVVM/Riverpod; theme/components Lab2; account/usage/quota/budget/reporting; Google Auth và guard/Profile; cloud workspace 4 tab, owner streams/transactions/revisions/retry/lifecycle; rules và 5 indexes đã deploy. Người dùng xác nhận Google web login/reload/logout/Users; manual Firestore CRUD/A-B và native còn chờ.

Verification trước lượt cập nhật docs: **299 Flutter tests**, **142 Rules Test API cases**, analyze/format/web release đã pass; 5 indexes READY theo [test report](test-report.md). Đây không phải ARTEMIS, Emulator rules tests, Android acceptance hoặc bằng chứng console của các dịch vụ chưa tích hợp. Lượt docs này không chạy lại runtime tests/build/deploy.

### Những điểm cần quyết định, không tự suy đoán

- [x] REQ-SCOPE-01 Chủ đề TokenLedger được giảng viên chấp thuận, theo xác nhận người dùng 21/10. Giữ core UI Lab2 và cập nhật traceability/Figma; chấp thuận chủ đề không tự nghiệm thu UI/flows.
- [x] REQ-SCOPE-02 Đã đối chiếu đủ 18 trang L3 và 9 trang FA; checklist mới bao phủ yêu cầu, rubric, phụ lục, evidence và submission.
- [ ] REQ-SCOPE-03 Chốt StudentID, cá nhân/nhóm (L3 mặc định cá nhân trừ thông báo khác), deadline, số commits/ngày còn placeholder `[N]`, URL và quyền truy cập nơi nộp. Không tạo lịch sử/backdate để đáp ứng số ngày.
- [ ] REQ-SCOPE-04 Xác nhận khác biệt **L3 upload Cloud Storage** (tr. 3, 6) với **FA loại Cloud Storage, PDF lưu/chia sẻ trên thiết bị, metadata Firestore** (tr. 3). Khi chưa có miễn trừ, giữ hai yêu cầu riêng; Cloudinary không tự được tính thay Storage. Không bật billing hoặc dịch vụ để giải quyết quyết định này trong lượt docs.
- [ ] REQ-SCOPE-05 Thống nhất vai trò web Final với giảng viên vì Lab2/TokenLedger hiện một vai trò. Admin/Staff/entity duyệt phải có ý nghĩa trong cùng chủ đề. Ý tưởng purpose/model catalog + yêu cầu bổ sung/duyệt chỉ là đề xuất, chưa được duyệt/implement.
- [ ] REQ-SCOPE-06 Chốt môi trường evidence nhẹ: ARTEMIS dùng **điện thoại Android thật**, không chạy/tạo/sửa máy ảo Android theo yêu cầu người dùng. Final yêu cầu Firebase Emulator rules tests (khác Android emulator); chưa khởi động loại emulator nào. Bố trí máy khác/CI hoặc xác nhận môi trường với người dùng trước khi chạy. Nếu tool/service không dùng được, báo giảng viên trước khi thay thế; lưu phê duyệt và vẫn đáp ứng evidence.

## 2. Lab3 — sản phẩm, thiết kế và kiến trúc

Nguồn: L3 mục 1–5, tr. 1–6; rubric tr. 12–14.

- [ ] REQ-L3-01 Hoàn tất mọi màn Final UI Lab2, **ít nhất 8 màn**, và **3 flows end to end**: F1 ghi usage, F2 phân tích/drilldown, F3 account/quota theo mapping TokenLedger; có alternative/error/recovery, Back và nội dung đúng screen spec. Kiểm backend thật, không chỉ local fixtures.
- [ ] REQ-L3-02 Giữ top-level destinations/nesting Lab2; Sign-in/Profile cùng design system; auth guard/deep links/cold start/Back không lộ dữ liệu user cũ. Bổ sung notifications/reports theo tích hợp, không dựng trang giả để đủ số màn.
- [ ] REQ-L3-03 Dữ liệu bản nộp lấy Firestore thật cho dữ liệu cá nhân. Không dùng seed/mock/hard-coded runtime content để chứng minh tính năng. Giới hạn demo local vào cấu hình phát triển; bản nộp không có đường mở seed demo. Tests được dùng fixture có nhãn, không trình bày fixture thành evidence production.
- [ ] REQ-L3-04 Mọi data-loading screen có loading/empty/error/data rõ ràng do VM sở hữu; error/permission/network/cancel có message và Retry phù hợp, không spinner vô hạn; giữ draft/filter và không báo saved trước persistence.
- [ ] REQ-L3-05 Tạo `docs/design-traceability.md`: persona/success criterion; từng screen/flow step/component Lab2 → Flutter route/widget/data source/status/evidence. Hợp nhất mapping từ [fidelity](fidelity-check.md), [change log](design-change-log.md), [Lab2 reference](lab2-ui-reference.md); không coi các file cũ là tự thay deliverable bắt buộc.
- [ ] REQ-L3-06 Ghi mọi khác biệt Figma/app và lý do platform/accessibility/API/scope được duyệt; cập nhật live Figma theo Auth/cloud/notifications/reports cuối. Annotations/mockups cũ không tự chứng minh đồng bộ source mới.
- [ ] REQ-L3-07 Rà MVVM toàn app: dependency chỉ đi xuống; widget không gọi HTTP/Firebase/SDK; filtering/aggregation/validation nằm VM/service; service inject để fake được; không global mutable state.
- [ ] REQ-L3-08 Hoàn thiện `docs/architecture.md` đúng source cloud: folder structure có mô tả từng folder, layer diagram, **sequence diagram một flow đầy đủ**, bảng mỗi VM và services nó dùng; giải thích khác suggested folder structure nếu có. Không chỉ thêm header mới trên phần body local đã lỗi thời.
- [ ] REQ-L3-09 Rà tokens tập trung `lib/theme/`: ColorScheme/TextTheme/spacing/radius/elevation named constants. Thay hard-coded styling/padding ở screens bằng tokens; giữ ngoại lệ có lý do rõ, không dùng ngoại lệ chung để bỏ gate đề.
- [ ] REQ-L3-10 Mỗi component Lab2 có reusable widget hoặc abstraction dùng chung, variants/states bằng parameters; 9 families button/textfield/card/navigation/appbar/dialog/loading/empty/error; không copy one-off giữa screens.
- [ ] REQ-L3-11 Nghiệm thu contrast, targets ≥48dp, body ≥14sp, không truyền nghĩa chỉ bằng màu, 360/412dp, feedback mọi action; thêm kiểm keyboard/large text/reduced motion/long data đã có. Semantics cho buttons/list items/charts; chứng minh Android thật, không thay bằng Flutter render.
- [ ] REQ-L3-12 Pin version tái lập cho Flutter/dependencies/tooling trong pubspec/lock và README; FlutterFire, ARTEMIS commit và AI review tool version/config phải ghi lúc thực dùng. Không invent phiên bản chưa chạy.

## 3. Lab3 — Firebase, PDF và evidence từng dịch vụ

Nguồn: L3 mục 6, tr. 6–8, rubric tr. 13. Sáu dịch vụ bắt buộc là Auth, Cloud Storage, FCM, Analytics, Crashlytics, Remote Config; Firestore còn cần cho dữ liệu cá nhân của TokenLedger. Không đếm Firestore thay dịch vụ còn thiếu.

### Authentication và Firestore hiện có cần nghiệm thu

- [ ] REQ-L3-13 Google success/cancel/error, auth-state routing, Profile identity, sign-out clear user-local state/draft/listeners và token binding; screenshot signed-in/out và Auth Users console đúng project. Web đã được người dùng xác nhận; Android/native account picker và release certificate vẫn cần kiểm.
- [ ] REQ-L3-14 Manual SDK CRUD/reload/realtime trên Firestore đã deploy; user A/B không đọc/ghi hoặc thấy state nhau; account/usage/quota/settings/counters/receipts, archive/edit/delete/concurrent retry và permission/network failure. Lưu environment/commit/results, không đọc/ghi user docs giả làm evidence trong lượt docs.
- [ ] REQ-L3-15 Chụp evidence rules/index readiness/data với project ID khớp google-services.json, che dữ liệu cá nhân/credentials; Rules API simulations không thay network/native acceptance. Giữ rules deny-by-default/owner/schema hiện có.

### Sinh PDF và Cloud Storage cho mốc Lab3

- [ ] REQ-L3-16 Sinh ít nhất **1 file thật** phản ánh filter/dataset đang xem: kỳ, account/purpose/provider, cost/token/unknown coverage/source; snapshot nhất quán, USD micros, tiếng Việt/font/multi-page/empty/large data; export error không mất UI state.
- [ ] REQ-L3-17 Sau khi xử lý REQ-SCOPE-04, implement L3 Storage dưới `reports/{uid}/...`, upload progress, success URL/open action; failure/retry/cancel/timeout có feedback. Save metadata Firestore/retry cùng export ID, tránh duplicate upload/ready giả.
- [ ] REQ-L3-18 `firebase/storage.rules` owner-only read/write theo folder; kiểm user khác/unauth denied, MIME/size constraints theo thiết kế; lưu console file list và mở file thật trên Android. URL delivery/access phải đúng policy đã công bố.

### FCM và notification center

- [ ] REQ-L3-19 Permission Android13+, denied/retry UX, token refresh và UID/device binding, logout/unbind/user-switch; không gửi server credentials trong app.
- [ ] REQ-L3-20 Receive và evidence Console test message ở **foreground, background, terminated**; handler đúng runtime; không giả tin nhận bằng seed.
- [ ] REQ-L3-21 Danh sách received notifications trong app, read/unread/dedupe/persistence theo UID; tap notification/shade/center mở đúng màn sau auth-ready, kiểm owner/missing target/fallback. Ghi giới hạn delivery/inbox trung thực.

### Analytics

- [x] REQ-L3-22 **Plan đã viết trước tracking code**, đã có `docs/analytics-plan.md` theo Appendix A: ≥7 events bao phủ login/logout, primary action/search, mỗi loại detail, export và upload; map flow step/success criterion/drop-off, trigger, typed parameters, product question từng event; recommended names nếu phù hợp, custom snake_case.
- [ ] REQ-L3-23 AnalyticsService injected; set user ID sau login/clear khi logout; không names/emails/raw work titles/notes hoặc thông tin cá nhân trong params; log sau outcome phù hợp, tránh duplicate vì rebuild/retry. Primary action ở đây là ghi usage, không phải suy ra provider sync.
- [ ] REQ-L3-24 DebugView thấy **mọi event và parameters** theo plan, evidence đúng project. Ít nhất **1 ARTEMIS test** kiểm analytics event qua Logcat hoặc DebugView, không chỉ assert UI.

### Crashlytics và Remote Config

- [ ] REQ-L3-25 Flutter/async hooks qua service; **1 handled non-fatal từ error path thật + 1 test crash**, attach user ID/ít nhất 1 custom key, clear identity khi logout, không log PII/secrets. Dashboard evidence cả hai với keys; demo controls có chủ đích, không mất draft.
- [ ] REQ-L3-26 **≥2 Remote Config parameters đổi visible behaviour**, in-app defaults/typed parsing/clamp/fetch failure. Dự kiến recent_limit và budget_warning_percent; không cắt dataset tính tổng và không chỉ in giá trị ra màn hình.
- [ ] REQ-L3-27 Profile/demo area có notification center, export/upload, RC effective values/refresh và Crashlytics actions; console đổi RC → app thay đổi **không rebuild**, ảnh before/after + console values, ghi fetch policy và môi trường.

## 4. Lab3 — ARTEMIS E2E và AI review

Nguồn: L3 mục 7–8, tr. 8–10, Appendix B/C tr. 17–18.

- [ ] REQ-L3-28 Chuẩn bị Python3.12+/uv/ADB, multimodal model API key bằng env, ARTEMIS commit pin và điện thoại test; dedicated Google test account, không dùng tài khoản cá nhân. Flash cho regression, Pro chỉ exploratory. Secrets không nằm repo/trace/video.
- [ ] REQ-L3-29 `docs/test-plan.md`: ≥10 cases, mỗi case có ID/flow/screens/precondition/natural-language instruction/expected visible result/type; coverage cả 3 flows và nhánh alternative/error, login, primary action, **mọi tab và loại detail**, export/upload, RC, logout.
- [ ] REQ-L3-30 `e2e_test/conftest.py`, `pyproject.toml`, pytest functions nhóm auth/usage/accounts/analytics/details/export/profile; mỗi case gọi ArtemisClient với starting point/steps/kết quả xác minh cụ thể. Không dựng `.mob`, không dùng Patrol/MobAI tự thay tool yêu cầu.
- [ ] REQ-L3-31 Assert status **và structured reported values** so expected (tổng, record, RC, URL...); không SUCCESS-only. Test độc lập, starting state/cleanup riêng, semantics hữu ích; fixtures phải tạo dữ liệu test thật có kiểm soát và không chứa personal data.
- [ ] REQ-L3-32 ≥1 error-path case và ≥1 native interaction (Google picker/notification permission/shade); test analytics theo REQ-L3-24. Manual step hoặc skipped case phải báo rõ, không tự tính thành automated pass.
- [ ] REQ-L3-33 Mỗi case chạy **≥3 lần**, report runs/pass rate/average time. Không đạt3/3 là flaky: phân biệt app/timing/instruction, ghi fix và rerun. Giữ command/trace ID/screenshots hoặc replay từng run và giải thích mọi failed/flaky/skipped.
- [ ] REQ-L3-34 **1 exploratory Pro session 15–30 phút, unscripted**, lưu issues/result thật và triage/fixes; không dựng findings hoặc chẻ session giả để đủ số.
- [ ] REQ-L3-35 AI review bằng ≥1 tool (ví dụ Copilot/CodeRabbit/Sonar/Kodus) trên **PR trước submission**, lưu raw output; app/rules/error/lifecycle đều trong phạm vi review phù hợp. PR#1 merged trước đây chưa phải evidence AI review cloud mới.
- [ ] REQ-L3-36 `docs/code-review.md`: **≥5 findings thật**, file:line, ≥2 kinds trong bug/security/architecture/performance/test gap/maintainability; mỗi finding accepted/modified/rejected + lý do gắn requirement/section5/measurable effect/constraint, không “AI nói vậy”.
- [ ] REQ-L3-37 Fix **≥3 accepted findings, mỗi finding một commit riêng có finding ID**, link commit/verification. Không gộp thành commit cũ hoặc bịa issue cho đủ; disclosure mọi AI tool/code generator/chat/slide assistant và purpose.

## 5. Lab3 — bàn giao, rubric và điều kiện đóng

Nguồn: L3 mục 9–11, tr. 10–16.

- [ ] REQ-L3-38 Repo `PRM393_Lab03_<StudentID>` khi chốt ID; gồm lib/android (google-services.json được commit)/firebase/docs/e2e_test/evidence/report/slides. Không tự rename remote/đổi visibility trong lượt cập nhật tài liệu.
- [ ] REQ-L3-39 Required docs: design-traceability, architecture, analytics-plan, test-plan, code-review; `firebase/storage.rules`, `firebase/remote-config-defaults.json`, E2E conftest/pyproject/tests. Firestore rules/indexes tiếp tục giữ vì app dùng Firestore. Chỉ đánh xong khi nội dung/evidence đủ, không tạo placeholder rồi tick.
- [ ] REQ-L3-40 README: topic/persona/API hoặc Firestore source, run app/tests/config, pinned versions, ARTEMIS commit, AI tools/purpose, deliverable map, demo video URL; fresh clone/build/install APK trên điện thoại từ submission commit, no mock runtime.
- [ ] REQ-L3-41 **Report 8–12 trang**, `report/Lab03_<StudentID>.pdf`: overview/Lab2 persona-flows-success criterion; traceability/deviations; architecture/MVVM/design system; từng Firebase service và failure; analytics plan/DebugView; Crash/RC; ARTEMIS plan/results/exploration; AI findings/decisions; challenges/lessons/AI disclosure. Mọi “works” claim có screenshot/link evidence.
- [ ] REQ-L3-42 **Slides 12–15, PDF**, `slides/Lab03_<StudentID>_slides.pdf`: topic/persona/success criterion, Figma vs app/deviations, layer diagram, tokens→theme/components→widgets; mỗi Firebase service/failure, analytics/DebugView, Crash/RC, tests/pass rate, review/fixes, challenges/lessons. Link docs thay chép nguyên; AI slide tools disclosed, readable/one message per slide.
- [ ] REQ-L3-43 **Video 5–10 phút**, live trên thiết bị theo test-plan: sign-in, 3 flows/error paths, export/upload, push, RC change không rebuild, Crash demo, ARTEMIS device test run, 1 review finding/fix; console khi chứng minh kết quả, narration rõ, không edited-in pass.
- [ ] REQ-L3-44 Evidence chọn lọc trong root `evidence/`, report link tới file/commit/env/time/project thật; che PII/secrets, không commit cache/inspector/bulk PDF nguồn. Quy định ignore cũ ở assets/evidence không cấm required root evidence; rà file trước khi publish.
- [ ] REQ-L3-45 Kiểm repo/report/slides/video và Figma/evidence dependencies mở được ở private browser cho người chấm đúng deadline. Repo private cần quyền hợp lệ; không tự đổi public hoặc mời ai. Inaccessible criteria chịu zero/late policy theo đề.
- [ ] REQ-L3-46 History stage Plan→Architect→Integrate→Instrument→Test→Review→Report theo tiến trình thật, `[N]` chốt với giảng viên; evidence Firebase project khớp client config. Không backdate/rewrite để chữa history; không claim prompt count/merged PR thay findings.
- [ ] REQ-L3-47 Chuẩn bị review khoảng **5 phút**: chạy 1 ARTEMIS test, đổi 1 RC live, giải thích 1 VM/1 code-review decision; hiểu code đã nộp, disclosure AI, không fabricated evidence/results.

### Mapping điểm để kiểm coverage, không tự chấm

| L3 rubric | Điểm | Yêu cầu kiểm |
|---|---:|---|
| Functional | 2.5 | Flows/navigation1.0, real data/file0.75, states/errors0.75 |
| Firebase/Analytics | 2.0 | Auth0.25, Storage0.25, FCM0.5, Analytics0.5, Crash0.25, RC0.25 |
| Architecture | 0.75 | Layering0.5, state/injection0.25 |
| UI/UX | 0.75 | Fidelity0.5, accessibility0.25 |
| ARTEMIS | 1.5 | Plan/coverage0.5, quality0.5, execution evidence0.5 |
| AI review | 0.5 | Findings/decisions0.25, fixes0.25 |
| Slides/video | 2.0 | Slides1.0, video1.0 |

Product6 + process4 =10. Report bắt buộc, không chấm riêng nhưng thiếu evidence làm criterion không đạt. Không dùng bảng100 điểm của plan cũ để kết luận điểm bài mới.

## 6. Final — scope hệ thống, vai trò và kiến trúc

Nguồn: FA mục 1–6, tr. 1–4. Đây là P0 của Final, không phải P1 tùy chọn của Lab3; chưa implement và chưa được coi là được user yêu cầu code trong lượt docs.

- [ ] FIN-01 `docs/gap-review.md`: map mọi gap Lab2/Lab3 với resolution/commit/evidence/pending; hoàn tất mobile Lab2 và Lab3, đóng review findings thật. Tránh thêm tính năng mới ngoài mục tiêu vì đề không thưởng feature thêm và trừ unfinished flows.
- [ ] FIN-02 Chốt vai trò theo REQ-SCOPE-05, giữ TokenLedger cùng topic; dựng ít nhất 1 flow mobile user gửi pending → staff/admin web approve/reject có reason → mobile cập nhật realtime/inbox. Không cấp staff quyền đọc ledger cá nhân mặc định.
- [ ] FIN-03 Tổ chức `mobile/`, `web/`, **`packages/core/`**: shared Dart models/Firestore services và theme/widgets dùng chung; MVVM/Riverpod cả hai clients, cùng một Firebase backend. `web/` hiện là scaffold Flutter preview, chưa phải admin project.
- [ ] FIN-04 No custom server; chỉ services trong sơ đồ FA: Auth/Firestore/AI Logic/App Check/Remote Config/Hosting/Analytics/FCM/Crashlytics mobile. **Cloud Functions, Cloud Storage, App Hosting, Cloud Run ngoài scope Final**. Không Cloudinary/custom proxy thay kiến trúc đề; PDF save/share device + metadata Firestore.
- [ ] FIN-05 `docs/data-model.md` theo Appendix A: từng collection/field/type/validation, C/R/U/D per role, screens dùng, status transitions per role, indexes/aggregation design; migration từ UID subcollections hiện có phải giữ lịch sử/privacy.
- [ ] FIN-06 `users/{uid}.role`; first sign-in chỉ user, **first Admin đặt console và named trong README**. Chỉ Admin đổi roles, **không ai đổi role của chính mình** kể cả qua UI/API; test bypass/escalation/stale sessions. Client mobile/web reject account sai role bằng message rõ.
- [ ] FIN-07 Rules deny by default, no `if true`; validate shapes/immutable fields/status transitions/cross-role ownership; bổ sung announcements/review/shared entities, không mở toàn bộ user ledgers. Role change/logout dispose subscriptions/state đúng client.
- [ ] FIN-08 **App Check trên Firestore và AI Logic**, tách debug/release configuration không commit debug token; verify requests/enforcement/failure UX, không chỉ thêm dependency. Không tự bật enforcement trước khi test client hợp lệ.
- [ ] FIN-09 **Remote Config và Analytics ở cả hai clients; Crashlytics trên mobile**; identity/role lifecycle và noPII, RC defaults/fetch errors, FCM/inbox theo scope. Web không được claim Crashlytics mobile evidence thay telemetry web.

## 7. Final — web admin, inbox và cross-role flow

Nguồn: FA mục 7, tr. 4–5; Appendix C tr. 9.

- [ ] FIN-10 **Sign-in:** Google login, reject non-staff, auth/role states/cancel/error/logout guard; không chỉ ẩn menu bằng UI.
- [ ] FIN-11 **Management:** list/search/create/edit/archive **1 entity mobile thật sự đọc**; domain validation/rules, states/retry; entity và archive behaviour chốt trước schema.
- [ ] FIN-12 **Review queue:** approve/reject items mobile submitted, **reason**, valid transitions và concurrent/repeated decision guard; mobile realtime update, không refresh giả bằng local state.
- [ ] FIN-13 **Dashboard:** **≥3 figures từ aggregation queries và ≥1 chart**, filters/permissions/empty/error; không dùng seed hoặc lấy tổng client-only rồi claim aggregation queries.
- [ ] FIN-14 **Announcement form:** ghi `announcements`, mobile **inbox realtime** nhận và đọc được; role permissions/read state/visibility policy rõ, không coi push toast thay inbox Firestore.
- [ ] FIN-15 Tất cả web screens loading/empty/error, Lab2 tokens/components + wide layout, focus/responsive/accessibility; thiết kế cập nhật Figma. Đích Flutter Web; đề cho phép React/Vue cùng tokens nếu sau này được lựa chọn, không cần đổi stack hiện tại.
- [ ] FIN-16 Deploy **Firebase Hosting**, live admin URL mở private window đúng deadline; routing/auth domains/config hợp lệ. Không nhầm App Hosting hoặc localhost preview là deployed admin.
- [ ] FIN-17 `docs/cross-role-flow.md`: từng step actor/client/screen/Firestore collection+fields/rule allowing/other client result; sequence diagram và **measured write→update latency**, mobile submit/web decision/inbox/realtime evidence thật, không đặt SLA tự bịa.
- [ ] FIN-18 Chạy cross-role flow **3 lần trên deployed system**, cả hai màn hình quan sát được, kiểm approve/reject/reason/permissions và ghi kết quả/timing/trace.

## 8. Final — Gemini feature và bảo vệ dữ liệu

Nguồn: FA mục 8, tr. 5.

- [ ] FIN-19 **≥1 Gemini feature qua Firebase AI Logic (Gemini Developer API)** giúp một bước flow Lab2/TokenLedger. App quản lý account AI không tự là AI feature. Đề xuất gợi ý purpose từ mô tả đã khử PII chưa phải scope đã duyệt.
- [ ] FIN-20 Đích đầy đủ điểm **level2 structured JSON → Dart model → user confirms**; stream text level1 chỉ partial. Output có label AI, preview/edit/reject/accept; schema/type/size/domain validation, không auto-save AI guess thành số liệu tiền/token thật.
- [ ] FIN-21 App Check, **model name/prompt/on-off flag lấy Remote Config**; defaults/versioning/kill switch thực sự thay behaviour không rebuild. Không nhúng backend/model secret trong clients.
- [ ] FIN-22 No personal data gửi model (name/email/photos people, cả metadata hoặc notes có PII); xác định payload tối thiểu và user confirmation. Network/quota/invalid output/disabled failure có message + manual fallback để flow vẫn hoàn thành không AI; không bịa output.
- [ ] FIN-23 Analytics **`ai_request`, `ai_result_accepted`, `ai_error`**, typed safe params, không raw PII/prompt cá nhân; record outcomes đúng, avoid duplicate/rebuild logging.
- [ ] FIN-24 `docs/ai-feature.md`: flow/value/model/config/privacy/request-response/schema/confirmation/fallback; **3 real inputs/outputs và 1 failure đã xử lý** với evidence; tách fixture từ kết quả Gemini thật.
- [ ] FIN-25 **Bonus tùy chọn**, chỉ sau mandatory gates: level3 function calling trên own scoped data hoặc second cross-role flow, bonus tổng max+0.5 và điểm toàn bài ≤10. Không tự thêm chat/payment/provider scraping.

## 9. Final — tests, release và hồ sơ nộp

Nguồn: FA mục 9–12, tr. 5–8, Appendix B tr. 9.

- [ ] FIN-26 **ARTEMIS mobile** mọi flow Lab2, mobile steps cross-role và AI feature; **3 runs mỗi case**, pass rate/structured outcomes/traces; reuse L3 suite bổ sung feature mới, dedicated test account/privacy.
- [ ] FIN-27 **Security Rules trong Firebase Emulator**, ≥1 allowed và ≥1 denied **per role per collection**, status transitions/self-role escalation/ownership/bypass, all pass; tests ở `firebase/tests/`, script/env/version command tái lập.142 Rules API simulations hiện tại không tick gate này.
- [ ] FIN-28 **Web checklist** main action từng screen, role rejection, empty/error, mỗi mục có screenshot; không bắt buộc tự biến thành ARTEMIS web test. Cross-role deployed3 lần theo FIN-18.
- [ ] FIN-29 AI review **new Final code ≥3 findings thật có decisions**, file/line/tool/output/fix verification; ghi trong `docs/test-report.md`, có thể link record chi tiết. L3 vẫn cần5 findings/3 separate fixes, không giảm theo ngưỡng Final.
- [ ] FIN-30 Tiếp tục repo Lab3, dự kiến rename **`PRM393_Final_<ID>`** khi có ID và yêu cầu publish; không tạo repo khác hoặc rewrite history. Structure packages/core/mobile/web/e2e_test/firebase/docs/evidence/report/slides; firebase config/rules/indexes/RC defaults/tests sắp xếp đúng và documented.
- [ ] FIN-31 README: roles/first Admin/demo accounts theo role (không passwords), web URL, run từng client và Firebase emulators, versions/config, AI tools/purpose, video/deliverable links. Kiểm keys/secrets/PII/artifacts và fresh clone install/deploy hướng dẫn.
- [ ] FIN-32 **Report 10–15 trang**, `report/Final_<ID>.pdf`: changes since L3, architecture/shared core, model/rules, web admin, cross-role, AI/privacy/fallback, tests/review/lessons; evidence mọi claim.
- [ ] FIN-33 **Slides12–15, PDF**, `slides/Final_<ID>_slides.pdf`: persona/system diagram/each client/cross-role/AI/test results/lessons; readable, claim có evidence; disclose AI tools.
- [ ] FIN-34 **Video8–12 phút live**: mobile flows, từng web screen, cross-role **cả hai màn hình cùng thấy**, AI và RC tắt AI, 1 test run. Không edited-in kết quả hoặc dùng preview thay deployed system.
- [ ] FIN-35 Repo/admin URL/report/slides/video/evidence mở được private window đúng deadline cho người chấm; IDs/accounts/rights rõ, không tự publish public hoặc chia credentials.
- [ ] FIN-36 History thật tiếp nối L3, `[N]` commits/days chốt giảng viên; team contributions nếu được thông báo làm nhóm. Chuẩn bị review **10 phút**: run cross-role, đổi RC, giải thích rule/AI decision; integrity/AI disclosure không fabricated results.

| FA rubric | Điểm | Coverage |
|---|---:|---|
| Mobile | 2.0 | L2/L3 finished1.25; real data/inbox0.75 |
| Web admin | 2.0 | Screens/actions1.25; design/deploy0.75 |
| Backend/integration | 2.0 | Model/rules1.0; cross-role1.0 |
| AI | 1.0 | Level2 + AppCheck/RC/fallback/privacy; level1 partial |
| Tests/code quality | 1.0 | Test evidence0.5; MVVM/shared package/review0.5 |
| Slides/video | 2.0 | Mỗi phần1.0 |

Report required, evidence thiếu thì criterion không đạt. Final không tự đóng khi Lab3 chạy tốt; bonus không bù việc bỏ mandatory requirements.

## 10. Thứ tự thực hiện và cách đóng yêu cầu

### Bảng kiểm coverage với hai PDF

| Nguồn | Phạm vi đã đưa vào backlog | Requirement IDs |
|---|---|---|
| L3 mục1–3, tr.1–3 | Work mode/platform/Lab2 scope/real data/file/demo area/topic approval/tool unavailability | REQ-SCOPE-01–06, REQ-L3-01–06/12/27/38 |
| L3 mục4–5, tr.3–6 | Stage outputs/MVVM/architecture diagrams/injection/state/tokens/components/accessibility | REQ-L3-05–12/39/46 |
| L3 mục6 và Appendix A, tr.6–8/16–17 | Sáu Firebase services/failure/evidence/≥7 events/params/questions/flow mapping | REQ-L3-13–27 |
| L3 mục7 và Appendix B, tr.8–9/17 | ARTEMIS setup/coverage/quality/native/error/analytics/3runs/exploratory/evidence | REQ-L3-28–34 |
| L3 mục8 và Appendix C, tr.9–10/17–18 | Tool/PR/5findings/2kinds/reasons/3fix commits/AI disclosure | REQ-L3-35–37 |
| L3 mục9–11, tr.10–16 | Repo structure/docs/report/slides/video/rubric/access/integrity/oral/checklist | REQ-L3-38–47 và bảng điểm L3 |
| FA mục1–6, tr.1–4 | Scope/no new features/shared architecture/backend/roles/model/rules/AppCheck/services | FIN-01–09 |
| FA mục7 và Appendix C, tr.4–5/9 | Web4screens+form/design/Hosting/inbox/cross-role steps/latency/deployed runs | FIN-10–18 |
| FA mục8, tr.5 | AI levels/AI Logic/AppCheck/RC/privacy/fallback/edit-confirm/events/examples | FIN-19–25 |
| FA mục9–12 và Appendix B, tr.5–9 | ARTEMIS/Emulator/web/review/deliverables/rubric/integrity/oral/bonus | FIN-26–36, FIN-25 và bảng điểm FA |

Các IDs này bao phủ yêu cầu nguyên bản; lựa chọn kiến trúc bổ sung của TokenLedger như receipts/retry/source isolation vẫn giữ trong backlog kỹ thuật, không coi là yêu cầu nguyên văn của đề.

### Thứ tự và gates

### Bảng kiểm coverage với hai PDF

| Nguồn | Phạm vi đã đưa vào backlog | Requirement IDs |
|---|---|---|
| L3 mục1–3, tr.1–3 | Work mode/platform/Lab2 scope/real data/file/demo area/topic approval/tool unavailability | REQ-SCOPE-01–06, REQ-L3-01–06/12/27/38 |
| L3 mục4–5, tr.3–6 | Stage outputs/MVVM/architecture diagrams/injection/state/tokens/components/accessibility | REQ-L3-05–12/39/46 |
| L3 mục6 và Appendix A, tr.6–8/16–17 | Sáu Firebase services/failure/evidence/≥7 events/params/questions/flow mapping | REQ-L3-13–27 |
| L3 mục7 và Appendix B, tr.8–9/17 | ARTEMIS setup/coverage/quality/native/error/analytics/3runs/exploratory/evidence | REQ-L3-28–34 |
| L3 mục8 và Appendix C, tr.9–10/17–18 | Tool/PR/5findings/2kinds/reasons/3fix commits/AI disclosure | REQ-L3-35–37 |
| L3 mục9–11, tr.10–16 | Repo structure/docs/report/slides/video/rubric/access/integrity/oral/checklist | REQ-L3-38–47 và bảng điểm L3 |
| FA mục1–6, tr.1–4 | Scope/no new features/shared architecture/backend/roles/model/rules/AppCheck/services | FIN-01–09 |
| FA mục7 và Appendix C, tr.4–5/9 | Web4screens+form/design/Hosting/inbox/cross-role steps/latency/deployed runs | FIN-10–18 |
| FA mục8, tr.5 | AI levels/AI Logic/AppCheck/RC/privacy/fallback/edit-confirm/events/examples | FIN-19–25 |
| FA mục9–12 và Appendix B, tr.5–9 | ARTEMIS/Emulator/web/review/deliverables/rubric/integrity/oral/bonus | FIN-26–36, FIN-25 và bảng điểm FA |

Các IDs này bao phủ yêu cầu nguyên bản; lựa chọn kiến trúc bổ sung của TokenLedger như receipts/retry/source isolation vẫn giữ trong backlog kỹ thuật, không coi là yêu cầu nguyên văn của đề.

### Thứ tự và gates

| Ưu tiên | Công việc | Điều kiện đóng |
|---|---|---|
| 1 | Chốt REQ-SCOPE-03–06; chuẩn hóa traceability/architecture/test/analytics plans | Quyết định cụ thể; không còn dùng ngưỡng đề cũ |
| 2 | Nghiệm thu Auth/Firestore Android thật + CRUD/A-B/retry và F1–F3 | Evidence backend/native, giữ invariants |
| 3 | L3 PDF theo quyết định Storage; Analytics/RC/Crash/FCM/Profile demo area | Behaviour + error handling + console evidence từng service |
| 4 | L3 ARTEMIS + review/fixes + final UI/data release audit | ≥10 cases×3, exploratory, ≥5 findings/3 commits; no runtime mock |
| 5 | Hoàn tất mốc nộp Lab3 | Report8–12p/slides12–15/video5–10m/access/verification |
| 6 | Final roles/model/core/mobile+admin/Hosting/inbox/cross-role | Least privilege và live3 runs; không phá dữ liệu cá nhân |
| 7 | Final AI/AppCheck/RC/telemetry và rules/E2E/web/review | Level2, 3 real examples+failure, role Emulator matrix, evidence |
| 8 | Hoàn tất mốc Final | Report10–15p/slides12–15/video8–12m/live URLs/review readiness |

Có thể thiết kế role/core/AI sớm để tránh rework nhưng không bỏ Lab3 flows/evidence. Không tự triển khai hoặc bật dịch vụ chỉ vì checklist ghi cần làm; từng lượt code theo yêu cầu người dùng.

Mỗi yêu cầu đóng phải có: **ID → implementation/docs → submission commit → environment/time → expected/actual result → evidence path → remaining limits** trong test-report hoặc record liên quan. Approval người dùng về topic chỉ đóng REQ-SCOPE-01; không tick các gates chưa có bằng chứng. Không tự tạo report/slides/mock traces/AI findings hoặc dates để làm đầy checklist.
