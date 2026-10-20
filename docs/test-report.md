# Test report — local scaffold

Ngày 19/10/2026. Phạm vi kết quả dưới đây là Flutter unit/widget tests và web scaffold, **không phải MobAI hoặc Firebase integration tests**.

## Môi trường

Flutter3.47.5, Dart3.13.4, macOS arm64. Android SDK chưa có; không chạy emulator/APK. Browser preview Flutter web qua localhost4183; font Inter bundle.

## Các kiểm tra đã chạy

| Suite | Số test | Kiểm tra |
|---|---:|---|
| calculator_test.dart |7| Totals/coverage, null-vs-zero, filter/kỳ/account, USD micros parser, JSON, quota stale, seed ở đầu tháng |
| ledger_viewmodel_test.dart |4| Persist/create-delete/idempotent usage, save failure không publish success, archive/history/delete guard, account CRUD/reload |
| widget_test.dart |5| Login demo +4 tab ở360/412/768/1440dp; usage validation/save nullable metrics |

Bộ16 tests đã pass ở lần chạy sau khi sửa sidebar và corrected fixture expectation. `flutter analyze` đã sạch. Lệnh kiểm tra cuối được chạy lại sau các thay đổi hoàn thiện UI; xem log trong `assets/evidence/`.

Lỗi tìm được và sửa:

- Unit assertion ban đầu kỳ vọng306k nhưng tổng token fixture thực là286k; kiểm tra lại11 entries có token rồi sửa expectation, không đổi data để khớp số bịa.
- Widget test1440 phát hiện text overflow ở logo/sidebar nav/footer; sửa Flexible/Expanded, chạy lại pass.
- Preview mobile thấy helper text cost bị cắt; cho phép helper/error text nhiều dòng trong theme.
- Bar cost0 từng có minimum visual height; sửa zero thành height0 để không biểu diễn usage không tồn tại.
- Overview chưa đặt budget không được gọi$0 là remaining known; chuyển label Chưa đặt ngân sách.

## Browser verification

Đã mở Login, Overview, Accounts, AccountDetail và UsageForm trên trình duyệt IAB. Skill inspector chụp1440/768/390; đọc cả3 ảnh. DOM lint không hỗ trợ Dart, DOM inspector không đọc được text/h1 của CanvasKit nên không dùng kết quả đó làm pass/fail cho Flutter. Report gốc được giữ nguyên.

## Chưa thực hiện

- 10 MobAI `.mob`, full run, healing và bug-catching exercises.
- Google Auth/Firestore/rules/security ownership/FCM/RC/Crashlytics/DebugView.
- PDF generation/upload, provider API import/sync.
- Android build/install, platform keyboard/native UI, mọi màn text scale2.0, full fidelity Figma comparison.
- AI PR review: chưa tạo PR hoặc findings; không tính lỗi sửa trong test trên thành findings AI PR của rubric.

## Verification lại ngày 20/10/2026 — trước publication

Scope lượt này là docs/agent/portable references, không sửa Dart/runtime. Đã chạy lại:

| Command | Kết quả |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` |28 file,0 thay đổi |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` |16/16 pass |

Log thật: [verification-2026-10-20.txt](../assets/evidence/verification-2026-10-20.txt). Prefix đường dẫn máy cá nhân trong diagnostic logs được đổi thành `<project>/` để dễ đọc sau clone; kết quả/count không thay đổi.

Không chạy lại web build cho docs-only change; web release build và screenshots ở lượt scaffold19/10 tiếp tục là bằng chứng lịch sử. Kiểm tra thêm17 Markdown documents,23 reference hashes và196 task IDs duy nhất. Chưa thực hiện MobAI/Firebase/Android/AI PR review trong lượt này.
