# UI audit B08–B13 — TokenLedger

## Analytics/Remote Config và manual web checks —21/10/2026

Người dùng xác nhận toàn bộ đợt manual web1–7 đạt: account edit/budget, usage totals/purpose drilldown, unknown data, validation/Back draft, archive/restore/history guard, empty-account delete, multi-quota/bounds; trước đó đã xác nhận reload/A-B isolation và offline/Retry. Đây là user-reported web evidence, không phải Android/ARTEMIS/concurrency stress hoặc console do agent kiểm.

Đã thêm Analytics13.0.0 và RemoteConfig7.0.0, typed/noPII event allowlist, UID-serialized lifecycle/dedupe/success-only cloud mutations và tab/account/usage detail events; demo no-op. Remote Config defaults overview_recent_limit3/budget_warning_percent80, parse/clamp/cache/fallback/retry/single-flight; dashboard recent rows/warning thực thay đổi qua projections, không cắt dataset hoặc đổi tiền/token. Profile có effective values/source/check time/refresh và Analytics SDK status; Crashlytics vẫn chưa nối. Đọc [plan Analytics](analytics-plan.md) và [implementation/manual guide](analytics-remote-config.md).

Verification cuối xem test-report; không coi SDK state hoặc fake tests là DebugView/console evidence. Remote Config publish→app before-after, DebugView mỗi event, Android/ARTEMIS vẫn pending; PDF export/upload events chỉ planned. FCM/Crash/PDF và Final modules chưa làm. Không Android emulator/billing/deploy hoặc push trong lượt này. Các câu SDK Analytics/RC còn pending ở checkpoint dưới đây đã được cập nhật implementation mới; giữ history/results đúng thời điểm.


## Cập nhật yêu cầu21/10 — ưu tiên hơn checkpoint phía dưới

[Baseline Lab3 + Final](ASSIGNMENT_REQUIREMENTS.md) đã đối chiếu đủ hai PDF mới. Giảng viên chấp thuận đổi sang TokenLedger theo xác nhận trực tiếp của người dùng21/10; các câu còn chờ duyệt chủ đề phía dưới là lịch sử. Không suy thành duyệt roles Final, miễn Storage/tests hoặc nghiệm thu UI.

Auth/Firestore workspace/rules/indexes đã có tại main484cc41;299 Flutter tests/142 Rules API cases là evidence trước lượt docs, manual CRUD/A-B/native còn chờ. Đề mới yêu cầu ARTEMIS (không MobAI), AI review5 findings/3 separate fixes, report8–12p/slides12–15/video5–10m. Final cần roles/admin/shared core/cross-role/Gemini/AppCheck và Emulator tests; PDF L3 Storage khác Final device save/share. Baseline mới giữ mọi việc còn mở, không tick từ lượt docs này. Các checkpoint phía dưới chỉ có hiệu lực trong scope/time ghi tại từng mục.


## Bước2 — visual handoff P0,21/10/2026

Đã cập nhật live Figma theo source checkpoint `d4b6167`:8 màn360/412,3 phần cuộn P0,6 feedback specimens và provider/cost-basis continuation;7 local components,455 text nodes/120 instances,0 image fills.8 original annotations và8 notes trang07 đã sync. Đã xem QA412/component states Lab2, app renders360/412 và ảnh Figma sau fixes. [Visual handoff](visual-handoff-21-10.md) giữ bảng3 phía, node links, môi trường, sai khác và giới hạn. Audit local F11–F13 đã có evidence; chưa pixel-perfect/sign-off/GATE-08/native/backend/submission. Lượt này không sửa Flutter hoặc chạy lại tests/build;83 runtime hashes giữ nguyên. Không emulator/Firebase/push.

Ngày 21/10/2026. Phạm vi: ứng dụng Flutter local; Firebase pending, không chạy emulator theo yêu cầu người dùng. Audit gồm cấu trúc/component/layout/accessibility/states; B13 đã annotate live Figma21/10. Chưa nghiệm thu final fidelity F11–F13 hoặc bài nộp.

## Nguồn và giới hạn đối chiếu

Đọc [Lab2 reference](lab2-ui-reference.md), [implementation plan](IMPLEMENTATION_PLAN.md), [design log](design-change-log.md), [architecture](architecture.md), [checklist](TASK_CHECKLIST.md), roadmap và source/tests. `lib/theme/app_theme.dart` giữ implementation token hiện hành: Inter, primary #006C49, background #FAF8FF, mint #E8F7EF, card20/control12, CTA52 và target48dp.

