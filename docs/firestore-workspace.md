# Firestore workspace — mục3–5, 21/10/2026

Đã nối4 màn quản lý hiện hành vào dữ liệu Firestore theo UID: Tổng quan, Tài khoản, Phân tích, Cá nhân. Google user mới thấy dữ liệu rỗng; app không tự seed hoặc import SharedPreferences. Demo local vẫn là không gian riêng. Rules, kết quả triển khai và giới hạn bằng chứng xem [test report](test-report.md).

Rules đã deploy vào tokenledger-lab3/(default);5 indexes READY được đọc lại lúc2026-10-21T06:09:30Z, remote rules khớp source và unauth read bị403. Chưa kiểm authenticated SDK CRUD bằng tài khoản thật thay người dùng.

## Chạy và kiểm tra bằng tài khoản thật

Nếu app cũ vẫn chạy, dừng terminal Flutter bằng Ctrl+C, vào root dự án rồi chạy:

```sh
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 4183
```

1. Đăng nhập Google. App mở Tổng quan với4 tab; user mới không có Claude/Codex seed. Chờ banner đồng bộ biến mất. Cá nhân chỉ báo Firestore **Đã kết nối** khi cả4 streams đã được server xác nhận, không phải chỉ vì SDK khởi tạo được.
2. Tài khoản → Thêm tài khoản. Nhập alias/provider/product/plan và ngân sách nếu có; không nhập password, API key hoặc cookie. Lưu xong reload để kiểm dữ liệu vẫn còn.
3. Ghi usage, ví dụ input8000/output2000/cost0.05USD. Đây là số tự nhập để kiểm tra: known tokens10000/cost50000micros. Sửa cost0.07 rồi xóa phiên, đối chiếu cùng kỳ/nguồn với Tổng quan và Phân tích. Không coi số này là usage hoặc giá provider xác thực.
4. Thêm quota theo window, thời điểm quan sát và reset ở tương lai. Kiểm nguồn/note/percent; quota độc lập với usage, qua reset chỉ thành stale. Quota và account lưu riêng, được ghép trước khi render.
5. Đổi múi giờ báo cáo rồi reload; lựa chọn lưu ở settings/reporting của UID. Ngân sách account vẫn tính theo timezone/cycle riêng.
6. Đăng xuất: về Login, Back không mở form/private route cũ. Nếu có Google user B, đăng nhập B và kiểm không thấy dữ liệu A. Sau đó vào lại A để kiểm dữ liệu A vẫn còn. Không tạo fake Google users để thay bước kiểm này.
7. Cá nhân → Mở demo local riêng biệt: hiện dữ liệu trên thiết bị, không hiển thị identity Google là owner; cloud listeners dừng. Thoát demo mở lại cloud session nếu còn đăng nhập. Reset/clear demo không ghi/xóa Firestore.

Console: Firebase → Firestore Database → users → UID của chính user → accounts/usage_sessions/quota_windows/settings. Document user cha có thể chưa tồn tại; Profile metadata vẫn lấy từ Auth SDK. Không sửa counters/receipts/quota_labels trực tiếp để thử UI; chúng bảo vệ transaction và retry.

## Kiến trúc state và lifecycle

- AuthGate chờ userChanges. Mỗi UID hoặc demo có `_WorkspaceScope` với ProviderContainer độc lập và nested Navigator. Chỉ chia sẻ service boundaries, clock và auth action coordinator; không kế thừa ledger/projections/filter cache từ root hoặc workspace trước. UID đổi/thoát demo thì toàn container/routes/forms/controllers bị dispose.
- CloudLedgerViewModel override API của LedgerViewModel để tái sử dụng screens/reporting/calculators. Mọi mutation cloud gọi repository theo operation; không dùng LocalLedgerRepository.load/save(snapshot). Base methods mới có optional revision nên local behavior giữ nguyên.
- 4 owner-scoped streams: accounts, toàn usage, toàn quota, settings. Full datasets phục vụ quy mô Lab và các kỳ/cycle; không tính totals từ một page. Projection chỉ publish khi references và usageCount/quotaCount khớp, tránh state ghép nửa transaction. LedgerValidation.snapshot tiếp tục kiểm tổng safe integer và null semantics.
- Loading → empty/data/error; lỗi listener giữ last-good data và search/filter/draft. Lỗi không tự biến thành connected chỉ vì stream khác cập nhật. Retry ở banner ngoài Navigator hoạt động cả khi form đang mở; concurrent retries dùng chung một connection. Bootstrap timeout20s và disposal không để attach listener muộn.
- Cache/pending/coherence/server metadata riêng. Chỉ confirmed khi cả4 streams từ server, không pending và dữ liệu ghép nhất quán. Có cache thì xem được nhưng mutation chờ confirmed; offline transaction có thể fail, không giả queued write hoặc success. Firestore factory tắt disk persistence trước operation đầu; SDK in-memory cache vẫn có thể tồn tại theo paths, app không claim đã xóa vật lý toàn SDK cache.
- Mất auth/đóng repo xóa state nhạy cảm của VM ngay, hủy listeners và dọn pending commands. App path luôn cố định theo ownerUID, không query A rồi lọc khi đang là B. `close()` chặn late writes báo success; server có thể đã commit dưới A trước logout, không chuyển mutation sang B.
- Một auth action coordinator tại root xử lý cả Login và workspace logout để chặn double tap dù các workspace containers độc lập. Same-UID metadata refresh vẫn cập nhật tên/email/avatar mà không reset tab/form.

