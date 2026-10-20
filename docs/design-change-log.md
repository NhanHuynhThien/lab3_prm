# Design change log — TokenLedger scaffold

Ngày 19/10/2026. Nguồn baseline: StudentPay `design/DESIGN.md` và final exports09/10 trong Lab2. Người dùng cho phép đổi chủ đề/nghiệp vụ, thiết kế logo, thêm animation và dashboard quản trị. Đây là ghi nhận lúc scaffold19/10. Hiện trạng21/10: live Figma đã annotate8 final360 và board233:3, xem mục B11–B13 cuối file; full QA412/mockup/fidelity và lecturer acceptance vẫn pending.

| ID | Thay đổi thực hiện | Lý do / kế thừa | Trạng thái |
|---|---|---|---|
| DC01 | StudentPay → TokenLedger, logo token hexagon + T/L | Chủ đề quản lý AI; giữ primary emerald và Inter | Code/SVG/PNG/icons có sẵn |
| DC02 | Expense → usage; category → purpose9 ô | Ghi AI dùng cho công việc gì, input/output/cost nullable | Form thật + validation local |
| DC03 | Bills/list/create/detail → AI accounts | Bỏ chia tiền, thêm account/budget/quota/archive | Local CRUD thật |
| DC04 | Home → dashboard usage/cost/quota/purpose | Mint summary card, progress và rows từ Lab2 | Responsive360/412/768/1440 |
| DC05 | Groups → Tài khoản, Activity → Phân tích, You → Cá nhân | Giữ4 destinations/thứ tự/vai trò navigation | Mobile bottom nav; desktop sidebar |
| DC06 | Analytics donut + legend + drilldown | Dữ liệu tính từ sessions; cost/token/session modes | Local data, không số tổng hard-code |
| DC07 | Login dùng demo entry; Google disabled/pending | Firebase được người dùng hoãn | Không giả Google login |
| DC08 | Profile có trạng thái pending/reset local | Kiểm soát dataset demo và biết backend chưa kết nối | Có confirmation khi reset/clear |
| DC09 | Android SafeArea thay iOS status bar/Dynamic Island | Đúng platform yêu cầu Lab3 | Android config sinh; device test pending |
| DC10 | Dashboard desktop framed-sheet | Yêu cầu nâng cấp dashboard; style framed-sheet, seed1978369971 (tooling local) | Giữ palette/type/core components Lab2 |
| DC11 | Motion chart/progress/counter/tab/route/sheet | Phản hồi thay đổi số liệu và navigation | AppMotion + system reduced-motion |
| DC12 | Helper/error text cho phép nhiều dòng | Đã thấy helperText bị cắt trên preview mobile | Sửa trong theme |

Các ngoại lệ so với style taste-skill: giữ Inter, primary button emerald, card radius20/control12, lavender ground và mint summary vì Lab2 là nguồn thiết kế bắt buộc. Dùng Material icons và accessibility target48dp theo core Lab2. Không đổi sang marketing page/dark dashboard. Sidebar/topbar chỉ bổ sung trên desktop; không phải role-based admin hay backend quản trị đa user.

Full fidelity Figma và acceptance về đổi chủ đề với giảng viên vẫn pending; annotation B13 đã có. Không báo cáo các screen/flow mới là bản sao nguyên vẹn nghiệp vụ StudentPay.

## Lịch sử snapshot ngày 20/10/2026 — đã cleanup sau đó

Không thay UI ở lượt docs/push. Đã snapshot nguồn Lab2 nguyên bản vào repo để đối chiếu độc lập, thêm architecture/agent instructions và chuẩn hóa link README. Bản copy và manifest hashes đã được cleanup khỏi Git, hiện xem [nguồn UI](lab2-ui-reference.md); không coi việc copy ảnh là đã cập nhật live Figma.

## Cleanup20/10/2026

Bỏ vendor skill/tooling, inspector output, ảnh/text Lab2 copy, đề PDF và logo PNG1024 dư khỏi Git. `pubspec.yaml` bỏ assets/brand directory: UI dùng Flutter painter, launcher icons giữ trong android/web. Tài liệu chạy chuyển hoàn toàn sang Flutter CLI; không đổi layout/nghiệp vụ. Tham chiếu core Lab2 vẫn giữ trong lab2-ui-reference.md và Figma gốc.

## Local form polish — 21/10/2026