Checkout không chứa sibling Lab2/bộ ảnh nguồn copy hoặc `.agents/skills/`; không cài vendor tooling. Ở B08–B10 đối chiếu mapping/spec local; sang B13 đã truy cập Figma gốc, xem đủ8 final360 frames, đọc metadata QA412 và annotate8 frame gốc cùng một trang handoff bổ sung. DESIGN-06 đạt annotation scope; DESIGN-01 vẫn thiếu full QA412/state/component image review, DESIGN-05 thiếu bộ mockup TokenLedger đầy đủ và F11–F13 final vẫn pending. Không suy việc annotate hoặc giữ palette thành hoàn tất pixel fidelity.

## B08 — Mapping đủ màn

| Lab2 → TokenLedger | Giữ core UI | Thích nghi nghiệp vụ và bằng chứng code |
|---|---|---|
| Home → Dashboard | Header, mint summary, metrics/progress, list icon/trailing value, 4 tab | Budget theo kỳ tự đặt; cost/token nullable, quota nhập tay. `dashboard_screen.dart`, reporting projections; không gọi budget là provider balance |
| Add expense → Usage form | Form cuộn, control12, footer CTA52 | Account/title/purpose, cặp token, USD/date/note; draft/Back/save failure. `usage_form_screen.dart` |
| Category → Purpose | Grid3 cột, icon/label, selected mint | 9 mục đích công việc; trả selection về form, giữ draft. `purpose_screen.dart` |
| Analytics → Usage analytics | Donut/legend, segmented control, drilldown | Cost/token/session từ cùng dữ liệu; missing coverage, so sánh account. `analytics_screen.dart` |
| Transactions → History/detail | Search/range, list icon + text + metric, sheet | Filter theo account/purpose, edit/delete, archive giữ lịch sử. `history_screen.dart` |
| Split bills → Accounts | Cards, metadata/progress và điều hướng chi tiết | Không chia hóa đơn; active/archive/search, budget/quota. `accounts_screen.dart` |
| Create bill → Account form | Form, input/helper/error, footer CTA | Metadata AI/budget USD, không credential/member/payment. `account_form_screen.dart` |
| Bill detail → Account detail | Header, mint summary, progress và list/actions | Quota snapshot, budget, purpose, usage history, archive/restore; chỉ xóa account rỗng. `account_detail_screen.dart` |

Màn bổ sung: Login là demo entry với Google disabled; Profile ghi rõ các dịch vụ pending và có reset/clear/leave; usage detail là sheet cuộn với edit/delete; quota form nhập snapshot/reset time. Notifications và Reports chưa có màn riêng vì FCM/PDF/cloud đang pending; Profile hiển thị trạng thái này, không tạo trang hoặc dữ liệu giả để đủ số màn.

Mobile giữ Tổng quan/Tài khoản/Phân tích/Cá nhân; desktop từ1000dp có framed-sheet/sidebar. IndexedStack giữ tab state. Android dùng SafeArea/system bars, không vẽ iPhone chrome. Đây là các thay đổi đã có chủ đích, không tuyên bố các flow StudentPay còn nguyên nghiệp vụ.

## B09 — Chín families và states

| Family | Implementation/states | Kiểm tra |
|---|---|---|
| Button | Material themes filled/outlined/text/icon/segmented; SaveButton dùng chung3 form, saving spinner + label và disabled | Gallery default/pressed/disabled/loading, kích thước>=48dp và filled>=52; form tests double tap/error/retry |
| Textfield | InputDecorationTheme; default/focus/filled/error/disabled; helper/error tới12 dòng để đọc ở chữ2.0 | Gallery nhập tiếng Việt/focus, form validation tests; budget helper nhắc USD khi label dài |
| Card | Panel surface/mint, radius20, progress và rows | Gallery và cả8 màn; không tạo palette mới |
| Navigation | NavigationBar4 destinations, selected indicator; sidebar scroll khi thiếu chiều cao | Gallery đổi selected, shell/navigation regression, IndexedStack giữ nguyên |
| Appbar | ContentPage/Back; title2 dòng và toolbar theo text scale; tooltip đầy đủ | Test title nằm trong bounds, ảnh chữ2.0; dirty/clean Back tests có sẵn |
| Dialog | confirmAction và DraftGuard AlertDialog; cancel/confirm | Gallery cancel ở360/412, chữ1/1.3/2; recovery/delete/Back flows kiểm confirmation thật bằng repository fixture |
| Loading | LoadingFeedback semantic label; SaveButton busy; Profile progress | Gallery có spinner thật, không pumpAndSettle vô hạn; local pending-save tests |
| Empty | EmptyFeedback title/message/optional action | Gallery, empty/missing account/session paths hiện có; không thêm dữ liệu giả |
| Error | ErrorFeedback/StorageRecovery; Retry/confirmed backup recovery, inline form/snackbar | Gallery + local repository/form/flow regression; giữ draft khi fail |

