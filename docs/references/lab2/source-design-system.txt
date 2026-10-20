# StudentPay — Quy tắc thiết kế cuối (cập nhật 09/10/2026)

Áp dụng cho các frame `Lab2 /` và `Prototype /` trong Figma. `DESIGN.md` ở root là bản tham chiếu Stitch lịch sử; khi có khác biệt, dùng đặc tả cuối này cho bộ màn hình bổ sung.

## Variables

Hai collections: `StudentPay / Primitives` (Value), `StudentPay / Semantic` (Light). Màu semantic alias sang palette; padding, gap, radius lấy từ variables. Các tokens có WEB code syntax để bàn giao. Collection `StudentPay / Prototype` chứa các biến chuỗi `selected-category` và `saved-category` cho prototype.

| Token | Giá trị | Vai trò |
|---|---|---|
| `color/primary` | #006C49 | CTA, menu được chọn, tiền thu |
| `color/accent` | #10B981 | Màu tham chiếu; không dùng nền nút có chữ trắng |
| `color/background` | #FAF8FF | Nền màn hình |
| `color/surface` | #FFFFFF | Thẻ, ô nhập và menu |
| `color/text` | #131B2E | Chữ chính |
| `color/muted` | #52625C | Chữ phụ |
| `color/border` | #73867A | Viền input, contrast3.87:1 với trắng |
| `color/soft` | #E8F7EF | Thẻ ngân sách và phản hồi thành công |
| `color/danger` | #BA1A1A | Khoản chi, lỗi |
| `color/error` | #FFDAD6 | Nền thông báo lỗi |
| `color/purple` | #494BD6 | Nhà trọ trên biểu đồ |
| `color/amber` | #895900 | Di chuyển trên biểu đồ |
| `color/disabled` | #D3E3DC | Nút disabled / track |

Màu #4CAF50 trong tài liệu ban đầu được thay bằng #006C49 cho CTA để chữ trắng đạt 4,5:1. Giá trị đo bằng công thức nằm trong `accessibility-report.md`; chưa chạy plugin Contrast.

## Text Styles

Inter đã xác nhận trong Figma. Đã sửa tab labels14/20; audit ngày09/10 ghi min text14px trên8 final360,8 QA412 và prototype. Không áp dụng kết luận này cho các board lịch sử ngoài phạm vi.

| Style | Size / line-height | Weight |
|---|---|---|
| `StudentPay/Display` | 28 / 36 | Bold |
| `StudentPay/Heading` | 24 / 32 | Bold |
| `StudentPay/Title` | 18 / 26 | Semi Bold |
| `StudentPay/Body` | 16 / 24 | Regular |
| `StudentPay/Label` | 14 / 20 | Semi Bold |
| `StudentPay/Caption` | 14 / 20 | Regular |

## Bố cục và components

- Frame 360×800, status iOS 59px, header 56px. Màn chính: content 602px + tab bar 83px. Màn form/chi tiết: content 581px + footer 104px, gồm nút 52px và vùng thanh vuốt 34px.
- Status bar, navigation bar, tab bar, button, form input và transaction row dùng instance của bộ StudentPay gốc trên trang 05. Components. Tab bar lấy mẫu Final UI StudentPay Overview (`49:3139`), giữ 4 tab Home / Groups / Activity / You, icon và home indicator gốc. Có variant chọn Home/Groups/Activity/You. Gap content 10px; màn nhiều thành viên dùng 8px.
- Padding nội dung16px: width328 tại360,380 tại412; dùng Fill và constraints, không scale font. Master thường có baseline324px; instances final thích ứng container. Category ba cột Fill:101.33/118.67px, gap12.
- Card radius 20px; input/button 12px; màn hình 24px.
- Button 324×52, font 16/24; form field 324×80; amount 324×116, font 28/36. Header chính 24/32, header chi tiết 20/28; member row 324×60, tên và số tiền 15/22. Back 48×48; tab bar 360×83 (49px tabs + 34px safe area).
- Tab bar cuối gồm Home / Groups / Activity / You, tương ứng Tổng quan / Chia tiền / Thống kê / Thông tin cá nhân. Bottom nav 3 tab trong bộ Lab2 cũ chỉ là tham chiếu lịch sử.
- Các families `StudentPay/Lab2`: Button, Amount, Bottom nav, Transaction, Feedback, Field, Member; thêm Error dialog và Spinner.
- Không chỉ dùng màu: tiền chi có dấu −, thành công có ✓, lỗi có !, thành viên có trạng thái bằng chữ.
- Danh mục Ăn uống, ngày hiện tại được chọn sẵn cho luồng nhập nhanh.
- Dữ liệu biểu đồ demo: 750.000đ, Ăn uống 45%, Nhà trọ 40%, Di chuyển 15%.
- Prototype dùng dữ liệu có sẵn để minh họa. Flutter phải nhận dữ liệu thật, cho phép nhập tự do và cuộn khi nội dung dài/bàn phím mở.


## Elevation và component library đã áp dụng

Ba effect styles StudentPay/Elevation/0,1,2: không shadow; y2/blur8/8%; y8/blur24/18%. Level1 áp dụng summary, level2 dialog. Chín nhóm Button/Textfield/Card/Navigation/Appbar/Dialog/Loading/Empty/Error có master và showcase instances. Field set57:86 có Default/Selected/Focused/Filled/Error/Disabled. Empty master143:74 dùng thật ở Analytics144:1855, CTA→Add.

Tám bản QA412 ở page03. [Bản ghi thay đổi và IDs](figma-changes-2026-10-09.md), [responsive audit](figma-responsive-audit-2026-10-09.json), [prototype graph](figma-live-audit-2026-10-09.json). Graph xác nhận OVERLAY/CLOSE; chưa chạy Present hoặc test nội dung dài/assistive technology.
