# Workflows — TokenLedger

## 1. Bắt đầu lượt mới

- Đọc root AGENTS.md và project-context; xem `git status --short --branch`, `git remote -v`.
- Xác định task là docs/UI/domain/platform/backend; không tự đổi phạm vi user đã hoãn.
- Đọc file source liên quan trước sửa. UI theo Lab2 reference; domain theo architecture/plan nhưng phân biệt actual/planned.
- Nêu hành động và trạng thái không chắc chắn ngắn gọn cho user; tiếp tục phần độc lập nếu có blocker.

## 2. Chạy local

```sh
flutter pub get
flutter run -d chrome --web-port 4183
```

Demo entry hoặc `/?demo=1`; không cần Firebase config. Không dùng cùng port với server đã chạy; xem process hiện có hoặc dừng server do chính task tạo trước khi mở cái mới. Đổi port có bộ SharedPreferences khác theo origin.

Đối với release build:

```sh
flutter build web --release
```

Chạy preview bằng Flutter dev server ở lệnh trên; compilation/dev server dùng Flutter CLI.

Build là local artifact trong `.gitignore`, không commit `build/`. Chỉ bind localhost khi chưa được yêu cầu expose mạng.

## 3. Domain hoặc state change

1. Thêm/sửa domain rule trong service/model/VM, giữ Views render-only.
2. Test case có giá trị: null-vs-zero, budget overrun, period boundaries, archive/history, persistence failure, retry ID.
3. Recalculate mọi nơi từ cùng projection/dataset; không sửa riêng KPI để che mismatch.
4. Format, analyze, tests phù hợp. Với state/theme/navigation dùng chung, chạy full flutter test.
5. Update architecture/test-report/AI log và checklist đúng scope; không đánh Firestore task done vì local test pass.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
```

## 4. UI hoặc motion change

1. Xem before screenshot và baseline Lab2 tương ứng.
2. Đọc skill UI áp dụng; giữ core palette/type/radius/touch sizes. Không chạy toàn bộ 13 skills cho cùng một chỉnh sửa.
3. Test states empty/loading/error/disabled khi liên quan; kiểm tra360/412dp, desktop nếu thay dashboard.
4. Chart values/legend phải cùng data; zero không có height giả, missing không hiển thị như measured0.
5. Motion phản hồi interaction/state; AppMotion tôn trọng reduced motion, tab stack không bị dispose chỉ vì transition.
6. Xem browser render thật. Taste inspector hỗ trợ HTML/CSS/JS, không hiểu Dart CanvasKit DOM; giữ kết quả thật và giải thích giới hạn, không làm giả pass.
7. Nếu cần ảnh để review thì giữ local, không commit output inspector/ảnh lịch sử copy; update design-change-log. Figma chỉ báo đã chỉnh khi có thao tác/evidence thật.

## 5. Docs-only change

- Cập nhật ngày/trạng thái ở phần mới; giữ evidence19/10 là lịch sử thay vì đổi ngày ảnh cũ thành hôm nay.
- Kiểm tra Markdown fences, local links, task ID uniqueness và paths portability.
- Links tới Lab2 dùng docs/lab2-ui-reference.md hoặc URL Figma gốc; không thêm absolute máy cá nhân vào hướng dẫn clone.
- AI log chép prompt user thực, outcome/verification/decision. Nếu chưa đủ 6 entries theo rubric thì để pending.
- Kiểm tra technical claims bằng source/test logs; không phải mọi mục trong plan đều implemented.

## 6. Git publication

- User yêu cầu push là authorization cho commit/push trong phạm vi repo họ chỉ định; không hỏi lại chỉ để xác nhận hành động đã được yêu cầu.
- Inspect remote refs trước init/fetch/push; nếu remote có history thì tích hợp an toàn, không force push.
- `git add` có kiểm soát; xem `git diff --cached --stat`, tracked file list và secret patterns. Ignore build/cache/local properties/signing credentials, local skill tooling, đề PDF, ảnh/text tham chiếu copy và scripting bytecode.
- Tạo commit meaningful; không backdate hoặc fabricate tiến trình nhiều ngày để đáp ứng rubric.
- Push branch được chấp thuận; xác minh remote SHA khớp HEAD và working tree sạch. Báo commit/branch/URL.
- Không đổi visibility, collaborators, deploy Pages/site hoặc merge PR ngoài phạm vi được yêu cầu.
- Repo hiện private; lecturer access là task riêng cần giải quyết trước submission.

## 7. Firebase continuation — chỉ khi có yêu cầu mới

1. Chốt project/package/SHA-1 và Auth provider.
2. Thiết kế owner paths/streams/atomic CRUD; không tái dùng snapshot save toàn bộ làm multi-user backend.
3. Rules/indexes/emulator isolation tests rồi deploy; xử lý mutation relation và delete/create races.
4. Session disposal/FCM binding theo UID; demo data không tự nhập vào dữ liệu user thật.
5. Từng service FCM/RC/Crash/Analytics/PDF có hành vi và console evidence thật.
6. Không lưu provider secret trong APK, Firestore client-readable, repo hoặc AI logs.
7. Sau integration mới làm MobAI10 scripts/AI review/fidelity/report/video và cập nhật gates tương ứng.

## Constraints hiện hành21/10/2026 — ưu tiên hơn ghi chú từng lượt

- Không chạy/tạo/sửa emulator theo yêu cầu người dùng vì máy yếu. Native/device checks hoãn; dùng Flutter tests và web preview, không báo chúng thay native evidence.
- Validation mới cập nhật LedgerValidation và tests ở VM/repository/form cùng lúc; giữ grapheme length/null-vs-zero/micros/date/quota semantics.
- Storage error không gọi resetDemo/clearDemo để bypass guard. Chỉ recovery UI có confirmation mới gọi recoverDemo; repository phải lưu raw backup thành công trước replace. Schema2 đã có migration1→2 theo yêu cầu mới; giữ backup-before-replace/retry/load ordering, không bump schema tiếp khi chưa có thiết kế/tests.
- Read clockProvider cho mutation/validation, watch nowProvider cho time-dependent UI/projections. Timer/projections phải dispose/pause đúng; tests dùng clock cố định và lifecycle fixture, không sleep thật để đợi reset.
- Chạy checks tuần tự trên máy yếu; web JS build có thể dùng --no-wasm-dry-run để bỏ compile Wasm không cần cho scope. Không claim Wasm/browser/native test nếu chưa chạy.

## UI audit bổ sung21/10/2026

- QA gallery nằm trong tests, không thêm route/dependency runtime. Tái tạo ảnh bằng flutter test --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true; ảnh/log .taste-skill ignored.
- UI tests phải kiểm360/412×800 và text1/1.3/2 với font thật, SafeArea/keyboard/long content. Kiểm title bounds và xem ảnh vì AppBar/helper clipping không luôn phát RenderFlex error.
- Finder tới field cuối dùng key ổn định thay vì .last khi ListView lazy; dialog đưa vào giữa viewport trước tap; spinner thật không dùng pumpAndSettle vô hạn.
- Báo riêng Flutter engine render, browser và Android; không dùng ảnh Flutter làm evidence live Figma/8 ảnh nguồn Lab2/native. B11–B13 local/annotation đã hoàn tất; giữ full QA412/mockups/final fidelity pending.

## Accessibility/state/Figma workflow —21/10/2026

- Action rows dùng ActionSurface cho button/selected/keyboard/focus/min48; không thay InkWell nếu không có action chỉ để tạo role giả. Busy hình tĩnh không cung cấp phần trăm completion không biết cho semantics.
- Bảo vệ requireValue/projections bằng ledgerFeedback; forms giữ controllers/ID/DraftGuard và search field có controller nếu cần giữ qua loading/error/Retry. Saving khóa cả focus và pointer.
- Confirmed mutations guard từ trước dialog, kiểm mounted sau await, chỉ onSuccess sau write; error giữ data/draft và cho retry. Not-found usage không tạo lại ID đã xóa qua route cũ.
- Flutter3.47 semantics tests phải dispose handle trong test/finally trước end-of-test verification; deferred addTearDown không đủ. Guideline pixel contrast có thể phát hiện text mảnh; rà render/token thực, không bỏ assertions để giả pass.
- Khi dùng Figma đọc skill figma-use/API index trước, inspect đúng node/fonts, return mọi IDs, giữ original UI khi chỉ annotate. Link thật và phân biệt annotations với full mockups/final fidelity. Không dùng create_new_file cho task chỉ bổ sung annotation trong file hiện có.

## A03–A06 —21/10/2026

Đọc docs/scope-decisions.md và context hiện hành; không dùng các số test/toolchain/Git trong đoạn lịch sử làm trạng thái mới. HG01–HG10 giữ nghĩa gốc trong plan. Checklist tick đúng local/full scope, file đã tồn tại không ghi là chưa tạo. A01/A02/A07 vẫn pending; không tự bỏ P0 hoặc bật Firebase. Docs-only kiểm links/fences/IDs/portability/runtime hash và diff whitespace, không chạy build để tạo thêm log. Bộ UI skills không có trong checkout; fresh clone không cần skills/Node.

## P0 local sau A04 —21/10

Đọc docs/local-p0-upgrade.md và schema2. Metadata account và usage đều có source để budget/source không trộn; reset/clear chỉ gắn demo, không xóa legacy/manual. Khi sửa quota giữ key qua rename, không trùng label/keys; edit route cũ không resurrect window đã xóa. Các timezone calculations ở ReportingCalendar, dùng instant UTC native ở boundary; không gọi TZDateTime.toLocal để suy timezone thiết bị. History query/cycle/source phải khớp card/chart/legend/provider. UI fields mới cần final Figma/fidelity update riêng; không báo annotation B13 là đã đồng bộ. Giữ tests/migration và docs nhất quán, không suy local implementation là đã có Firestore/UID.