## Save, draft và conflict

Form account/usage/quota/settings giữ revision khi mở;0 là token tạo mới, không tự chuyển thành update khi record mới xuất hiện. Retry chưa rõ kết quả giữ operationId, payload và closure/revision gốc. Sửa payload trong lúc kết quả trước chưa rõ bị chặn; không cấp ID mới rồi tạo bản trùng. Receipt đã commit có thể xác nhận lại dù record sau đó bị xóa; stream, không phải receipt revision cũ, quyết định state hiển thị.

Conflict không tự lấy revision mới để ghi đè thiết bị khác. Draft giữ nguyên; xem lại bản mới và mở form mới trước khi quyết định sửa tiếp. Lưu fail không pop form hoặc báo thành công. Snapshot local demo không làm fallback cho cloud lỗi.

Account có usage không hard-delete; archive giữ lịch sử, chặn usage mới và cho sửa/xóa phiên cũ. Account có quota cũng cần xóa các window trước khi hard-delete hoặc chọn archive. Không cascade cả collections không kiểm soát.

## Rules và schema bổ sung

[Rules](../firebase/firestore.rules) default deny. Chỉ ownerUID có thể đọc các ledger subcollections. Writes có allowlists, type/bounds, USD/integer/null/token-pair/source/enums, immutable owner/createdAt/accountId và revision. IANA đầy đủ được validate phía Dart; rules giới hạn cấu trúc/độ dài timezone. Rules string-size là giới hạn wire bảo thủ, không hứa tương đương mọi cụm Unicode/grapheme của local form.

- Account/usage/quota/settings envelope có `lastOperationId`. Receipt thêm collection/entityId/action, phải gắn với mutation thực trong getAfter hoặc deletion thực; không cho tự sửa/xóa receipt để vô hiệu retry.
- Usage create/delete bắt buộc child và account counter/marker tương ứng trước/sau cùng transaction. Quota create/update/delete bảo vệ quotaCount, parent revision và label reservation. Chỉ parent counter không có child/receipt hợp lệ bị deny.
- Quota và label IDs chuyển từ base64 JSON của foundation chưa deploy sang SHA-256 lowercase hex của `accountId + newline + key`; label dùng tên trim/lowercase thay key. Rules tính cùng hash và đối chiếu canonical ID, không tin ID do client tự chọn. Không chạy migration/import hoặc xóa dữ liệu cloud cũ không nhận diện được.
- `settings/reporting`: envelope + payload.reportingTimezone, create/update có revision/receipt. User/Report/Notification/Device services chưa triển khai; paths còn lại bị deny.
- `firebase.json` giữ nguyên FlutterFire config và thêm rules/indexes cho database(default).5 composite ledger indexes và exemption receipt.intent có source. CLI triển khai bằng project ID rõ ràng, không đổi billing/visibility hoặc bật services ngoài phạm vi.

## Verification và giới hạn

299 Flutter tests pass, gồm14 cloud VM tests và11 cloud workspace tests mới: CRUD/totals/quota/settings, lost acknowledgement/retry không duplicate, stale save/draft, error/cache/pending/last-good/search, initial error/Profile/logout, dispose/retry concurrency, A/B và demo isolation. Auth15 tests hiện có đã thích nghi với4-tab workspace, giữ assertions. UI360/412/1440×800, text1/2, Inter/MaterialIcons; ảnh Profile fixture đã xem, không phải ảnh Firestore hoặc Google user thật.

142 cases qua Rules Test API trên source thật: allow các writes hợp lệ và deny foreign/unauth write tương ứng, ownership/schema/currency/counter/receipt/reference/quota ID/rename/delete/unknown paths. API có get/getAfter/exists/existsAfter mocks đầy đủ cho trạng thái trước/sau fixtures; không ghi Firestore documents, không chạy emulator. Cách chạy lại cần Node + Firebase CLI đã login:

```sh
node tool/firestore_rules_test.cjs tokenledger-lab3
```

Đây là mô phỏng service rules và fake-store MVCC/UI tests, chưa thay thế Google user A/B thật, SDK transactions qua mạng, native/device/Play services, flaky network hay giới hạn document access calls của một batch thực. Sau deploy, cần chạy bước manual phía trên để nghiệm thu G3/G4; không tự tick các gate này từ số tests. FCM/Remote Config/Crashlytics/Analytics SDK/PDF chưa nối. Figma chưa cập nhật sau cloud workspace.