Gallery nằm trong `test/component_audit_test.dart`, chỉ là QA tooling, không thêm destination vào app. Tái sử dụng components/theme thật, không tạo một gallery đẹp nhưng app dùng style riêng.

## B10 — Layout, ảnh và rà thiếu

`test/ui_audit_test.dart` tải Inter/MaterialIcons thật. Ma trận4 kích thước360/412/768/1440×800 logical pixels, DPR1, text scale1/1.3/2 và2 bộ dữ liệu =24 cases, mỗi case render/cuộn12 màn (288 screen instances), mở usage detail sheet, kiểm Edit/Delete và title bounds. Insets top/bottom24dp; reduced motion bật cho ảnh ổn định. Dữ liệu stress: alias80 ký tự, work title100, note880, mỗi token bucket1 tỷ, cost/budget9,999,999.999999USD, quota window dài. Form sửa dùng giá trị stress thật, không chỉ render form trống.

6 cases keyboard/SafeArea chạy3 form tại360/412×800, chữ1/1.3/2, bottom inset300dp. Cuộn tới field cuối bằng key ổn định, focus EditableText; xác minh field tương tác được, CTA cao>=52, hit-test được và nằm trên bàn phím. Đây là simulated insets qua Flutter test engine, chưa phải Android keyboard/device evidence.

Các thiếu sót phát hiện và đã sửa:

- Bar chart overflow ở chữ2.0: đo label theo font/text scaler, giữ chiều cao plot, cuộn ngang khi thiếu rộng và có chỉ dẫn; dùng ngày lịch local cho label. Zero vẫn không có cột giả.
- Sidebar desktop overflow ở chữ1.3/2: cho cuộn khi chiều cao không đủ, giữ footer cuối sidebar và navigation.
- Legend có tiền lớn tràn ngang: AdaptivePair chuyển dọc khi thiếu không gian, trailing values Wrap. UsageRow dùng cùng cách để không ép mất phần title/metadata.
- Tổng donut quá dài/chữ lớn: chuyển caption xuống dưới vòng; không thu nhỏ text scaler hoặc cắt tổng.
- Appbar title bị cắt tại chữ2.0 dù không báo RenderFlex: tăng toolbar theo scaler, title tối đa2 dòng/tooltip; thêm assertion bounds để bắt regression.
- Helper/error giới hạn3 dòng có thể cắt hướng dẫn ở chữ2.0: mở lên12 dòng, nội dung form cuộn. Budget helper ghi USD rõ ràng.
- Nút text/icon/segmented trước đây dựa vào default Material kích thước nhỏ: theme đặt min48; SaveButton chung đảm bảo label/loading nhất quán và CTA52. Account list dùng lại budgetProgress projection thay tính lại trong widget.

Title dài trong list vẫn tối đa2 dòng/ellipsis và mở sheet để đọc đủ. Alias dropdown có ellipsis theo quyết định DC15; ô nhập một dòng cuộn ngang theo Material. Không tắt scaling toàn ứng dụng hoặc dùng FittedBox để che lỗi. Full screen-reader/contrast/focus-order/reduced-motion audit thuộc B11, full loading/empty/error flow audit thuộc B12.

Ảnh QA và logs nằm local trong `.taste-skill/b08-b10/` cùng các `.taste-skill/b08-b10-*.log`, được gitignore. Có ảnh12 màn ở360/412/1440 và stress360 chữ2.0, component gallery360/412. Lệnh tái tạo: `flutter test --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true`. Không bundle/commit ảnh QA. Đây là ảnh Flutter engine render; không gọi là Chrome/CanvasKit, live Figma hoặc Android screenshots.

