# Firestore — thiết kế và repository, 21/10/2026

Checkpoint foundation mục1–2 dưới đây được tiếp tục bằng [workspace mục3–5](firestore-workspace.md): UI/VM và rules/indexes đã nối/deploy. Những đoạn “chưa” của foundation là trạng thái trước mục3–5. Phạm vi checkpoint ban đầu: mục1 thiết kế dữ liệu và mục2 dependency/repository. Đã thêm `cloud_firestore 7.0.0`, contract streams/atomic CRUD, converters và adapter SDK. Chưa inject vào ViewModel/giao diện, chưa ghi dữ liệu lên project, chưa viết/deploy Security Rules hoặc deploy indexes. Profile vẫn ghi Firestore “Chưa nối” đúng trạng thái. Không thay billing, telemetry, chạy máy ảo hoặc tự import dữ liệu local.

Người dùng xác nhận đã đăng nhập Google trên web, reload giữ session, logout/login lại và thấy user trong Firebase Console; sau đó xác nhận đã tạo Firestore. Đây là kết quả người dùng báo, không phải agent tự chạy OAuth/native hoặc đọc Console database configuration.

## 1. Paths và phiên bản

| Path dưới `users/{uid}` | Implementation hiện có |
|---|---|
| `accounts/{accountId}` | Account metadata, budget/cycle/source, revision và relation counters |
| `usage_sessions/{usageId}` | Usage có relation accountId bất biến, token/cost nullable |
| `quota_windows/{quotaId}` | Mỗi quota window là một document độc lập |
| `quota_labels/{labelId}` | Reservation cho tên quota không trùng trong account, phục vụ transactions |
| `settings/reporting` | Múi giờ báo cáo có revision và receipt |
| `mutations/{operationId}` | Receipt của command đã commit, chống retry trùng và resurrect bản đã xóa |

Không query collection toàn cục rồi lọc UID. Root user document chưa tự tạo; subcollections có thể tồn tại độc lập. User profile/settings, reports, notifications, devices và lịch sử quota không nằm trong phạm vi lượt này. Paths này được dành cho các bước sau, chưa có model/service giả.

Cloud envelope `schemaVersion=1` độc lập với snapshot local `schemaVersion=2`. Mỗi document account/usage/quota có chính xác các field:

| Field | Quy tắc |
|---|---|
| `ownerId` | UID cố định bằng owner trên path; không nhận owner từ form |
| `schemaVersion` | integer1; phiên bản khác lỗi, không tự ghi đè |
| `revision` | integer dương, tối đa9007199254740991; optimistic concurrency |
| `createdAt`, `updatedAt` | server Timestamp; createdAt giữ nguyên khi sửa |
| `lastOperationId` | ID command/receipt tương ứng cho rules getAfter |
| `payload` | Domain fields, allowlist theo converter; thời gian domain là Timestamp |

Account có thêm `usageCount`, `quotaCount` integer không âm, `lastUsageMutationId`, `lastQuotaMutationId` nullable. Chỉ repository cập nhật chúng cùng child mutation. Count không dùng làm số liệu tài chính. Receipt có `ownerId/schemaVersion/intent/revision/createdAt/collection/entityId/action`; `intent` là JSON command ổn định, không chứa OAuth/provider credentials. Receipt revision là kết quả command tại thời điểm commit, không phải revision hiện tại sau các thao tác khác.

## 2. Mapping từ model hiện hành

