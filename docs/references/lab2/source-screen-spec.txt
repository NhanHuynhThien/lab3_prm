# Đặc tả 8 màn hình cuối

Bộ `Lab2 /` tại page `03. Final UI`, 360×800. Tên và số màn hình dùng nhất quán ở handoff.

| # | Frame | Mục đích, dữ liệu demo | Điều hướng |
|---|---|---|---|
| 01 | Home | Còn 1.250.000đ trong ngân sách 2 triệu; 3 giao dịch gần nhất | Add → 02; tabs → 04/06 |
| 02 | Add expense | Số tiền, danh mục Ăn uống mặc định, hôm nay, ghi chú tùy chọn | Category → 03; Save → loading → 01; lỗi → Retry |
| 03 | Category | Lưới 9 danh mục; chạm chọn cập nhật biến danh mục | Chọn/Xong/Back → 02 |
| 04 | Analytics | 750.000đ; donut 45/40/15%; danh sách có nhãn và số tiền | Mảng màu/dòng danh mục →05 đã lọc; Month↔Empty tháng9; CTA→02 |
| 05 | Transactions | Nhóm giao dịch tháng 10 theo danh mục, tổng và ngày | Back → 04 |
| 06 | Split bills | Mọi người nợ bạn 200.000đ; danh sách hóa đơn | Tạo → 07; hóa đơn → 08 |
| 07 | Create bill | Đi siêu thị 300.000đ; Quân, Tuấn, Linh; mỗi người 100.000đ | Confirm → loading → 08; thêm An → chia 4 |
| 08 | Bill detail | Ai đã trả/chưa trả; tiền còn cần thu; nhắc thanh toán | Back → 06; Remind → bản xem trước |

## Trạng thái ngoài 8 màn hình chính

Tám bản QA412 nằm trên page03; node IDs trong [responsive audit](figma-responsive-audit-2026-10-09.json).

Page `06. Prototype` có thêm Analytics Empty, true error overlay và form rỗng, form nhập chữ, hộp lỗi, loading/spinning, Home cập nhật số dư, lịch sử Nhà trọ/Di chuyển, nhóm 4 người và bản xem trước nhắc thanh toán. 3 starting points tương ứng 3 user flows.

## Giới hạn prototype

Nút preset mô phỏng nhập 30.000đ, `Thử nhập bằng chữ` mô phỏng giá trị `ba mươi nghìn`; Figma không nhận bàn phím nhập tự do ở bản này. Ngày, ghi chú và danh sách bạn là dữ liệu mẫu. Trong Flutter, đây phải là form thực có validation. Checkbox minh họa nhóm chọn sẵn; chưa mô phỏng mọi tổ hợp thành viên. Nhắc thanh toán chỉ mở xem trước, không gửi tin nhắn.
