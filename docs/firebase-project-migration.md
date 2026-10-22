# Firebase project migration — 21/10/2026

Người dùng yêu cầu tạo Firebase mới sau lỗi Google login Android
`UNREGISTERED_ON_API_CONSOLE`; đã đồng ý quyền Firebase CLI rộng và email hỗ trợ.

## Cấu hình hiện hành

| Mục | Giá trị |
| --- | --- |
| Owner / email hỗ trợ | nhanhuynh7115@gmail.com |
| Project | tokenledger-nhan-20261021 |
| Project number | 437223340054 |
| Plan | Spark, không gắn billing |
| Android package | com.tokenledger.token_ledger |
| Android app ID | 1:437223340054:android:b74287e291dd8cd3c31d37 |
| Web app ID | 1:437223340054:web:d39e6ac3503a9beec31d37 |
| Firestore | (default), Standard, asia-southeast1 |
| Auth domains | localhost, tokenledger-nhan-20261021.firebaseapp.com, tokenledger-nhan-20261021.web.app |

SHA-1 debug Mac:
`6E:26:62:77:36:B7:E8:67:1C:D0:C4:69:76:BE:A0:48:80:63:70:5F`.
SHA-256 debug Mac:
`D6:20:3E:A8:28:19:B6:ED:7D:26:96:C2:07:67:CE:23:EF:1A:D4:C6:03:2F:9F:27:9A:1F:7C:0B:EC:30:05:A7`.

## Checklist thực tế

- [x] CLI đăng nhập đúng owner; tạo Firebase project và Android/web app.
- [x] Đăng ký SHA-1/SHA-256; Google provider Enabled, tên public TokenLedger.
- [x] Tải config sau khi bật Google; kiểm OAuth client đúng package và SHA.
- [x] Cập nhật android/app/google-services.json, lib/firebase_options.dart,
  firebase.json, .firebaserc.
- [x] Tạo Firestore production mode, deploy rules owner/schema và 5 indexes cùng field override.
- [ ] Index readiness: cả 5 indexes hiện Building theo Console; deploy accepted chưa phải Enabled.
- [x] Publish Remote Config v1: overview_recent_limit=3, budget_warning_percent=80;
  đọc lại từ server khớp. Template firebase/remoteconfig.template.json.
- [x] Analyzer sạch; 48 Auth/guard/RC tests pass; Dart format không đổi.
- [x] APK debug 7.0s, web release 19.9s; APK install/open trên emulator thành công.
- [x] Native Google Auth đã thành công theo FirebaseAuth log; bản UI mới restore session và nhận snapshot Codex trên Android.
- [ ] Live SDK CRUD/reload/logout sau login; tests không thay nghiệm thu thật.
- [ ] Liên kết GA/Analytics cho project mới; SDK đang có nhưng chưa xác minh console.
- [ ] Đăng ký release signing SHA khi có signing key thật; hiện chỉ debug Mac.

## Vận hành và giới hạn

Console: https://console.firebase.google.com/project/tokenledger-nhan-20261021/overview

Build với --dart-define-from-file=.env.local như README. Client Firebase public
ở source; CLI OAuth token không vào repo/env. Local provider bridge không đổi.
Không bật billing hoặc Storage trong lượt này.

Project cũ tokenledger-lab3 giữ nguyên; không migrate users hoặc dữ liệu cũ.
Project mới có UID/workspace mới, dữ liệu bắt đầu trống. Evidence/test console
cũ không tự áp dụng cho project mới. Các mục lịch sử trong docs được giữ; mục
migration này là trạng thái hiện hành. Backup config cũ nằm local /tmp, không commit.
