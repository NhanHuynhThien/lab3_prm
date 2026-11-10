# TokenLedger

TokenLedger giúp người dùng biết **AI nào đang được sử dụng, token dùng cho việc gì, tốn bao nhiêu và trong khoảng thời gian nào**. Ứng dụng Flutter cho PRM393 Lab 3; chủ đề chuyển từ StudentPay đã được giảng viên duyệt theo xác nhận user 21/10/2026.

## Người dùng và nghiệp vụ

| Chức năng | Người dùng làm gì | Kết quả |
|---|---|---|
| Đăng nhập | Dùng tài khoản Google | Workspace riêng theo UID, không có login demo |
| Tài khoản AI | Thêm/sửa, archive hoặc xóa account rỗng | Quản lý provider/model, ngân sách và lịch sử |
| Phiên sử dụng | Companion tự ghi từng task CLI (Codex, Claude Code, Gemini CLI); user chỉ sửa mục đích/tên/ghi chú hoặc ẩn. Nhập tay chỉ cho nguồn không đọc được | Một sổ usage chung có thể tìm kiếm/sửa/xóa |
| Tổng quan | Xem quota agent đang kết nối và tổng token/phiên trong kỳ | Một dashboard: quota agent ở trên, số liệu từ cùng sổ usage |
| Phân tích | Lọc theo kỳ, account, mục đích và xem chi tiết | Tổng token/chi phí, tỷ trọng và coverage nguồn |
| Quota | Theo dõi từng account và cửa sổ quota | Có thời điểm cập nhật; không cộng quota% giữa account |
| Nguồn AI | Kết nối companion local hoặc nhập Takeout do user chọn | Chỉ lấy dữ liệu nguồn hỗ trợ; thiếu số liệu hiển thị unknown |
| Báo cáo | Chọn kỳ, tạo và mở PDF trên thiết bị | Không upload PDF lên cloud |
| Hồ sơ | Xem tài khoản đăng nhập, thông báo và chẩn đoán | Quản lý phiên và các tích hợp Firebase |

Ba flow chính: **kết nối Companion → usage tự vào sổ (nhập tay là dự phòng) → xem phân tích**; **lọc lịch sử → mở chi tiết → sửa/xóa usage**; **xem account → quota/lịch sử → archive**. Lỗi lưu phải giữ draft và cho thử lại; dữ liệu không được lẫn giữa UID khi logout.

## Quy tắc số liệu và quyền riêng tư

- Tiền lưu integer USD micros; `null` là chưa biết, khác số 0. Giá suy từ token phải có nguồn và nhãn estimate, không gọi là hóa đơn.
- Token/quota/tốc độ/thời gian chỉ xuất hiện khi nguồn có dữ liệu tương ứng. Thời gian gọi API không phải thời gian user làm việc.
- Firestore owner rules tách dữ liệu cá nhân. Companion là nguồn chính của usage; thiếu Companion thì app vẫn chạy với sổ nhập tay.
- Dữ liệu tự động (`users/{uid}/auto_usage`): mỗi task CLI theo ngày địa phương, ID là hash, chỉ có nhãn mục đích suy từ từ khóa (suy ngay trên máy), model, token và thời gian; không upload prompt, đường dẫn hay session ID. Gói thuê bao không có chi phí từng phiên nên chi phí để unknown. Account tự động (`auto-codex`, `auto-claude`, `auto-google`) không sửa/lưu trữ/xóa tay; ẩn phiên thì Companion không thêm lại.
- Admin chỉ vận hành model/bảng giá/thông báo và trạng thái hệ thống; không xem nội dung chat hay toàn bộ sổ token của user.
- Gemini/FCM/Supabase secret không nằm mobile hoặc frontend bundle. Không đọc Gmail, cookies hoặc thay đổi bảo mật tài khoản Google.

## Web quản trị

