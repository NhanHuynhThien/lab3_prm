# TokenLedger — PRM393 Lab 3

## Provider sync và giao diện thống kê

Nguồn AI nằm trước sổ nhập tay trên Tổng quan/Tài khoản/Phân tích. Bộ chọn
Codex/Claude/Gemini/Antigravity, quota còn lại/reset và model/token riêng;
không coi thiếu nguồn là usage=0. Antigravity và Gemini web chưa có adapter.
Nguồn AI vẫn hiển thị khi sổ cloud tải lỗi. Giữ core UI Lab2, cỡ chữ hệ thống,
reduced motion; tắt overscroll stretch Android. Nút Google có icon và label đầy đủ.

Companion local loopback8787 với pairing token, CORS/Host allowlist; Codex App
Server + model history, Claude Code statusline, Gemini CLI history. Không đọc
cookie/credential provider, gọi model để tạo số liệu hoặc thay billing. Quota,
token theo model và phí đã charge là các nguồn khác nhau; không tự cộng vào sổ.
Xem docs/provider-sync.md. Claude/Gemini thiếu nguồn thật hiện setup.

Auto-connect là opt-in của bản local: chỉ email tài khoản khớp owner được cấu
hình mới ghép nguồn; fresh clone mặc định tắt. Demo không đọc provider thật;
logout/đổi UID dispose snapshot/timer. Token chỉ local/session, không commit.
Tạo .env.local bằng cách copy .env.example rồi chạy tool/provider_bridge/setup.mjs
trước khi dùng launch config. Không chia sẻ build chứa mã ghép nối máy cá nhân.

Verification:355 Flutter tests và12 companion tests pass; analyzer sạch;
Android debug/web release build pass. Android đã nhận1 nguồn ready/6model rows.
QA render360/412/1440px, text1/2; ảnh QA không thay screenshot native.
Cấu hình project, email, SHA và tài liệu chuyển Firebase được giữ ngoài commit.


## Analytics và Remote Config —21/10

Đã triển khai [Analytics/Remote Config](docs/analytics-remote-config.md): sự kiện typed không gửi PII, Google-only business telemetry, UID lifecycle/dedupe; cấu hình số recent rows và ngưỡng cảnh báo ngân sách với defaults/refresh/fallback, Profile hiện giá trị/source/status. Analytics plan được viết trước tracking. Người dùng xác nhận đợt manual cloud web1–7 đã đạt; đây không phải Android/ARTEMIS hoặc console evidence. RC publish→app/DebugView còn cần kiểm theo hướng dẫn, FCM/Crashlytics/PDF vẫn pending. Không chạy máy ảo; 326 Flutter tests pass, analyzer/format sạch, web release build pass; chi tiết xem test-report.


## Yêu cầu hiện hành Lab3 và Final —21/10

Đọc [toàn bộ yêu cầu và việc còn lại](docs/ASSIGNMENT_REQUIREMENTS.md), rồi [roadmap](docs/APP_COMPLETION_ROADMAP.md)/[checklist](docs/TASK_CHECKLIST.md). Giảng viên đã chấp thuận TokenLedger theo xác nhận người dùng21/10. Auth/Firestore trên main484cc41; FCM/RC/Crash/Analytics SDK/PDF và Android/manual/backend acceptance còn thiếu. Final cần thêm roles/web admin/shared core/Hosting/cross-role/inbox/Gemini/AppCheck; web hiện chỉ preview, chưa admin.

Đề mới: ARTEMIS ≥10cases×3runs + exploratory, AI review≥5findings/3separate fixes; Lab3 report8–12p/slides12–15/video5–10m, Final report10–15p/slides12–15/video8–12m. PDF L3 Cloud Storage và Final device save/share cần xác nhận khác biệt. Baseline mới thay ngưỡng MobAI/Cloudinary/report-video cũ; không tự triển khai, billing, emulator hoặc publication trong lượt docs.


## Publication trước Firebase —21/10

