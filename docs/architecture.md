# Kiến trúc TokenLedger — trạng thái code hiện hành

Verification 21/10: **326/326 Flutter tests pass (221s, concurrency=1)**; analyzer sạch 13.7s; format 134 files 0 changed (66 lib / 68 test files, 100% <= 300 dòng theo script check_line_limits.dart); web release JS build pass 71.6s. Đã tách nhỏ UI, styles, state, streams, loại bỏ cupertino_icons thừa và tối ưu O(N) publish mapping cùng RepaintBoundary rebuild zones. Không chạy emulator/Android/ARTEMIS hoặc console verification; xem [test report](test-report.md).


## Analytics/Remote Config và manual web checks —21/10/2026

Người dùng xác nhận toàn bộ đợt manual web1–7 đạt: account edit/budget, usage totals/purpose drilldown, unknown data, validation/Back draft, archive/restore/history guard, empty-account delete, multi-quota/bounds; trước đó đã xác nhận reload/A-B isolation và offline/Retry. Đây là user-reported web evidence, không phải Android/ARTEMIS/concurrency stress hoặc console do agent kiểm.

Đã thêm Analytics13.0.0 và RemoteConfig7.0.0, typed/noPII event allowlist, UID-serialized lifecycle/dedupe/success-only cloud mutations và tab/account/usage detail events; demo no-op. Remote Config defaults overview_recent_limit3/budget_warning_percent80, parse/clamp/cache/fallback/retry/single-flight; dashboard recent rows/warning thực thay đổi qua projections, không cắt dataset hoặc đổi tiền/token. Profile có effective values/source/check time/refresh và Analytics SDK status; Crashlytics vẫn chưa nối. Đọc [plan Analytics](analytics-plan.md) và [implementation/manual guide](analytics-remote-config.md).

Verification cuối xem test-report; không coi SDK state hoặc fake tests là DebugView/console evidence. Remote Config publish→app before-after, DebugView mỗi event, Android/ARTEMIS vẫn pending; PDF export/upload events chỉ planned. FCM/Crash/PDF và Final modules chưa làm. Không Android emulator/billing/deploy hoặc push trong lượt này. Các câu SDK Analytics/RC còn pending ở checkpoint dưới đây đã được cập nhật implementation mới; giữ history/results đúng thời điểm.


## Cập nhật yêu cầu21/10 — ưu tiên hơn checkpoint phía dưới

[Baseline Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md) đã đối chiếu đủ hai PDF mới. Giảng viên chấp thuận đổi sang TokenLedger theo xác nhận trực tiếp của người dùng21/10; các câu còn chờ duyệt chủ đề phía dưới là lịch sử. Không suy thành duyệt roles Final, miễn Storage/tests hoặc nghiệm thu UI.

Auth/Firestore workspace/rules/indexes đã có tại main484cc41;299 Flutter tests/142 Rules API cases là evidence trước lượt docs, manual CRUD/A-B/native còn chờ. Đề mới yêu cầu ARTEMIS (không MobAI), AI review5 findings/3 separate fixes, report8–12p/slides12–15/video5–10m. Final cần roles/admin/shared core/cross-role/Gemini/AppCheck và Emulator tests; PDF L3 Storage khác Final device save/share. Baseline mới giữ mọi việc còn mở, không tick từ lượt docs này. Các checkpoint phía dưới chỉ có hiệu lực trong scope/time ghi tại từng mục.


## Cloud workspace/rules —21/10/2026, mục3–5

Đã nối4 tab với Firestore theo UID, CloudLedgerViewModel dùng4 streams ghép nhất quán, full-dataset reporting, CRUD/quota/settings atomic, revision từ lúc mở form, last-good/cache/pending/error/retry giữ draft/filter. Mỗi UID/demo có ProviderContainer/Navigator riêng, root auth action coordinator dùng chung; logout/change UID dọn state/listeners/routes, không seed/upload local vào cloud. Factory tắt Firestore disk persistence. [Workspace hướng dẫn](firestore-workspace.md) ghi thiết kế và manual checks.

