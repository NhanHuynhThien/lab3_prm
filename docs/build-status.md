# Build status — source hiện hành

## Checkpoint local —21/10/2026

Theo yêu cầu “bước 1. bắt đầu làm”, checkpoint chứa B01–B13/A03–A06 và P0 local trên branch `codex/local-form-safety`; xem SHA bằng `git log -1 --oneline`. Đây là commit local, chưa push. Các đoạn “chưa commit” bên dưới ghi trạng thái ở lần thực hiện trước checkpoint.

Audit candidate102 files: không phát hiện secret theo các pattern đã kiểm, file cấm hoặc file lớn hơn2MB; build/cache, local properties, generated registrant và tooling vẫn ignored.83 file runtime khớp fingerprint của full200 tests/analyzer/format/web JS build gần nhất, nên không chạy lại Flutter chỉ để commit. Đây không phải secret audit toàn bộ lịch sử Git hoặc AI PR review. Firebase, native/MobAI và final fidelity vẫn pending; không chạy emulator.

Hiện trạng sau nâng cấp P0 local21/10/2026: **33 lib/14 test files,200/200 tests pass140s**, analyzer sạch, format47 files0 changed. Schema2/migration/model/default purposes/multi-quota/cycle/IANA/provenance/source isolation/provider/history đã implement. Web release JS build cuối pass57.7s; evidence/giới hạn xem [test report](test-report.md). Firebase/native/MobAI/submission vẫn pending; không emulator hoặc commit/push.

## Baseline trước upgrade — lịch sử B11–B13/A03–A06

Cập nhật21/10/2026. Baseline B11–B13:31 lib/12 test files,168 tests pass; analyzer/format sạch, web JS build pass51.4s. Đã có draft/validation/recovery/concurrency/clock, responsive/accessibility/state audit và live Figma annotation B13. Firebase pending; native hoãn, không emulator. APK lịch sử trước B03–B13 không phải bản source này.

A03–A06 đã chuẩn hóa [scope/gaps SD01–SD08](scope-decisions.md), checklist, HG01–HG10 và Git/context. Đây là lượt docs-only, không chạy lại Flutter checks. HEAD/remote main4aeb7b7, branch codex/local-form-safety; B/A thay đổi chưa commit/push.

## P0 local sau A04 — implementation mới nhất21/10

33 lib/14 test files. Schema2 giữ storage key cũ, migration1→2 backup raw trước replace, shared load/migration và save ordering; thiếu nguồn cũ giữ legacy/unspecified, timestamps ghi UTC. Account có model/default purposes/cycle/timezone, usage có model/provenance/cost basis, quota nhiều windows/source/note/unitpercent và delete guard. Source picker tách manual/demo/legacy; reset/clear demo giữ dữ liệu khác và tránh collision IDs. Account budgets/custom cycle/DST, history theo cùng cycle khi drilldown, nhóm ngày/report timezone, provider/legend/sector drilldown và adaptive metric đã nối UI. Chi tiết [upgrade](local-p0-upgrade.md); kết quả cuối ở [test report](test-report.md).

Không Firebase, estimate engine, provider sync hoặc auth/router/Notifications/Reports mới. Không sửa live Figma; annotation B13 chưa mô tả đầy đủ field mới. Native hoãn theo user, không emulator; chưa commit/push. Các kết quả168 tests ở đầu phần lịch sử là baseline B11–B13, không phải bộ test cuối của upgrade.

## Lịch sử scaffold và cleanup20/10

Các số lượng/giới hạn dưới đây ghi tại từng giai đoạn, không phải hiện trạng khi đã có cập nhật21/10.

### Đã có trong code tại scaffold20/10

-25 Dart source files,3 test files;12 screen files và usage-detail sheet.
- MVVM/Riverpod, local repository/seed/calculator, reporting projections tách khỏi Views.
- Account CRUD/archive/restore, usage CRUD, quota update, analytics và history filters.
- Desktop sidebar, mobile4 tab, IndexedStack giữ state và animation hỗ trợ reduced motion.
- SharedPreferences JSON schemaVersion1; cost integer USD micros; missing token/cost giữ null.
- Seed3 accounts/12 sessions: cost$12.84, token286k,1 phiên thiếu cost/token. Đây là dữ liệu giả định.
- SVG logo/Flutter painter, font Inter và native/web launcher icons.

## Dọn repo20/10

