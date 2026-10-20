# AI implementation log — dữ liệu thật của phiên làm việc

Hiện có14 prompt nguồn thực (entry12/14 Git-only, entry13 visual/docs) đến21/10; công cụ/kết quả ghi riêng theo từng entry. Không coi entry docs là code evidence nếu rubric không chấp nhận.

Lịch sử lượt đầu19/10/2026. Tool: Codex; shell/Flutter/Dart; cua_repl IAB; local taste-skill draw/lint/inspect. Không gọi AI provider để phân tích usage trong app. Không có subagent, Firebase console, MobAI hoặc AI PR review trong lượt này.

## Entry1 — phạm vi đổi nghiệp vụ

Prompt người dùng nguyên văn:

> Bạn có thể build hơn nhưng do mình đổi chủ đề về quản lí token nên chức năng cũng sẽ có sự thay đổi nha

Output: mapping StudentPay → TokenLedger, accounts/usage/purpose/quota thay expense/bill; P0/P1/P2 và checklist triển khai.

Verification: đọc đủ17 trang PDF; đối chiếu final design tokens/handoff/screenspec Lab2 và các ảnh final. Decision: accepted về hướng nghiệp vụ; lecturer acceptance/live Figma annotations vẫn pending.

## Entry2 — scaffold và logo

Prompt người dùng nguyên văn:

> Build và dựng khug sườn cho mình. Mình cho phép bạn DESIGN LOGO app luôn. FireBase thì pending lại

Output: Flutter Android/web, MVVM+Riverpod, local repository/seed/calculator, UI và CRUD local; logo vector T/L token hexagon + PNG/launcher/PWA.

Verification: analyzer, calculator/VM/widget tests, web release build, mở app trên browser; source/code đọc và sửa qua các lượt tool. Decision: modified: không giả Auth/Firebase, dùng demo entry ghi rõ local persistence, để integration contract và backlog backend.

## Entry3 — taste-skill, animation và dashboard

Prompt người dùng nguyên văn:

> 1. Cài thêm npx skills add Leonxlnx/taste-skill để làm đẹp UI
> 2. Bổ sung thêm animation và nâng cấp dashoboard quản trị cho mình luôn nha

Output: cài 13 skills vào project, app-screen draw framed-sheet seed1978369971; sidebar desktop/4-tab mobile, chart/progress/amount/tab/route animation và visual review.

Verification: đã đọc app-screen workflow; chạy draw/lint/inspect. Dart không được source linter hỗ trợ; inspector CanvasKit có no-title/hero-void DOM limitations, không báo pass giả. Đọc ảnh desktop/tablet/mobile và sửa layout/helper text/zero bars.

Decision: modified: giữ màu/Inter/radius/component Lab2 thay vì thay trọn token palette theo skill. Không dùng fake financial metrics hoặc role-based admin chưa có backend.

## Entry4 — cập nhật tài liệu/agent và publication

Prompt người dùng nguyên văn:

> cập nhật .md và .agent chi tiết sau đó push vào repo này cho mình
> [https://github.com/NhanHuynhThien/lab3_prm.git](https://github.com/NhanHuynhThien/lab3_prm.git)

Ngày 20/10/2026. Output: README/docs index/architecture/portable Lab2 references; AGENTS.md và `.agents/` context/workflows; chuẩn bị initial source publication. Không chỉnh vendor skills và không bắt đầu Firebase.

Verification: đọc code thực tế, kiểm tra remote private/empty, kiểm tra links/provenance/ignore/secret patterns, chạy format/analyzer/tests theo report 20/10. Remote commit phải đối chiếu bằng Git trước khi báo push thành công; không ghi SHA tưởng tượng trong log.

Decision: accepted. Giữ private visibility và lịch sử commit thật; phần Firebase/MobAI/Android/PR review vẫn pending.

## Entry5 — cleanup source tree

Prompt người dùng nguyên văn:

> bỏ các file thừa + compile python nữa. Nó đang không đúng với src code á nha

Ngày20/10/2026. Output: loại vendor skills/tool cache/lock, đề PDF, ảnh/log inspector, ảnh/text tham chiếu copy và PNG export dư khỏi Git. Giữ skills đã cài local, thêm ignore patterns; bỏ asset brand directory không dùng khỏi pubspec. README/workflows chạy bằng Flutter CLI.

Verification: đối chiếu pubspec và các reference trong Dart; trước cleanup không có file .py/.pyc tracked. Chạy clean, dependency resolution, analyzer/tests và web build sau thay asset bundle; kết quả ghi trong test-report. Không sửa dữ liệu nghiệp vụ hoặc bật Firebase.

Decision: accepted. Repo tập trung source Dart/Flutter và assets cần thiết; không rewrite Git history hoặc gỡ skill đã được người dùng yêu cầu cài.

## Entry6 — local form safety và Android verification

Prompt người dùng nguyên văn:

> bạn làm cho tôi

Ngày21/10/2026. Ngữ cảnh: người dùng yêu cầu thực hiện thứ tự vừa đề xuất từ roadmap: kiểm tra Android toolchain, bảo vệ form/draft/retry, xử lý account archived, mobile layout và APK/native smoke. Firebase vẫn pending.

Output: DraftGuard dùng chung cho account/usage/quota, CTA theo keyboard inset, responsive dropdown, account ID ổn định khi retry; cho sửa usage đã có của account archived nhưng chặn phiên mới và đổi accountId. Bổ sung tests và cập nhật docs/roadmap.

Verification: `flutter doctor -v` xác nhận toolchain/licenses; pub get thành công; analyzer sạch; full38/38 tests pass gồm21 form safety tests. Tests phát hiện billing dropdown overflow360dp đã sửa; cả360/412dp với text scale1/2 và keyboard inset300dp pass. APK/emulator results ghi trong test-report sau khi kiểm thực, không suy từ widget tests. AVD Pixel7 cũ có lỗi SettingsProvider/settings_global.xml; dùng AVD QA riêng, không wipe dữ liệu máy ảo cũ.

Decision: accepted về local polish; giữ UI Lab2 và giới hạn Firebase. Chưa gọi MobAI/AI PR review, chưa cập nhật Figma và chưa push trong lượt này.

## Entry7 — triển khai và audit B03–B07

Prompt người dùng nguyên văn:

> bắt đầu làm b03 đến b07. làm xong check lại từ b03 đến b07 xem có thiếu cái gì không. nếu có thì thêm xoá sửa cho đủ. đảm bảo bám sát các yêu cầu ban đầu ở các tài liệu và markdown có từ trước.

Ngày21/10/2026. Output: LedgerValidation dùng chung, UUIDv4, repository lazy init/typed errors/backup recovery; mở action archived history; concurrency/reload/dispose guards; reactive clock/projections và UTC-local UI/formatting. Giữ Riverpod, USD integer micros, null-vs-zero, accountId immutable, archive history và Lab2 tokens. Firebase vẫn pending, không chạy emulator theo yêu cầu mới.

Verification: pub get (characters1.4.1 từ transitive thành direct, không upgrade), format38 files không đổi, analyzer sạch, full106/106 tests pass; web release JS build pass. Rà từng tiêu chí B03–B07 và thêm các case thiếu: hidden archived Edit, plugin-init error trước render, saveAccount quota bypass, timer unused, Unicode grapheme, integer USD round trip và UTC/local year-boundary history/edit. Chi tiết/các lỗi fixture được sửa ghi trong test-report. HTTP localhost200; không có Chrome/IAB điều khiển được, ảnh recovery render bằng Flutter tests360/412 với font thật, không báo browser/native pass.

Decision: accepted trong local scope. Không đổi schema1, không tự tạo migration/backend/pricing integration; giữ giới hạn snapshot một VM, timezone thiết bị và raw backup1 bản, không claim multi-device hoặc cloud recovery. Chưa cập nhật live Figma, chưa commit/push, không dùng subagent.

## Entry8 — triển khai và kiểm tra B08–B10

Prompt người dùng nguyên văn:

> làm b08 đến b10 cho tôi.làm xong kiểm tra lại xem có thiếu cái gì không. nếu có thì thêm xoá sửa cho đủ. đảm bảo bám sát các yêu cầu ban đầu ở các tài liệu và markdown có từ trước.

Ngày21/10/2026. Output: audit mapping8 màn/màn phụ theo scope; fidelity draft; gallery9 families trong test; SaveButton/LoadingFeedback/themes, responsive chart/legend/usage rows/donut/sidebar, appbar và helper/error. Giữ Lab2 Inter/palette/radius, Riverpod/projections/IndexedStack và Firebase pending. Không dùng subagent hoặc emulator.

Verification:142/142 tests pass, analyzer sạch, format40 files không đổi; UI ma trận4 viewport×3 scales×2 datasets và keyboard/SafeArea, ảnh Flutter với font thật. Rà ảnh tìm được appbar clipping dù không báo RenderFlex; thêm title bounds test bắt font rounding1.3 và sửa khoảng thở. Fixture ban đầu alias vượt80/last finder thay đổi khi lazy scroll/dialog chưa cuộn đúng được sửa thành dữ liệu hợp lệ/key ổn định/center alignment, không giảm assertions để che lỗi. Kết quả build cuối và môi trường ở test-report.

Decision: accepted cho audit local B08–B10. B11–B13 tiếp theo; không claim live Figma,8 ảnh Lab2 gốc, native hoặc backend evidence. Gallery/ảnh QA không bundle vào app; ảnh/log local ignored. Chưa commit/push.

## Entry9 — triển khai, kiểm tra B11–B13 và live Figma annotation

Prompt người dùng nguyên văn:

> làm b11đến b13 cho tôi.làm xong kiểm tra lại xem có thiếu cái gì không. nếu có thì thêm xoá sửa cho đủ. đảm bảo bám sát các yêu cầu ban đầu ở các tài liệu và markdown có từ trước.

Ngày21/10/2026. Output: ActionSurface semantics/min48/focus/keyboard, contrast fixes, spoken chart dates/USD/final values, reduced route/dialog/sheet/busy motion và saving focus exclusion. ledgerFeedback/cold init/Retry/search/draft/not-found, confirmed mutation/Profile lifecycle guards.23 accessibility/state tests và3 brand tests. Giữ architecture/invariants/core Lab2 và Firebase pending; không emulator/delegation.

Figma: đã đọc skill figma-use (plugin Figma16.0.0, SKILL.md và Plugin API index/type definitions), dùng get_metadata/use_figma/get_screenshot. Đọc page1:3, xem8 final360 images, annotate nodes59:2/49/78/121/160/202/236/279; create page233:2 và board233:3 với16 cards, return52 created node IDs, screenshot840×2402 kiểm thật. Từng link ở fidelity-check. Không sửa original geometry/text, không tạo file mới hoặc đăng site; notes nêu rõ Notifications/Reports pending. Skill không yêu cầu approval hoặc đổi palette; giữ ngoại lệ kế thừa Lab2 Inter/colors/radius/framed-sheet. Bộ vendor UI skills không có trong checkout và không cài lại.

Verification: automated contrast/touch/labels guidelines ở Purpose/4 tabs360/412; Tab/Enter/selected/focus; dynamic reduced motion giữ scroll/search/metric; reload5 forms/screens và dirty Back/error, cold load/not-found/disabled, reset/clear failure/retry/pending/cancel, repeated confirmation/dispose, saving keyboard guard. Brand SVG/geometry/5 Android densities/favicon/PWA/maskable/emoji initials. Tests phát hiện chữ RangePicker mảnh không đạt pixel contrast, đã dùng label semibold; tĩnh busy không được công bố50% như tiến độ thật, đã loại semantics của hình indicator. Fixture lỗi được sửa riêng: semantics handles dispose trước Flutter verification, generic SegmentedButton finder, navigator reset khi đổi fixture screen. Không bỏ assertion để che lỗi app.

Final: format43 files0 changed, analyzer sạch,168/168 tests pass108s, web JS release build pass51.4s; quota unknown/stale/budget chưa đặt có lời đọc trạng thái riêng. Chi tiết ở test-report. Decision: accepted trong local/annotation scope B11–B13; chưa final mockups/QA412+states review/native/MobAI/backend/submission approval. Không commit/push.

## Entry10 — quyết định và audit A03–A06

Prompt người dùng nguyên văn:

> làm a03 đến a06 cho tôi. .làm xong kiểm tra lại xem có thiếu cái gì không. nếu có thì thêm xoá sửa cho đủ. đảm bảo bám sát các yêu cầu ban đầu ở các tài liệu và markdown có từ trước.

Ngày21/10/2026. Output: scope-decisions.md chốt manual/USD/P1/P2/thuật ngữ và SD01–SD08; giữ các yêu cầu P0 thiếu trong backlog, chưa thêm pricing engine. Đồng bộ checklist/gate partial, HG01–HG10 theo nghĩa gốc, nguồn Lab2/Figma, README/build-status/architecture/roadmap và agent context; tách lịch sử khỏi hiện trạng. A01/A02/A07 vẫn pending, không tự miễn trừ rubric.

Verification: đọc models/services/VM/screens/tests và docs; git status/log/remote và ls-remote xác minh branch codex/local-form-safety, HEAD/remote main4aeb7b7. Kiểm local Markdown links, fences/task IDs, paths portability, runtime hashes và git diff --check; kết quả trong test-report. Dùng shell/Python cho docs, không chạy lại Flutter/tests/build vì không sửa runtime;168 tests là kết quả gần nhất ở Entry9. Không dùng skill/subagent, Firebase/emulator/commit/push.

Decision: accepted trong phạm vi quyết định kỹ thuật/docs; model/default purposes/multi-window/provenance/cycle còn phải code theo P0, estimate hoãn có điều kiện đề gốc. Không coi tick A03–A06 là implementation hay lecturer approval.

## Entry11 — code P0 local sau A04 và kiểm tra lại

Prompt người dùng nguyên văn:

> làm cho tôi.

Ngày21/10/2026. Ngữ cảnh: thực hiện bốn bước vừa thống nhất: model/migration → form và quota → cycle/timezone → analytics/history, giữ Firebase pending và không máy ảo.

Output: schema2 + backup-first migration/schema validation, shared load/migration/save ordering, model/default purposes, multi-window percent quota/source/note/stable key/rename/delete guard, usage model/provenance/cost basis. ReportingCalendar IANA/cycle/UTC/DST, source picker/manual-demo-legacy isolation, demo-only reset/clear giữ dữ liệu khác và remap collision. Provider/cost breakdown/adaptive metric/donut drilldown, unified history filters/day grouping/timezone và account-cycle history khớp budget. Giữ Riverpod/service boundary/Lab2 tokens/IndexedStack/reduced motion; không thêm pricing/Auth/provider sync.

Tools: shell/Python/apply_patch/Dart/Flutter; đọc [timezone docs chính thức](https://pub.dev/packages/timezone) trước thêm dependency0.11.2 (http/http_parser transitive), không nâng packages cũ. Không skill UI local; mở rộng components hiện hành theo Lab2 docs/theme, không cài vendor tooling hoặc sửa Figma ở lượt này. Không subagent.

Verification/fixes: tests mới schema_v2_test/scope_forms_test; migration backup/replace/retry/race, provenance/UTC/DST/leap/cycle31, quota independent/upsert/delete, defaults immutable/clear/Back, demo retention, provider/donut/filter/history/timezone và form retry360/412. Lượt đầu tìm được clearDemo sync-Future error contract, UTC special alias và TZDateTime.toLocal quirk: đã sửa native UTC ở seed/model boundary và dùng calendar explicit trong report formatting. Tests cũ cập nhật assertion instant thay local-vs-UTC representation, quota đúng key, source flag giữ khi edit và nhãn kỳ. Fixture legacy phải dùng DateTime ISO cũ, helper scroll đúng vertical ListView thay EditableText/horizontal scroll; không bỏ assertions. Rà thêm cycle drilldown/global filters để các báo cáo không khác tập dữ liệu. Bổ sung source metadata account để không tăng budget từ legacy không liên quan; default account theo nguồn để tránh lưu nhầm vào seed; createdAt dùng cùng instant sau UTC reload và giữ ổn định qua retry khi clock tiến. Xem ảnh phát hiện ký tự mũi tên thiếu glyph Inter, đã thay bằng Material icon. Các lượt full test đang chạy được dừng khi có thay đổi cần kiểm lại, không ghi chúng là pass; full199 pass có ảnh rồi thêm case mixed-source và chạy full cuối. Final:200/200 pass140s, analyzer sạch, format47 files0 changed, web JS build pass57.7s;83 runtime hashes giữ nguyên qua verification/build,21 Markdown links/IDs/portability/fences và git diff --check sạch. Chi tiết test-report; không coi số test B11–B13 là lần chạy mới.

Decision: accepted cho P0 local đã nêu; estimate SD06 hoãn, Firebase/SD07/native/MobAI/auth routes/S13/S14/final fidelity/lecturer acceptance vẫn pending. Chưa commit/push, không emulator hoặc live Figma update. Chưa có cloud owner isolation dù đã tách nguồn local.

## Entry12 — audit và commit checkpoint local

Prompt người dùng nguyên văn:

> bước 1. bắt đầu làm

Ngày21/10/2026. Ngữ cảnh: bước1 đã đề xuất là rà diff/file thừa/secret rồi commit checkpoint local; chưa push. Tools: Git, shell/Python, apply_patch; không skill/subagent. Rà candidate102 files, dependency/lockfile, ignore rules, diff và logs; không phát hiện secret theo pattern đã kiểm hoặc file cấm trong tập candidate. Không tuyên bố scan toàn bộ history.83 runtime hashes không đổi so với fingerprint trước full200 pass/analyzer/format/web JS build; tái sử dụng kết quả thật, không chạy lại Flutter cho Git/docs-only. Kiểm links/fences/IDs/portability và staged whitespace; stage có kiểm soát, commit trên codex/local-form-safety. SHA xem git log của checkpoint, không dùng SHA baseline4aeb7b7 để đại diện source mới.

Decision: checkpoint local để review/khôi phục; không phải reviewed PR, push, native/Firebase/MobAI/final submission. Ghi chú chưa commit của các entry trước là lịch sử; entry Git-only không tự thay evidence implementation theo rubric.

## Entry13 — bước2 Figma và evidence

Prompt người dùng nguyên văn:

> tiếp bước 2

Ngày21/10/2026. Ngữ cảnh: sau checkpoint d4b6167, thực hiện bước2 đã đề xuất là Figma/evidence; Firebase pending, không máy ảo. Tools: Figma metadata/use_figma/get_screenshot/get_libraries/search_design_system, shell/Python/apply_patch/view_image; không subagent. Đã đọc các SKILL.md figma-use/figma-generate-design/figma-generate-library của plugin Figma16.0.0 và Plugin API/type/component/variable/gotchas references. Code Connect trong repo không có; inspect local screens/components rồi get_libraries/search để xác minh source picker/quota không có component published. Reuse Lab2 local variable/text styles/Button, thêm7 local components và1 chartTertiary variable; không import kit khác để đổi core UI.

Output: page237:2 với8 màn360/412,3 phần cuộn P0,6 feedback specimens, notes/component/provider-basis boards;455 text/120 instances/0 UI bitmap fills. Sync8 original annotations và8 notes trang07; geometry/text StudentPay giữ nguyên. View đủ8 QA412 vàcomponent/state boards67:10/144:1934,8 app screens ở360/412 vàcomponent gallery2 widths. View screenshot Figma sau compose/fixes; sửa row sizing/overlap/source picker, donut segments+caption/legend, segmented wrapping/stroke overflow, purpose chips/order, source title style và disabled palette. RIGHT constraints enum bị từ chối/rollback; đọc lại canvas, thay MAX rồi retry. Không bịa app bug hoặc findings PR từ lỗi dựng Figma.

Verification: live structural read-back fontsInter/Material Icons, variables scopes, component properties, image fills/bounds; screenshot final360/412/continuations/states/components/provider vàboard233:3 đã xem. Runtime hashes83 giữ nguyên theo manifest full200; không chạy lại tests/build cho Figma/docs.22 Markdown/IDs/links/fences/portability vàdiff whitespace được kiểm; chi tiết node/environment/sai khác ở visual-handoff-21-10.md.

Decision: accepted cho annotated mockups vàlocal comparison/audit/sync F11–F13 ở source d4b6167; mockups chưa pixel-perfect, có sai khác Material control details/metrics/row/padding/tile ratio đã ghi. Không tick G8/GATE-08/native/Firebase/MobAI/lecturer/submission; không emulator/push/commit mới.

## Entry14 — commit và publication theo yêu cầu

Prompt người dùng nguyên văn:

> push hết lên cho tôi

Ngày21/10/2026. Ngữ cảnh: đưa checkpoint local d4b6167 và toàn bộ tài liệu bước2 hợp lệ lên branch codex/local-form-safety của repo đã chỉ định. Tools Git/shell/Python/apply_patch; không skill/subagent/Firebase/emulator. Trước publication: ls-remote chỉ có main4aeb7b719b95c0b4aa21f02bc0f05329b909cdf2; chưa có branch đích trên remote. Kiểm diff/ignore và candidate103 files/92 text files không phát hiện secret theo pattern hoặc file cấm; không scan toàn bộ history.22 Markdown links/fences/portability và93 roadmap/196 checklist IDs sạch;83 runtime hashes không đổi, không chạy lại Flutter tests/build.

Commit docs/visual handoff có kiểm soát; source checkpoint và commit docs cùng đi theo branch. Không force push, merge main, đổi visibility/collaborators hoặc publish ignored artifacts. Kết quả publication xác minh bằng remote branch SHA khớp HEAD và working tree sạch; SHA thật tra Git log/remote refs, không gán SHA baseline cho source mới. Các ghi chú chưa commit/push trong entry trước là trạng thái lịch sử. Git-only không tự thay implementation hoặc reviewed PR evidence.

## Trạng thái theo rubric

Hiện có14 prompt nguồn thực (entry12/14 Git-only, entry13 visual/docs), gồm entry implementation/verification B03–B13; cần đối chiếu chất lượng/phạm vi từng entry theo rubric trước nộp, không chỉ đếm số lượng. Các lượt tiếp theo (Firebase/rules/PDF/tests/review) ghi prompt thực và verification tại lúc thực hiện. Không chia nhỏ một prompt thành các prompt tưởng tượng để đủ số lượng.