Rules default deny/owner/schema/relations/counters/quota labels/receipts đã code và deploy với5 indexes vào tokenledger-lab3/(default), Standard/asia-southeast1. Rules Test API142 cases pass (mocks trước/sau, không emulator/doc writes), live source hash khớp local và unauth GET403. Index readiness xem test-report, không suy deploy accepted thành READY. Full299 Flutter tests pass162s, analyzer sạch, web release48.3s;46 lib/22 test Dart files (2 helpers).25 tests VM/workspace mới;15 Auth tests cập nhật giữ assertions. Native/A-B thật/SDK transactions qua mạng/F1–F3 manual gates vẫn cần nghiệm thu. FCM/RC/Crash/Analytics SDK/PDF/Figma sync chưa làm. Không emulator/billing/commit/push.


## Firestore foundation —21/10/2026, mục1–2

Đã thêm cloud_firestore7.0.0, thiết kế envelope/paths theo UID, CloudLedgerRepository streams/atomic CRUD và SDK adapter cho account/usage/quota. Counters/revisions/quota label reservations và operation receipts commit cùng transaction, không upload snapshot local.35 tests repository mới pass; full regression274 tests pass138s trước lần siết receipt/path validation cuối, sau đó35 tests liên quan pass lại; analyzer sạch và web build xem test-report. Source44 lib/20 test Dart files, gồm2 support helpers. [Data contract](firestore-data-contract.md) ghi mapping/invariants/query/indexes và lifecycle. Chưa nối UI/VM, chưa viết/deploy rules/indexes hoặc kiểm database thật; các backend gates còn pending. Không emulator, billing, telemetry hoặc publication.

Người dùng báo Google web login/reload/logout và Authentication Users đã thành công, đồng thời đã tạo Firestore. Đây là xác nhận người dùng; native/Play services/release cert và Firestore integration chưa được kiểm bởi agent.


Hiện trạng21/10/2026 sau Auth:39 lib/18 test Dart files (gồm1 support helper),239 tests; schema2/model/default purposes/multiple quota windows/provenance/cycle/timezone và analytics/history local đã triển khai, xem [upgrade](local-p0-upgrade.md). Các số106/142/168 tests bên dưới giữ theo lịch sử; full Firebase schema/owner/services trong plan chưa có.

Cập nhật21/10/2026. Tài liệu này mô tả implementation local hiện tại; [implementation plan](IMPLEMENTATION_PLAN.md) mô tả cả những phần chưa build.

## 1. Bootstrap và dependency injection

`main.dart` khởi tạo Flutter bindings, inject FirebaseAuthService qua authServiceProvider và override `ledgerRepositoryProvider` bằng `LocalLedgerRepository.open()`, rồi chạy `TokenLedgerApp` trong `ProviderScope`. Repository mở SharedPreferences lúc load; lỗi khởi tạo plugin cũng vào error/Retry, không làm bootstrap dừng trước khi render app.

`app.dart` tạo MaterialApp/theme và AuthGate trước mọi route. authSessionProvider initialize Core/Auth và đợi userChanges; timeout20 giây mở error/Retry/demo, không tự giả signed-out/signed-in. Navigator keyed demo/UID tháo stack cũ khi logout/change user. Profile lấy AuthUser từ Firebase stream; authenticated workspace inject CloudLedgerViewModel/repository trong container riêng theo UID.4 tab dùng cloud streams; không dùng seed local. `/?demo=1` mở sandbox local riêng; xem firebase-auth-setup.md.

AuthService là nơi gọi Firebase/Google SDK; native dùng ID token credential, web dùng Firebase popup trong lượt click. Client Firebase config không phải provider secret; tokens không lưu vào ledger. Không có provider usage sync hoặc Analytics telemetry SDK. Firestore repository trong services được provider lifecycle tạo sau auth ready; demo local không gọi factory cloud.

## 2. Ranh giới lớp

