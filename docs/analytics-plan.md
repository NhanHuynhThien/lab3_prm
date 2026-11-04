# Analytics plan — TokenLedger

Cập nhật22/10/2026, chuẩn PDF17trang §6.8,tr6–7. SDK code có nhưng event contract/DebugView còn gaps; bảng này phân biệt mục tiêu với source hiện tại. Không đánh hoàn tất chỉ từ unit tests.

## Flows và câu hỏi đo lường

F0 Google login/logout; F1 ghi usage; F2 phân tích→history→detail; F3 account/quota CRUD. Đo việc vào màn và mutation confirmed để thấy flow sử dụng/thất bại; không đo bằng nội dung chat, token/cost hoặc dữ liệu tài khoản cá nhân.

| Event yêu cầu | Trigger/parameters cần có | Source hiện tại / việc cần sửa |
|---|---|---|
| `login` | Auth thành công,`method=google` | Có lifecycle event, gồm restore; không suy count là số lần bấm |
| `logout` | Rời UID trước clear SDK identity | Có auth lifecycle event |
| `screen_view` | Mỗi route,`screen_name` | Hiện4tabs; cần phủ forms/detail/source/report/notification routes |
| `view_account`,`view_usage` | Mở entity,`item_id`,`item_name` | Có event vớidetail_type, còn thiếu params theo đề; cần safe ID/name policy, không gửi alias/titlePII |
| `create_account`,`update_account`,`delete_account` | Sau repository confirmed,`item_id` | Source đangaccount_saved(action)/account_deleted; cần đổi contract |
| `create_usage`,`update_usage`,`delete_usage` | Sau repository confirmed,`item_id` | Source đangusage_saved(action)/usage_deleted; cần đổi contract |
| `create_quota`,`update_quota`,`delete_quota` | Sau snapshot mutation confirmed,`item_id` | Source đangquota_saved(action)/quota_deleted; cần thống nhất tên |
| `export_pdf` | **Sau export+upload thành công**,`item_count` | Sourceexport_report trước upload vàupload_report riêng; chưa đạt yêu cầu |
| `remote_config_refresh` (custom) | Refresh hoàn tất,`outcome` | Có; lỗi giữ last-good config, không đẩy lỗi sang CRUD |
| `notification_received`,`notification_opened` (custom) | Nhận/mở thông báo thật,enum params | Có service event; cần routing/delivery và Console evidence thật |

Tên lowercase/digits/underscore≤40chars; payload typed/allowlist, không arbitrary map từ widget.≥2custom events và cả params phải được xác nhận trong DebugView đúng project.

## Privacy và lifecycle

Firebase UID khi auth-ready; không email/displayName/photo/account alias/work title/note/chat/search/provider credentials, tiền/token/quota vào Analytics. Business data vẫn ở Firestore của user, không trở thành tracking payload. Item name requirement cần dùng tên entity chung/safe taxonomy, không đưa tên user nhập tùy ý.

Serialize identity changes/events; logout trước clear UID/disable, bỏ stale queue khi owner đổi. Mutation chỉ log sau success, dedupe operation ID bounded trong app session, không hứa exactly-once qua reload. SDK fail không làm save fail. Signed-out không ghi business events; không có runtime demo.

Tắt automatic Android screen reporting để MainActivity không thay route. Debug build bằng `--dart-define=FIREBASE_ANALYTICS_DEBUG=true`; không coi last submitted event hoặc SDK enabled là server nhận.

## Kế hoạch evidence

1. Sửa event naming/route/params/export timing, unit tests success-only/privacy/lifecycle/dedupe.
2. Chạy dedicated test account; mở từng route, create/update/delete, export **upload success**, nhận/mở FCM và RCrefresh.
3. Chụp DebugView từng event/params, auth lifecycle đúng project hiện hành; che identity nếu đưa vào bài nộp.
4. Đối chiếu MobAI/manual flow với Logcat/DebugView; unit/fake transports không thay evidence online.

Project `tokenledger-nhan-20261021` chưa có DebugView evidence đầy đủ/liên kết GA được xác nhận. RC setup/evidence xem [firebase-setup](../TASKS.md), kết quả thực xem [test-report](test-report.md).
