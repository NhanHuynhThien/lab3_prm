# Design change log — TokenLedger

Cập nhật22/10/2026. Chuẩn Lab3 PDF17trang; Lab2 Figma/handoff và mapping ở [fidelity-check](fidelity-check.md). Thay đổi dưới đây có chủ đích, không tuyên bố sao chép nguyên nghiệp vụ StudentPay.

## Nền tảng giữ lại

Inter; primary#006C49,background#FAF8FF,mint#E8F7EF; radius20/12; spacing4/8/12/16/24/32; target≥48,CTA52;4mobile destinations và desktop sidebar. Material reusable controls/Panel/forms/feedback/charts dùng tokens chung. Không áp style web marketing trái design system.

## Các thay đổi chính

| Ngày | Thay đổi | Lý do / giới hạn |
|---|---|---|
|19–21/10|StudentPay→TokenLedger, token hexagon brand; expense→usage,category→9purposes,bills→accounts/quota|Topic được user xác nhận giảng viên duyệt; mapping8màn giữ tại fidelity|
|21/10|Account model/default purposes/timezone/cycle/source; multiple quota windows; data scope và history drilldown|Dữ liệu AI cần phân biệt model, kỳ, unknown và actual/manual cost|
|21/10|DraftGuard, persistent controllers/Retry, SaveButton busy,48dp controls, ActionSurface focus/semantics, chart/legend responsive|Đọc được ở text2, giữ draft và tránh duplicate writes|
|21/10|Live Figma annotations trang07 và mockups trang08 theo checkpointd4b6167|Đã có live node links, chưa đồng nghĩa pixel/native/lecturer sign-off|
|22/10|Google-only login; bỏ demo/seed/bypass runtime; fixture chuyển test|User yêu cầu dùng login chính; empty cloud được tạo dữ liệu bằng form|
|22/10|Login theo composition BeeWise Mobile thực của user: logo/welcome căn giữa,form trắng,nền mint tĩnh|Giữ identity TokenLedger/Inter/green; không copy BeeWise logo/mascot|
|22/10|Typography display32/headline26/title20/body15; muted#4C5C55|Tăng phân cấp tiêu đề/nội dung và độ rõ; thay đổi intentional so với Lab2, chưa syncFigma|
|22/10|Tổng quan căn giữa,max1040dp; dashboard agent thay duplicate account summary; summary2×2mobile/4cột rộng; cards2cột từ720dp|Overview theo dõi các agent đã có dữ liệu; sổ thủ công thu gọn|
|22/10|Logo provider chính thức bundle offline; logo và tên cùng hàng; chuông chuyển topbar cạnh lịch sử|Theo phản hồi user, hành động thông báo tách khỏi CTA ghi sử dụng; không suy endorsement|
|22/10|Analytics token theo task/purpose/model/day/input/output/cache/reasoning; time window và unknown cost rõ nhãn|Số liệu trước, phương pháp thu gọn; không suy token/cost Antigravity từ quota|
|22/10|Validation error ngay footer; detail/tinyUSD giữ6digits|Lỗi token-pair không bị dưới fold;0.001234 không thành0.00 ở detail/phân tích|
|22/10|Panel đổi Material, lazyvisitedtabs/Offstage/TickerMode, fade180ms/chart280ms, bỏ IntrinsicHeight/loop/blur|Sửa Ink/ListTile assertion và giảm layout/animation work; reduced motion giữ đúng|

Provider asset provenance tại [assets/providers](../assets/providers/README.md), Google button tại [assets/auth](../assets/auth/README.md). Custom Flutter Google button, không claim SDK-rendered hoặc đã được Google duyệt.

## Fidelity và performance còn phải nghiệm thu

Figma21/10 chưa annotate Login/theme/dashboard/provider detail22/10. Cần ảnh mọi màn cùng360×800, UI412/text2/state evidence và đo thực; giữ các difference rõ ràng. Widget screenshot không thay native. Emulator chuyển SwiftShader→host Metal120Hz; kết quả mẫu ở [test report](test-report.md), không hứa mọi frame120FPS.