| Lớp | File chính | Trách nhiệm |
|---|---|---|
| Auth | `lib/services/auth_service.dart`, `firebase_auth_service.dart`, `lib/viewmodels/auth_viewmodel.dart` | Core initialization, Google credential/popup, session stream và typed error/Retry; SDK chỉ trong services |
| Identity model | `lib/models/auth_session.dart` | AuthUser public metadata/AuthFailure thuần Dart, không lưu OAuth tokens |
| Model | `lib/models/ledger.dart` | Plain Dart, schema, JSON serialization; enum Purpose/BillingMode |
| Cloud data | `lib/models/cloud_ledger.dart`, `lib/services/cloud_ledger_repository.dart`, `firestore_ledger_repository.dart`, `firestore_ledger_codec.dart`, `firestore_ledger_store.dart` | Owner-scoped streams, metadata/cache/pending, converters và atomic entity/counter/receipt/label commands; cloud VM/UI đã nối và rules đã deploy |
| Persistence contract | `lib/services/ledger_repository.dart` | Snapshot `load()` / `save()`; adapter SharedPreferences |
| Domain calculation | `lib/services/usage_calculator.dart` | Filter khoảng thời gian/account/purpose/search, summarize, purpose shares, daily costs |
| Seed | `lib/services/demo_seed.dart` | Dataset giả định, có thể khôi phục rõ ràng |
| Mutation ViewModel | `lib/viewmodels/ledger_viewmodel.dart` | Initialize/load, validations, CRUD, archive, quota update, write guard, persistence errors |
| Reporting ViewModel | `lib/viewmodels/reporting_viewmodel.dart` | Derived screen projections; tập trung budget/aggregation, không để widgets tự tính tài chính |
| View | `lib/screens/` | Render state, controller/form interactions, navigation; gọi VM khi mutation |
| Component | `lib/widgets/` | Panel, feedback, chart, progress/counter, brand mark |
| Theme/util | `lib/theme/`, `lib/utils/` | Lab2 tokens/motion; tiền micros/date formatting |

Views không gọi SharedPreferences/Firebase. Khi thêm backend, service adapter chịu trách nhiệm SDK/API; VM orchestration và pure calculator tiếp tục được test độc lập.

## 3. State và data flow

1. `ledgerProvider` là `AsyncNotifierProvider`: loading → local data hoặc error.
2. Lần đầu chưa có storage: tạo seed rồi persist; dữ liệu đã tồn tại thì load/validate snapshot, không tự chèn seed khi blob lỗi hoặc không đọc được. Local errors chờ Retry chủ động.
3. Form gửi model tới LedgerViewModel, VM validate rồi save snapshot mới.
4. Chỉ khi repository save thành công mới publish `AsyncData(next)`; save fail giữ dữ liệu cũ và trả lỗi cho form.
5. `_writing` chặn hai mutation đồng thời trong cùng instance; account/usage form giữ operation ID khi retry. `_pendingWrite` cho reload chờ write hoàn tất; load epoch/mounted guard không publish kết quả cũ vào VM đã reload/dispose. UUIDv4 từ Random.secure không phụ thuộc timestamp. Chưa có multi-window/multi-device conflict resolution.
6. Reporting providers derive kết quả từ ledger/range/clock; widgets render cùng một nguồn số liệu.
7. Shell dùng IndexedStack giữ state/scroll khi đổi tab; fade điều khiển riêng để không dispose form/filter của tab chỉ vì animation.

`clockProvider` cung cấp hàm đọc thời gian để validate/save và cố định trong tests. `nowProvider` reactive dùng một timer one-shot đến phút kế tiếp hoặc quota reset gần hơn: refresh báo cáo khi qua ngày/tháng/năm, pause khi app không resumed, refresh ngay khi resumed. Reporting projections auto-dispose và timer dừng khi không còn listeners. Không có background sync/write. Schema2 ghi timestamps UTC; reportingTimezone mặc định Asia/Ho_Chi_Minh cho dữ liệu mới, dữ liệu migrate giữ device. ReportingCalendar service dùng timezone0.11.2, IANA/DST và cycleStartDay1–31 clamp cuối tháng; budget tính kỳ account, report/history ngày/tháng theo reportingTimezone. Chi tiết policy migration/biên kỳ ở local-p0-upgrade.md.

## 4. Models và persistence

| Model | Nội dung quan trọng |
|---|---|
| AIAccount | id, alias, provider/product, billingMode, plan, budgetMicros nullable, archived, createdAt, quotaWindows, defaultModelId/defaultPurposes, timezone/cycleStartDay/isDemo/dataSource |
| UsageSession | id/accountId/title/purpose/occurredAt, input/output nullable, costMicros nullable, note, modelId/dataSource/costBasis/isDemo |
| QuotaSnapshot | windowKey/window, unit=percent, usedPercent, observedAt/resetAt/source/sourceLabel/note; từng window stale riêng |
| LedgerData | immutable accounts/sessions, reportingTimezone; schemaVersion2 và JSON round trip |

