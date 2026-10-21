# Firebase — Auth/Firestore đã nối, dịch vụ bổ sung còn pending

## Cloud workspace/rules —21/10/2026, mục3–5

Đã nối4 tab với Firestore theo UID, CloudLedgerViewModel dùng4 streams ghép nhất quán, full-dataset reporting, CRUD/quota/settings atomic, revision từ lúc mở form, last-good/cache/pending/error/retry giữ draft/filter. Mỗi UID/demo có ProviderContainer/Navigator riêng, root auth action coordinator dùng chung; logout/change UID dọn state/listeners/routes, không seed/upload local vào cloud. Factory tắt Firestore disk persistence. [Workspace hướng dẫn](firestore-workspace.md) ghi thiết kế và manual checks.

Rules default deny/owner/schema/relations/counters/quota labels/receipts đã code và deploy với5 indexes vào tokenledger-lab3/(default), Standard/asia-southeast1. Rules Test API142 cases pass (mocks trước/sau, không emulator/doc writes), live source hash khớp local và unauth GET403. Index readiness xem test-report, không suy deploy accepted thành READY. Full299 Flutter tests pass162s, analyzer sạch, web release48.3s;46 lib/22 test Dart files (2 helpers).25 tests VM/workspace mới;15 Auth tests cập nhật giữ assertions. Native/A-B thật/SDK transactions qua mạng/F1–F3 manual gates vẫn cần nghiệm thu. FCM/RC/Crash/Analytics SDK/PDF/Figma sync chưa làm. Không emulator/billing/commit/push.


## Firestore foundation —21/10/2026, mục1–2

Đã thêm cloud_firestore7.0.0, thiết kế envelope/paths theo UID, CloudLedgerRepository streams/atomic CRUD và SDK adapter cho account/usage/quota. Counters/revisions/quota label reservations và operation receipts commit cùng transaction, không upload snapshot local.35 tests repository mới pass; full regression274 tests pass138s trước lần siết receipt/path validation cuối, sau đó35 tests liên quan pass lại; analyzer sạch và web build xem test-report. Source44 lib/20 test Dart files, gồm2 support helpers. [Data contract](firestore-data-contract.md) ghi mapping/invariants/query/indexes và lifecycle. Chưa nối UI/VM, chưa viết/deploy rules/indexes hoặc kiểm database thật; các backend gates còn pending. Không emulator, billing, telemetry hoặc publication.

Người dùng báo Google web login/reload/logout và Authentication Users đã thành công, đồng thời đã tạo Firestore. Đây là xác nhận người dùng; native/Play services/release cert và Firestore integration chưa được kiểm bởi agent.


Cập nhật21/10/2026. Người dùng đã tiếp tục C01–C03 và cung cấp cấu hình project `tokenledger-lab3`. Core/Auth/Google Sign-In, auth guard/Profile có code; Google provider/authorized domains/debug SHA đã kiểm thật. [Auth setup](firebase-auth-setup.md) ghi239 tests, web build và giới hạn OAuth/native. Không có Firestore/rules deploy/FCM/RC/Crash/Analytics SDK/PDF; không đổi billing hoặc chạy emulator. Các mục “Khi tiếp tục” dưới đây giữ làm dependency checklist, phần Auth đã có code không phải chưa bắt đầu.

## Đã chuẩn bị

- Models Dart thuần, VM không truy cập SDK; `LedgerRepository` tách khỏi Views.
- `ledgerRepositoryProvider` được override tại `main.dart` bằng `LocalLedgerRepository`.
- Local storage schemaVersion2 với backup-first migration1→2; cost integer USD micros/null-vs-zero; model/defaults/multi-quota/cycle/IANA và source manual/demo/legacy đã có. Xem [local P0 upgrade](local-p0-upgrade.md). Chưa có owner UID hoặc stream/backend isolation.
- Profile authenticated lấy identity Firebase Auth thật; nút Google gọi SDK, không giả đăng nhập. Demo Profile không gắn owner Google vào ledger local.

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

Có stream identity Firebase Auth; chưa có realtime listener dữ liệu Firestore, user isolation backend, notification delivery, RC fetch hay provider synchronization. `SharedPreferences` chỉ dùng dữ liệu demo và không phải kho bí mật. Không lưu API key/password/cookie trong local repository.