Theo yêu cầu “push hết lên cho tôi”, target là [branch codex/local-form-safety](https://github.com/NhanHuynhThien/lab3_prm/tree/codex/local-form-safety), gồm checkpoint Flutter d4b6167 và commit tài liệu visual handoff chứa đoạn này. Xem Git log/remote refs cho SHA publication; các đoạn “chưa push” bên dưới ghi thời điểm trước yêu cầu này. Không merge main hoặc thay visibility. Runtime giữ nguyên bản200 tests đã kiểm; Firebase/native/lecturer acceptance vẫn pending.

Ứng dụng **Flutter/Dart** quản lý tài khoản AI, phiên sử dụng, token, chi phí và quota. Core UI kế thừa StudentPay Lab 2. Android là platform của bài lab; web dùng để chạy preview.

## Trạng thái hiện tại

Baseline source hiện hành trên `main`: `484cc41`, sau merge PR#1 (`824df0b`). Đã nối Firebase Core/Auth cho project `tokenledger-lab3`; Auth/Firestore workspace được đưa vào commit publication trực tiếp lên `main` theo yêu cầu mới của người dùng. Các ghi chú checkpoint/publication phía trên giữ theo thời điểm cũ. Xem [Auth setup](docs/firebase-auth-setup.md) và [build status](docs/build-status.md).

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

**Firebase Auth đã có implementation:** Google Sign-In Android/web, auth guard, Profile từ user SDK và logout; người dùng xác nhận web login/reload/logout và Firebase Users đã thành công, native còn chờ. **Firestore đã nối vào4 tab, CRUD/quota/settings theo UID; rules/indexes đã triển khai. Tests/rules simulations đã pass, manual web CRUD/A-B được người dùng xác nhận; native/concurrency stress còn chờ. Analytics/Remote Config có client code; console/DebugView còn chờ. FCM/Crashlytics/PDF vẫn pending.** Không gian Google dùng cloud ledger riêng; user mới thấy empty, không tự nhận seed. Demo local tách biệt, không tự upload hoặc đọc usage/quota từ Claude/Codex.

Figma P0 đã có8 màn360/412 và mẫu trạng thái chỉnh sửa được; xem [visual handoff](docs/visual-handoff-21-10.md) cho links/đối chiếu và các sai khác còn lại. Chưa nghiệm thu pixel/native/backend.

## Chạy bằng Flutter

Đã kiểm tra gần nhất với Flutter 3.47.4 / Dart 3.13.3. Dùng `pubspec.lock` để resolve đúng dependency.

```sh
git clone https://github.com/NhanHuynhThien/lab3_prm.git
cd lab3_prm
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 4183
```

Bấm **Đăng nhập bằng Google** để kiểm Auth, hoặc chọn **Mở không gian demo** / `http://localhost:4183/?demo=1` để dùng local riêng. User Google mở4 tab với cloud data theo UID; demo local tách biệt. Xem [Firestore workspace](docs/firestore-workspace.md) để kiểm CRUD/reload/logout. Dừng bằng Ctrl+C. Toàn bộ dev server và compilation do Flutter quản lý.

Seed gồm 3 accounts, 12 usage sessions giả định. Mọi thay đổi lưu trên thiết bị/trình duyệt hiện tại; origin/port khác có dữ liệu khác. Cấu hình Firebase client Android/web do người dùng tạo được giữ trong source; không có admin/service-account key. Demo không yêu cầu đăng nhập và không dùng để lưu credential thật.

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
  services/        # Auth/Firestore/local repositories, converters, calculator
  viewmodels/      # mutations, validations, reporting projections
  screens/         # dashboard, accounts, usage, analytics, profile
  widgets/         # shared components, charts, logo painter
  theme/           # Lab2 tokens và motion
  utils/           # money/date formatting
android/           # native Android project và launcher icons
web/               # Flutter web host, PWA icons/manifest
assets/fonts/      # Inter và OFL license
assets/brand/      # source SVG/logo documentation; không bundle vào app
test/             # 299 unit/widget tests
```

Git theo dõi source Flutter, cấu hình platform, lockfile, tài liệu và assets cần thiết. Build/cache, tooling skill cài local, bản chụp tài liệu Lab2, ảnh/log inspector và đề PDF được loại khỏi source tree trên GitHub.

## Tài liệu

- [Kiến trúc hiện tại](docs/architecture.md), [build status](docs/build-status.md), [test report](docs/test-report.md).
- [Nâng cấp P0 local/model/migration](docs/local-p0-upgrade.md).
- [Phạm vi và gaps A03–A06](docs/scope-decisions.md), [roadmap](docs/APP_COMPLETION_ROADMAP.md).
- [Kế hoạch](docs/IMPLEMENTATION_PLAN.md), [checklist](docs/TASK_CHECKLIST.md): có cả tính năng chưa triển khai.
- [Nguồn thiết kế Lab2](docs/lab2-ui-reference.md), [design changes](docs/design-change-log.md), [handoff gaps](docs/handoff-gaps.md), [UI audit/fidelity draft](docs/fidelity-check.md).
- [Cloud workspace/rules và manual verification](docs/firestore-workspace.md).
- [Firestore data contract/repository](docs/firestore-data-contract.md).
- [Firebase pending](docs/firebase-pending.md), [AI log](docs/implementation-ai-log.md), [docs index](docs/README.md).
- [Agent instructions](AGENTS.md), [agent context/workflows](.agents/README.md).

Không có backend scripting trong dự án. Bộ skill UI không có trong checkout hiện tại; đó là công cụ phát triển tùy chọn, không phải dependency để clone/build app.