SharedPreferences key: `tokenledger.demo.v1`. Snapshot không có ownerUID, encryption hoặc multi-device conflict resolution. Nó chỉ dùng cho demo; không lưu credential hoặc coi đây là production data store.

Không tự sửa/xóa blob corrupt trong load: repository phân biệt lỗi read/corrupt/unsupportedVersion/write, kiểm schema/ISO date/types/domain/duplicates/references. UI có Retry và khôi phục sau confirmation. `recoverDemo()` chỉ dùng ở trạng thái load error: sao lưu raw value vào `tokenledger.demo.v1.recovery-backup` trước khi thay main key bằng seed; backup thất bại không replace, replace thất bại giữ error/backup. Reset/clear thông thường không vượt qua error state. Backup là một bản raw local gần nhất, không có restore/import UI hoặc cloud backup. Key chính vẫn tokenledger.demo.v1; schema2 có migration1→2 sau validate và raw backup riêng tokenledger.demo.v1.migration-v1-backup. Load đồng thời chia sẻ future; save chờ migration xong. Xem local-p0-upgrade.md cho failure/retry và policy legacy.

`LedgerValidation` là service Dart thuần dùng chung bởi form/VM/repository. Required text, provider allowlist, alias80/title120/product-plan-window60/note1000 đếm grapheme Unicode giống Flutter; token0..1 tỷ/cả cặp hoặc null; USD0..9999999.999999; IDs không rỗng; quan hệ account/session và tổng trong safe integer web. Usage mới/lưu sửa có ngày từ2020 và không sau now. Quota ghi mới có observedAt<=now<resetAt và resetAt>observedAt; stale snapshot cũ vẫn đọc/giữ khi sửa metadata, không gán lại100%. SaveAccount không bypass được quota validation. Load không từ chối lịch sử chỉ vì đồng hồ hệ thống lùi.

## 5. Các quy tắc nghiệp vụ đã thực hiện

- Tiền là integer USD micros,1USD=1,000,000 micros. Parser nhận dấu chấm/phẩy thập phân, không nhận âm/NaN/exponent/separators hỗn hợp, tối đa7 số nguyên và6 số lẻ. `money`/`usdInput` làm việc bằng integer để không mất micro khi round trip.
- Token thiếu khác token0; usage input/output cùng biết hoặc cùng để trống. Phiên chỉ có công việc vẫn hợp lệ nhưng coverage ghi rõ missing.
- Tổng cost là tổng các cost đã nhập; không tự tạo estimate theo giá provider. Tổng token chỉ là volume đã ghi.
- Dashboard metric/range là selected period; riêng budget card có label Kỳ hiện tại và cộng cost theo kỳ/timezone từng account. Không áp range7ngày lên ngân sách kỳ; account detail drilldown dùng cùng cycle, có lựa chọn đổi về kỳ báo cáo.
- Budget còn lại=budget tự đặt trừ cost đã ghi của active accounts có budget trong kỳ account; không phải provider credit balance. Chưa có budget thì hiện Chưa đặt ngân sách.
- Quota nhập tay độc lập usage logs; không quy% thành token hoặc cộng% giữa accounts. Sau reset không tự về100%.
- Usage edit không đổi accountId. Account có lịch sử không hard-delete được; archive giữ lịch sử, cho sửa/xóa phiên đã có qua history/detail sheet và chặn tạo usage mới. Account rỗng có thể xóa. Monthly remaining/progress của account nằm trong AccountProjection, không tính lại trong widget build.
- Demo restore/clear thay dữ liệu local sau confirmation. Không có tài khoản thật bị ảnh hưởng và không có backend sync.

## 6. Screens và navigation

| Screen | Đường vào / thao tác |
|---|---|
| Login | Google Auth thật hoặc demo local riêng |
| Shell |4 destinations; desktop sidebar từ1000dp, mobile bottom navigation |
| Dashboard | Budget, selected-period metrics, 7-day chart, quota, latest/purpose; Ghi sử dụng |
| Accounts | Search, active/archive state, create/detail |
| AccountForm / Detail | Metadata/budget CRUD; quota, purpose, archive/restore, empty delete |
| UsageForm / Purpose | Account/title/token/cost/date/note; grid9 purposes, giữ controllers khi chọn purpose |
| History / detail sheet | Search/range/account/purpose drilldown, edit/delete usage |
| QuotaForm | Window key/name/unitpercent, used%, observed/reset time/source label/note, create/edit/delete guard |
| Analytics | Cost/token/session metrics, donut/legend, account comparison, history filter |
| Profile | Google metadata và Firestore server/cache/error status; logout/demo riêng. Local Profile có restore/clear/leave |

