# Firebase Auth — C01–C03

Cập nhật21/10/2026. Người dùng đã yêu cầu tiếp tục Firebase, tự tạo project và cung cấp cấu hình FlutterFire; lượt này triển khai Core/Auth/Google Sign-In, auth guard/Profile và tách demo. Làm trên `main` sau merge PR#1 (`824df0b`). Không tự đổi billing, bật Firestore/FCM/Remote Config/Crashlytics/Analytics SDK/PDF hoặc deploy rules. Không chạy máy ảo.

## Cấu hình thật

| Mục | Giá trị / kiểm chứng |
|---|---|
| Project ID | `tokenledger-lab3` |
| Android package | `com.tokenledger.token_ledger` |
| Android app ID | `1:306832186195:android:74cc79579e088cba1fdfa6` |
| Web app ID | `1:306832186195:web:b573b2f9cfcdd6321fdfa6` |
| Config do người dùng tạo | `android/app/google-services.json`, `lib/firebase_options.dart`, `firebase.json` |
| Google provider | GET cấu hình Auth project trả `enabled: true` |
| Authorized domains | GET trả `localhost`, `tokenledger-lab3.firebaseapp.com`, `tokenledger-lab3.web.app` |
| Debug SHA-1 | Firebase CLI SHA list trả `8B:57:EB:AA:72:AF:AC:16:5F:21:2B:AB:B4:76:5D:9B:93:FC:6B:7D`, khớp fingerprint người dùng đã cung cấp |
| OAuth Android | Config có Android client type1 và web OAuth client type3; Google SDK dùng resource `default_web_client_id` qua Gradle |

Đã đọc API/dependency docs chính thức trước code. Resolve: firebase_core5.0.0, firebase_auth7.0.0, google_sign_in7.2.0; Android implementation7.2.18.13 dependencies mới, không nâng các packages cũ. Google services Gradle plugin4.5.0; Firebase Flutter plugins tự quản lý native BoM, không chèn dependencies native trùng lặp. Flutter minSdk24 khớp plugins Core/Auth; thêm INTERNET permission cho release Android.

File cấu hình client chứa identifiers/API key client công khai theo thiết kế Firebase; không phải admin/service-account secrets. Không lưu token đăng nhập, OAuth client secret hoặc private key vào source/SharedPreferences. Script kiểm config chỉ GET và xuất các trường an toàn; không in/lưu access token hoặc nội dung OAuth secret.

