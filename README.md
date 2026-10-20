# TokenLedger — PRM393 Lab 3

## Publication21/10

Theo yêu cầu “push hết lên cho tôi”, target là [branch codex/local-form-safety](https://github.com/NhanHuynhThien/lab3_prm/tree/codex/local-form-safety), gồm checkpoint Flutter d4b6167 và commit tài liệu visual handoff chứa đoạn này. Xem Git log/remote refs cho SHA publication; các đoạn “chưa push” bên dưới ghi thời điểm trước yêu cầu này. Không merge main hoặc thay visibility. Runtime giữ nguyên bản200 tests đã kiểm; Firebase/native/lecturer acceptance vẫn pending.

Ứng dụng **Flutter/Dart** quản lý tài khoản AI, phiên sử dụng, token, chi phí và quota. Core UI kế thừa StudentPay Lab 2. Android là platform của bài lab; web dùng để chạy preview.

## Trạng thái hiện tại

Checkpoint local21/10 trên branch `codex/local-form-safety` (SHA: `git log -1 --oneline`), chưa push. Audit và phạm vi kiểm chứng ở [build status](docs/build-status.md).

- Dashboard responsive và 4 tab: Tổng quan, Tài khoản, Phân tích, Cá nhân.
- Account CRUD, archive/restore; account có lịch sử chỉ được archive, account rỗng có thể xóa.
- Usage CRUD, model tùy chọn, mục đích gợi ý từ tài khoản; lịch sử nhóm ngày và bộ lọc account/purpose/provider.
- Chi phí nhập tay bằng USD micros, token/cost chưa biết được giữ riêng.
- Quota nhập tay theo nhiều cửa sổ độc lập, có nguồn/ghi chú/quan sát/reset và stale riêng; thêm/sửa/xóa từng cửa sổ.
- MVVM + Riverpod, local persistence bằng SharedPreferences; dữ liệu mẫu có thể reset.
- Form account/usage/quota xác nhận khi Back có thay đổi, giữ draft khi lưu lỗi; có thể sửa usage lịch sử của account archived nhưng không tạo phiên mới cho account đó.
- Validation dùng chung form/VM/storage; lỗi dữ liệu local có Retry và khôi phục có xác nhận/sao lưu, migration schema1 →2 có sao lưu raw trước replace.
- Báo cáo/quota cập nhật theo thời gian và khi quay lại app; ID ngẫu nhiên không phụ thuộc đồng hồ.
- Ngân sách theo kỳ account (ngày1–31/múi giờ IANA), timestamps UTC; báo cáo chọn múi giờ, mặc định Asia/Ho_Chi_Minh cho dữ liệu mới. Dữ liệu cũ giữ policy device.
- Báo cáo tách dữ liệu nhập tay/demo/dữ liệu cũ, có phân loại chi phí và nhóm provider; không trộn các nguồn vào một tổng.
- UI đã audit8 màn kế thừa/9 nhóm component; layout360/412/768/1440×800, chữ1/1.3/2, keyboard/SafeArea và dữ liệu dài có regression tests.
- Accessibility/states: keyboard focus/semantics/reduced motion; loading/error/Retry giữ draft/filter, destructive actions có confirmation guard. Figma8 màn đã có annotation chuyển đổi và notes bổ sung.
- Logo vector gốc, font Inter bundle, Android/PWA icons và animation hỗ trợ reduced motion.

**Firebase đang pending:** chưa có Google Auth, Firestore, FCM, Remote Config, Crashlytics, Analytics hoặc PDF/cloud export. Demo không tự đọc usage/quota từ Claude/Codex.

Figma P0 đã có8 màn360/412 và mẫu trạng thái chỉnh sửa được; xem [visual handoff](docs/visual-handoff-21-10.md) cho links/đối chiếu và các sai khác còn lại. Chưa nghiệm thu pixel/native/backend.

## Chạy bằng Flutter

Đã kiểm tra gần nhất với Flutter 3.47.4 / Dart 3.13.3. Dùng `pubspec.lock` để resolve đúng dependency.

```sh
git clone https://github.com/NhanHuynhThien/lab3_prm.git
cd lab3_prm
flutter pub get
flutter run -d chrome --web-port 4183
```

Chọn **Mở không gian demo** hoặc mở `http://localhost:4183/?demo=1`. Dừng bằng Ctrl+C. Toàn bộ dev server và compilation do Flutter quản lý.

Seed gồm 3 accounts, 12 usage sessions giả định. Mọi thay đổi lưu trên thiết bị/trình duyệt hiện tại; origin/port khác có dữ liệu khác. Không cần Firebase config để chạy. Demo không có xác thực và không dùng để lưu credential thật.

Lần mở dữ liệu schema1 sẽ sao lưu raw rồi chuyển sang schema2, giữ nguyên số liệu; chọn **Dữ liệu cũ** để xem. Reset/clear chỉ xóa dữ liệu đã gắn nhãn demo, giữ dữ liệu nhập tay/dữ liệu cũ. Chi tiết [migration và phạm vi local](docs/local-p0-upgrade.md).

## Kiểm tra và build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Web output nằm trong `build/web/` và không được commit.

Android SDK/licenses đã được xác nhận21/10. Khi có thiết bị Android thật để kiểm tra (không chạy emulator theo yêu cầu):

```sh
flutter devices
flutter run -d <android-device-id>
flutter build apk --debug
```

Application ID: `com.tokenledger.token_ledger`. Ngày21/10 đã xác nhận Android toolchain và build debug APK trước B03–B13; APK đó không đại diện source hiện hành. Cài/chạy native hoãn theo yêu cầu không dùng emulator. Xem [test report](docs/test-report.md); build APK không thay device smoke test.

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
test/             # 200 unit/widget tests
```

Git theo dõi source Flutter, cấu hình platform, lockfile, tài liệu và assets cần thiết. Build/cache, tooling skill cài local, bản chụp tài liệu Lab2, ảnh/log inspector và đề PDF được loại khỏi source tree trên GitHub.

## Tài liệu

- [Kiến trúc hiện tại](docs/architecture.md), [build status](docs/build-status.md), [test report](docs/test-report.md).
- [Nâng cấp P0 local/model/migration](docs/local-p0-upgrade.md).
- [Phạm vi và gaps A03–A06](docs/scope-decisions.md), [roadmap](docs/APP_COMPLETION_ROADMAP.md).
- [Kế hoạch](docs/IMPLEMENTATION_PLAN.md), [checklist](docs/TASK_CHECKLIST.md): có cả tính năng chưa triển khai.
- [Nguồn thiết kế Lab2](docs/lab2-ui-reference.md), [design changes](docs/design-change-log.md), [handoff gaps](docs/handoff-gaps.md), [UI audit/fidelity draft](docs/fidelity-check.md).
- [Firebase pending](docs/firebase-pending.md), [AI log](docs/implementation-ai-log.md), [docs index](docs/README.md).
- [Agent instructions](AGENTS.md), [agent context/workflows](.agents/README.md).

Không có backend scripting trong dự án. Bộ skill UI không có trong checkout hiện tại; đó là công cụ phát triển tùy chọn, không phải dependency để clone/build app.
