# Analytics plan — TokenLedger

Ngày21/10/2026. Viết trước tracking code của lượt Analytics/Remote Config. Scope: user Google thật trong cloud workspace; sandbox demo không gửi events. Source là Firestore do người dùng nhập, không provider sync. Kết quả kiểm tra thủ công được người dùng xác nhận trong hội thoại, không phải Analytics evidence.

## Câu hỏi và success criterion

Theo 3 flows Lab2 đã chuyển sang TokenLedger: F1 ghi usage thành công, F2 tìm/phân tích và mở đúng detail, F3 quản lý account/quota. Đo lượt vào các màn và mutations thành công để nhận biết flow nào được dùng/hoàn tất; không dùng số token/cost/chi tiết công việc làm tracking data. Success criterion cụ thể của persona tiếp tục tham chiếu Lab2 reference/traceability, không tự đặt chỉ tiêu phần trăm đạt.

| Event | Trigger thành công | Typed parameters cho phép | Flow / câu hỏi |
|---|---|---|---|
| login | Auth state chuyển sang UID khác/null→UID, kể cả restore phiên | method:string=`google`, entry:string=`auth_state` | F0: bao nhiêu phiên authenticated được mở? Restore được tính, không suy thành số người bấm login |
| logout | Auth state rời UID sang null hoặc UID khác, trước khi clear SDK identity | reason:string=`auth_state` | F0: phiên nào kết thúc? Có thể logout/token expiry/account switch, không suy duration từ count |
| screen_view | Mở workspace ban đầu/chọn tab khác | screen_name:string enum overview/accounts/analytics/profile | F1–F3: người dùng đi tới các destination nào? IndexedStack rebuild không tạo event |
| view_account | User chủ động mở account detail | detail_type:string=`account` | F3: account details được mở bao nhiêu lần? Không gửi account alias/ID |
| view_usage | User chủ động mở usage detail sheet | detail_type:string=`usage` | F1/F2: bao nhiêu lượt xem chi tiết sau history/dashboard? |
| account_saved | Account mutation repository confirmed | action:string enum create/update | F3: bao nhiêu account được tạo/cập nhật? Archive/restore tính update |
| account_deleted | Empty account deletion confirmed | action:string=`delete` | F3: bao nhiêu tài khoản rỗng bị xóa? |
| usage_saved | Usage repository confirmed | action:string enum create/update | F1: bao nhiêu phiên được ghi/sửa thành công? Không suy failed request là saved |
| usage_deleted | Usage deletion confirmed | action:string=`delete` | F1: mức độ chỉnh sửa dữ liệu đã ghi? |
| quota_saved | Quota window mutation confirmed | action:string enum create/update | F3: quota được cập nhật thường xuyên không? Không gửi %/source text |
| quota_deleted | Quota delete confirmed | action:string=`delete` | F3: bao nhiêu quota windows bị xóa? |
| remote_config_refresh | Chủ động refresh hoàn tất | outcome:string enum success/failure | Demo area: cấu hình refresh có hoàn tất không? |
| export_report | **Planned**, chỉ khi sinh PDF thật thành công | format:string=`pdf` | Export: lượt tạo report. Chưa implement PDF, không phát event giả |
| upload_report | **Planned**, chỉ khi upload thật thành công | destination:string=`cloud_storage` | L3: bao nhiêu exports được upload? Phụ thuộc quyết định Storage, không log giả |

≥7 events đang có phạm vi implementation; export/upload phải được nối khi feature đó được triển khai, nên gate toàn plan/DebugView vẫn mở. Không có search keyword tracking: primary action là usage_saved; mọi kind detail hiện có gồm account và usage. Khi thêm Report/Notification detail phải thêm safe event tương ứng trước code.

## Privacy, identity và lifecycle

- Firebase UID đặt bằng setUserId sau auth-ready; không gửi email/displayName/photo/alias/title/note/product/model/custom source/search text hoặc tiền/token/quota values. Không log thông điệp exception thô, URL hoặc credentials.
- Payload allowlist tên event/parameter và enum, không nhận arbitrary widget parameters. Tên recommended login/screen_view khi phù hợp; custom snake_case. Không tự bật quảng cáo/user properties.
- Auth restore/switch/logout xử lý theo hàng đợi SDK; logout event trước clear UID/disable collection. Demo hoặc signed-out không ghi business events. Tắt automatic screen reporting Android để không ghi MainActivity thay route. Web automatic events không dùng để chứng minh flow/custom event coverage.
- Tracking là best effort: failure không làm CRUD thất bại; UI Profile báo lỗi SDK theo message sanitized, không nói đã thấy DebugView. Mutation events chỉ sau repository success, dedupe operationId trong session; retry receipt cùng ID không gửi lặp trong lifetime coordinator. Không claim exactly-once toàn install/reload/server.
- Debug flag chủ động qua `--dart-define=FIREBASE_ANALYTICS_DEBUG=true`; dev evidence dùng DebugView, không gửi tên cá nhân. Service chưa gửi events từ seed/demo.

## Verification cần thu thập

Unit/fake tests: allowlist/noPII, success-only, SDK failure không throw vào CRUD, owner lifecycle/queued stale events/dedupe, demo disabled, tab/detail events không do rebuild. UI checks giữ360/412dp và Lab2 tokens.

Manual pending: chạy real SDK trên web/Android; DebugView từng event/params/user identity lifecycle đúng project; Android Analytics debug bằng thiết bị thật nếu cần. ≥1 ARTEMIS test phải đối chiếu event bằng Logcat/DebugView; không coi fake transport tests hoặc manual CRUD trước đó là analytics evidence. Export/upload và future detail events chưa có feature vẫn pending.

Nguồn API chính thức: [Flutter log events](https://firebase.google.com/docs/analytics/events?platform=flutter), [collection controls](https://firebase.google.com/docs/analytics/configure-data-collection?platform=flutter), [Remote Config Flutter](https://firebase.google.com/docs/remote-config/flutter/get-started). API/version thực dùng ghi sau pub resolve/verification, không giả console evidence.
