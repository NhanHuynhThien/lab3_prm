# Kiến trúc TokenLedger — trạng thái code hiện hành

Cập nhật 20/10/2026. Tài liệu này mô tả implementation local hiện tại; [implementation plan](IMPLEMENTATION_PLAN.md) mô tả cả những phần chưa build.

## 1. Bootstrap và dependency injection

`main.dart` khởi tạo Flutter bindings, lấy `SharedPreferences`, override `ledgerRepositoryProvider` bằng `LocalLedgerRepository`, rồi chạy `TokenLedgerApp` trong `ProviderScope`.

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
2. Lần đầu chưa có storage: tạo seed rồi persist; dữ liệu đã tồn tại thì load lại, không tự chèn seed vào mỗi lần mở app.
3. Form gửi model tới LedgerViewModel, VM validate rồi save snapshot mới.
4. Chỉ khi repository save thành công mới publish `AsyncData(next)`; save fail giữ dữ liệu cũ và trả lỗi cho form.
5. `_writing` chặn hai mutation đồng thời trong cùng instance; usage form giữ operation ID ổn định để retry không tạo hai bản.
6. Reporting providers derive kết quả từ ledger/range/clock; widgets render cùng một nguồn số liệu.
7. Shell dùng IndexedStack giữ state/scroll khi đổi tab; fade điều khiển riêng để không dispose form/filter của tab chỉ vì animation.

`clockProvider` cho phép tests cố định thời gian. Đây chưa phải lịch IANA timezone hay scheduler: dữ liệu local dùng timezone thiết bị và tháng dương lịch.

## 4. Models và persistence

| Model | Nội dung quan trọng |
|---|---|
| AIAccount | id, alias, provider/product, billingMode, plan, budgetMicros nullable, archived, createdAt, một quota snapshot tùy chọn |
| UsageSession | id/accountId/title/purpose/occurredAt, input/output nullable, costMicros nullable, note |
| QuotaSnapshot | window, usedPercent, observedAt/resetAt; quá reset là stale |
| LedgerData | immutable accounts/sessions lists; schemaVersion 1 và JSON round trip |

SharedPreferences key: `tokenledger.demo.v1`. Snapshot không có ownerUID, encryption hoặc multi-device conflict resolution. Nó chỉ dùng cho demo; không lưu credential hoặc coi đây là production data store.

Không tự sửa/xóa blob corrupt trong load: UI có error/retry, tránh ghi đè dữ liệu mà chưa có hành động chủ động. Trước migration schema phải thiết kế backup/validation và test version cũ.

## 5. Các quy tắc nghiệp vụ đã thực hiện

- Tiền là integer USD micros,1USD=1,000,000 micros. Parser nhận dấu chấm/phẩy thập phân, không nhận âm/NaN, tối đa6 chữ số thập phân.
- Token thiếu khác token0; usage input/output cùng biết hoặc cùng để trống. Phiên chỉ có công việc vẫn hợp lệ nhưng coverage ghi rõ missing.
- Tổng cost là tổng các cost đã nhập; không tự tạo estimate theo giá provider. Tổng token chỉ là volume đã ghi.
- Dashboard metric/range là selected period; riêng budget card có label tháng và luôn tính chu kỳ tháng. Không áp range 7 ngày lên monthly budget rồi gọi là số dư tháng.
- Budget còn lại=budget tự đặt trừ cost đã ghi của active accounts có budget trong tháng; không phải provider credit balance. Chưa có budget thì hiện Chưa đặt ngân sách.
- Quota nhập tay độc lập usage logs; không quy% thành token hoặc cộng% giữa accounts. Sau reset không tự về100%.
- Usage edit không đổi accountId. Account có lịch sử không hard-delete được; archive giữ lịch sử và chặn tạo usage mới. Account rỗng có thể xóa.
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
| QuotaForm | Window, used%, reset time và source nhập tay |
| Analytics | Cost/token/session metrics, donut/legend, account comparison, history filter |
| Profile | Pending services, demo restore/clear/leave |

Navigation dùng Navigator/MaterialPageRoute và sheet, chưa có router URL đầy đủ cho mọi screen/deep link Firebase. Chưa có discard-draft dialog khi Back khỏi form.

## 7. Test và mở rộng

7 calculator tests +4 VM tests +5 widget tests=16. Widget tests gồm navigation/layout360/412/768/1440 và usage validation/save. Chúng không thay thế Android/MobAI/Firestore tests.

Khi nối Firebase cần mở rộng repository snapshot sang owner-scoped stream/atomic operations, add auth lifecycle, rules/indexes/transaction tests. Không dùng client snapshot toàn bộ như cơ chế merge backend. Thứ tự và backlog: [firebase-pending](firebase-pending.md), [task checklist](TASK_CHECKLIST.md).
