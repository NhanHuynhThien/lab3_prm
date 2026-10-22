# Audit Lab 3 theo PDF17trang — 22/10/2026

## Kết luận và phạm vi

**Repo chưa đáp ứng đầy đủ bài. Cây thư mục MVVM tương đối đúng; baseline tài liệu, một số ranh giới lớp, các tích hợp bắt buộc và bằng chứng nộp còn thiếu.** Chưa có cơ sở chấm “hoàn tất” từ số tests hoặc APK chạy được.

Nguồn chuẩn duy nhất cho lượt này: **PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf**,17trang, SHA-256 `563eb49ef0eca4d860b4edd67c4c818d08728fa657c3c07231ee7229a197589c`. Đã đọc toàn bộ17trang; xem trực quan trang5/6/9/11/12. [Requirements chuẩn hóa](ASSIGNMENT_REQUIREMENTS.md).

Đã đối chiếu source lib/main,models,services,viewmodels,screens,widgets,theme; rules/deploy config; docs/assets/test inventory và regression suite. Console services không được coi là verified bằng kiểm tra tĩnh. Native từng flow đang kiểm theo quyền user mới cấp; xem [báo cáo native](test-report.md).

Trạng thái: **Có code** = thấy implementation, chưa đủ E2E/evidence; **Thiếu** = gap xác nhận từ source/inventory; **Chờ evidence** = cần kiểm môi trường thật.

## 1. Sai baseline phải sửa trước

Repo trước lượt này lấy đề **Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review),18trang** và Final làm chuẩn. Vì vậy có hướng dẫn bỏ MobAI, chuyển ARTEMIS, AI review5findings/3fixcommits, report8–12p/slides12–15/video5–10m. Chúng **không phải yêu cầu của PDF người dùng vừa chỉ định**.

| Nội dung | Đúng theo PDF17trang | Tác động |
|---|---|---|
| E2E | MobAI,10 `.mob`, healing + bug-catching (tr9–10) | Không dùng Flutter/ARTEMIS thay gate |
| AI review | ≥3findings,≥1security/robustness, review rules, featurePR (tr11) | Cần findings/decisions/fixes/evidence thực |
| AI log | ≥6prompts nguyên văn + verification/decision (tr9) | Count không thay chất lượng nội dung |
| Report/video | 5–10trang /3–5phút (tr12–13) | Không cần tự thêm slide requirement |
| Storage | Cloudinary free được khuyến nghị; Firebase Storage cần billing (tr5–6) | Spark hiện tại chưa có đường upload hoàn chỉnh |
| Tổng điểm | 100điểm, MobAI15 (tr13–16) | Không dùng bảng rubric10điểm của đề khác |

Đã chuẩn hóa requirements/README/AGENTS/architecture và dọn các roadmap/checklist/bản sao đề cũ khỏi docs. Các phát hiện và việc cần làm giữ trong audit này; prompt lịch sử giữ ở AI log. Đã bỏ metadata `.agents/` cũ; hướng dẫn hiện hành là root AGENTS/user/PDF này.

## 2. Structure và MVVM

| Yêu cầu | Source thực tế | Đánh giá |
|---|---|---|
| Folder structure §5,tr4 | `lib/{theme,models,services,viewmodels,screens,widgets,utils}`,main,firebase_options | Khớp cây đề gợi ý |
| Một state library | Riverpod xuyên Auth/ledger/report/source | Có, không thấy Provider/BLoC trộn |
| Models plain Dart + conversion | Models thuần; Firestore conversion ở `services/firestore_ledger_codec.dart` | Hợp lý, cần giải thích converter ở service |
| Chỉ services gọi Firebase/API | `rg` views/VM/models không có Firebase imports; SDK ở services | Firebase boundary khá tốt |
| Mỗi screen + VM,tr4 | 8screens mapped + Login/Profile/Quota/ProviderConnections; shared ledger/reportingVM; Purpose chỉ local selection | **Chưa bám hoàn toàn** one-screen+VM mapping |
| Views không business | `ExportReportDialog` tự sum cost/tokens, giữ export/upload state và gọi service; filepicker/notification mutations ở widgets | **Partial**; chuyển vào VM/services |

**Không cần đổi toàn repo thành `mobile/web/packages/core`**: cấu trúc đó thuộc Final khác. Việc tạo VM rỗng để đủ tên file cũng không đáp ứng ranh giới state/business của §5. [Kiến trúc và mapping chi tiết](architecture.md).

## 3. Chức năng và Firebase