- DC13: Account/usage/quota form có `DraftGuard`: Back khi có thay đổi cho tiếp tục sửa/bỏ; form sạch thoát ngay; đang lưu chặn Back/interactions. Giữ palette/type/radius Lab2.
- DC14: ContentPage đưa CTA lên trên keyboard inset. Dropdown account provider/billing và usage account co theo chiều rộng; sửa overflow billing tại360dp. Tests360/412×800dp, text scale1/2, keyboard300dp.
- DC15: Account archived vẫn cho sửa usage lịch sử với accountId khóa; chặn usage mới. Dropdown giữ account archived hiện tại và có giải thích; alias dài hiển thị ellipsis.
- Save fail có snackbar nhìn thấy được cùng inline error; draft và operation ID giữ để retry. Account mới có ID ổn định như usage.
- Bộ taste-skill local trước đây không còn trong checkout ở lượt này; dùng Lab2 reference và theme hiện có làm baseline, không cài lại hoặc sửa vendor. Live Figma chưa thao tác; full fidelity/native accessibility chưa được suy ra từ widget tests.

## B03–B07 —21/10/2026

- DC16: Error local có Retry và nút khôi phục với confirmation/sao lưu raw trước replace; dùng ErrorFeedback/OutlinedButton/Dialog và tokens Lab2 có sẵn. Đã kiểm widget flows360/412 và xem ảnh render hai viewport với font thật; browser automation không có trong phiên.
- DC17: Detail sheet hiện Sửa phiên cho account archived; form vẫn khóa accountId, account detail không mở CTA new usage khi archived. History edit/delete/restore test đủ360/412.
- DC18: Quota chưa có snapshot để trống percent thay vì mặc định0; validation Unicode và dates dùng chung; UTC timestamp hiển thị theo ngày/giờ local. Không đổi palette/font/layout/navigation hoặc giảm motion accessibility.
- Live Figma chưa thao tác. Không claim native/browser fidelity từ widget render; emulator bị bỏ qua theo yêu cầu người dùng.

## B08–B10 —21/10/2026

- DC19: UsageBarChart đo label theo Inter/text scaler, tăng phần dành cho chữ và cuộn ngang khi thiếu rộng, có chỉ dẫn; giữ plot/giá trị và cột zero đúng dữ liệu. Donut caption chuyển xuống dưới vòng khi tổng/chữ không vừa lòng vòng. Không giảm text scaling.
- DC20: AdaptivePair dùng chung legend/UsageRow: xếp dọc khi thiếu không gian, trailing Wrap cho số liệu lớn; normal mobile vẫn giữ row icon/text/trailing. Sidebar desktop cho cuộn khi chữ lớn/viewport thấp, giữ IndexedStack và4 destinations.
- DC21: SaveButton dùng chung3 form với disabled/loading spinner+label. Text/icon/segmented buttons có min48dp, CTA52 giữ nguyên. LoadingFeedback có label. Gallery9 families chỉ nằm trong tests, không thêm trang QA vào sản phẩm.
- DC22: ContentPage AppBar title tối đa2 dòng/tooltip và toolbar theo text scale có4dp khoảng thở; sửa clipping quan sát được ở chữ2.0 và font rounding1.3. Helper/error tới12 dòng thay vì3; budget helper nhắc USD. Các field cuối có key để kiểm focus/scroll ổn định.
- Giữ toàn bộ palette/Inter/card20/control12 của Lab2, framed-sheet direction và AppMotion. Không có skill UI local trong checkout, không cài/sửa vendor. Source Lab2 gốc/live Figma chưa được xem/cập nhật trong lượt này; audit theo mapping/spec lưu trong repo và ảnh Flutter thật. [Fidelity draft](fidelity-check.md) ghi đủ8 màn,9 families, ma trận layout và giới hạn.


## B11–B13 —21/10/2026

