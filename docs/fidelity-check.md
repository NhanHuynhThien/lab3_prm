# Fidelity check — nguồn thiết kế và trạng thái

Cập nhật22/10/2026. Không coi palette giống hoặc widget tests pass là pixel fidelity/native nghiệm thu. [Design log](design-change-log.md) ghi intentional deltas; [test report](test-report.md) ghi kết quả thực.

## Nguồn Lab2

- [Figma gốc](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336).
- [flutter-handoff](https://github.com/dmm717/lab2_prm/blob/main/handoff/flutter-handoff.md); source local đã đọc tại `../lab2_prm/handoff/flutter-handoff.md`. App build không phụ thuộc sibling repo.
- BeeWise composition đã đọc từ source Mobile của user, chỉ tham khảo Login; giữ TokenLedger identity.
- Topic StudentPay→TokenLedger được giảng viên duyệt theo user21/10; acceptance fidelity vẫn riêng.

## Mapping8màn

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

Bổ sung Login/Profile/Quota/ProviderConnections, detail usage sheet, Notification Center và PDF export dialog. Runtime Google-only; không demo/reset seed. Notifications/PDF có code nhưng các luồng cloud bắt buộc chưa đủ evidence.

## Tokens và ngoại lệ

Lab2: Inter;display28/36,heading24/32,title18/26,body16/24,caption14/20;primary006C49,bgFAF8FF,text131B2E,muted52625C,mintE8F7EF;space4–32,radius20/12,target48,CTA52.

Source22/10 chủ đích tăng display32/headline26/title20 và body15,muted4C5C55; palette/spacing/radii giữ theo theme. Giá trị presentation riêng (chart bar/legend/date/logo tile/native system bars) là ngoại lệ có lý do trong code/components. Provider logo giữ màu gốc, không recolor vào brandgreen. Chưa có full hardcoded-value inventory/final token acceptance.

## Reusable components và states

| Family | Implementation/states | Kiểm tra |
|---|---|---|
| Button | Material themes filled/outlined/text/icon/segmented; SaveButton dùng chung3 form, saving spinner + label và disabled | Gallery default/pressed/disabled/loading, kích thước>=48dp và filled>=52; form tests double tap/error/retry |
| Textfield | InputDecorationTheme; default/focus/filled/error/disabled; helper/error tới12 dòng để đọc ở chữ2.0 | Gallery nhập tiếng Việt/focus, form validation tests; budget helper nhắc USD khi label dài |
| Card | Panel surface/mint, radius20, progress và rows | Gallery và cả8 màn; không tạo palette mới |
| Navigation | NavigationBar4 destinations, selected indicator; sidebar scroll khi thiếu chiều cao | Gallery đổi selected, shell/navigation regression, lazy visited tabs/Offstage giữ nguyên |
| Appbar | ContentPage/Back; title2 dòng và toolbar theo text scale; tooltip đầy đủ | Test title nằm trong bounds, ảnh chữ2.0; dirty/clean Back tests có sẵn |
| Dialog | confirmAction và DraftGuard AlertDialog; cancel/confirm | Gallery cancel ở360/412, chữ1/1.3/2; recovery/delete/Back flows kiểm confirmation thật bằng repository fixture |
| Loading | LoadingFeedback semantic label; SaveButton busy; Profile progress | Gallery có spinner thật, không pumpAndSettle vô hạn; local pending-save tests |
| Empty | EmptyFeedback title/message/optional action | Gallery, empty/missing account/session paths hiện có; không thêm dữ liệu giả |
| Error | ErrorFeedback/feedback/recovery; Retry/confirmed backup recovery, inline form/snackbar | Gallery + local repository/form/flow regression; giữ draft khi fail |

Gallery chỉ trong test, không thêm QA destination vào sản phẩm. Responsive360/412/1440 và text1/2 đã chạy với fonts; native viewport hiện~426.7dp, chưa thay ảnh cùng360×800 theo đề. Target/focus/semantics có checks, TalkBack/IME native chưa nghiệm thu đầy đủ.

## Figma evidence lịch sử21/10

Checkpointd4b6167 có annotations8originalframes, trang07handoff và trang08mockups360/412/continuations/states. Đây là evidence theo checkpoint, không phải UI22/10.

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

Brand audit đối chiếu SVG/painter/các điểm hexagon/T/mint,5 Android densities, favicon/PWA icons và maskable safe circle. Assets hiện có khớp; không sinh lại logo hoặc thêm asset runtime. Provider initials dùng grapheme, hỗ trợ emoji ghép, không trình bày là logo chính thức. Chi tiết dung sai raster/geometry ở [brand source](../assets/README.md#tokenledger-logo-source).

Verification cuối/môi trường ở test-report. Ảnh QA app mới dưới `.taste-skill/b11-b13/`, log cùng prefix; tái tạo bằng `flutter test --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true --dart-define=UI_AUDIT_OUTPUT=.taste-skill/b11-b13`. Ảnh/log local ignored; Figma links là evidence live có quyền truy cập theo file gốc. Native TalkBack/IME, MobAI/Firebase và final F11–F13/submission vẫn pending, không dùng emulator để xử lý các phần này trong lượt hiện tại.

### Các link handoff bổ sung đã lưu

- [Figma node 1](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3)
- [Figma node 2](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-108)
- [Figma node 3](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-144)
- [Figma node 4](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-183)
- [Figma node 5](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-2)
- [Figma node 6](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-218)
- [Figma node 7](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-252)
- [Figma node 8](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-286)
- [Figma node 9](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-318)
- [Figma node 10](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-33)
- [Figma node 11](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-349)
- [Figma node 12](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-36)
- [Figma node 13](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-386)
- [Figma node 14](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-40)
- [Figma node 15](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-422)
- [Figma node 16](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-461)
- [Figma node 17](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-496)
- [Figma node 18](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-530)
- [Figma node 19](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-564)
- [Figma node 20](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-595)
- [Figma node 21](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-697)
- [Figma node 22](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-71)
- [Figma node 23](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-725)
- [Figma node 24](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=240-236)
- [Figma node 25](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=240-290)

## Còn thiếu theo yêu cầu bài

- Ảnh Figma cạnh app mọi màn cùng360×800, ghi khác biệt và lý do; lặp412dp/text2/keyboard.
- Annotate/update Figma sau Google-only Login, typography, dashboard/logo/header và detailed provider analytics22/10.
- Loading/empty/error situations thật, full component/token inventory và contrast review.
- Native TalkBack/IME/reduced-motion/touch targets; reviewer/lecturer visual sign-off nếu cần.

Không gán ảnh fixture hoặc screenshot cũ cho SDK/native/current build. Link live Figma là nguồn; ảnh temp/ignored trên máy không tự thành deliverable được clone.