Navigation dùng Navigator/MaterialPageRoute và sheet, chưa có router URL đầy đủ cho mọi screen/deep link Firebase. Từ 21/10, `DraftGuard` bảo vệ Back appbar/system cho account/usage/quota form: form sạch thoát ngay, form có thay đổi cho tiếp tục sửa/bỏ thay đổi; đang lưu chặn Back và interactions. Save thành công chủ động pop không hỏi bỏ draft. Account và usage form giữ ID ổn định khi retry. Footer ContentPage đặt trên keyboard inset.

## 7. Test và mở rộng

Ngày21/10 sau B03–B07: 106 tests trong8 suites: calculator8, ledger VM5, navigation/widget5, form safety21, ledger stability24, local repository27, live clock10, local flows6. Full suite pass, analyzer sạch và web release JS build pass. Bao gồm malformed JSON/schema/storage errors, backup/confirmation, concurrent writes/ID/dispose/reload, archived history UI360/412, UTC/local biên năm/tháng/ngày nhuận/reset/resume và timer disposal. Navigation kiểm360/412/768/1440; form keyboard/text scale1/2 giữ regression. Không thay Android/MobAI/Firestore evidence; không chạy emulator theo yêu cầu.

Khi nối Firebase cần mở rộng repository snapshot sang owner-scoped stream/atomic operations, add auth lifecycle, rules/indexes/transaction tests. Không dùng client snapshot toàn bộ như cơ chế merge backend. Thứ tự và backlog: [firebase-pending](firebase-pending.md), [task checklist](TASK_CHECKLIST.md).

## B08–B10 — component/layout audit21/10

`SaveButton` và `LoadingFeedback` trong common.dart thống nhất saving/loading; Material themes giữ CTA52/min touch48 và field helper/error multiline. `AdaptivePair` chuyển legend/list metric xuống dòng khi không gian theo text scaler không đủ. Chart đo text bằng TextPainter cùng font/scaler hiện hành, cuộn ngang có chỉ dẫn; donut caption tách khỏi vòng nếu không vừa. ContentPage AppBar hỗ trợ title2 dòng và toolbar theo scaler. Sidebar cuộn khi thiếu chiều cao, không đổi IndexedStack/tab lifecycle. Account list lấy budgetProgress từ AccountProjection.

`test/ui_audit_test.dart` kiểm12 màn + usage sheet ở4 viewport×3 text scales×2 datasets và3 form với keyboard/SafeArea; `test/component_audit_test.dart` là gallery QA9 families, không được import vào runtime app. Không thêm package/assets/backend/route QA. [Fidelity draft](fidelity-check.md) phân biệt audit local với đối chiếu ảnh Lab2 gốc/Figma/native còn pending.


## B11–B13 —21/10/2026

ActionSurface cung cấp semantic button/selected, touch48 và keyboard/focus treatment; theme vẫn theo Lab2. MotionAwareTransitions tôn trọng disableAnimations, dialogs/sheet có noAnimation, busy indicator dùng trạng thái tĩnh khi reduced motion với semantics không gán phần trăm giả. DraftGuard có ExcludeFocus để saving không tiếp nhận keyboard input.

ledgerFeedback là helper render từ AsyncValue, không persistence/API: các route/sheet/forms hiển thị loading/StorageRecovery trước khi đọc requireValue hoặc projections. Usage initState có thể mở trước load; account/quota/usage edit kiểm not-found. Form State/controllers/ID/DraftGuard vẫn giữ qua Retry; account/history có search controller riêng để text khớp filter. ConfirmedActionButton giữ lifecycle confirmation→write→success/error, guard repeated actions/dispose; Profile khóa từ lúc hỏi confirmation và disable Leave trong operation. Không đổi VM/service boundaries hoặc snapshot schema.

31 lib/12 test files; thêm23 accessibility/state và3 brand tests, full168. Figma annotations là handoff design metadata, không phụ thuộc runtime/build. Không thêm package hoặc runtime assets. Xem fidelity-check/test-report cho matrix, original/annotation nodes và limitations.
