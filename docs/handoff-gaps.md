# Handoff gaps — hiện trạng21/10/2026

## Bước2 — visual handoff P0,21/10/2026

Đã cập nhật live Figma theo source checkpoint `d4b6167`:8 màn360/412,3 phần cuộn P0,6 feedback specimens và provider/cost-basis continuation;7 local components,455 text nodes/120 instances,0 image fills.8 original annotations và8 notes trang07 đã sync. Đã xem QA412/component states Lab2, app renders360/412 và ảnh Figma sau fixes. [Visual handoff](visual-handoff-21-10.md) giữ bảng3 phía, node links, môi trường, sai khác và giới hạn. Audit local F11–F13 đã có evidence; chưa pixel-perfect/sign-off/GATE-08/native/backend/submission. Lượt này không sửa Flutter hoặc chạy lại tests/build;83 runtime hashes giữ nguyên. Không emulator/Firebase/push.

Hiện trạng mới sau A04: [local P0 upgrade](local-p0-upgrade.md) đã giải quyết phần local model/default purposes/multi-window/source/cycle của HG06/HG09, mở rộng form/retry HG03/HG07 và source isolation HG04. Bảng HG dưới đây đã cập nhật implementation sau A04; backend/native/lecturer/final fidelity vẫn pending. Không đánh toàn gap đã đóng theo local tests.

HG01–HG10 giữ đúng nghĩa trong [plan mục2](IMPLEMENTATION_PLAN.md), không đánh số lại các lỗi kỹ thuật thành gap gốc khác. Phần chi tiết scaffold phía dưới là lịch sử; bảng này và [scope decisions SD01–SD08](scope-decisions.md) là trạng thái hiện hành. A03–A06 là audit docs; lượt upgrade sau đó có code/test/build, kết quả cuối ở test-report.

| Gap gốc | Resolution hiện có | Verification / phần còn lại |
|---|---|---|
| HG01 Root DESIGN lịch sử khác final | Dùng Lab2 reference/theme; đã xem8 final360/8 QA412 và component/state boards live | Visual handoff có mockups360/412/annotations P0; local audit hoàn tất, pixel/native/lecturer sign-off pending |
| HG02 Handoff chưa có Flutter code |33 lib files, theme/components/screens Riverpod đã có | Bộ local tests hiện hành trong test-report; chưa coi là đủ backend hoặc native |
| HG03 Preset/form giả | Form thật, validation chung, draft/Back/Retry/stable ID | Form safety/stability/local flows tests; native IME hoãn |
| HG04 Dataset prototype độc lập | Shared local ledger/projections/calculator, source isolation và demo-safe reset đã có | Firestore/UID/atomic counters và cloud demo isolation chưa có; C05–C15/SD07 pending |
| HG05 iOS chrome trong bài Android | App dùng SafeArea/Material system bars, không vẽ Dynamic Island | Flutter simulated insets đã test; APK trước polish không thay native test source hiện hành |
| HG06 Thiếu login/quota/provider/usage | Có demo entry/metadata/usage/purpose/model/defaults/multi-window/source/cycle/IANA; S09–S12 local thích nghi | Google Auth/S13–S14 chưa có; numeric quota allowances/estimates không thuộc mode hiện tại, full Firebase/fidelity pending |
| HG07 Loading/error minh họa | Async local states/typed failures/Retry/recovery và confirmed mutations thật | Tests load/write/backup/dispose/reload đã có; query/network/auth/PDF upload states chờ backend |
| HG08 Chưa kiểm keyboard/text lớn/accessibility | Ma trận360/412/768/1440, scale1/1.3/2, semantics/focus/targets/contrast/reduced motion | Tests/ảnh Flutter trong fidelity-check; TalkBack/IME/native hoãn, không claim widget tests thay chúng |
| HG09 Chưa rõ remaining tiền/token/% | USD micros/null-vs-zero/coverage/basis breakdown, budget theo cycle/source, quota windows manual stale không cộng% | Calculator/schema/VM/calendar/live clock/form tests; numeric allowance/pricing mode/backend/native còn pending |
| HG10 Đổi chủ đề chưa được chấp nhận | Người dùng cho phép đổi; design log/mapping, annotations và mockups page237:2 đã có | Lecturer acceptance A01/A02 chưa có; không suy từ Figma edits là được duyệt |

HG01–HG10 có resolution hoặc phần pending rõ, không đồng nghĩa tất cả gap đã đóng. DESIGN-03 là hoàn tất **ghi nhận gap**, các gates giữ pending. Backend không được coi là done theo local tests; đã có annotated mockups, nhưng pixel/native/lecturer sign-off, MobAI và release vẫn thiếu.

## Lịch sử gaps khi dựng scaffold và local stability

Các số lượng30 source/106 tests, Figma pending và B11 pending dưới đây chỉ mô tả thời điểm cũ; B11–B13 resolution sau đó đã thay thế. Không dùng đường dẫn Lab2 sibling để build fresh clone.