- Account payload dùng fields của `AIAccount.toJson()` trừ `quotaWindows`, thêm `currency='USD'`: id/alias/provider/product/billingMode/plan/budgetMicros/archived/createdAt/defaultModelId/defaultPurposes/timezone/cycleStartDay/isDemo/dataSource. Không đổi các enum/provider labels trong source local hoặc tự đoán provider IDs. `archived` thay status enum của plan; `cycleStartDay/timezone` thay period cố định, cùng policy đã có trong ReportingCalendar. `payload.createdAt` là thời gian nghiệp vụ, envelope.createdAt là thời gian tạo bản ghi cloud; cả hai bất biến khi edit.
- Usage payload giữ id/accountId/title/purpose/occurredAt/modelId/dataSource/costBasis/isDemo/inputTokens/outputTokens/costMicros/note, thêm currencyUSD. Một costMicros duy nhất phân loại bằng costBasis; chưa có estimate/pricing snapshot, không cộng reported+estimated hai lần. Cost basis null trên model được normalize thành unknown hoặc unspecified theo dữ liệu, không thành actual.
- Quota payload là accountId cộng toàn bộ `QuotaSnapshot.toJson()`: window/windowKey/unit/source/sourceLabel/note/usedPercent/observedAt/resetAt. unit chỉ percent, không suy allowance từ token hoặc usage. Sau mục3, ID là SHA-256 lowercase hex từ `accountId + newline + windowKey` để rules tính và kiểm chứng cùng công thức; label ID dùng tên trim/lowercase thay key. Base64 JSON của foundation chưa deploy không còn dùng. UTF8 document ID tối đa1500 bytes; tên/key vẫn qua giới hạn domain Unicode.
- USD integer micros,1USD=1000000micros. Token input/output cùng null hoặc cùng integer; null không thành0. Timestamps UTC trong SDK; IANA/cycle1–31 giữ nguyên. Unknown/stale quota không tự reset; metadata-only edit của stale quota giữ snapshot cũ, đổi observation/percent phải validate thời gian mới.
- Account cloud không chứa quota list. `CloudRecord<AIAccount>.value.quotaWindows` rỗng có chủ đích; lớp projection sau này ghép với stream quota riêng trước khi render. Không hiểu list rỗng đó là mọi account không có quota.
- `LedgerValidation` vẫn dùng chung. Totals sau này phải lấy đủ dataset và kiểm giới hạn safe integer khi ghép/aggregate, không dùng counter hoặc một trang lịch sử thay tổng.

Không thay schema local, không tự migrate/upload snapshot SharedPreferences, không tự tạo seed cho user cloud mới. Import/seed cloud sẽ là thao tác rõ ràng riêng, có source/isDemo và counters đúng.

## 3. Contract và lifecycle

Source: [models](../lib/models/cloud_ledger.dart), [contract](../lib/services/cloud_ledger_repository.dart), [repository](../lib/services/firestore_ledger_repository.dart), [converters](../lib/services/firestore_ledger_codec.dart), [SDK store](../lib/services/firestore_ledger_store.dart).

`FirestoreLedgerRepository.forCurrentUser()` chỉ được gọi trong service composition sau khi Firebase/Auth ready. Factory lấy UID thật và tạo instance cố định cho UID đó. Tests inject LedgerCloudStore thay SDK. Giao diện/VM không import Firebase; không thay LocalLedgerRepository bằng adapter snapshot cloud.

- Streams: watchAccounts với archived optional/order updatedAt desc; watchUsage theo `[start,end)` UTC, optional account/purpose/order occurredAt desc; watchQuotas theo account/order updatedAt desc. Usage stream không limit/page, thích hợp dữ liệu Lab; pagination riêng sẽ làm sau, không lấy một page để tính tổng kỳ.
- Chưa có sự kiện đầu tiên là loading ở consumer; snapshot.records rỗng là empty; snapshot có records là data; stream error là typed failure. Không chèn seed để thay empty/error. Lỗi stream đóng listener; Retry tạo subscription mới với cùng query. ViewModel bước sau cần giữ last good data/filter, chưa có cơ chế đó trong UI cloud.
- Snapshot giữ fromCache/hasPendingWrites, chỉ serverConfirmed khi cả hai false. Timestamp server chưa resolve có thể null khi pending; không gọi cache/pending là kết quả đã xác nhận.
- Lưu theo command, Future chỉ complete khi transaction được SDK xác nhận. Offline transaction có thể fail, không hứa queue. Repository không tự thêm timeout làm giả thất bại/thành công; sau lỗi chưa rõ kết quả, retry đúng command và operationId.
- Edit/delete phải gửi expectedRevision từ bản đọc. Nếu bản mới đã thay đổi, conflict và không đè sửa của thiết bị khác. Tạo/update không tự upsert bản đã mất; đổi accountId của usage bị chặn. UUID entity IDs không tái sử dụng cho một vòng đời mới.
- Repository có auth listener, phiên thay UID bị revoke vĩnh viễn kể cả A→B→A. Mọi write kiểm UID trước/trong/sau transaction; streams cũng kiểm và dừng khi user đổi. Consumer phải cancel/close instance khi logout/dispose. In-flight command có thể đã commit dưới UID cũ trước lúc logout; không báo thành công cho phiên mới, không chuyển path sang UID mới.
- Typed failures: unauthenticated/permission/unavailable/conflict/notFound/invalidData/closed; thông báo không lộ raw SDK errors/credentials. Client guard giúp lifecycle, không thay thế Security Rules.

