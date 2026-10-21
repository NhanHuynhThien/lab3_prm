# Build status — source hiện hành

## Publication trực tiếp main —21/10/2026

Theo yêu cầu “push code lên thẳng main cho tôi.”, commit publication gồm Auth, Firestore workspace/rules/tests và tài liệu hiện hành. Đối chiếu SHA bằng Git log/remote main; các ghi chú chưa commit/push bên dưới là checkpoint trước yêu cầu này. Runtime104 files khớp bản299 Flutter tests/142 rules cases/analyzer/format/web build đã kiểm, không chạy lại build cho Git/docs-only. Native/manual SDK CRUD/A-B vẫn pending.


## Cloud workspace/rules —21/10/2026, mục3–5

Đã nối4 tab với Firestore theo UID, CloudLedgerViewModel dùng4 streams ghép nhất quán, full-dataset reporting, CRUD/quota/settings atomic, revision từ lúc mở form, last-good/cache/pending/error/retry giữ draft/filter. Mỗi UID/demo có ProviderContainer/Navigator riêng, root auth action coordinator dùng chung; logout/change UID dọn state/listeners/routes, không seed/upload local vào cloud. Factory tắt Firestore disk persistence. [Workspace hướng dẫn](firestore-workspace.md) ghi thiết kế và manual checks.

Rules default deny/owner/schema/relations/counters/quota labels/receipts đã code và deploy với5 indexes vào tokenledger-lab3/(default), Standard/asia-southeast1. Rules Test API142 cases pass (mocks trước/sau, không emulator/doc writes), live source hash khớp local và unauth GET403. Index readiness xem test-report, không suy deploy accepted thành READY. Full299 Flutter tests pass162s, analyzer sạch, web release48.3s;46 lib/22 test Dart files (2 helpers).25 tests VM/workspace mới;15 Auth tests cập nhật giữ assertions. Native/A-B thật/SDK transactions qua mạng/F1–F3 manual gates vẫn cần nghiệm thu. FCM/RC/Crash/Analytics SDK/PDF/Figma sync chưa làm. Không emulator/billing/commit/push.


## Firestore foundation —21/10/2026, mục1–2

Đã thêm cloud_firestore7.0.0, thiết kế envelope/paths theo UID, CloudLedgerRepository streams/atomic CRUD và SDK adapter cho account/usage/quota. Counters/revisions/quota label reservations và operation receipts commit cùng transaction, không upload snapshot local.35 tests repository mới pass; full regression274 tests pass138s trước lần siết receipt/path validation cuối, sau đó35 tests liên quan pass lại; analyzer sạch và web build xem test-report. Source44 lib/20 test Dart files, gồm2 support helpers. [Data contract](firestore-data-contract.md) ghi mapping/invariants/query/indexes và lifecycle. Chưa nối UI/VM, chưa viết/deploy rules/indexes hoặc kiểm database thật; các backend gates còn pending. Không emulator, billing, telemetry hoặc publication.

Người dùng báo Google web login/reload/logout và Authentication Users đã thành công, đồng thời đã tạo Firestore. Đây là xác nhận người dùng; native/Play services/release cert và Firestore integration chưa được kiểm bởi agent.


## Firebase/Auth C01–C03 —21/10/2026

Người dùng đã cho phép tiếp tục Firebase và cung cấp config project `tokenledger-lab3`. Core/Auth/Google SDK, service/VM, loading/cancel/error/Retry, auth guard/Profile và sandbox demo đã có code. Google provider/localhost và debug SHA được kiểm trực tiếp qua API/CLI; không gọi ledger trước auth hoặc đưa seed vào dữ liệu cloud. Profile authenticated hiện identity thật từ SDK, dữ liệu Firestore chưa nối. Full239 tests pass140s, analyzer sạch, web JS build45.3s; Gradle processDebugGoogleServices pass112s, không build APK/chạy máy ảo. [Auth setup](firebase-auth-setup.md) ghi source/flows/config/evidence và manual OAuth/native còn cần kiểm; GATE-01 chưa đạt. Không đổi billing, bật Analytics SDK hoặc các services ngoài Auth. Làm trên main sau PR#1; lượt này chưa commit/push.

## Publication21/10

Theo yêu cầu “push hết lên cho tôi”, target là [branch codex/local-form-safety](https://github.com/NhanHuynhThien/lab3_prm/tree/codex/local-form-safety), gồm checkpoint Flutter d4b6167 và commit tài liệu visual handoff chứa đoạn này. Xem Git log/remote refs cho SHA publication; các đoạn “chưa push” bên dưới ghi thời điểm trước yêu cầu này. Không merge main hoặc thay visibility. Runtime giữ nguyên bản200 tests đã kiểm; Firebase/native/lecturer acceptance vẫn pending.

## Bước2 — visual handoff P0,21/10/2026

Đã cập nhật live Figma theo source checkpoint `d4b6167`:8 màn360/412,3 phần cuộn P0,6 feedback specimens và provider/cost-basis continuation;7 local components,455 text nodes/120 instances,0 image fills.8 original annotations và8 notes trang07 đã sync. Đã xem QA412/component states Lab2, app renders360/412 và ảnh Figma sau fixes. [Visual handoff](visual-handoff-21-10.md) giữ bảng3 phía, node links, môi trường, sai khác và giới hạn. Audit local F11–F13 đã có evidence; chưa pixel-perfect/sign-off/GATE-08/native/backend/submission. Lượt này không sửa Flutter hoặc chạy lại tests/build;83 runtime hashes giữ nguyên. Không emulator/Firebase/push.

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