| Gap | Quyết định trong code | Kiểm chứng / phần còn lại |
|---|---|---|
| Root DESIGN.md lịch sử khác final | Dùng `lab2_prm/design/DESIGN.md` cho màu/type/radius | Theme manual review; live Figma pending |
| Không có Flutter Lab2 code | Xây reusable theme/widgets trước screens |30 source Dart files + 8 test files sau B03–B07 ngày21/10 |
| Prototype chỉ preset tiền | Form account/usage thật, nullable metrics, validation, draft giữ khi chọn purpose |21/10: guard Back cho3 form; widget tests draft/lỗi lưu/retry/keyboard pass |
| Nghiệp vụ mới khác hóa đơn | Map8 màn sang account/usage/purpose/analytics | DC02–DC06; giảng viên acceptance pending |
| Login/profile chưa thiết kế đủ | Demo entry/profile cùng tokens, Google pending | Không claim Auth tích hợp |
| Backend chưa cấu hình | Interface repository + local implementation | Firebase pending theo yêu cầu |
| iOS chrome trong final | Dùng platform appbar/SafeArea, không vẽ iPhone UI |21/10: doctor xác nhận Android toolchain có; native results ghi trong test-report |
| Token/quota/cost chưa có định nghĩa | USD micros, missing khác0, quota snapshot nhập tay độc lập | Calculator/VM tests |
| Validation khác nhau giữa form và VM | LedgerValidation dùng chung, Unicode graphemes, bounds/null/zero/date/quota/references |106 tests toàn suite; quota-time bypass qua saveAccount đã chặn |
| Storage hỏng không vào được Profile để reset | Lazy repo init; error/Retry + confirmed recovery, backup raw trước replace | Load/init/read/write/schema/backup/recovery UI/failure tests; schema1 giữ nguyên |
| ID timestamp và reload/dispose khi đang save | UUIDv4 và VM write/reload/epoch/mounted guards | Cùng clock/lùi clock/retry/concurrency/dispose/forced route removal tests; multi-window vẫn ngoài scope |
| Reporting không tự đổi khi thời gian trôi | Reactive nowProvider, minute/reset deadline, pause/resume/dispose; UTC-local thống nhất |10 live clock tests; không tự seed lại hoặc reset quota |
| Timezone và quota cycle | Local demo theo timezone thiết bị/tháng dương lịch; stale quota khi reset | IANA timezone/cycle tùy chỉnh còn pending |
| Desktop layout chưa có Lab2 | Framed-sheet sidebar responsive; mobile4 tab | Browser screenshots và widget360/412/768/1440 |
| Visual inspector dựa vào DOM | Flutter dùng CanvasKit, DOM inspector không thấy canvas text/h1 | Dùng ảnh thật + Flutter widget tests; không claim DOM gate pass |
| Chart/legend/sidebar tràn khi chữ lớn hoặc số tiền dài | Chart đo label + cuộn ngang, caption donut có fallback, AdaptivePair và sidebar cuộn | B08–B10: ma trận360/412/768/1440×800, scale1/1.3/2, seed/stress; xem fidelity-check |
| Appbar/helper bị cắt nhưng không luôn báo RenderFlex | Toolbar theo scaler, title2 dòng, helper/error12 dòng | Ảnh Flutter font thật + title bounds assertions, keyboard focus/CTA tests |
| Component states/targets thiếu audit chung | Material themes min48/CTA52, SaveButton/LoadingFeedback; gallery chỉ trong test | 9 families, pressed/focus/filled/disabled/loading/error/empty/dialog/selection; B11 accessibility đầy đủ vẫn pending |

## Portability sau publication 20/10

Repo dùng [lab2-ui-reference](lab2-ui-reference.md) và Figma gốc thay các bản copy ảnh/text nguồn. Flutter build chỉ đọc source/font/platform assets; không phụ thuộc sibling Lab2 hoặc bộ skill local.


## B11–B13 resolutions —21/10/2026

- Custom tap rows thiếu role/focus: ActionSurface semantics/min48/Tab+Enter/focus outline, guideline checks Purpose/4 tabs360/412. Border/range label contrast được sửa, không đổi palette.
- Reduced motion chưa bao phủ route/dialog/sheet/busy hoặc đổi setting giữa fade: thêm bypass/noAnimation/static status, giữ tab/filter/scroll; saving khóa keyboard focus.
- Reload/cold load trên route có thể requireValue crash/mất controls: ledgerFeedback + nullable init đọc; controllers/DraftGuard giữ qua lỗi, not-found không resurrect session. ConfirmedActionButton/Profile guard repeated confirm/dispose và không báo success khi write fail.
- Live Figma annotation trước đây pending: đã xem8 final360, annotate8 original nodes và thêm page233:2/board233:3 gồm16 handoff cards. Từng link ở fidelity-check.md. DESIGN-05/full QA412/state/component review/final fidelity chưa tự đạt từ annotations.
- Brand geometry/initials:3 tests xác minh SVG/painter/native/PWA/favicon/maskable; initials grapheme có label không phải logo provider. Không thêm tài sản runtime hoặc tái tạo icon không cần thiết.

Native TalkBack/IME và MobAI vẫn hoãn; Flutter engine guidelines không thay Android evidence. Firebase/Notifications/Reports còn pending. Không emulator/delegation/commit/push.
