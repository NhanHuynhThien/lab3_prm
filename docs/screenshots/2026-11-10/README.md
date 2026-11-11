# Ảnh màn hình mobile — 10/11/2026

Chụp thật trên emulator-5554 (Pixel 10 Pro, 1280×2856, bản profile), tài khoản Google của chủ dự án, sau khi đổi sang mô hình tự động. Số liệu là dữ liệu thật tại thời điểm chụp; Companion mới (đọc cả file log lớn, dọn dòng mồ côi) **chưa chạy** vì rules mới chưa deploy, nên tổng token Codex vẫn là số cũ (259.2M / 722 phiên).

Ảnh có email cá nhân (trang Cá nhân) — không đưa lên repo công khai.

| Ảnh | Màn |
|---|---|
| 01-tong-quan-1…4 | Tổng quan: tiêu đề + bộ lọc kỳ, thẻ Token/Phiên, tóm tắt agent, 3 card agent, Token 7 ngày, gần đây |
| 02-tai-khoan | Tài khoản (Codex CLI, Claude Code) |
| 03-chi-tiet-codex-1…2 | Chi tiết account tự động |
| 04-lich-su-tai-khoan | Lịch sử theo account |
| 05-chi-tiet-phien | Bottom sheet chi tiết phiên tự động |
| 06-sua-phien-tu-dong | Sửa phiên tự động (mục đích/tên/ghi chú) |
| 07-phan-tich-1…6 | Phân tích: kỳ, chỉ số, Gemini, theo mục đích, so sánh, Từng agent |
| 08-chon-khoang-ngay | Date range picker |
| 09-ca-nhan-1…2 | Cá nhân |
| 10-nguon-ai | Kết nối nguồn AI |
| 11-thong-bao | Trung tâm thông báo |

## Lỗi UI thấy khi soát (chưa sửa)

1. **Lịch sử (04)**: tổng vẫn ghi "$0.00 đã ghi" và "722 phiên chưa biết chi phí"; mỗi dòng có dấu "—" chi phí; nút "Kỳ ngân sách tài khoản · Đổi sang kỳ báo cáo" vô nghĩa với account tự động (không có ngân sách); tiêu đề dòng lặp tên account ở cả dòng phụ.
2. **Chi tiết phiên (05)**: hai dòng "Chi phí: Chưa biết" và "Loại chi phí: Chưa biết" thừa với phiên thuê bao.
3. **Phân tích → Từng agent (07-3…6)**: vẫn tính "30 ngày" từ snapshot (158.353.421 token, 11/10–10/11), không theo kỳ đang chọn và lặp lại phần "Theo mục đích" phía trên.
4. **Nguồn AI (10)**: thẻ Codex ghi "Token CLI · 30 ngày 158.4M" (snapshot cũ, trước khi đọc file lớn), "Phí đã charge: Chưa có nguồn", "Hạn mức · 0" — nhiều ô trống; Codex App Server không trả hạn mức.
5. **Chi tiết account (03)**: "Hạn mức đã ghi nhận: Chưa có" trong khi card agent có mục "Hạn mức hiện tại" — hai cách gọi cho cùng một thứ.