Nguồn: [Flutter setup](https://firebase.google.com/docs/flutter/setup), [Google Auth](https://firebase.google.com/docs/auth/flutter/federated-auth#google), [Google Sign-In API](https://pub.dev/packages/google_sign_in), [Android integration](https://pub.dev/packages/google_sign_in_android), [Google services plugin](https://firebase.google.com/docs/android/setup), [Auth config GET](https://cloud.google.com/identity-platform/docs/reference/rest/v2/projects/getConfig).

## Code và vòng đời

- `main.dart` inject FirebaseAuthService và repository local; Firebase errors không chặn runApp. Auth initialization shared/retry; gate đợi userChanges đầu tiên. Timeout20 giây mở lỗi/Retry/demo thay vì loader vô hạn; retry dùng cùng init Future nếu SDK còn đang chạy.
- Models AuthUser/AuthFailure thuần Dart. AuthService contract và Firebase/Google adapters nằm trong services; SDK không được gọi từ screens/widgets/VM. SDK messages được chuyển sang thông báo đã lọc, không lộ token/email/URLs nội bộ.
- Android: GoogleSignIn singleton initialize trước authenticate, lấy ID token rồi Firebase credential; missing token không tạo session thành công. Web: Firebase Google popup được gọi trong lượt click, không await native Google init trước popup; hỗ trợ lỗi popup blocked/unauthorized domain/cancel/network/config và Retry.
- authSessionProvider chờ ready, theo dõi Firebase userChanges; AuthViewModel giữ busy/failure, chặn double tap và mounted guard. Không tự xuất bản user giả sau Future sign-in; session chỉ đến từ stream.
- AuthGate nằm trước mọi data route; browser initialRoute và unknown routes đều vào gate. Navigator riêng keyed theo demo hoặc UID; logout/đổi UID tháo toàn bộ route stack/forms cũ. Profile cập nhật cùng UID vẫn đọc metadata mới.
- `/?demo=1` hoặc nút demo mở sandbox local. Cold demo không subscribe AuthService qua Dart; demo không đăng nhập Google, không đọc/ghi cloud và không tự upload ledger. Firebase native có thể tự bootstrap Core từ config Android; không gọi đó là bằng chứng demo hoàn toàn không có native Firebase initialization.
- Khi Firebase authenticated, app mở Profile từ UID/name/email/photo của Firebase Auth. Avatar chỉ tải URL HTTPS và có fallback; thiếu tên/email không tự bịa thông tin. Account/usage/quota Firestore chưa nối, nên không dùng local seed để đóng giả dữ liệu cloud. Có nút mở demo local riêng và nút đăng xuất Google.
- Logout gọi Firebase trước rồi dọn Google session native đã initialize; lỗi không báo thành công giả. Chưa có Firestore listeners/FCM binding để dọn; đầy đủ C04–C15 vẫn cần triển khai và nghiệm thu riêng.

## Chạy và xác minh bằng tài khoản thật

Trong thư mục dự án, dùng:

```sh
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 4183
```

1. Mở địa chỉ localhost do Flutter in ra, không thêm `?demo=1` khi kiểm Google.
2. Bấm **Đăng nhập bằng Google**, chọn tài khoản Google của bạn. Profile phải hiện tên/email/avatar do Firebase cung cấp; Firebase Console → Authentication → Users phải có user tương ứng.
3. Reload: gate đợi restore, rồi vào đúng Profile. Không hiện seed Claude/Codex như dữ liệu cloud.
4. Bấm **Đăng xuất Google**: quay Login, Back/deep link không mở lại Profile cũ. Đăng nhập user B để kiểm metadata B.
5. Mở demo local riêng:4 tab/local ledger vẫn dùng được, identity Google không được trình bày là owner của dataset demo. Thoát demo trở về session Google nếu session vẫn tồn tại.
6. Hủy popup phải có feedback hủy; popup bị chặn phải chỉ cách cho phép; offline phải có lỗi/Retry. Không nhập password/API key provider vào ledger.

Android: dùng điện thoại thật có Google Play services khi cần; không chạy emulator. App hiện ký release bằng debug key theo template, không coi đó là signing production. Release/Play signing certificate khác phải đăng ký SHA tương ứng trước nghiệm thu.

## Bằng chứng và giới hạn

Kiểm config thực qua Firebase CLI và Auth config GET nêu trên; không tạo user giả, không nhập tài khoản Google thay người dùng.39 tests auth mới kiểm service init/retry/ID-token exchange/popup ordering/cancel/errors/concurrent/signout, VM state và route guard/deep link/session restore/change-user/draft disposal/demo isolation. UI kiểm360/412/1440×800, Inter/MaterialIcons, chữ1/2; ảnh Profile trong tests dùng identity fixture `example.test`, không phải bằng chứng đã đăng nhập Google thật.

Full regression **239/239 pass140s**, analyzer sạch11.9s, format57 files0 changed. Kết quả web build và kiểm cuối ở [test report](test-report.md). Ảnh/log local nằm trong `.taste-skill/c01-c03/`, được ignored; không thêm vào assets runtime hoặc giả làm console/native evidence.

C01 đã có cấu hình thật/SDK. C02 và C03 có implementation và automated checks; nghiệm thu OAuth bằng user thật, Google Play services/native, Android Back và các signing variants còn cần chạy thật. GATE-01/G3–G9 không tự đạt từ tests giả lập SDK. Không có Firestore CRUD/owner rules/counters, sync provider, notification delivery, Analytics events hoặc PDF export trong lượt này. Figma Login/Profile chưa cập nhật sau thay đổi Auth; bộ annotated page08 vẫn là snapshot trước Auth.

## Xác nhận tiếp theo của người dùng —21/10/2026

Người dùng xác nhận web Google login hiển thị đúng Profile, reload giữ session, logout/login lại và tài khoản đã xuất hiện trong Firebase Authentication Users. Ảnh Profile được cung cấp trong hội thoại. Không chuyển xác nhận này thành bằng chứng agent đã tự test native/OAuth, A/B isolation hoặc Firestore. Người dùng sau đó đã tạo Firestore; [data contract](firestore-data-contract.md) ghi repository mới, UI/rules vẫn pending.