Đã loại khỏi Git: vendor skill files, skill draw cache/lock local, ảnh Lab2 copy, text snapshots, PDF đề bài, ảnh/log inspector và bản logo PNG1024 xuất dư. Ở lượt cleanup giữ bộ skill local qua `.gitignore`; checkout hiện tại không có thư mục skills. Không cần khôi phục để build Flutter.

`pubspec.yaml` chỉ bundle font Inter; logo trong UI do Flutter painter vẽ. Source SVG giữ để chỉnh thiết kế, launcher PNG nằm trong `android/` và `web/`.

Hướng dẫn chạy dùng Flutter CLI. Build/cache sinh local không đưa lên GitHub. Không thay chức năng app hoặc bắt đầu Firebase ở lượt cleanup.

### Chưa hoàn tất tại scaffold20/10

Google Auth/Firestore/rules/FCM/RC/Crash/Analytics/PDF cloud, provider sync, MobAI, AI PR review, Figma fidelity đầy đủ và Android build/device testing.

Android SDK chưa có ở lần doctor trước; web build không thay thế APK. Xem [test report](test-report.md) cho verification hiện hành, [architecture](architecture.md) cho source boundaries và [Firebase pending](firebase-pending.md) cho việc tiếp theo.

## Local form safety — 21/10/2026

26 Dart source files/4 test files; thêm DraftGuard, bảo vệ Back và saving cho3 form. Account/usage retry giữ ID; lỗi lưu giữ draft và có feedback. Archived account cho sửa usage đã tồn tại nhưng vẫn chặn usage mới/đổi accountId. CTA theo keyboard inset và dropdown co chiều rộng.

Pub get thành công, analyzer sạch, full38/38 tests pass. Doctor21/10 xác nhận Android SDK/licenses có sẵn; APK/native outcomes và emulator limitations xem test-report, không còn kết luận thiếu SDK chỉ từ doctor19/10. Firebase tiếp tục pending.

## Hoàn tất B03–B07 —21/10/2026

30 lib Dart files/8 test files. Shared validation và UUIDv4; lazy storage init + typed error/Retry/confirmed recovery có raw backup; archived history edit/delete UI; guard concurrency/reload/dispose; live clock/foreground resume/auto-dispose và UTC-local thống nhất. Model schemaVersion1/key chính giữ nguyên. Account budget formulas nằm trong projection.

Final: pub get, format38 files, analyzer sạch,106/106 tests pass và web release JS build pass. characters1.4.1 đã có sẵn chuyển thành direct dependency để text validation khớp Flutter Unicode; không nâng package versions. Xem test-report và audit cuối roadmap cho evidence/limits. Không chạy emulator theo yêu cầu; native verification hoãn, Firebase tiếp tục pending.


## B08–B10 —21/10/2026

30 lib Dart files/10 test files;142/142 tests pass, format40 files không đổi, analyzer sạch. Audit mapping8 màn và12 màn hiện hành/usage sheet; gallery9 families chỉ trong tests. Sửa chart/legend/usage row/donut/sidebar responsive, AppBar title bounds và helper/error multiline; SaveButton/LoadingFeedback dùng chung, button targets48/CTA52. UI tests tải font thật, kiểm360/412/768/1440×800 với text1/1.3/2, seed/stress, keyboard/SafeArea; đã xem ảnh render. Chi tiết: fidelity-check.md/test-report.md. Chưa so pixel bộ ảnh Lab2 gốc, live Figma/native/final accessibility còn pending; Firebase vẫn pending, không emulator/commit/push.

Web release JS build bản UI cuối thành công (`--no-wasm-dry-run`, compile38.2s); không phải Android hoặc browser interaction evidence.


## B11–B13 —21/10/2026

31 lib/12 test files. Accessibility/motion/states có code và26 tests mới; total168. ActionSurface, ledgerFeedback, confirmed mutations, nullable cold usage init, persistent search/draft và focus/motion guards; brand/assets geometry giữ nguyên. Đã xem/annotate8 frame live Figma, thêm16 cards ở page233:2/board233:3, không thay original StudentPay visuals. Final verification ở test-report. Không có Firebase/MobAI/native evidence mới; không emulator, không commit/push.

B11–B13 final: format43 files0 changed, analyzer sạch,168/168 tests pass108s, web release JS build pass51.4s. Quota unknown/stale và budget chưa đặt có semantics riêng thay vì0%; không đổi data.