Kết quả kiểm tra cuối và môi trường xem [test report](test-report.md). B08–B10 đạt phạm vi audit local đã nêu; các khoảng trống nguồn Lab2 gốc/Figma/native/final fidelity được giữ rõ, không tick thay gate tích hợp hoặc bài nộp.


## B11 — Accessibility và motion,21/10/2026

ActionSurface dùng chung cho UsageRow, QuotaRow có action, analytics legend/comparison, purpose tiles và sidebar. Mỗi action có semantics button/selected, target>=48dp, hỗ trợ Tab/Enter và viền focus primary2dp; rows chỉ trình bày khi không có onTap không bị gọi là nút. IconButton giữ tooltip; provider avatar có label phân biệt initials với logo. Outline buttons dùng border#73867A thay structural line để đủ contrast; RangePicker dùng label semibold giúp legibility và pixel contrast guideline. Không đổi primary/palette/type/radius Lab2.

Unit contrast kiểm text/muted/primary/danger trên surface/background/mint/neutral và trắng trên primary >=4.5:1; input/outline border với white>=3:1. Flutter androidTapTargetGuideline, labeledTapTargetGuideline và textContrastGuideline pass trên Purpose cùng4 tab Shell ở360/412×800 với font thật. Đây là các viewport được render, không tuyên bố mọi màn/state đã được screen reader trên Android duyệt. Disabled controls miễn contrast cho disabled state; chart pale colors là phụ trợ, không phải nguồn thông tin duy nhất.

Chart có một semantic summary chứa từng ngày/năm, USD và giá trị; progress/counter đọc giá trị cuối một lần, không đọc lặp các frame trung gian. Quota thiếu/quá reset và budget chưa đặt có semantic value trạng thái riêng, không bị đọc thành measured0%. Donut có total + legend bằng chữ và không đọc caption lặp. Focus traversal theo cấu trúc/ReadingOrder Material; dialog giữ focus trong modal. Tests có Tab/Enter vào action row, selected state và focus outline, không dùng DOM/h1 giả.

System disableAnimations: AppMotion zero-duration cho chart/progress/counter; MotionAwareTransitions bypass visual route transition; dialog/DraftGuard/sheet dùng AnimationStyle.noAnimation. Loading/save/Profile busy dùng indicator tĩnh kèm status khi reduced motion, vẫn mô tả đang xử lý. Shell chặn fade ngay nếu setting đổi giữa animation. Tests giữ cùng IndexedStack, scroll300dp, account search và analytics Token selection khi đổi tab/setting. DraftGuard ExcludeFocus cùng AbsorbPointer chặn keyboard và pointer khi saving. Không thêm loop trang trí.

## B12 — States, Retry và destructive actions

| Nhánh | Hành vi cuối / evidence |
|---|---|
| Cold loading/init error | Usage có thể mở trước load; không requireValue trong initState. LoadingFeedback → lỗi → Retry → form thật, không seed đè lỗi |
| Reload lỗi trên route | ledgerFeedback dùng chung cho dashboard/accounts/analytics/history/detail và3 forms; bao gồm sheet. Forms giữ controllers/ID/DraftGuard, Accounts/History giữ search controller khi Retry |
| Empty / not-found | Empty feedback cuộn ở text lớn; account/detail/edit/quota thiếu account không có CTA Save; usage đã xóa có not-found riêng, không resurrect record. Empty usage mở Account form; Google entry disabled thật |
| Reset / clear | Profile xác nhận đúng hậu quả không thể hoàn tác; guard từ lúc mở confirmation, error không publish success, Leave disabled khi xử lý. Tests cancel/fail/retry/pending/clear/reset tại360/412 |
| Delete / archive / restore | ConfirmedActionButton guard một dialog/write, thông điệp archive giữ history/chặn new usage, delete không thể hoàn tác/tính lại tổng. Fail giữ màn/data và cho retry; dispose owner không gọi mutation sau confirmation |
| Draft protection |3 forms giữ draft khi save/reload error; dirty Back ở error vẫn hỏi tiếp tục/bỏ. Save pending khóa focus/pointer/Back. Existing failure/retry/UUID/archived tests tiếp tục pass |

StateRepository trong tests chỉ là fixture lỗi/delay có kiểm soát, không phải fault-injection UI hoặc backend mới. Chưa tạo network/auth/FCM/PDF states giả. Full repository typed errors/raw backup và local recovery vẫn giữ từ B03–B07.

