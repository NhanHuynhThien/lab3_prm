# Flutter handoff — StudentPay

Đặc tả triển khai tương lai cho 8 màn hình `Lab2 /` 360×800. Tham chiếu thiết kế cuối ở `design/DESIGN.md`, screen IDs trong `design/figma-responsive-audit-2026-10-09.json`. Repo chưa có mã ứng dụng Flutter. Các hành vi nhập tự do, dữ liệu thật và gửi nhắc thanh toán dưới đây là yêu cầu triển khai, không phải tính năng đã chạy trong prototype.

## Quy tắc chung

- Tiếng Việt, tiền VND dạng số nguyên. Từ chối trống, chữ, số âm, 0 và kiểm tra cả paste. Lưu integer, format dấu chấm khi hiển thị.
- Tab bar cuối: Home = Tổng quan, Groups = Chia tiền, Activity = Thống kê, You = Thông tin cá nhân. You là trang phụ, không tính vào 8 màn hình chính.
- Status/header/footer cố định, chỉ content cuộn. Dùng SafeArea và cuộn khi bàn phím mở. Đã có8UI360 và8 QA412 trên Figma, content328/380; ảnh trong assets/figma/2026-10-09. Chưa kiểm tra bàn phím hoặc dữ liệu dài trong Present.
- Nội dung ≥14sp, vùng chạm ≥48×48dp. Label tab đã sửa14/20; audit phạm vi final/prototype ghi min text14. Board lịch sử ngoài phạm vi không được coi đã sửa.
- Ngân sách 2.000.000đ, trước/sau khoản chi 30.000đ: 1.250.000đ / 1.220.000đ. Các flow dùng dữ liệu mẫu độc lập.
- Chia 300.000đ cho 3 người gồm người trả trước: 100.000đ/người; 4 người: 75.000đ/người. Số không chia hết: phân phối phần dư 1đ theo thứ tự thành viên ổn định.

## Ánh xạ token sang Flutter

| Token/style cuối | Giá trị | Flutter dự kiến |
|---|---|---|
| `color/primary` | #006C49 | ColorScheme.primary |
| `color/danger` | #BA1A1A | ColorScheme.error |
| `color/background` | #FAF8FF | Scaffold background |
| `color/surface` | #FFFFFF | ColorScheme.surface |
| `color/text` | #131B2E | ColorScheme.onSurface |
| `color/muted` | #52625C | ThemeExtension cho text phụ |
| `StudentPay/Display` | Inter 28/36, Bold | displaySmall, fontSize 28, height 36/28 |
| `StudentPay/Heading` | Inter 24/32, Bold | headlineSmall, fontSize 24, height 32/24 |
| `StudentPay/Title` | Inter 18/26, Semi Bold | titleLarge, fontSize 18, height 26/18 |
| `StudentPay/Body` | Inter 16/24 | bodyLarge, fontSize 16, height 1.5 |
| `StudentPay/Label`, `Caption` | Inter 14/20 | labelLarge/bodySmall, fontSize 14 |
| `spacing/4,8,12,16,24,32` | 4/8/12/16/24/32px | EdgeInsets / SizedBox tương ứng |
| `radius/12`, `radius/20` | 12px, 20px | BorderRadius.circular(12/20) |
| `size/touch-target` | 48px | BoxConstraints(minWidth:48, minHeight:48) |
| StudentPay/Elevation/0 | Không shadow | Không BoxShadow |
| StudentPay/Elevation/1 | y2/blur8/alpha0.08 | BoxShadow(offset0/2,blurRadius8,color alpha0.08) |
| StudentPay/Elevation/2 | y8/blur24/alpha0.18 | BoxShadow(offset0/8,blurRadius24,color alpha0.18) |

Ba effect styles đã áp dụng trên Figma09/10; đây vẫn là mapping Flutter dự kiến.

## Ánh xạ component sang widget

| Thành phần thiết kế | Widget Flutter dự kiến | States/ghi chú |
|---|---|---|
| Primary button | FilledButton | Default, Pressed, Disabled, Loading |
| Amount / Field | TextFormField | Default, Filled, Error, Disabled |
| Budget/bill card | Card hoặc Container | Populated, Empty khi phù hợp |
| Tab bar 4 tab | NavigationBar hoặc CupertinoTabBar tùy platform | Home, Groups, Activity, You selected |
| Header / Back | AppBar, IconButton | Target tối thiểu 48×48 |
| Error dialog | AlertDialog, showDialog | Error, Retry, đóng và giữ dữ liệu |
| Spinner | CircularProgressIndicator | Loading, timeout/error |
| Empty feedback | Text + nút thêm dữ liệu | Hướng dẫn hành động tiếp theo |
| Error feedback | Icon + Text + Retry | Không chỉ dùng màu |
| Member row | CheckboxListTile/ListTile | Selected, paid/unpaid |
| Transaction row | ListTile | Dấu +/−, ngày, danh mục và số tiền |

