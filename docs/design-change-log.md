# Design change log — TokenLedger scaffold

Ngày 19/10/2026. Nguồn baseline: StudentPay `design/DESIGN.md` và final exports09/10 trong Lab2. Người dùng cho phép đổi chủ đề/nghiệp vụ, thiết kế logo, thêm animation và dashboard quản trị. Live Figma **chưa cập nhật**, cần annotate trong bước tiếp theo.

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

Đối chiếu Figma và acceptance về đổi chủ đề với giảng viên vẫn pending. Không báo cáo các screen/flow mới là bản sao nguyên vẹn nghiệp vụ StudentPay.

## Bổ sung ngày 20/10/2026

Không thay UI ở lượt docs/push. Đã snapshot nguồn Lab2 nguyên bản vào repo để đối chiếu độc lập, thêm architecture/agent instructions và chuẩn hóa link README. Xem [nguồn UI](lab2-ui-reference.md) và manifest hashes; không coi việc copy ảnh là đã cập nhật live Figma.

## Cleanup20/10/2026

Bỏ vendor skill/tooling, inspector output, ảnh/text Lab2 copy, đề PDF và logo PNG1024 dư khỏi Git. `pubspec.yaml` bỏ assets/brand directory: UI dùng Flutter painter, launcher icons giữ trong android/web. Tài liệu chạy chuyển hoàn toàn sang Flutter CLI; không đổi layout/nghiệp vụ. Tham chiếu core Lab2 vẫn giữ trong lab2-ui-reference.md và Figma gốc.