## B13 — Live Figma và brand

Đã dùng skill figma-use của plugin Figma cài local để gọi Figma Plugin API; nguồn skill cụ thể nằm trong plugin Figma của môi trường (xem AI log). Không dùng subagent. Đã xem8 ảnh final360 từ live file và giữ toàn bộ original visuals; chỉ thêm annotation metadata vào8 frames, không đổi text/geometry của StudentPay.

| Mapping | Frame Lab2 đã annotate | Ghi chú implementation |
|---|---|---|
| Home → Dashboard | [59:2](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-2) | [233:6](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-6) |
| Add expense → Usage | [59:49](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-49) | [233:9](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-9) |
| Category → Purpose | [59:78](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-78) | [233:12](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-12) |
| Analytics | [59:121](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-121) | [233:15](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-15) |
| Transactions → History | [59:160](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-160) | [233:18](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-18) |
| Split bills → Accounts | [59:202](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-202) | [233:21](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-21) |
| Create bill → Account form | [59:236](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-236) | [233:24](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-24) |
| Bill detail → Account detail | [59:279](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=59-279) | [233:27](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-27) |

[Trang 07. TokenLedger · Lab3 annotations](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3), page233:2/board233:3, có16 cards. Ngoài8 conversions còn Login233:30/Profile233:33/Usage sheet233:36/Quota233:39, Notifications233:42 và Reports233:45 ghi rõ pending, accessibility/motion/brand233:48 và giới hạn233:51. Đã xem screenshot board840×2402, text/auto-layout không bị cắt. Đây là annotations/handoff notes, không phải bộ mockup8 màn mới hoặc final fidelity được duyệt.

Brand audit đối chiếu SVG/painter/các điểm hexagon/T/mint,5 Android densities, favicon/PWA icons và maskable safe circle. Assets hiện có khớp; không sinh lại logo hoặc thêm asset runtime. Provider initials dùng grapheme, hỗ trợ emoji ghép, không trình bày là logo chính thức. Chi tiết dung sai raster/geometry ở [brand source](../assets/brand/README.md).

Verification cuối/môi trường ở test-report. Ảnh QA app mới dưới `.taste-skill/b11-b13/`, log cùng prefix; tái tạo bằng `flutter test --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true --dart-define=UI_AUDIT_OUTPUT=.taste-skill/b11-b13`. Ảnh/log local ignored; Figma links là evidence live có quyền truy cập theo file gốc. Native TalkBack/IME, MobAI/Firebase và final F11–F13/submission vẫn pending, không dùng emulator để xử lý các phần này trong lượt hiện tại.

## Delta UI sau A04 —21/10/2026

Đã mở rộng components theo DC29–DC32: model/default purpose chips/cycle/timezone, multi-window quota details, DataScopePicker/settings, provider/cost breakdown, day headings và donut sector. Form vẫn có draft/Retry, CTA/keyboard/focus giữ theo gallery cũ. Không có vendor UI skill local; không cài lại hoặc đổi Lab2 palette/type/radius. Figma B13 chưa cập nhật cho field mới; final fidelity vẫn pending. Kiểm Flutter render/matrix thực cuối ghi trong test-report.md và local-p0-upgrade.md, không dùng ảnh làm native evidence.

Final upgrade checks: full200 tests pass140s, analyzer/format sạch, web JS build57.7s; source33 lib/14 test files. Full199 trước case default-account/source có ảnh Flutter đã xem tại analytics360/account-detail412/history360/dashboard1440 và account-form360 scale2; lỗi glyph arrow đã đổi sang Material icon. Full200 giữ cùng UI matrix, không xuất ảnh lặp. Các ảnh/log local ignored, chưa có kiểm browser/native hoặc đồng bộ Figma cho field mới.

## Delta Auth C01–C03 —21/10

[Auth setup](firebase-auth-setup.md): Login Google thật qua SDK, busy/errors/Retry; root AuthGate và Profile identity/HTTPS avatar tách local sandbox. UI360/412/1440 text1/2 và full239 tests pass; đã xem ảnh login360/profile360/profile412 dùng fixture. Giữ core Lab2/4-tab demo; Figma chưa sync Login/Profile sau Auth, không dùng page08 trước Auth để claim fidelity mới. Không có live OAuth/Android screenshot mới.