Bảng này là mapping triển khai. Sự hiện diện của đủ 9 nhóm component master và states trong thư viện Figma cần đối chiếu theo checklist trực tiếp, không suy ra chỉ từ bảng.

## Màn hình 01 — Home

1. **Layout:** Status/header trên, content cuộn với padding 16dp, tab bar 4 mục ở dưới. Thẻ ngân sách, tiến độ, 3 giao dịch và nút Thêm chi tiêu rộng vùng content.
2. **Components:** Budget card, progress indicator, transaction rows, primary button, header, tab bar.
3. **States:** Populated; sau lưu số dư 1.220.000đ và xác nhận. Empty/loading/error dữ liệu là yêu cầu cho ứng dụng tương lai.
4. **Interactions:** Thêm chi tiêu mở form rỗng. Trong prototype chọn preset 30.000đ; không nhập bằng bàn phím thật.
5. **Navigation:** Add tới 02; Groups tới 06; Activity tới 04; You tới thông tin cá nhân. Back hệ thống theo quy tắc platform.
6. **UI constraints:** Display 28/36, button 52dp; giữ footer cố định, không cắt số tiền quan trọng. Kiểm tra 360/412dp trước khi chốt layout.

## Màn hình 02 — Add expense

1. **Layout:** Header có một Back, content cuộn, amount, category, date, note và vùng nút lưu cố định dưới.
2. **Components:** Amount input, field, category row, primary button, Back.
3. **States:** Empty, Filled 30.000đ, Invalid chữ/trống, Saving, Error và Retry.
4. **Interactions:** Category mặc định Ăn uống, ngày mặc định hôm nay. Preset và nút thử nhập chữ mô phỏng kịch bản. Ứng dụng thật dùng TextFormField với numeric validation, không nhận số thập phân cho VND.
5. **Navigation:** Category tới 03; Back về 01; Lưu hợp lệ qua loading tới Home đã cập nhật; lỗi cho phép nhập lại.
6. **UI constraints:** Button 52dp, target ≥48dp; bàn phím không che lưu/lỗi. Save empty/invalid hiện dùng OVERLAY; Retry vàscrim CLOSE vềform gốc. Đã kiểm tra graph, chưa chạyPresent.

## Màn hình 03 — Category

1. **Layout:** Header/Back, lưới 3 cột gồm 9 danh mục và vùng Xong khi cần.
2. **Components:** Category tile có icon và nhãn, selected state, Back.
3. **States:** Populated, Selected. Empty danh mục tùy chỉnh là yêu cầu triển khai tương lai.
4. **Interactions:** Chọn danh mục cập nhật selected-category và trở về form. Chọn bằng cả icon/label.
5. **Navigation:** Từ 02; Chọn/Xong/Back về 02. Back không làm mất số tiền đã nhập.
6. **UI constraints:** Tile ≥100px trong thiết kế gốc. Cho phép nhãn xuống dòng, kiểm tra grid ở 412dp và text scaling.

## Màn hình 04 — Analytics

1. **Layout:** Header, content cuộn, tổng 750.000đ, donut và danh sách tỷ trọng, tab bar cố định.
2. **Components:** Donut, category summary rows, header, tab bar.
3. **States:** Populated tháng10; Empty tháng9 có component và CTA→Add. Loading entrance trước dữ liệu; lỗi tải là yêu cầu ứng dụng thật.
4. **Interactions:** Chọn Month đổi tháng10/tháng9; Empty CTA mở Add. Chạm mảng biểu đồ hoặc dòng danh mục dẫn tới lịch sử đã lọc. Dữ liệu demo: 45% Ăn uống, 40% Nhà trọ, 15% Di chuyển.
5. **Navigation:** Activity từ 01/06; danh mục tới 05; Groups/Home tới tab tương ứng.
6. **UI constraints:** Luôn có nhãn và số tiền ngoài màu chart. Giữ danh sách dễ tiếp cận, dùng Semantics trong ứng dụng thật.

## Màn hình 05 — Transactions

