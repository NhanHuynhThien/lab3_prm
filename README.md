# TokenLedger — PRM393 Lab 3

Ứng dụng **Flutter/Dart** quản lý tài khoản AI, phiên sử dụng, token, chi phí và quota. Core UI kế thừa StudentPay Lab 2. Android là platform của bài lab; web dùng để chạy preview.

## Trạng thái hiện tại

- Dashboard responsive và 4 tab: Tổng quan, Tài khoản, Phân tích, Cá nhân.
- Account CRUD, archive/restore; account có lịch sử chỉ được archive, account rỗng có thể xóa.
- Usage CRUD, mục đích công việc, lịch sử và bộ lọc.
- Chi phí nhập tay bằng USD micros, token/cost chưa biết được giữ riêng.
- Quota nhập tay có thời gian quan sát/reset, hiển thị stale khi quá reset.
- MVVM + Riverpod, local persistence bằng SharedPreferences; dữ liệu mẫu có thể reset.
- Logo vector gốc, font Inter bundle, Android/PWA icons và animation hỗ trợ reduced motion.

**Firebase đang pending:** chưa có Google Auth, Firestore, FCM, Remote Config, Crashlytics, Analytics hoặc PDF/cloud export. Demo không tự đọc usage/quota từ Claude/Codex.

## Chạy bằng Flutter

Đã kiểm tra với Flutter 3.47.5 / Dart 3.13.4. Dùng `pubspec.lock` để resolve đúng dependency.

```sh
git clone https://github.com/NhanHuynhThien/lab3_prm.git
cd lab3_prm
flutter pub get
flutter run -d chrome --web-port 4183
```

Chọn **Mở không gian demo** hoặc mở `http://localhost:4183/?demo=1`. Dừng bằng Ctrl+C. Toàn bộ dev server và compilation do Flutter quản lý.

Seed gồm 3 accounts, 12 usage sessions giả định. Mọi thay đổi lưu trên thiết bị/trình duyệt hiện tại; origin/port khác có dữ liệu khác. Không cần Firebase config để chạy. Demo không có xác thực và không dùng để lưu credential thật.

## Kiểm tra và build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Web output nằm trong `build/web/` và không được commit.

Khi đã cài Android SDK/emulator:

```sh
flutter devices
flutter run -d <android-device-id>
flutter build apk --debug
```

Application ID: `com.tokenledger.token_ledger`. Chưa xác nhận APK/native test trên máy hiện tại vì thiếu Android SDK ở lần kiểm tra trước.

## Source tree

```text
lib/
  main.dart        # Flutter bootstrap, repository override
  app.dart         # MaterialApp, theme, demo entry
  models/          # account, usage, quota, JSON schema
  services/        # local repository, seed, pure calculator
  viewmodels/      # mutations, validations, reporting projections
  screens/         # dashboard, accounts, usage, analytics, profile
  widgets/         # shared components, charts, logo painter
  theme/           # Lab2 tokens và motion
  utils/           # money/date formatting
android/           # native Android project và launcher icons
web/               # Flutter web host, PWA icons/manifest
assets/fonts/      # Inter và OFL license
assets/brand/      # source SVG/logo documentation; không bundle vào app
test/             # 16 unit/widget tests
```

Git theo dõi source Flutter, cấu hình platform, lockfile, tài liệu và assets cần thiết. Build/cache, tooling skill cài local, bản chụp tài liệu Lab2, ảnh/log inspector và đề PDF được loại khỏi source tree trên GitHub.

## Tài liệu

- [Kiến trúc hiện tại](docs/architecture.md), [build status](docs/build-status.md), [test report](docs/test-report.md).
- [Kế hoạch](docs/IMPLEMENTATION_PLAN.md), [checklist](docs/TASK_CHECKLIST.md): có cả tính năng chưa triển khai.
- [Nguồn thiết kế Lab2](docs/lab2-ui-reference.md), [design changes](docs/design-change-log.md), [handoff gaps](docs/handoff-gaps.md).
- [Firebase pending](docs/firebase-pending.md), [AI log](docs/implementation-ai-log.md), [docs index](docs/README.md).
- [Agent instructions](AGENTS.md), [agent context/workflows](.agents/README.md).

Không có backend scripting trong dự án. Skill UI đã cài ở local là công cụ phát triển tùy chọn, không phải dependency để clone/build app.