| Mục PDF | Trạng thái | Bằng chứng/gap cụ thể |
|---|---|---|
| ≥8màn/3flows/tr2,4–5 | Có code; native nghiệm thu đang làm | Dashboard,UsageForm,Purpose,Analytics,History,Accounts,AccountForm,AccountDetail +Login/Profile; [mappingLab2](fidelity-check.md). Chủ đề đổi đã được user xác nhận lecturer duyệt, nhưng không suy mọi sai khác UI được miễn |
| Auth6.2,tr5 | Có code; real session restored theo run trước | `FirebaseAuthService` GoogleSDK, `AuthGate` signedout→Login, UID navigator, Profile metadata/logout. Runtime demo entry/seed đã bỏ; không tính fake auth tests là GoogleOAuth end-to-end |
| Firestore6.3,tr5 | Có code + lịch sử deploy; nativeCRUD/evidence đang kiểm | ≥2subcollections accounts/usage_sessions/quota_windows; store where/orderBy/snapshots, atomic repo, ownerRules/defaultdeny. Form tạo dữ liệu thật đáp ứng test-data path, không phải khôi phục seed |
| PDF6.4,tr5–6 | **Thiếu** | `ReportManagementService._reports/_cachedBytes` chỉ RAM. Không Firestore report metadata write/read; rules cũng chưa có report collection. URL tồn tại trong object không đáp ứng persistence |
| Storage6.4 | **Thiếu vận hành** | `FirebaseStorageTransport` có putData nhưng project mới Spark/chưa provision Storage theo migration notes; `firebase.json` chưa khai báo storage rules deployment. Chưa upload thật. Cloudinary là lựa chọn đúng đề nếu triển khai restricted PDF unsigned preset; chưa được cấu hình |
| FCM6.5,tr6 | **Partial** | Transport có onMessage/onMessageOpenedApp/getInitialMessage; NotificationService có inbox RAM và route stream. **Không consumer route stream**, tap inbox chỉ pop sheet; background handler rỗng và chưa register. Không suy mọi notification payload background đều thất bại (OS có thể hiển thị), nhưng routing/center chưa hoàn chỉnh |
| RC6.6,tr6 | Có code; chờ console→app evidence | recent_limit/budget_warning_percent defaults3/80, service fetch/clamp/fallback, Profile effective values, reporting behavior. Publish snapshot v1 lịch sử không thay demonstration đổi A→B trên app |
| Crash6.7,tr6 | Có hooks/controls; **chưa dashboard evidence** | Controls handled/testcrash trong Profile chẩn đoán được giữ lại theo đề. Trong cleanup đã xóa nhầm controls nên lượt này phục hồi. Chưa tự gây crash hoặc claim dashboard pass |
| Analytics6.8,tr6–7 | **Partial** | Plan/SDK/ownerqueue có; event `account_saved`/`usage_saved` khác `create_/update_`; detail thiếu item_id; screen allowlist chỉ4tabs; export_report log trước upload, thiếu `export_pdf(item_count)` sauupload. Project mới chưa có GA/DebugView evidence theo migration notes |
| SDK lifecycle | Sửa một gap, còn rủi ro | AuthGate childcontainer trước đây không share actualNotification/Crash/Storage/report service; đã inject service boundaries root. Report owner async vẫn mở (bên dưới) |

### Rủi ro robustness xác nhận từ source

1. **Đã sửa report completion qua UID change**: `generateReport()` đọc `_ownerId` sau awaits, `uploadToCloudStorage()` giữ index rồi access `_reports[index]` sau awaits; bindOwner clears/reassigns collection. Có thể gắn PDF phiênA vào UIDB/cacheB hoặc RangeError khi logout. Đã capture UID+epoch, kiểm stale completion/progress và bỏ anonymous fallback cho cloud; 3 owner lifecycle tests pass. Native upload còn phụ thuộc Storage.
2. **Rules/report path**: Firestore cuối file deny-all, chưa `/users/{uid}/reports/{id}`. Viết metadata mới mà không rules tương ứng sẽ permission-denied; không được chữa bằng open rules. Storage rules hiện owner-only nhưng không MIME/maxsize; thiếu deploy mapping. Đây là reviewsecurity/robustness, không bằng chứng đã bị khai thác.
3. **Crash status chưa đáng tin**: `bindOwner` có thể publish enabled=true dù transportnull; recordHandled tăng localcount sau lỗi SDK bị swallow. UI không dùng số local để khẳng định dashboard nhận; cần result semantics và async owner guard.
4. **Notification account scope/routing**: inbox RAM được clear khi authchange, nhưng payload không có ownervalidation/persistedtarget logic. Mở route cần allowlist và xác minh entity thuộc currentUID, không chạy arbitraryroute từ payload.

