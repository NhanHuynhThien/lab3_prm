# Google login và môi trường chạy

> Cấu hình hiện hành đã chuyển sang `tokenledger-nhan-20261021`. Xem [migration](firebase-project-migration.md); thông tin project cũ bên dưới là lịch sử.

Cập nhật 21/10/2026 sau yêu cầu cài Android Studio và sửa scroll/login.
Các ghi chú cũ “không chạy máy ảo” chỉ mô tả những lượt trước.

## Môi trường đã cài trên Mac

- Android Studio Rabbit 1 2026.2.1, Apple Silicon; plugin Flutter/Dart đã bật.
- Android SDK chuẩn tại `$HOME/Library/Android/sdk`; Flutter đã trỏ tới SDK và
  JDK 25 đi kèm Android Studio. Không thay Java mặc định của dự án khác.
- API 36/build-tools 36.0.0, platform-tools, command-line tools, Emulator,
  NDK 28.2.13676358, CMake 3.22.1. Các SDK phụ do Gradle/Studio yêu cầu đã cài.
- AVD `TokenLedger_API_36`: Google APIs ARM64, Android 16/API 36, Pixel 4a,
  2 CPU, 2 GB RAM. Có Google Play services. VS Code có extension Flutter/Dart.
- Android toolchain/licenses đã pass `flutter doctor`. Cảnh báo Xcode còn lại
  thuộc iOS/macOS, không chặn Android.

## Env và chạy app

File `.env.example` có định dạng **JSON**, dùng trực tiếp với Dart defines.
Tạo bản local khi clone mới:

```sh
cp .env.example .env.local
flutter pub get
flutter emulators --launch TokenLedger_API_36
flutter devices
flutter run -d emulator-5554 --dart-define-from-file=.env.local
```

ID thiết bị có thể đổi; lấy lại từ `flutter devices`. Trong VS Code, mở thư mục
repo, chọn cấu hình `TokenLedger · Android`, chọn AVD rồi nhấn F5. Cấu hình web
dùng localhost:4183 để khớp domain preview. Khởi động lại VS Code/terminal sau
lần cài SDK đầu tiên nếu chưa nhận PATH mới.

`FIREBASE_ANALYTICS_DEBUG` là boolean compile-time đã được source hỗ trợ;
mặc định false. Chỉ đổi true khi cần kiểm DebugView theo kế hoạch Analytics.
Env không phải nơi lưu mật khẩu, OAuth client secret hoặc token. Mọi define
đều có thể đọc từ app đã build. `.env.local` được gitignore.

Firebase dùng cấu hình FlutterFire thật ở `lib/firebase_options.dart` và
`android/app/google-services.json`, không đọc Firebase keys từ file env này.
Giữ một nguồn cấu hình, không thêm key trùng lặp hoặc chỉ dẫn env không được
source đọc. Public Firebase identifiers không phải service-account secret.

## Kết nối Google trên Mac

Source hiện trỏ project `tokenledger-lab3`, Android app
`1:306832186195:android:74cc79579e088cba1fdfa6`, package
`com.tokenledger.token_ledger`. OAuth config hiện chỉ có SHA-1 từ máy trước.

Chứng chỉ debug **Mac hiện tại**:

```text
SHA-1:   6E:26:62:77:36:B7:E8:67:1C:D0:C4:69:76:BE:A0:48:80:63:70:5F
SHA-256: D6:20:3E:A8:28:19:B6:ED:7D:26:96:C2:07:67:CE:23:EF:1A:D4:C6:03:2F:9F:27:9A:1F:7C:0B:EC:30:05:A7
```

- [x] SDK/licenses, Google Play services và APK debug build/install đã kiểm.
- [x] Đối chiếu project/package và OAuth Android/web client trong config local.
- [ ] Mở đúng project bằng tài khoản có quyền. Tại lần kiểm này, người dùng
  Console tài khoản người dùng hiện trang chưa có project và URL
  `tokenledger-lab3` báo không tồn tại/không đủ quyền. Người dùng sau đó xác
  nhận bạn của mình setup Firebase và yêu cầu skip Console; nhờ owner thực
  hiện các bước SHA/provider bên dưới. Không tạo project thay thế/đổi các ID.
- [ ] Firebase Console → Project settings → Your apps → đúng Android app →
  Add fingerprint: thêm SHA-1 và SHA-256 trên, giữ chứng chỉ máy trước.
- [ ] Authentication → Sign-in method → Google: kiểm tra Enabled và support
  email. Web thêm localhost/hosting domain vào Authorized domains nếu thiếu.
- [ ] Tải lại `google-services.json` từ đúng Android app; thay file local sau
  khi kiểm project ID/package/app ID và OAuth clients. Không sửa thủ công
  `certificate_hash` trong JSON vì thao tác đó không đăng ký OAuth trên server.
- [ ] Build lại; mở app trên AVD; chọn Google account. Người dùng tự nhập
  mật khẩu/2FA nếu được yêu cầu. Không lưu credential vào env/source.
- [ ] Kiểm success → Profile đúng identity, restart giữ session, logout,
  cancel/error và dữ liệu riêng theo UID. Chưa coi APK build là OAuth pass.
- [ ] Với release/Play, đăng ký SHA của signing certificate tương ứng;
  debug key hiện tại không phải production signing.

Nguồn: [Google Auth Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth#google),
[Google Sign-In Android](https://pub.dev/packages/google_sign_in_android),
[Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup).

## UI

Nút Google đầy đủ có icon chính thức được bundle offline, nền trắng, viền,
label tiếng Việt và busy/disabled states. Google đứng trước demo. Giữ Inter,
palette và radius Lab2; đây là button Flutter tùy biến, không phải button SDK
render. Asset attribution ở `assets/auth/README.md`.

App tắt overscroll indicator toàn cục để Android Material 3 không kéo giãn
cards khi cuộn quá đầu/cuối. Giữ scrolling, scrollbar, tab state và reduced
motion; không cố định text scale để che lỗi layout.
