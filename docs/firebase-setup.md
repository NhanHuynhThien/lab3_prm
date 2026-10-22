# Firebase và môi trường chạy

Cập nhật 22/10/2026. Đây là hướng dẫn cấu hình hiện hành, không phải xác nhận mọi dịch vụ đã nghiệm thu. [Audit](requirements-audit.md) và [test report](test-report.md) giữ trạng thái cụ thể.

## Project và cấu hình

| Mục | Giá trị |
|---|---|
| Project | `tokenledger-nhan-20261021` |
| Gói | Spark; chưa bật billing |
| Android package | `com.tokenledger.token_ledger` |
| Firestore | `(default)`, `asia-southeast1` |
| Client config | `lib/firebase_options.dart`, `android/app/google-services.json` |
| CLI/deploy config | `.firebaserc`, `firebase.json`, `firebase/` |
| Web auth domains | localhost và hai domain firebaseapp.com/web.app của project |

Project cũ không dùng cho cấu hình hiện tại. Không chuyển người dùng hoặc dữ liệu giữa project. Firebase client identifiers không phải service-account secret; không commit credential, OTP, OAuth client secret, admin key hoặc `.env.local`.

## Chạy Android

Flutter 3.47.5 / Dart 3.13.4; Android SDK tại `$HOME/Library/Android/sdk`; API 36 Google APIs ARM64 có Play services. AVD hiện hành **TokenLedger_Pixel_10_Pro_120Hz**, host GPU/Metal; AVD cũ đã archive ngoài danh sách active.

```sh
flutter pub get
cp .env.example .env.local  # chỉ trên clone mới chưa có file local
./tool/start_lab3_120hz.sh
```

`.env.local` là JSON Dart defines. Các defines đều có thể được trích từ binary, không dùng để giữ provider API secrets. Companion xem [provider-sync](provider-sync.md). Display hỗ trợ 120 Hz không bảo đảm mọi frame đạt 120 FPS; đo bằng profile theo test report.

Web preview:

```sh
flutter run -d chrome --web-hostname localhost --web-port 4183
```

## Google login

Google provider đã cấu hình trên project hiện hành; native login và restore trên máy ảo đã quan sát. Signed-out chỉ có Login. User mới bắt đầu empty, tạo account/usage/quota qua form. Không `?demo=1`, seed hoặc bypass.

Debug SHA-1 của Mac đã dùng: `6E:26:62:77:36:B7:E8:67:1C:D0:C4:69:76:BE:A0:48:80:63:70:5F`.

Máy mới phải kiểm chứng chỉ bằng `cd android && ./gradlew signingReport`, đăng ký SHA đúng Android app rồi tải lại client config từ Firebase. Không tự sửa certificate_hash trong JSON để giả đăng ký server. Khi có release/Play signing cần SHA tương ứng; debug signing không phải production signing.

Kiểm thực: login → Profile đúng identity → restart restore → logout về Login → Back không vào workspace cũ. Kiểm A/B bằng tài khoản test được phép; không dùng mật khẩu/OTP trong source hoặc log. Quyền QA tài khoản cá nhân hiện tại không thay yêu cầu dedicated MobAI test account của đề.

## Firestore

Rules owner/schema và indexes nằm trong `firebase/`; data contract ở [architecture](architecture.md). Không query toàn bộ users rồi lọc UID ở client. Giữ default deny, không mở Test mode để chữa permission error. Rules/indexes đã deploy theo checkpoint cấu hình trước; cần kiểm readiness/console khi nghiệm thu, không suy từ file config.

Đã tạo account và usage QA qua native SDK, sửa usage và quan sát dữ liệu còn sau đổi emulator/re-login. Full CRUD/error/recovery/owner-isolation cần kết quả từng case trong test report.

## Remote Config

| Key | Default | Bounds | Hành vi |
|---|---:|---|---|
| `overview_recent_limit` | 3 | 1–10 | Số phiên gần đây trên Tổng quan/sổ thủ công |
| `budget_warning_percent` | 80 | 1–100 | Ngưỡng cảnh báo chi phí so với ngân sách tự đặt |

Defaults: `firebase/remote-config-defaults.json`. Client parse/clamp/cache/fallback/Retry; Profile hiển thị effective values/source/time và refresh. Số tiền/tổng không đổi khi thay giới hạn hiển thị. Debug minimum interval 0, release 12h; release không hứa nhận template mới tức thì.

Console v1 đã có 3/80 theo checkpoint setup. Evidence **thay giá trị → publish → refresh → hành vi app đổi** vẫn còn thiếu. Chỉ dùng dữ liệu QA để kiểm, giữ các keys/conditions khác của template.

## PDF, FCM, Crashlytics, Analytics

- PDF local generation/upload transport có code. **Storage chưa provision/billing; report metadata chưa lưu Firestore.** Không coi upload đạt. PDF đề cho phép Cloudinary restricted unsigned PDF preset; adapter đó chưa triển khai. Không tự bật billing.
- FCM có transport/permission/RAM inbox; mở Notification Center empty đã kiểm. Tap target routing/background delivery và Console push evidence còn thiếu.
- Crashlytics có handled-exception và deliberate test-crash controls trong vùng chẩn đoán. Cần evidence cả hai trên dashboard; trạng thái SDK/local counter không phải xác nhận Console nhận.
- Analytics có typed events và SDK; project mới còn cần kiểm liên kết/property/DebugView. Xem [analytics-plan](analytics-plan.md) cho sai khác event contract phải sửa. Không đưa PII/chat/usage amounts vào Analytics.

Console: [project hiện hành](https://console.firebase.google.com/project/tokenledger-nhan-20261021/overview). Không deploy, thay billing hoặc chụp evidence giả chỉ để đóng checklist.