[Code review ghi file:line/decisions](code-review.md). Đây là local Codex review, **chưa thay PR-based review evidence**.

## 4. Design system và fidelity

| Yêu cầu tr8 | Đánh giá |
|---|---|
| Tokens từ Lab2 | Primary/Inter/spacing/radius giữ; typography một số cấp tăng để rõ hierarchy, muted đổi nhẹ. Chưa liệt kê toàn bộ hardcoded values; phải ghi và reconcile Figma, không claim100%tokencompliant |
| BeeWise login | Composition từ source app user: centeredlogo/welcome, formcard, tintedbackdrop. TokenLedger palette/logo, không loop/blur. User yêu cầu này không tự miễn design-change/Figmaannotation |
| Body/touch/layout | bodySmall đã trả14sp theo handoff; targets48/button52; tests360/412/768/1440text1/1.3/2. Cần nativecontrast/tap/keyboard từng màn và khó đọc thực tế |
| Mỗi screen Figma vsapp360×800 | Có notes/mockups cũ, **chưa bộ evidence đủ hiện hành**. Widget fixture screenshots không phải real-state native |
| Loading/empty/error | Có component/state tests; cần ảnh actualnetwork/permissionfail/empty thật |
| Motion | Shorten transition/chart, lazytabs/offstageTickerMode, bỏlargecrossfade/intrinsiclayout; chưa đo frameperformance profile trên Android nên chưa kết luận mượt hoàn toàn |

## 5. Deliverable inventory

| Artifact | Trạng thái22/10 |
|---|---|
| `README.md` topic/Figma/handoff/run/setup | Đã chuẩn hóa source hiện tại; freshclone/visibility chưa nghiệm thu |
| lib/android/google-services.json/firebase rules | Có; Storage vận hành/deploy còn thiếu |
| `docs/handoff-gaps.md`,design-change-log,fidelity-check,analytics-plan | Có files, nội dung/evidence cần update theo gaps này |
| implementation-ai-log | Có21entries cũ; một số entry là Git/docs, không suy đủ6verification hữu ích chỉ từcount; thêm actualprompts lượt này |
| `docs/code-review.md` | Tạo localreview thật lượt này; PR/screenshots/fixes còn pending |
| `mobai_tests/` | **Không có10.mob/run/healing/bugcatch** |
| assets Firebase/DebugView/Crash/test/review evidence | **Chưa có bộ evidence tracked đủ**; runtimefonts/icons không thay evidence |
| Report5–10trang /video3–5phút | **Chưa thấy deliverables hoàn chỉnh** |
| Repo name `PRM393_Lab03_<StudentID>` | Remote đang `lab3_prm`; chưa đổi, StudentID cần chốt khi đóng gói |
| ≥1mergedPR | Có lịch sử PR#1, không suy PRđó đã AIreview source hiện tại |

## 6. Thứ tự hoàn thiện

1. Stabilize/test từng native screen/flow bằng real Google+Firestore, chỉ dữ liệu QA riêng. Đóng lỗi hiện thấy trước thêm extension.
2. ReportViewModel + owner lifecycle + metadataRepository/ownerRules + storage option hoạt động thật; export_pdf sau thành công.
3. FCMrouteallowlist/authready, foreground/background/initial; permission và Consolepush evidence. RCconsolechange và Crash2types/DebugView cần projectsetup/evidence thực.
4. Reconcile event contract theo tr7,screenmapping và Lab2token/componentexceptions/Figma360screens.
5. 10MobAI trên dedicatedaccount, healing/realbugcatch; AI PRreview+fixes; report/video/repoaccess.

Chưa tick gate nếu chỉ tạo folder/doc hoặc service stub. Không tự bật billing, sửa mail/tài khoản bảo mật, fabricate scripts/logs hoặc push/deploy để làm đẹp trạng thái.

## 7. Verification hiện hành

391 Flutter tests pass; 26 Node adapter tests pass; analyzer sạch; Android profile và web release build pass. Native flow nào đã quan sát được ghi riêng tại [test report](test-report.md), không suy unit/widget tests là E2E.

Còn thiếu Storage/report metadata, FCM routing/background/console, Analytics contract/DebugView, RC/Crash dashboard evidence, 10 MobAI/dedicated account/healing/bug-catching, final fidelity/report/video và feature PR review. Repo chưa đủ điều kiện coi là hoàn tất bài nộp.
