# Analytics và Remote Config — implementation và nghiệm thu

Verification21/10: **326/326 Flutter tests pass185s**,27 mới; analyzer sạch14.9s, format76files0changed; web release JS53.8s pass.52 lib/24 test Dart files. Không chạy emulator/Android/ARTEMIS hoặc console verification; xem [test report](test-report.md).


Ngày21/10/2026. Tiếp theo manual cloud checks do người dùng xác nhận. [Analytics plan](analytics-plan.md) được viết trước instrumentation; [baseline](ASSIGNMENT_REQUIREMENTS.md) giữ scope/evidence đầy đủ. Lượt này không chạy máy ảo hoặc thay billing, không publish template Remote Config và không tự tạo console screenshots/events để giả nghiệm thu.

## Source và hành vi

- SDK đã resolve: firebase_analytics13.0.0, firebase_remote_config7.0.0; lockfile giữ dependencies thực tế. Chỉ Firebase transports trong services gọi SDK; models/plain services/VM/widgets tách lớp.
- Main inject AnalyticsService/FirebaseAnalyticsTransport và RemoteConfigService/FirebaseConfigTransport. Root auth lifecycle điều khiển identity; cloud containers chia sẻ đúng services root, demo dùng no-op/defaults riêng. Telemetry không nhận arbitrary strings: event/parameter enums allowlist, không gửi email/names/account aliases/work titles/notes/amounts/tokens/quota/provider credentials.
- Auth UID transitions (kể cả restore) log login/logout theo auth_state; serialized queue set identity trước events, clear/disable sau logout. Không suy login count là số lần bấm nút. Cloud mutation events sau repository confirmation, dedupe operation ID bounded512 trong app session; không claim exactly-once qua reload. SDK failure không làm business save fail.
- Tab events trên initial overview và tab selection; account detail1 lần mỗi route, usage detail mỗi lần user mở sheet, không log vì IndexedStack rebuild. Export/upload events còn planned tới lúc feature PDF thật có implementation.
- Android collection mặc định tắt trong manifest; chỉ service enable khi Google session sẵn sàng; automatic Android screen reporting tắt để tránh MainActivity thay route. Firebase SDK có automatic lifecycle events/cache riêng: app không claim xóa lịch sử Analytics đã gửi hoặc bảo đảm không có SDK startup events từ setting được SDK persist ở lần chạy trước. Demo không gửi business/seed events và không init SDK qua Dart khi bắt đầu trực tiếp demo.
- Profile tách Analytics và Crashlytics: Analytics chỉ báo SDK state/last submitted event; Crashlytics vẫn chưa nối. Lỗi telemetry sanitized; chưa có DebugView evidence, không hiển thị nhãn khẳng định console đã nhận.

## Remote Config parameters

| Key | Type/default | Clamp | Hành vi |
|---|---|---|---|
| overview_recent_limit | Number/3 |1–10| Số usage rows ở Tổng quan → Sử dụng gần đây |
| budget_warning_percent | Number/80 |1–100| Banner cảnh báo khi chi phí đã ghi trong kỳ đạt ngưỡng ngân sách |

Defaults cùng [JSON](../firebase/remote-config-defaults.json); số không parse được fallback riêng từng key, source ghi default. Giá trị remote vượt bounds được clamp. Budget chưa đặt/0 không xuất warning; tiền giữ integer micros và không đổi công thức tổng. Giới hạn recent rows chỉ thay presentation, không giới hạn dataset/report/chart.

SDK ensureInitialized dùng activated cache, setDefaults, fetchAndActivate. Cold failure giữ activated cache/defaults; failure sau success giữ last-good values, message/Retry. Concurrent refresh share1 request; prepare/fetch có timeout, dispose bỏ late publication. Profile hiển thị effective values/source/time và nút refresh. Timestamp là lần SDK check/fetchAndActivate hoàn tất trong phiên app, **không đảm bảo mỗi lần đã tải template mới từ mạng** (release cache12h).

Debug build minimumFetchInterval0; release12h; fetchTimeout15s (service guard prepare15s/fetch20s). Không real-time listener: publish→Refresh trong debug là đường demo được hỗ trợ. Release cần chờ interval; không hứa instantaneous update.

## Hướng dẫn kiểm thật một đợt