- DC23: ActionSurface dùng chung cho data rows/purpose/sidebar: button/selected semantics, min48, Tab/Enter và focus outline primary2dp. ProviderAvatar dùng grapheme/semantic label initials, không phải logo provider; chart/date/USD/progress/counter/donut có lời đọc cuối không lặp.
- DC24: Outline button dùng border#73867A thay line nhạt; RangePicker dùng label semibold để đạt contrast guideline. Giữ nguyên palette/Inter/radius/token Lab2, không áp palette/font từ skill Figma thay nguồn thiết kế.
- DC25: disableAnimations bypass route visuals, dialog/DraftGuard/sheet zero style; busy indicators tĩnh với label và không công bố phần trăm giả. Shell dừng fade ngay khi setting đổi, giữ IndexedStack/filter/scroll; DraftGuard khóa cả focus lẫn pointer khi saving. Motion enabled giữ Android FadeForwards và iOS/macOS Zoom delegate.
- DC26: ledgerFeedback bảo vệ loading/error/Retry trên routes/forms/sheet; cold usage không đọc requireValue trước load. Search controllers/draft/ID/dirty Back giữ khi reload lỗi. Empty feedback cuộn; not-found account/session không có Save. ConfirmedActionButton/Profile guard từ lúc hỏi xác nhận, lỗi giữ data và retry, Leave disabled khi busy.
- DC27: Đã dùng skill figma-use của plugin Figma, xem8 final360 và annotate original nodes59:2/49/78/121/160/202/236/279 (metadata, không thay geometry/text source). Tạo [trang07 annotations](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3) board840×2402,16 cards:8 conversions + Login/Profile/Usage sheet/Quota + Notifications/Reports pending +2 summaries. Đã xem screenshot, auto-layout/text không cắt; từng node ở fidelity-check. Đây là annotation/handoff, không phải8 mockup mới hay final submission approval.
- DC28: Audit SVG/painter/5 Android icon densities/PWA/favicon/maskable và app labels đã khớp; không cần regenerate assets. Brand tests có dung sai raster antialias và maskable safe circle; không claim pixel-identical hoặc logo provider.
- Skill áp dụng figma-use chỉ hướng dẫn Figma API, không yêu cầu thay design direction; giữ framed-sheet/Inter/palette/radius Lab2, không cài vendor UI tooling vào repo. Native/MobAI/Firebase/final fidelity còn pending; không chạy emulator theo user.

B11 rà cuối: progress quota chưa biết/quá reset và budget chưa đặt đọc trạng thái riêng thay vì0%; không sửa giá trị tài chính/quota hoặc vẽ lại assets. Thêm regression semantics cho nhánh unknown/stale.

## P0 local sau A04 —21/10/2026

- DC29: Account/usage mở rộng model và default-purpose FilterChips; account có timezone/cycle, cost basis có lựa chọn và giải thích nhập tay/chưa phân loại. Giữ Material form/Inter/palette/radius/CTA52; không redesign nguồn Lab2.
- DC30: Account detail liệt kê các quota windows độc lập với source/note/quan sát/reset/sửa/xóa có confirmation; dashboard chỉ preview window đầu và báo còn window khác, không cộng%.
- DC31: DataScopePicker + múi giờ báo cáo ở các màn dữ liệu, settings có draft/Retry; ngày row/header/detail nhất quán. Budget nhãn Kỳ hiện tại và detail ghi khoảng ngày exclusive; lịch sử từ account dùng cycle đó, đổi được sang kỳ báo cáo.
- DC32: Analytics thêm provider group/drilldown và cost-basis breakdown, adaptive initial metric; donut sector hỗ trợ tap với legend accessible48dp làm thao tác tương đương. History thêm day headings và source/model/basis trong detail. Giữ IndexedStack/AppMotion/reduced motion.
- Lượt này không sửa live Figma; annotation B13 là baseline trước field mới. Cần đồng bộ mockups/annotations ở final fidelity, không đánh DESIGN-05/F11–F13 done. Kiểm ma trận Flutter và ảnh mới ghi ở test-report/fidelity-check; không claim browser/native/MobAI.

## DC33–DC35 — bước2 visual handoff21/10

- DC33: Live Figma page237:2,8 core mockups360/412 và3 continuations cho model/purpose chips/cycle/timezone/usage/quota. Giữ tokens/Inter/geometry nguồn; tái sử dụng Button44:1648 và7 local components, thêm chartTertiary variable đúng source. Không đổi original Lab2 screen visuals hoặc Flutter runtime.
- DC34:6 loading/empty/error specimens, storage/draft/quota/source notes, nav/input/busy examples và provider/cost-basis continuation. Đã xem screenshot và sửa layout rows/sourcepicker/donut/legend/filter/chips/order/disabled palette/stroke overflow; Inter + Material Icons,0 flattened UI image fills.
- DC35:8 original annotations +8 notes trang07 sync P0, gắn checkpoint d4b6167. Bảng3 phía và node links tại [visual handoff](visual-handoff-21-10.md); QA412/state/component sources và app360/412 đã xem. Audit local F11–F13 không đồng nghĩa pixel-perfect/native/lecturer sign-off. Firebase/MobAI/GATE-08 pending, không emulator/push.
