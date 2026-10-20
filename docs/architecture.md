# Kiến trúc TokenLedger — trạng thái code hiện hành

Hiện trạng21/10/2026 sau A04:33 lib/14 test files; schema2/model/default purposes/multiple quota windows/provenance/cycle/timezone và analytics/history local đã triển khai, xem [upgrade](local-p0-upgrade.md). Các số106/142/168 tests bên dưới giữ theo lịch sử; full Firebase schema/owner/services trong plan chưa có.

Cập nhật21/10/2026. Tài liệu này mô tả implementation local hiện tại; [implementation plan](IMPLEMENTATION_PLAN.md) mô tả cả những phần chưa build.

## 1. Bootstrap và dependency injection

`main.dart` khởi tạo Flutter bindings, override `ledgerRepositoryProvider` bằng `LocalLedgerRepository.open()`, rồi chạy `TokenLedgerApp` trong `ProviderScope`. Repository mở SharedPreferences lúc load; lỗi khởi tạo plugin cũng vào error/Retry, không làm bootstrap dừng trước khi render app.

`app.dart` tạo MaterialApp và theme. `demoSessionProvider` chọn Login hoặc Shell; `/?demo=1` mở demo trực tiếp. Đây là điều hướng demo, không có Firebase Auth hoặc user identity thật.

Không có network request provider, API key, Firebase initialize hoặc Analytics telemetry trong ứng dụng hiện tại.

## 2. Ranh giới lớp

| Lớp | File chính | Trách nhiệm |
|---|---|---|
| Model | `lib/models/ledger.dart` | Plain Dart, schema, JSON serialization; enum Purpose/BillingMode |
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
| Login | Demo entry; Google disabled/pending |
| Shell |4 destinations; desktop sidebar từ1000dp, mobile bottom navigation |
| Dashboard | Budget, selected-period metrics, 7-day chart, quota, latest/purpose; Ghi sử dụng |
| Accounts | Search, active/archive state, create/detail |
| AccountForm / Detail | Metadata/budget CRUD; quota, purpose, archive/restore, empty delete |
| UsageForm / Purpose | Account/title/token/cost/date/note; grid9 purposes, giữ controllers khi chọn purpose |
| History / detail sheet | Search/range/account/purpose drilldown, edit/delete usage |
| QuotaForm | Window key/name/unitpercent, used%, observed/reset time/source label/note, create/edit/delete guard |
| Analytics | Cost/token/session metrics, donut/legend, account comparison, history filter |
| Profile | Pending services, demo restore/clear/leave |

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
