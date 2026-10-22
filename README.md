# TokenLedger — PRM393 Lab 3

Flutter app quản lý tài khoản AI, phiên sử dụng, token, chi phí nhập tay và quota. Android là platform bài lab; web hỗ trợ preview. Topic chuyển từ StudentPay sang TokenLedger đã được giảng viên chấp thuận theo xác nhận người dùng21/10/2026.

## Chuẩn bài và trạng thái

Dùng PDF **From Design to Working App with Flutter and Firebase,17trang** do người dùng chỉ định22/10. Đọc [yêu cầu](docs/ASSIGNMENT_REQUIREMENTS.md), [audit chi tiết](docs/requirements-audit.md) và [kiến trúc hiện tại](docs/architecture.md). Bản18trang/ARTEMIS trước đây là tài liệu khác.

- Google login thật, Profile và Firestore workspace theo UID; **không runtime demo/seed/bypass**. Tạo dữ liệu qua form account/usage/quota.
- 8 màn kế thừa Lab2 + Login/Profile/Quota; 4 tabs mobile, desktop sidebar. USD micros và null=unknown.
- PDF/FCM/Crash/Analytics có client implementation nhưng còn gaps và console evidence; **chưa đủ điều kiện nộp hoàn chỉnh**. MobAI/report/video còn thiếu.
- Provider companion là extension tùy chọn do user yêu cầu; core Firestore flows không cần companion. Codex/Claude/Gemini CLI theo nguồn khả dụng; Antigravity quota qua CLI chính thức; Gemini web qua JSON Takeout do user chọn. Không suy token/phí khi thiếu nguồn và không đọc Gmail/cookies/credentials.

## Thiết kế Lab2

- [Figma gốc + annotations](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336).
- [Lab2 flutter-handoff.md](https://github.com/dmm717/lab2_prm/blob/main/handoff/flutter-handoff.md); bản workspace đọc đối chiếu ở `../lab2_prm/handoff/flutter-handoff.md` (không phải runtime dependency).
- [Fidelity và mapping8màn](docs/fidelity-check.md), [design changes](docs/design-change-log.md), [handoff gaps](docs/handoff-gaps.md).
- Login lấy composition BeeWise Mobile của user, giữ logo/Inter/green/mint TokenLedger; các khác biệt token/Figma cần nghiệm thu trong design log.

## Chạy app

Toolchain đã dùng22/10: Flutter3.47.5 / Dart3.13.4, AndroidAPI36 ARM64. Giữ `pubspec.lock`.

```sh
flutter pub get
cp .env.example .env.local
flutter devices
./tool/start_lab3_120hz.sh
```

`.env.local` là JSON Dart defines, không commit. Không điền provider API secrets. Firebase client identifiers trong `firebase_options.dart`/`android/app/google-services.json` không phải admin credentials. Emulator cần Google Play services và SHA debug đăng ký đúng Firebase.

Web preview:

```sh
flutter run -d chrome --web-hostname localhost --web-port 4183
```

Đăng nhập bằng Google, tạo account rồi ghi usage. Signed-out chỉ thấy Login. New user bắt đầu empty; dữ liệu chỉ của UID đó. Không có đường `?demo=1` để bỏ qua login.

### Firebase và storage

Project hiện hành `tokenledger-nhan-20261021` (Spark). Auth/Firestore/RC setup và giới hạn trong [migration notes](docs/firebase-setup.md). Rules/indexes/config ở `firebase/` và `firebase.json`; không deploy chỉ vì build.

PDF đang dùng Firebase Storage transport, nhưng Storage chưa được provision/billing và report metadata chưa lưu Firestore; upload chưa đạt §6.4. PDF cho phép Cloudinary restricted unsigned PDF preset như đường miễn phí; việc chuyển adapter chưa thực hiện. Không đưa secret hoặc service-account key vào app. Analytics của project mới chưa có DebugView evidence; không coi SDK status là Console pass.

### Companion tùy chọn

```sh
node tool/provider_bridge/server.mjs
adb reverse tcp:8787 tcp:8787
```

Bridge chỉ loopback, ghép nối token; [setup/scope](docs/provider-sync.md). Owner auto-connect là opt-in trong `.env.local`, token không in log/commit. Antigravity cần official `agy` CLI đã đăng nhập. Gemini web cần user tự xuất/ chọn Takeout JSON; import local aggregate, không lưu nội dung hội thoại/không lấy mail.

## Source tree

```text
lib/{models,services,viewmodels,screens,widgets,theme,utils}
android/                    Android + Google client config
firebase/                   rules, indexes, RC defaults/template
assets/                     fonts, Google icon, brand/provider logos
 test/                      unit/widget regression + fixtures
 tool/provider_bridge/      optional local read-only source adapters
 docs/                      13 tài liệu: 7 bắt buộc + setup/architecture/audit
```

`mobai_tests/` chưa có run/scripts hợp lệ; không tạo placeholder để nhận là hoàn thành. Repo submission cần tên `PRM393_Lab03_<StudentID>`; remote hiện tại vẫn `lab3_prm`.

## Kiểm tra

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
node --test tool/provider_bridge/*.test.mjs
flutter build apk --debug
flutter build web --release
```

22/10: 391/391 Flutter tests pass,26 Node tests pass, Androidprofile/webrelease build pass, analyzer sạch. Đây là unit/widget verification; native từng flow và Firebase Console có báo cáo riêng, không thay10MobAI. Xem [test report](docs/test-report.md) và [audit](docs/requirements-audit.md).
