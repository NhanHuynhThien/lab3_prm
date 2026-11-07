# TokenLedger

TokenLedger giúp người dùng biết **AI nào đang được sử dụng, token dùng cho việc gì, tốn bao nhiêu và trong khoảng thời gian nào**. Ứng dụng Flutter cho PRM393 Lab 3; chủ đề chuyển từ StudentPay đã được giảng viên duyệt theo xác nhận user 21/10/2026.

## Người dùng và nghiệp vụ

| Chức năng | Người dùng làm gì | Kết quả |
|---|---|---|
| Đăng nhập | Dùng tài khoản Google | Workspace riêng theo UID, không có login demo |
| Tài khoản AI | Thêm/sửa, archive hoặc xóa account rỗng | Quản lý provider/model, ngân sách và lịch sử |
| Phiên sử dụng | Ghi công việc, mục đích, token, thời gian và chi phí có nguồn | Sổ usage có thể tìm kiếm/sửa/xóa |
| Tổng quan | Xem các agent/provider thực sự đã sử dụng | Dashboard theo nguồn, không lặp màn tài khoản |
| Phân tích | Lọc theo kỳ, account, mục đích và xem chi tiết | Tổng token/chi phí, tỷ trọng và coverage nguồn |
| Quota | Theo dõi từng account và cửa sổ quota | Có thời điểm cập nhật; không cộng quota% giữa account |
| Nguồn AI | Kết nối companion local hoặc nhập Takeout do user chọn | Chỉ lấy dữ liệu nguồn hỗ trợ; thiếu số liệu hiển thị unknown |
| Báo cáo | Chọn kỳ, tạo và mở PDF trên thiết bị | Không upload PDF lên cloud |
| Hồ sơ | Xem tài khoản đăng nhập, thông báo và chẩn đoán | Quản lý phiên và các tích hợp Firebase |

Ba flow chính: **tạo account → ghi usage → xem phân tích**; **lọc lịch sử → mở chi tiết → sửa/xóa usage**; **xem account → quota/lịch sử → archive**. Lỗi lưu phải giữ draft và cho thử lại; dữ liệu không được lẫn giữa UID khi logout.

## Quy tắc số liệu và quyền riêng tư

- Tiền lưu integer USD micros; `null` là chưa biết, khác số 0. Giá suy từ token phải có nguồn và nhãn estimate, không gọi là hóa đơn.
- Token/quota/tốc độ/thời gian chỉ xuất hiện khi nguồn có dữ liệu tương ứng. Thời gian gọi API không phải thời gian user làm việc.
- Firestore owner rules tách dữ liệu cá nhân. Companion là lựa chọn bổ sung, không bắt buộc cho core flows.
- Admin chỉ vận hành model/bảng giá/thông báo và trạng thái hệ thống; không xem nội dung chat hay toàn bộ sổ token của user.
- Gemini/FCM/Supabase secret không nằm mobile hoặc frontend bundle. Không đọc Gmail, cookies hoặc thay đổi bảo mật tài khoản Google.

## Web quản trị

Repo độc lập: [lab3_prm_web_admin](https://github.com/NhanHuynhThien/lab3_prm_web_admin). Next.js + shadcn/ui, backend Fastify, DB Supabase cho dữ liệu vận hành. Local checkout ở `../lab3_prm_web_admin/`. Dữ liệu account/usage cá nhân vẫn ở Firestore.

## Chạy mobile

Giữ `pubspec.lock`. Cấu hình local duy nhất là `.env` JSON, Git ignore. Pairing token chỉ phục vụ ghép nối local; build mặc định không nhúng file env vào APK. Companion có bộ cài desktop tại `companion/dist/` sau khi build. Cài TokenLedger Companion, mở ứng dụng, đăng nhập cùng tài khoản Google với mobile và bật đồng bộ. Cửa sổ có đồng bộ ngay, tạm dừng, đăng xuất và tùy chọn tự mở khi đăng nhập máy. Đóng cửa sổ vẫn chạy ở thanh menu. Phiên dùng kho bảo mật hệ điều hành; token được cập nhật theo thay đổi log CLI, gom sự kiện theo chu kỳ chọn trên giao diện (2/5/10/30 giây, mặc định 5 giây) và ghi vào `users/{uid}/provider_snapshots/latest` khi aggregate thay đổi. Native watcher có kiểm tra metadata dự phòng để xử lý sự kiện bị bỏ lỡ. Hạn mức được làm mới mỗi 5 phút; lỗi mạng tự thử lại. Lệnh CLI sync dành cho phát triển vẫn dùng chu kỳ 5 phút. Lệnh CLI `cloud.mjs` tiếp tục dùng cho phát triển. `setup.mjs` chỉ còn chuẩn bị status line Claude và mã cho chế độ ghép trực tiếp khi dev. Không đưa Gemini/service-account keys vào file này. Phân tích Gemini và hộp thư cần địa chỉ backend qua `TOKENLEDGER_API_URL` (mặc định `http://127.0.0.1:8788`, chỉ dùng cho môi trường dev).

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

```sh
cd companion
npm ci
npm test
npm run build:mac
```

Bản macOS Apple Silicon nằm ở `companion/dist/TokenLedger Companion-0.1.2-arm64.dmg` và thư mục `mac-arm64`. Gói runtime dùng Firebase public config tại `tool/provider_bridge/firebase-config.json`, chạy độc lập với source Flutter và Node cài ngoài. Source desktop ở `companion/src/`; các collector được tái sử dụng từ `tool/provider_bridge/`. CLI `login/once/install` dành cho phát triển, người dùng thao tác qua giao diện. Bản macOS local chưa ký/notarize; Windows cần build và nghiệm thu trên môi trường phù hợp.

## Tiến độ và tài liệu bài

[Xem TASKS.md](TASKS.md) cho toàn bộ việc đã làm, việc cần làm, tiêu chí nghiệm thu, rủi ro và audit theo đề. Đây là nguồn tiến độ duy nhất của mobile.

Đề chuẩn: **From Design to Working App with Flutter and Firebase, 17 trang**. Giữ [yêu cầu chuẩn hóa](docs/ASSIGNMENT_REQUIREMENTS.md) và 7 tài liệu bắt buộc trong `docs/`. User bỏ upload PDF là ngoại lệ với đề gốc; chưa tự coi giảng viên đã miễn. MobAI/report/video và một số evidence Firebase chưa đủ điều kiện nộp hoàn chỉnh.

[Figma Lab 2](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336) · [Handoff Lab 2](https://github.com/dmm717/lab2_prm/blob/main/handoff/flutter-handoff.md). Design system: Inter, green `#006C49`, background `#FAF8FF`, mint `#E8F7EF`, radius 20/12 và touch ≥48. Login mượn composition BeeWise theo yêu cầu user.
