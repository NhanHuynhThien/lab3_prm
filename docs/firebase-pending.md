# Firebase pending — điểm nối sau local scaffold

Ngày 19/10/2026. Theo yêu cầu người dùng, **không tạo hoặc cấu hình Firebase trong lượt build này**. Không có project, Firebase identifiers, SDK Firebase, credentials hay rules deploy.

## Đã chuẩn bị

- Models Dart thuần, VM không truy cập SDK; `LedgerRepository` tách khỏi Views.
- `ledgerRepositoryProvider` được override tại `main.dart` bằng `LocalLedgerRepository`.
- Local storage schemaVersion 1; cost integer USD micros; null khác0; source local demo hiển thị trong UI.
- Profile hiển thị trạng thái pending rõ ràng; nút Google không giả đăng nhập.

## Khi tiếp tục

1. Tạo project riêng, bật Analytics, đăng ký Android package/SHA-1, Google provider và FlutterFire configure.
2. Thêm `AuthService`, auth state/route guard thật; demo session không được dùng làm production auth.
3. Tạo Firestore converters/path `users/{uid}/accounts`, `usage_sessions`, `quota_windows` và collections liên quan.
4. Mở rộng repository snapshot sang scoped streams/atomic CRUD. Không ghi nguyên snapshot local lên backend để xử lý concurrency.
5. Xử lý account/usage relation, transaction/counter/delete race, rules validation/ownership; emulator tests rồi deploy.
6. Hủy listeners/cache/draft khi auth đổi; không trộn local demo với data của user Firebase.
7. Tích hợp FCM/Center/deep links, Remote Config defaults/behavior, Crashlytics demo và Analytics DebugView.
8. Generate/export PDF và storage phù hợp; save URL/metadata; không nhúng API secret.
9. MobAI10 scripts, healing/bug exercises, AI PR review và evidence console thật theo checklist.

## Chưa cam kết

Chưa có realtime listener, user isolation backend, notification delivery, RC fetch hay provider synchronization. `SharedPreferences` chỉ dùng dữ liệu demo và không phải kho bí mật. Không lưu API key/password/cookie trong local repository.