1. Khởi động lại Flutter sau thêm dependencies (hot reload không đủ): chạy từ root repo `flutter run -d chrome --web-hostname localhost --web-port 4183 --dart-define=FIREBASE_ANALYTICS_DEBUG=true`. Nếu port đang được dev server cũ dùng, dừng đúng phiên đó bằng q/Ctrl+C trước chạy lại; không dừng process Flutter khác tự động.
2. Đăng nhập Google, mở Cá nhân. Xem Cấu hình và đo lường: defaults3/80 hoặc activated remote. Nếu Analytics/RemoteConfig initialization/config/network fail, app vẫn dùng cloud ledger độc lập và báo message phù hợp.
3. Firebase Console → project tokenledger-lab3 → tìm Remote Config (menu có thể đổi nhóm). Tạo hai parameters đúng key ở bảng trên, Number, default values3/80; publish nếu chưa có. Trước khi sửa template có sẵn, giữ các keys/conditions khác.
4. Tạo ít nhất3 usage records trên Google test account; dữ liệu thử có nhãn và không dùng tài khoản cá nhân trong ARTEMIS. Trong console đổi overview_recent_limit=1 → publish → Cá nhân/Làm mới cấu hình → Tổng quan chỉ1 recent row, tổng cost/token/số phiên không đổi. Đổi thành3 rồi kiểm lại.
5. Để thấy warning, chọn ngân sách/chi phí test sao cho tỷ lệ nằm giữa hai ngưỡng. Ví dụ budget20USD, spent1USD (5%): warning_percent=4 hiện banner, warning_percent=80 ẩn. Chỉ dùng dữ liệu thử có kiểm soát, không sửa dữ liệu thật vì demo. Cả hai lần publish→refresh không rebuild; ảnh console/effective source remote/app before-after.
6. Test Offline bằng Chrome Network sau khi đã có remote values. Refresh thất bại giữ values/source cũ, báo lỗi; Online→refresh khôi phục. Không reload offline hoặc suy SDK cache là network success.
7. Analytics Console/DebugView: mở4tabs, xem account/usage detail, create/update/delete usage/account/quota, logout/login; đối chiếu events/typed params theo analytics-plan.md. Nếu console yêu cầu liên kết Analytics/property, hoàn tất trên đúng project trước kiểm; SDK success không chứng minh DebugView. Ad blockers/browser restrictions có thể chặn telemetry dù Firestore vẫn chạy.
8. DebugView đủ từng event/params và auth lifecycle còn **pending đến khi có evidence thật**. Muốn thêm Android evidence dùng điện thoại thật, debug flag và Analytics debug mode theo docs Firebase; không chạy máy ảo. ARTEMIS analytics assertion vẫn cần làm ở giai đoạn E2E, không thay bằng ảnh fake transports.

## Manual cloud checks đã được người dùng xác nhận

Trong hội thoại21/10, người dùng báo đã đạt: account create/edit/budget/reload; usage create/edit/delete/totals; Google A/B isolation và trở lại A; offline save giữ draft/retry không trùng; unknown token/cost không cộng giả0; required/token-pair/negative input/Back draft; analytics purpose drilldown; archive/restore/history/new-usage guard; empty-account delete; quota create/edit/delete/multiple windows/percent bounds, không đổi tiền/token.

Provenance là **user-reported web checks** trên app hiện hành, có các ảnh hội thoại ở một số bước; không phải agent-controlled device test, automated integration, test run logs, concurrency stress, native Android, ARTEMIS, Rules Emulator hoặc analytics DebugView. Không tick toàn GATE/native/REQ-L3-14 từ xác nhận này. Không copy ảnh temp/machine paths vào repo.

## Evidence chưa có

Console Remote Config before/after và DebugView cho Analytics, Android/device/native cert matrix, ARTEMIS3runs+analytics assertion, PDF export/upload event hooks, FCM/Crashlytics/PDF/Figma cloud sync vẫn còn backlog. File này không tự chứng minh các mục đó đã chạy.

Nguồn chính thức: [Remote Config Flutter setup](https://firebase.google.com/docs/remote-config/flutter/get-started), [Analytics events Flutter](https://firebase.google.com/docs/analytics/events?platform=flutter), [collection controls](https://firebase.google.com/docs/analytics/configure-data-collection?platform=flutter). Các số clamp/timeouts là quyết định app, không phải quota/billing Firebase.
