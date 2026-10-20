# Test report — Flutter local scaffold

Cập nhật20/10/2026. Kết quả là unit/widget tests của Flutter, chưa phải MobAI/Firebase/Android integration evidence.

## Coverage hiện có

| Suite | Tests | Kiểm tra |
|---|---:|---|
| calculator_test.dart |7| Totals/coverage, null-vs-zero, period/account filter, USD parser, JSON, quota stale, seed đầu tháng |
| ledger_viewmodel_test.dart |4| Usage persistence/idempotency, save failure, archive/delete guards, account CRUD/reload |
| widget_test.dart |5| Demo/navigation/layout360/412/768/1440dp và usage form validation/save |

Tổng16 tests. Lượt verification trước cleanup đã pass format/analyzer/tests; web release build scaffold cũng thành công. Raw logs và ảnh inspector đã loại khỏi repo theo yêu cầu dọn source. Kết quả CLI tiếp theo được ghi bằng summary tại cuối tài liệu này, không tạo script hoặc compiled artifacts trong Git.

## Các lỗi đã xử lý ở lượt scaffold

- Sửa test expectation306k về tổng seed thực286k.
- Sửa logo/sidebar text overflow bằng Flexible/Expanded.
- Helper/error text cho nhiều dòng; zero-value bar không có height giả.
- Chưa có budget thì hiển thị Chưa đặt ngân sách.

## Cleanup verification

Thay đổi packaging: bỏ directory assets/brand khỏi Flutter asset bundle. Logo UI dùng CustomPainter, launcher PNG ở platform source; font Inter vẫn được bundle.

Cần clean build rồi chạy pub get, format/analyze/test và web release build để xác minh không có asset reference bị hỏng. Build/cache sinh ra được gitignore và dọn sau verification.

## Chưa làm

Google Auth/Firestore/rules/FCM/Remote Config/Crashlytics/DebugView, PDF cloud, provider sync,10 MobAI scripts/healing/bug exercise, AI PR review, Android APK/device tests và full Figma fidelity/accessibility.

Kết quả clean verification20/10/2026: pub get thành công; format28 files không thay đổi; analyzer No issues found;16/16 tests pass; web release build thành công sau khi bỏ brand directory khỏi bundle. Đã xác minh output không có assets/brand, font Inter vẫn hiện diện. Sau verification chạy Flutter clean để bỏ output/cache local. Không commit artifacts sinh từ compile.