Repo độc lập: [lab3_prm_web_admin](https://github.com/NhanHuynhThien/lab3_prm_web_admin). Next.js + shadcn/ui, backend Fastify, DB Supabase cho dữ liệu vận hành. Local checkout ở `../lab3_prm_web_admin/`. Dữ liệu account/usage cá nhân vẫn ở Firestore.

## Chạy mobile

Giữ `pubspec.lock`. Cấu hình local dùng `.env` JSON đã được Git ignore; build mặc định không nhúng file env vào APK. Backend cho phân tích Gemini và hộp thư được cấu hình qua `TOKENLEDGER_API_URL`, mặc định `http://127.0.0.1:8788` trong môi trường dev.

```sh
flutter pub get
# Fresh clone: tạo .env chứa {} nếu chưa có cấu hình local
flutter devices
./tool/start_lab3_120hz.sh
# Hoặc chọn device:
flutter run -d <device-id>
```

Android cần Google Play services và SHA debug đã đăng ký đúng Firebase project `tokenledger-nhan-20261021`. Emulator Pixel 10 Pro đã cấu hình 120Hz; nghiệm thu bài và performance vẫn cần device thật.

```sh
flutter analyze
flutter test
node --test tool/provider_bridge/*.test.mjs
```

04/11: analyzer sạch, 391 Flutter tests pass sau thay đổi bỏ upload PDF. E2E/console/MobAI còn thiếu được đánh dấu riêng, không suy từ unit/widget tests.

## Phát triển Companion desktop

Companion là app Flutter macOS trong chính project này (entry `lib/main_companion.dart`, source `lib/companion/`, native shell `macos/Runner/AppDelegate.swift`). Mở Companion, đăng nhập cùng tài khoản Google với mobile qua trình duyệt và bật đồng bộ. Có tùy chọn tự khởi động khi đăng nhập máy (LaunchAgent, chỉ bản release); đóng cửa sổ sẽ tiếp tục chạy ở thanh menu.

Token tự cập nhật ngầm theo thay đổi log CLI, chỉ ghi Firestore khi aggregate đổi. Hạn mức được kiểm tra mỗi 5 phút; lỗi mạng tự thử lại. Phiên đăng nhập lưu trong Keychain macOS, aggregate và quota ghi vào `users/{uid}/provider_snapshots/latest`, từng task ghi upsert vào `users/{uid}/auto_usage/{id}` với update mask chỉ gồm trường của Companion (chỉ gửi dòng đổi). CLI `tool/provider_bridge/cloud.mjs` chưa ghi `auto_usage`. Firebase public config lấy từ `DefaultFirebaseOptions.web`.

```sh
flutter test test/companion
flutter run -d macos -t lib/main_companion.dart
flutter build macos --release -t lib/main_companion.dart
```

App build ra `build/macos/Build/Products/Release/TokenLedger Companion.app`. App tắt App Sandbox vì cần đọc log CLI, chạy lệnh usage chỉ đọc, dùng Keychain và LaunchAgent; bản local chưa ký/notarize. Collector Node trong `tool/provider_bridge/` vẫn dùng cho status line Claude Code và bridge phát triển (`adb reverse tcp:8787 tcp:8787`).

## Tiến độ và tài liệu bài

[Xem TASKS.md](TASKS.md) cho toàn bộ việc đã làm, việc cần làm, tiêu chí nghiệm thu, rủi ro và audit theo đề. Đây là nguồn tiến độ duy nhất của mobile.

Đề chuẩn: **From Design to Working App with Flutter and Firebase, 17 trang**. Giữ [yêu cầu chuẩn hóa](docs/ASSIGNMENT_REQUIREMENTS.md) và 7 tài liệu bắt buộc trong `docs/`. User bỏ upload PDF là ngoại lệ với đề gốc; chưa tự coi giảng viên đã miễn. MobAI/report/video và một số evidence Firebase chưa đủ điều kiện nộp hoàn chỉnh.

[Figma Lab 2](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336) · [Handoff Lab 2](https://github.com/dmm717/lab2_prm/blob/main/handoff/flutter-handoff.md). Design system: Inter, green `#006C49`, background `#FAF8FF`, mint `#E8F7EF`, radius 20/12 và touch ≥48. Login mượn composition BeeWise theo yêu cầu user.

Nguồn và quy tắc sử dụng logo, biểu tượng, font được gom tại [tài nguyên](assets/README.md).