## 4. Atomic mutations và retry

Mọi write đọc receipt trước. Nếu operationId đã commit với đúng intent, trả kết quả cũ, không sửa document/count lần nữa. Cùng operationId nhưng khác command/payload/expectedRevision bị conflict. Receipt và tất cả entity/counter/label writes nằm cùng transaction. Không xóa receipt độc lập; cleanup/retention phải có thiết kế mới để không phá retry sau mất acknowledgement.

- Create account: document phải chưa có, counters0 và relation markers null. Sửa metadata giữ counters, createdAt/source/isDemo. Archive/restore là updateAccount dùng revision.
- Create usage: account cùng UID tồn tại, active và cùng isDemo; usage ID mới; usageCount+1 và lastUsageMutationId=usageId cùng commit. Edit giữ accountId/source/isDemo, không đổi count; archived account vẫn sửa/xóa history. Delete usage giảm count1 và xóa document; count sai/âm bị chặn.
- Hard-delete account chỉ khi usageCount=0 **và** quotaCount=0. Account có quota cần xóa quota riêng trước, hoặc archive giữ lịch sử. Không cascade toàn collection. Usage/quota create và account delete cùng đọc/ghi parent nên xung đột transaction được retry, không tạo orphan qua adapter hợp lệ.
- Quota create/update/delete đọc parent và quota, kiểm revision, reserve/release label cùng commit; không trùng key hoặc tên chuẩn hóa trong account. Rename giữ windowKey. Form cũ không resurrect quota đã xóa. Account revision cũng tăng để stale metadata edit không ghi đè relation state.
- SDK có thể chạy callback nhiều lần; callback không publish UI, không sinh IDs, không gọi external service. Dùng stable entity ID và operationId tạo ngoài callback, giữ nguyên payload cho retry chưa rõ kết quả. Khi đã nhận conflict và user sửa command sau reload, cấp operationId mới.

## 5. Indexes và bước kế tiếp

[firestore.indexes.json](../firebase/firestore.indexes.json) có5 composite indexes cho account active/order, usage account/purpose/cả hai + kỳ, quota account/order; tắt index receipt.intent. File chưa gắn Firebase CLI config hoặc deploy, không báo index đã ready. Query chỉ theo occurredAt/order dựa single-field index mặc định.

Bước3: viết default-deny rules với exact owner/field/type/null/bounds/immutable/revision/relations; getAfter phải đối chiếu usageCount/quotaCount và child trước/sau, bảo vệ mutations receipts và quota_labels khỏi forge/delete/counter tamper. Cần xác minh canonical quota/label ID trong rules hoặc điều chỉnh layout trước deploy; client reservations chưa chứng minh chống request tự tạo. Kiểm A/B/unauth, forged receipt/counter/reference, races và quota rename. Không mở Test mode. User yêu cầu không chạy máy ảo; phương án rules verification cần tách khỏi Android emulator và được nêu rõ ở bước đó.

Bước4–5: nối repository vào Riverpod theo UID, ghép account/usage/quota đủ kỳ, last-good/error/retry/draft cleanup và empty user flow; không gọi factory trong widget build. Chỉ sau rules/indexes và integration thực mới đổi Profile sang Firestore đã kết nối hoặc đánh backend gates hoàn tất.

## 6. Verification

35 tests mới trong [firestore_ledger_repository_test.dart](../test/firestore_ledger_repository_test.dart) dùng optimistic fake store local: empty user/path A/B, schema/currency/null/zero/UTC, version conflict, archive/history, receipt/lost acknowledgement/retry after delete, usage/quota create vs account delete, concurrent duplicate command, quota labels/stale metadata, permission/network, stream cache/pending/error/cancel/logout/close. Fake cấm transaction read sau write.

Đây là unit tests của contract/repository, **không evaluate Security Rules, không chạy Firestore emulator hoặc database thật**. Kết quả full regression/analyzer/build được ghi ở [test report](test-report.md). Nguồn SDK semantics: [transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [metadata/listeners](https://firebase.google.com/docs/firestore/query-data/listen), [offline/cache](https://firebase.google.com/docs/firestore/manage-data/enable-offline).