1. **Layout:** Header/Back, tổng danh mục, filter tháng/danh mục và list cuộn nhóm theo ngày.
2. **Components:** Transaction rows, filter, header, Back.
3. **States:** Populated Ăn uống/Nhà trọ/Di chuyển; Empty/Loading/Error là yêu cầu triển khai tương lai.
4. **Interactions:** Cuộn danh sách. Filter trong ứng dụng thật cập nhật truy vấn; prototype dùng các frame danh mục đã dựng.
5. **Navigation:** Từ 04 sau chọn danh mục; Back về 04.
6. **UI constraints:** Giữ dấu +/− và format VND, tên dài xuống dòng hoặc ellipsis có semantic label đầy đủ. Không để giá trị tiền tràn.

## Màn hình 06 — Split bills

1. **Layout:** Header, summary mọi người nợ bạn 200.000đ, list hóa đơn và nút tạo, tab bar cố định.
2. **Components:** Summary/bill cards, create button, header, tab bar.
3. **States:** Populated. Empty/loading/error khi chưa có hóa đơn hoặc tải thất bại là yêu cầu tương lai.
4. **Interactions:** Tạo mới mở 07; chọn hóa đơn mở 08 tương ứng.
5. **Navigation:** Groups từ 01/04; Tạo tới 07; hóa đơn tới 08; Home/Activity tới tab tương ứng.
6. **UI constraints:** Tên và trạng thái nợ bằng chữ. Button 52dp. Không mô tả FAB tự ẩn nếu bản final dùng nút thường.

## Màn hình 07 — Create bill

1. **Layout:** Header/Back, content cuộn: tên hóa đơn, tổng tiền, người trả trước, danh sách thành viên và nút xác nhận ở dưới.
2. **Components:** Fields, member rows, Add friend, primary button, Back.
3. **States:** Nhóm 3 người, nhóm 4 người, Saving. Validation/error cho dữ liệu tự nhập là yêu cầu ứng dụng thật.
4. **Interactions:** Demo 300.000đ cho Quân, Tuấn, Linh; Thêm bạn mới mô phỏng An. Ứng dụng thật cho chọn thành viên và chia lại, kiểm tra tổng >0 và có thành viên hợp lệ.
5. **Navigation:** Từ 06; Back về 06; thêm bạn rồi quay lại form; xác nhận qua loading tới 08 cho đúng nhóm.
6. **UI constraints:** Chạm toàn dòng chọn thành viên, target ≥48dp. Tổng phần chia phải bằng tổng hóa đơn; scroll khi bàn phím mở.

## Màn hình 08 — Bill detail

1. **Layout:** Header/Back, tổng hóa đơn, tiến độ, thành viên với trạng thái trả tiền và nút nhắc thanh toán.
2. **Components:** Summary card, member rows, status text, reminder button, Back.
3. **States:** Nhóm 3/4 người, paid/unpaid theo dữ liệu mẫu. All-paid/Loading/Error là yêu cầu triển khai tương lai.
4. **Interactions:** Nhắc thanh toán chỉ mở preview trong prototype. Ứng dụng thật cần người dùng xác nhận trước khi gửi/chia sẻ. Chuyển paid/unpaid chưa mô phỏng đầy đủ.
5. **Navigation:** Từ 06 hoặc sau tạo ở 07; Back về 06; đóng preview trở lại đúng hóa đơn.
6. **UI constraints:** Trạng thái ghi bằng chữ, không chỉ màu. Giữ tên thành viên đọc được, button/target ≥48dp.

## Điều kiện trước khi triển khai

Đã sửa responsive360/412, overlay, elevation vàcomponentstates trênFigma09/10. Còn nghiệm thuPresent/nội dungdài vàquyềnxem. Handoff mô tả đề xuất Flutter, không chứng minh đã có backend, nhập tự do, screen reader hoặc kiểm thử bàn phím.


## Bổ sung đặc tả sau AI critique — 08/10/2026

Theo [AI critique mới](../ai/critique-2026-10-08.md), đã sửa UX04–08: tab14, EmptyCTA, overlay, elevation vàresponsive. [Change ledger](../design/figma-changes-2026-10-09.md) ghi IDs/exports; Flutter mapping vẫn là triển khai tương lai.

Mỗi screen đã có 6 mục. Với Category, prototype hiện trả về form preset 30.000đ; việc giữ số tiền nhập tự do là yêu cầu ứng dụng thật. Retry hiện dùng CLOSE để trở lại form nền, giữ trạng thái trống hoặcinvalid; chọn preset 30k để phục hồi. TrongFlutter,showDialog/AlertDialog giữcontroller dữliệu khi đóng. Cần testPresent để xác nhận trải nghiệm tương tác.
