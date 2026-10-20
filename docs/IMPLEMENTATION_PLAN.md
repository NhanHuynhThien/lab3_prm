# TokenLedger — Kế hoạch ứng dụng Lab 3

Ngày lập: 19/10/2026. Trạng thái cập nhật: đã có Flutter local scaffold, logo/dashboard/animation và tests; Firebase vẫn pending theo yêu cầu. Xem `build-status.md`/`test-report.md`; phần dưới là kế hoạch đầy đủ còn tiếp tục triển khai.

## 1. Quyết định sản phẩm và cách dùng tài liệu

**TokenLedger** là ứng dụng Flutter Android giúp một người quản lý nhiều tài khoản/công cụ AI: Claude, Codex và các công cụ khác. Với mỗi tài khoản, người dùng biết đã dùng cho công việc gì, bao nhiêu token hoặc hạn mức, chi phí bao nhiêu, còn bao nhiêu ngân sách và khi nào reset.

Theo yêu cầu đã làm rõ: được thay đổi và mở rộng nghiệp vụ theo chủ đề token; kế thừa **core UI Lab 2**, không giữ nghiệp vụ chia hóa đơn. Tài liệu này là kế hoạch build, không phải tuyên bố các chức năng đã hoạt động.

Thứ tự đọc: tài liệu này → `TASK_CHECKLIST.md` → đối chiếu nguồn Lab 2 khi triển khai từng màn hình. Trong checklist, `[ ]` nghĩa là chưa hoàn thành; chỉ đánh dấu khi có bằng chứng nghiệm thu.

### 1.1 Hai loại tài khoản phải tách biệt

- **Tài khoản đăng nhập TokenLedger:** Google Sign-In qua Firebase Authentication, sở hữu toàn bộ dữ liệu của người dùng.
- **Tài khoản AI được quản lý:** bản ghi metadata do người dùng tạo, ví dụ “Claude cá nhân”, “Codex học tập”, “OpenAI API dự án A”. Không phải phiên đăng nhập thật vào Claude/Codex.
- Bản Lab 3 không yêu cầu mật khẩu Claude, cookie, session token hay API secret. Từ “token” trong sản phẩm nghĩa là đơn vị sử dụng AI; không phải access token để xác thực.
- Một provider có thể có nhiều account; một account có nhiều phiên sử dụng và nhiều cửa sổ hạn mức. Không gộp hai account chỉ vì cùng email/provider.
- “Agent” trong yêu cầu được hiểu là công cụ/account AI có phân tích sử dụng. `provider`, `product`, `model` và `account` là các khái niệm khác nhau.

### 1.2 Ba lớp chức năng

| Lớp | Phạm vi | Điều kiện hoàn thành |
|---|---|---|
| P0 — bản nộp Lab 3 | Auth, 8 màn kế thừa UI, CRUD account và usage, phân tích mục đích, budget/quota, toàn bộ Firebase, export PDF, MobAI/review/evidence | Hoàn thành trước khi thêm tính năng nâng cao |
| P1 — mở rộng thực dụng | Import CSV có preview và chống trùng, template công việc, so sánh theo mục đích, cảnh báo trong app | Không làm giảm độ ổn định P0; cập nhật design log/Figma |
| P2 — kết nối thật | Adapter cho API chính thức có quyền phù hợp, đồng bộ tự động, nhiều thiết bị đối soát | Chỉ sau khi xác minh khả năng truy cập, bảo mật, chi phí và phạm vi giảng viên cho phép |

Không cần chức năng chat AI, thanh toán, mua gói, chia sẻ tài khoản, đa thành viên hay tự chạy agent để hoàn thành mục tiêu này.

### 1.3 Ràng buộc đề và thay đổi chủ đề

Đề PDF, trang 2, yêu cầu build ứng dụng thiết kế ở Lab 2, đủ ít nhất 8 màn / 3 flow; thay đổi phải ghi `docs/design-change-log.md` và cập nhật/annotate Figma. Đề cũng giới hạn tính năng ngoài thiết kế cũ. Người dùng đã cho phép đổi nghiệp vụ và mở rộng, nhưng điều này chưa xác nhận giảng viên chấp nhận thay đổi chủ đề.

Hành động đầu lộ trình: chuẩn bị mapping UI/flow ở mục 3 để trình giảng viên; ghi kết quả thật. Không tự đánh dấu đã được duyệt. Không cần trì hoãn công việc lập kế hoạch. Khi build, ưu tiên giữ design system và skeleton điều hướng; mọi đổi khác được truy vết.

Đề mặc định làm cá nhân trừ khi giảng viên thông báo làm nhóm. Lab 2 có hai thành viên; không tự suy ra Lab 3 được làm nhóm. Deadline, trọng số môn và số commit/ngày `[N]` trong đề chưa được điền: cần hỏi giảng viên, không tự đặt thành yêu cầu chính thức.

## Cập nhật tài liệu ngày 20/10/2026

Để đọc sau clone, dùng `lab2-ui-reference.md` và Figma gốc. Theo yêu cầu cleanup20/10, không còn commit bản copy ảnh/text/PDF nguồn; các đường dẫn Lab2 sibling ở bảng dưới là provenance lịch sử. Kiến trúc đang chạy được mô tả ở `architecture.md`, hướng dẫn agent ở root `AGENTS.md` và `.agents/`. Firebase vẫn pending; source Dart không thay ở lượt docs/push.

## 2. Nguồn đã đọc và kết luận audit

### 2.1 Nguồn local

Các đường dẫn sau tính từ thư mục `lab3_prm/`:

| Nguồn | Vai trò |
|---|---|
| `PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf` | Đã trích xuất đủ 17 trang; kiểm tra hình trang 2 về phạm vi/thay đổi |
| `../lab2_prm/README.md` | Lab 2 StudentPay; Figma/prototype và lịch sử bàn giao |
| `../lab2_prm/design/DESIGN.md` | **Nguồn token cuối**, cập nhật 09/10; ưu tiên hơn DESIGN.md tại root |
| `../lab2_prm/handoff/flutter-handoff.md` | Mapping token/component, 8 màn, trạng thái, giới hạn prototype |
| `../lab2_prm/design/screen-spec.md` | Danh sách 8 màn final và navigation |
| `../lab2_prm/assets/figma/2026-10-09/` | Bộ final360, QA 412, states, component, elevation; baseline visual |

Lab 2 là repo thiết kế/handoff, **chưa có mã Flutter để copy**. “Lấy core UI” nghĩa là chuyển tokens/components/bố cục thành Flutter dựa trên tài sản này. Repo app chỉ giữ tài liệu mapping/tokens và nguồn Figma; không đưa bản copy ảnh/tài liệu Lab2 vào asset bundle.

Đã xem trực tiếp ảnh Home, Analytics và Create bill final360. Trước khi code từng màn còn lại phải xem ảnh màn đó; không suy diễn từ tên file. Chưa đọc/chỉnh sửa live Figma trong lượt lập kế hoạch này.

- Figma gốc: https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336
- Prototype gốc: https://www.figma.com/proto/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?page-id=1%3A6&node-id=65-2&starting-point-node-id=65%3A2

### 2.2 Phát hiện cần chuyển thành handoff gaps

| ID | Khoảng trống / mâu thuẫn | Quyết định đề xuất |
|---|---|---|
| HG01 | DESIGN.md root là bản lịch sử, màu khác bản final | Dùng `design/DESIGN.md` và ảnh final09/10 |
| HG02 | Handoff chưa có Flutter code | Build theme và component library trước screens |
| HG03 | Preset giả lập nhập tiền; chưa có keyboard/form thật | Form thật, validation cả paste, giữ draft khi Back/Retry |
| HG04 | Dữ liệu prototype độc lập giữa flow | Một bộ dữ liệu Firestore thống nhất và seed có thể reset |
| HG05 | Status bar/home indicator theo iOS, bài yêu cầu Android | Dùng system bars Android/SafeArea, không vẽ Dynamic Island |
| HG06 | Không có login, quota, provider, usage session | Thêm đặc tả và thiết kế thích nghi, ghi log mọi thay đổi |
| HG07 | Loading/error cũ có phần chỉ là frame minh họa | State thật do query, validation, lỗi mạng và upload |
| HG08 | Chưa chứng minh keyboard/text lớn/long content/accessibility thật | Kiểm tra app ở 360/412dp và text scale 1.3/2.0 |
| HG09 | “Còn bao nhiêu” chưa phân biệt tiền/token/% | Quy tắc mục 5; thiếu dữ liệu phải là null/không xác định |
| HG10 | Chưa xác định việc đổi chủ đề có được chấp thuận | Ghi quyết định giảng viên và liên kết Figma đã annotate |

## 3. Core UI kế thừa và mapping màn hình

### 3.1 Giữ nguyên nền tảng thị giác

| Nhóm | Giá trị từ Lab 2 | Cách áp dụng |
|---|---|---|
| Primary / accent | `#006C49` / `#10B981` | CTA/menu; accent không dùng nền chữ trắng nhỏ |
| Background / surface | `#FAF8FF` / `#FFFFFF` | Scaffold và cards |
| Text / muted | `#131B2E` / `#52625C` | Text chính/phụ |
| Border / soft | `#73867A` / `#E8F7EF` | Input và summary card |
| Danger / error | `#BA1A1A` / `#FFDAD6` | Vượt hạn mức, validation |
| Chart | `#494BD6`, `#895900`, primary | Tái dùng palette; không chỉ dùng màu để phân biệt |
| Disabled | `#D3E3DC` | Disabled/track |
| Font | Inter: 28/36 bold, 24/32 bold, 18/26 semibold, 16/24 regular, 14/20 semibold/regular | ThemeData; hỗ trợ tiếng Việt |
| Spacing | 4, 8, 12, 16, 24, 32 | Constants trong theme |
| Radius | Card20, input/button12 | Component chung |
| Touch / CTA | >= 48×48dp / cao52dp | Kế thừa vùng chạm |
| Width | 360×800, 412×800; margin16; content328/380 | Fluid width, không thu nhỏ cả màn |
| Elevation | 0; y2 blur8 alpha.08; y8 blur24 alpha.18 | Theme, card/dialog variants |

Kế thừa header, summary card mint, progress, list row icon/trailing value, category grid, donut + legend, form footer và bottom navigation 4 tab. Đổi label tab thành **Tổng quan / Tài khoản / Phân tích / Cá nhân**; giữ thứ tự/vai trò tương ứng Home/Groups/Activity/You.

Không dùng dashboard phong cách mới, dark neon, gradient nặng hay thay font tùy ý. Extension tokens chỉ được thêm có lý do và log. Android system inset là khác biệt platform được ghi nhận, không copy thanh trạng thái iPhone vào UI.

### 3.2 Mapping 8 màn chính

| ID | Lab 2 → TokenLedger | Giữ | Đổi nghiệp vụ / route |
|---|---|---|---|
| S01 | Home → Tổng quan sử dụng | Header, card mint, progress, 3 dòng gần nhất, CTA, bottom nav | Budget còn lại USD, coverage, usage gần nhất; `/overview` |
| S02 | Add expense → Ghi phiên sử dụng | Form, ô số lớn, category/date/note, Save footer | Account, công việc, mục đích, model, input/output token hoặc chỉ số hợp lệ; `/usage/new` |
| S03 | Category → Chọn mục đích | Grid3 cột, icon/label/selected, Back | Code, Debug, Review, Test, Học tập, Viết, Nghiên cứu, Thiết kế, Khác; `/purposes` |
| S04 | Analytics → Phân tích AI | Chọn thời gian, summary, donut, legend, tab nav | Theo mục đích/provider/account; drilldown đúng filter; `/analytics` |
| S05 | Transactions → Lịch sử sử dụng | List nhóm ngày, tổng, filter, Back | Usage rows; xem/sửa/xóa phiên; `/usage` |
| S06 | Split bills → Tài khoản AI | Summary card, list cards, Create CTA, tab nav | Danh sách account, trạng thái quota/budget; `/accounts` |
| S07 | Create bill → Thêm/sửa tài khoản | Header, fields, selection rows, footer | Provider/product, alias, plan, budget, chu kỳ, mục đích thường dùng; `/accounts/new`, `/accounts/:id/edit` |
| S08 | Bill detail → Chi tiết tài khoản | Summary, progress, list trạng thái, CTA | Used/remaining, quota windows, purpose breakdown, history, edit/archive; `/accounts/:id` |

S07 thay member rows bằng các dòng chọn cấu hình/mục đích thường dùng; **bỏ phép chia tiền và trạng thái paid/unpaid**, không giả lập chúng bằng chỉ số token. S08 thay reminder thanh toán bằng thao tác ghi nhận usage/cập nhật quota. Đây là thay đổi chức năng có chủ đích, không được báo cáo “giữ nguyên mọi flow”.

### 3.3 Màn bổ sung cho Lab 3 và thao tác dữ liệu

| ID | Màn / trình bày | Nội dung |
|---|---|---|
| S09 | Login | Google Sign-In, loading, cancel/error/retry |
| S10 | Cá nhân | Avatar/tên/email, logout, RC hiện tại/refresh, export, Notification Center, demo diagnostics |
| S11 | Chi tiết phiên — sheet hoặc screen | Token breakdown, mục đích, mô tả công việc, nguồn số liệu, cost basis, Edit/Delete |
| S12 | Cập nhật quota — sheet | Window, remaining/used %, resetAt, observedAt, nguồn, ghi chú |
| S13 | Notification Center trong Profile | Danh sách, read/unread, tap tới account/overview |
| S14 | Báo cáo trong Profile | Export filter/progress, kết quả URL, danh sách file đã tạo |
| S15 | P1 Import CSV | Chọn file → map columns → preview/validate → commit → kết quả |

S09–S14 dùng chung design system; thêm log/Figma. Ưu tiên sheet/section cho thao tác phụ, giữ 4 tab và 8 màn lõi dễ nhận ra.

## 4. Luồng nghiệp vụ chi tiết

### F0 — Đăng nhập và phiên người dùng

1. Khởi động Firebase/services → chờ auth state → Login hoặc Overview; không nháy dữ liệu user trước đó.
2. Google Sign-In thành công → tạo/cập nhật profile tối thiểu → đăng ký thiết bị FCM khi được cấp quyền → mở Overview.
3. Cancel giữ Login; lỗi network/cấu hình SHA-1 báo rõ, cho Retry; không tạo user data giả.
4. User mới thấy Empty và CTA “Thêm tài khoản AI”; seed demo là thao tác rõ ràng, không tự chèn vào dữ liệu thật.
5. Logout hủy listeners và provider state, xóa draft nhạy cảm, xử lý device token binding, chuyển Login và chặn Back/deep link.
6. Kết quả nghiệm thu: sign-in/out thật; user A/B không nhìn thấy dữ liệu nhau, kể cả khi đổi tài khoản trên cùng thiết bị.

### F1 — Ghi phiên sử dụng AI (kế thừa Add expense)

1. Overview → “Ghi sử dụng” → S02. Nếu chưa có account: giải thích và mở S07, lưu xong quay lại form.
2. Chọn account đang active; product/model điền theo account nhưng cho sửa model nếu phù hợp.
3. Nhập tên công việc bắt buộc, ví dụ “Sửa lỗi Google Sign-In”, chọn purpose qua S03, chọn thời điểm.
4. Mode token: nhập input/output token không âm; ít nhất tổng >0. Mode không biết token: để token null, có thể nhập chi phí thực hoặc chỉ ghi công việc. Không ép thuê bao phải có token giả.
5. Chi phí chọn một nguồn: nhập số thực tế đã biết; tính ước tính từ pricing snapshot; hoặc chưa biết. Xem preview đơn vị và nhãn nguồn trước lưu.
6. Validate → Save disabled/loading khi request đang chạy → ghi Firestore theo client-generated ID ổn định → chỉ báo đã lưu khi server xác nhận.
7. Quay Overview/account detail, listener tính lại tổng; mở lại lịch sử thấy chính phiên vừa tạo. Analytics phát một lần khi save thành công.
8. Lỗi input: field error + focus đúng ô, giữ draft. Lỗi permission/network: feedback có Retry; không tự đổi sang success.
9. Usage mutation dùng transaction nên khi offline có thể thất bại và cần Retry khi mạng trở lại; giữ draft, không hứa tự queue transaction. Trong lúc chờ server xác nhận, hiển thị đang lưu, không tính là confirmed. Nếu thiết kế sau này dùng queued writes phải có trạng thái “Chờ đồng bộ” riêng. Retry dùng lại ID, không tạo phiên trùng; logout hủy hiển thị dữ liệu của user cũ.
10. Back khi draft có thay đổi: tiếp tục sửa hoặc bỏ; đi chọn purpose rồi quay lại phải giữ tất cả trường khác.

**AC-F1:** Create/edit/delete phiên làm thay đổi đúng tổng; double tap không tạo hai bản; số liệu thiếu không biến thành 0; lỗi và recovery chạy thật.

### F2 — Phân tích mỗi agent/account dùng cho việc gì (kế thừa Analytics)

1. S04 mặc định tháng hiện tại theo Asia/Ho_Chi_Minh; chọn khoảng thời gian kết thúc loại trừ.
2. Chọn metric: chi phí usage / token đã biết / số phiên; chọn group: purpose hoặc account/provider. Metric mặc định là chi phí nếu có, còn không là số phiên.
3. Mỗi chart có legend chứa giá trị/đơn vị, tổng, số phiên thiếu dữ liệu. Tap slice/row → S05 với cùng khoảng thời gian và đúng filter.
4. S05 nhóm ngày, hiển thị công việc + account + purpose + giá trị/nguồn; tap mở S11. Back giữ nguyên filter/scroll.
5. S08 trả lời cho một account: dùng nhiều cho purpose nào, bao nhiêu phiên, tổng token đã ghi, tổng cost đã biết, remaining budget và quota windows.
6. Ví dụ kết luận từ dữ liệu: “Codex học tập: 8/12 phiên là Debug; chi phí đã ghi $1.20; 3 phiên chưa biết chi phí”. Không kết luận công cụ tốt nhất chỉ từ tên model.
7. Khi có outcome tùy chọn, cho đánh dấu hoàn thành/chưa xong và thời gian; P1 mới so sánh cost/phiên hoàn thành trong cùng purpose/cost basis.
8. Empty kỳ đã chọn: giữ filter + CTA Ghi sử dụng; lỗi query/retry giữ filter. Không vẽ chart 0% rồi làm người dùng tưởng dữ liệu đầy đủ.

**AC-F2:** Tổng legend bằng tổng metric đủ điều kiện; detail/list drilldown cùng tập dữ liệu; mục đích do người dùng gán, không gọi LLM để đoán ngầm.

### F3 — Quản lý account và ngân sách/hạn mức (thay flow tạo hóa đơn)

1. S06 → S07 → chọn provider (Claude/OpenAI/Khác), product (Claude/Claude Code/Codex/API/Khác), alias và loại billing.
2. Đặt ngân sách theo dõi riêng của người dùng bằng USD; optional plan fee được ghi riêng; thêm chu kỳ bắt đầu/kết thúc/timezone.
3. Chọn purpose thường dùng để gợi ý trong S02. Gợi ý không tự gán các phiên chưa có nhãn.
4. Lưu account → S08 thật. Read list/detail realtime, edit alias/budget/purpose/chu kỳ phải phản ánh ngay.
5. Nếu có thông tin quota: mở S12 → tạo window chính xác (ví dụ 5h/weekly/custom) → nhập used hoặc remaining %, resetAt, observedAt. Không suy ra % từ số phiên tự ghi.
6. S08 hiển thị từng window riêng: “Còn 35% — ghi nhận lúc 09:00 — reset 14:00”; nếu quá resetAt chuyển “Cần cập nhật”, không tự tuyên bố đã khôi phục 100%.
7. Account không có lịch sử: cho hard delete sau xác nhận. Account có usage: đề xuất archive để giữ lịch sử; hard delete yêu cầu xóa usage trước và kiểm tra quan hệ tham chiếu.
8. MVP hard delete chỉ cho account rỗng qua service transaction/rules kiểm tra account counters; không cascade nhiều collection không kiểm soát. Archived account không cho tạo usage mới, vẫn xem lịch sử/export.
9. Update budget thấp hơn used hợp lệ nhưng hiện vượt budget; không cắt bớt lịch sử. Edit cycle không viết lại `occurredAt` hay pricing lịch sử.

**AC-F3:** Account CRUD thật; quota/budget không bị trộn; archive giữ analytics; lỗi input/network có recovery; không dùng mật khẩu provider.

### F4 — Export PDF và file storage

1. Từ S04 hoặc Profile chọn thời gian/account; preview số record, coverage và đơn vị.
2. Chụp snapshot dữ liệu của filter để PDF không đổi giữa chừng khi listener nhận bản ghi mới.
3. Generate PDF cùng màu/font Lab 2: tiêu đề, owner hiển thị, kỳ, summary account/purpose, bảng usage, chú giải estimated/manual/unknown.
4. Upload Cloudinary cấu hình hạn chế PDF/size; thành công mới lưu URL + metadata vào Firestore.
5. Nếu upload thành công nhưng metadata fail: giữ trạng thái retry metadata với cùng export ID/URL, không tự upload lại. Có log để xử lý file orphan thủ công.
6. Profile hiển thị report ready, filename/time và Open URL; lỗi generation/upload/network tách biệt, Retry không tạo bản ghi thành công giả.
7. PDF không chứa mật khẩu, FCM token hay email provider riêng tư không cần thiết. Nêu rõ URL demo có thể được người có link truy cập; PDF bảo mật thực sự cần luồng signed/authenticated delivery ngoài phạm vi unsigned demo.

### F5 — Thông báo và điều hướng

1. Xin notification permission đúng ngữ cảnh, hỗ trợ Android13+; từ chối không khóa app.
2. Firebase Console gửi test notification kèm data `route=account_detail`, `accountId`, `eventId`; route whitelist, không mở URL tùy ý từ payload.
3. Foreground: nhận → lưu Notification Center + banner; background: system tray, tap xử lý `onMessageOpenedApp`; cold start xử lý `getInitialMessage` sau auth ready.
4. Background handler thực hiện công việc được SDK hỗ trợ, không điều khiển UI. Không hứa persist ngay mọi notification khi app bị kill; khi app được mở qua notification phải reconcile vào Center, chống trùng bằng messageId/eventId.
5. Nếu cần Center đầy đủ dù notification không được tap, phải tạo inbox document phía gửi; đây là extension, Firebase Console đơn thuần không đảm bảo đầy đủ lịch sử trên mọi trạng thái Android.
6. Account đích mất/khác owner/đã logout → Login hoặc Overview + thông báo phù hợp, không đọc dữ liệu user khác.
7. Cảnh báo budget/quota P0 là banner trong app. Push tự động khi vượt ngưỡng cần backend scheduler/trusted sender, để P2; không nhúng server key để tự gửi FCM từ app.

## 5. Quy tắc dữ liệu, tính toán và tính trung thực

### 5.1 Phân biệt chỉ số

| Khái niệm | Ý nghĩa | Có tính “còn lại” được không? |
|---|---|---|
| Token usage | Input/output/cache của request/log đã biết | Chỉ khi có token allowance cùng đơn vị/kỳ rõ ràng |
| Budget | Hạn mức tiền tự đặt để theo dõi | Có: budget trừ cost usage đã biết trong kỳ; nhãn “ngân sách theo dõi” |
| Quota window | %/credit/message theo cửa sổ provider công bố/nhập tay | Chỉ trong đúng window, có nguồn và thời gian |
| Subscription fee | Phí gói theo chu kỳ | Là fixed cost, không tự chia thành giá/token hay cộng lặp vào từng phiên |
| API credit balance | Số dư được provider cung cấp | Không có dữ liệu thì “Chưa có dữ liệu”; không lấy budget thay thế |
| Auth token | Credential đăng nhập | Không thuộc dữ liệu sản phẩm, không nhập/lưu |

API usage và hạn mức Codex/Claude dạng subscription không mặc định tương đương. API Usage/Cost của Claude cần quyền phù hợp; không giả định Google Sign-In cấp quyền đọc usage của provider. Thiết kế Lab 3 chọn manual entry đáng tin cậy + nguồn rõ ràng; đồng bộ provider là adapter P2.

### 5.2 Công thức chuẩn

- `knownTokens = inputUncached + cacheRead + cacheWrite + output`, chỉ cộng các bucket **không chồng lặp** đã chuẩn hóa. Nếu source trả input tổng đã gồm cache, phải tách trước; P0 chỉ nhập input/output không cache.
- Một usage có token null là chưa biết; token0 chỉ hợp lệ khi source xác nhận bằng0. Không dùng `null ?? 0` trong phần báo cáo completeness.
- `estimatedCost = Σ(tokensBucket × rateBucketPerMillion) / 1_000_000`, chỉ khi đầy đủ pricing snapshot và bucket cần thiết. Giá công cụ/server tool khác phải khai báo riêng hoặc ghi “chưa bao gồm”.
- `effectiveCost = reportedCost` nếu có; nếu không có dùng estimatedCost; không có cả hai thì null. Không cộng reported + estimated của cùng usage.
- `periodUsed = Σ(effectiveCost)` của phiên confirmed trong `[periodStart, periodEnd)`, cùng currency. Hiển thị số tiền actual/estimated riêng và số phiên thiếu cost.
- `remainingBudget = budget - periodUsed`; giá trị âm hiển thị “Vượt $x”, progress có thể clamp khi vẽ nhưng số thật không bị clamp.
- `remainingPercent = 100 - usedPercent` chỉ cho cùng window; cả hai không được mâu thuẫn. Giới hạn input0..100. Percent và token count không chuyển đổi qua lại nếu không có allowance.
- `tokenRemaining = max(allowance - knownTokens, 0)` chỉ cho allowance nhập rõ ràng; excess = max(knownTokens - allowance, 0). Nhãn là theo log, không phải số dư provider.
- `purposeShare = metric(purpose) / totalKnownMetric × 100`; denominator0 → empty, không chia0; legend dùng giá trị gốc và phần trăm làm tròn có chú thích.
- Tổng cost usage và tổng subscription fees là hai hàng; P0 không cộng chúng thành tổng hóa đơn provider vì có thể trùng nhau.
- Tổng token đa model chỉ là volume đã ghi, không đo năng lực/giá trị; không cộng % quota các account vào một “% tổng”.
- Forecast P1: extrapolate trên số ngày đủ dữ liệu, gắn “ước tính”; không dùng forecast làm giá trị usage thật.

### 5.3 Tiền, thời gian, nguồn và chỉnh sửa

- P0 chọn USD duy nhất; integer `costMicros` (1 USD = 1,000,000 micros), dùng decimal/rational ở bước tính rồi làm tròn một lần mỗi phiên. Tránh dùng double làm nguồn tiền. Không gọi tỷ giá live trong P0.
- Nếu user cần VND: P1 hỗ trợ thêm currency/FX snapshot; không cộng USD và VND trực tiếp.
- Lưu timestamp UTC; query theo khoảng UTC được chuyển từ timezone chu kỳ. UI mặc định Asia/Ho_Chi_Minh. Phân biệt `occurredAt`, `createdAt`, `updatedAt`, `observedAt`, `resetAt`.
- Giá provider thay đổi: lưu rate snapshot/model/source/effectiveAt vào usage; sửa pricing hiện tại không được thay cost lịch sử.
- Dữ liệu nguồn: `manual`, `demo`, `csv_import`, `provider_api`; giá trị `actual`, `estimated`, `unknown`. Badge “Nhập tay” không được đổi thành “Đã đồng bộ”.
- Quota snapshot mới thay snapshot hiện hành của đúng window; không cộng các snapshot với nhau.
- Demo và dữ liệu thật phân biệt `isDemo`; analytics mặc định không trộn nếu filter không cho phép. Chỉ báo số liệu đầy đủ khi đủ input.
- Khi edit phiên: account relation/counters update trong cùng transaction; rules chặn đổi owner; nếu chuyển account phải cập nhật cả old/new counters hoặc P0 khóa account field khi edit và yêu cầu tạo lại.

## 6. Data model Firestore đề xuất

Main entity để chấm CRUD: **AIAccount**; UsageSession cũng có CRUD đầy đủ để kiểm tra tính toán. Ít nhất hai subcollections được đáp ứng bằng accounts và usage_sessions.

```text
users/{uid}
  accounts/{accountId}
  usage_sessions/{usageId}
  quota_windows/{windowId}
  reports/{reportId}
  notifications/{notificationId}
  devices/{installationId}
```

| Entity | Trường chính | Invariant |
|---|---|---|
| User | displayName, photoURL, email, timezone, createdAt | uid lấy từ Auth path |
| AIAccount | ownerId, alias, providerId, productId, billingMode, planLabel, defaultModelId?, purposeIds[], budgetMicros?, currency=USD, periodStart, periodEnd, timezone, status, usageCount, lastUsageMutationId?, createdAt, updatedAt, schemaVersion | alias1..80, enum hợp lệ, budget>=0, start<end, usageCount>=0 |
| UsageSession | ownerId, accountId, workTitle, purposeId, modelId?, occurredAt, inputTokens?, outputTokens?, reportedCostMicros?, estimatedCostMicros?, pricingSnapshot?, costBasis, dataSource, isDemo, note?, createdAt, updatedAt | title1..120, note<=1000, tokens integer>=0, không owner/account không tồn tại |
| QuotaWindow | ownerId, accountId, windowKey, unit, usedPercent?, limitValue?, usedValue?, observedAt, resetAt?, source | unique logic account+windowKey, không trộn đơn vị; percent0..100 |
| Report | ownerId, fileName, url, storagePublicId, mimeType, sizeBytes, createdAt, periodStart/End, accountId?, recordCount, status | Chỉ ready khi upload xong, HTTPS host allowlist |
| Notification | ownerId, messageId, title, body, route, accountId?, receivedAt, readAt? | messageId dùng idempotency; route whitelist |
| Device | ownerId, fcmToken, platform, updatedAt | dữ liệu private; cleanup/rebind khi logout/change user |

`pricingSnapshot`: modelId, currency, inputRateMicrosPerMillion, outputRateMicrosPerMillion, effectiveAt, sourceLabel. Giá mẫu chỉ để demo, không ghi là giá niêm yết hiện tại. `UsageSession` có thể không có tokens/cost khi chỉ ghi mục đích; lúc đó cần ít nhất workTitle/purpose/time/account.

`usageCount` là counter phục vụ ràng buộc xóa account; không dùng làm tổng tài chính. Create/delete usage cập nhật counter và document trong transaction, rules kiểm tra `getAfter` consistency. P0 không đổi accountId của usage khi edit. Mỗi account có `lastUsageMutationId` để rules truy được usage đối ứng khi count tăng/giảm: kiểm tra document trước/sau tồn tại đúng create/delete, accountId trùng và delta chính xác; không chỉ kiểm tra count không âm. Counter seed/cleanup cũng phải giữ invariant; cần test race create usage vs delete account. Nếu chưa triển khai được rules bảo vệ counter thì dùng archive là luồng xóa nghiệp vụ tạm thời, nhưng **chưa đạt hard-delete main entity**; phải hoàn thiện trước nộp.

### 6.1 Query và realtime

- Accounts active: `status == active`, `orderBy(updatedAt desc)`; stream cho S06.
- Usage kỳ: `occurredAt >= start`, `< end`, `orderBy(occurredAt desc)`; stream dataset đủ kỳ cho tính tổng trong phạm vi Lab.
- Account usage: thêm `accountId == id`; purpose drilldown thêm `purposeId == id` khi cần. Khai báo composite indexes trong `firebase/firestore.indexes.json` theo query thực tế.
- Lịch sử dài có pagination theo cursor; **không tính tổng kỳ từ một trang history**. P0 data nhỏ cho phép stream đầy đủ kỳ, history paginate độc lập. Lớn hơn chuyển aggregate có chiến lược update/delete rõ ràng.
- S01/S04/S08 chia sẻ cùng normalized dataset + calculation service, không tự tính ba công thức khác nhau.
- Snapshot metadata phân biệt cache/pending/server; errors giữ last good data và banner phù hợp. Không gọi cache stale là live provider balance.
- Report/notification queries có ordering và owner path; không chạy query global rồi lọc UID trong widget.

### 6.2 Security Rules và kiểm thử

- Default deny. Mỗi path yêu cầu `request.auth != null && request.auth.uid == uid`; không dùng wildcard allow tất cả descendants mà bỏ validation.
- Create/update kiểm tra owner, field allowlist, type, enum, size, numeric bounds; ownerId/createdAt không đổi sau tạo; timestamps hợp lệ.
- Usage tham chiếu account cùng UID, active lúc create, accountId immutable P0. Rules kiểm tra quan hệ/counter bằng transaction `getAfter`, không chỉ tin client.
- Account hard delete chỉ khi usageCount0 và transaction không tạo usage trùng race. Usage create/delete bắt buộc counter tương ứng, không cho sửa counter độc lập.
- Quota chỉ ghi cùng owner/account tồn tại. Report/notification/device không cho chuyển owner.
- Test emulator: unauth deny; A đọc/ghi A pass; A đọc/ghi B deny; thiếu owner/type sai/số âm/đổi owner deny; invalid relation deny; counter tamper deny; concurrent usage-vs-delete giữ nhất quán.
- Deploy rules/indexes và ghi bằng chứng project thật. Không nộp rules test mode. Rules bảo vệ data ownership, không chứng minh số liệu manual là dữ liệu provider xác thực.

## 7. Kiến trúc MVVM + Riverpod

Chọn **Riverpod** duy nhất cho dependency/state. Models là Dart thuần; services là nơi duy nhất truy cập Firebase/external APIs. ViewModels giữ state, validate/orchestrate và gọi pure calculation services. Views render và gửi user intents, không import Firebase SDK.

```text
lib/
  main.dart
  app.dart
  firebase_options.dart
  theme/                 # Lab2 colors, type, spacing, radius, elevation
  models/                # account, usage, quota, report, app_notification
  services/
    auth_service.dart
    firestore_service.dart
    account_service.dart
    usage_service.dart
    usage_calculator.dart # pure, dễ unit test
    quota_service.dart
    report_service.dart
    file_storage_service.dart
    notification_service.dart
    analytics_service.dart
    remote_config_service.dart
    crash_reporting_service.dart
  viewmodels/            # một VM/screen chính + auth/session scope
  screens/               # S01-S10 và màn/section bổ sung
  widgets/               # component library Lab2 + domain wrappers
  routing/               # auth guards, tab stacks, notification intents
  utils/                 # formatting, dates, validators, typed failures
firebase/
  firestore.rules
  firestore.indexes.json
mobai_tests/
test/                    # calculator, VM, mapping, widget checks trọng yếu
integration_test/        # nếu cần cho Flutter-level checks
docs/
```

Không bắt buộc codegen Riverpod để giảm setup; chốt version tương thích ở lúc setup và commit lockfile. Gói dự kiến: firebase_core/auth/firestore/messaging/analytics/crashlytics/remote_config, google_sign_in, flutter_riverpod, router, pdf/printing, HTTP client, URL launcher; local notifications nếu cần foreground system notification. Chỉ thêm package có chức năng thật; API/version phải kiểm tra docs hiện hành trước code.

### 7.1 State và sự kiện

- State chung: loading / empty / data / error; form thêm idle / validating / saving / pendingSync / saved / failed.
- Error phân loại validation/auth/network/permission/notFound/upload/configuration; message tiếng Việt dễ hiểu, debug details không lộ secret.
- Stream/provider auto-dispose theo UID; auth boundary invalidate toàn bộ data providers. Không giữ global list của user trước.
- Save có stable operation ID và guard double tap; timeout không được suy ra chắc chắn write fail nếu Firestore còn pending.
- Analytics/logging side effects ở service/VM sau trạng thái nghiệp vụ, không đặt trong widget build.
- Router có auth guard; back từ detail về đúng tab/list; tab stack giữ filter; notification intent chờ auth + account ownership check.

## 8. Tích hợp Firebase và storage

| Thành phần | Cách triển khai | Bằng chứng nghiệm thu |
|---|---|---|
| Firebase setup | Project riêng, Analytics enabled, Android package duy nhất, FlutterFire configure | App khởi động project thật |
| Auth | Google provider, debug SHA-1; nếu release demo đăng ký signing cert tương ứng | Google login, profile thật, logout |
| Firestore | Schema mục6, rules/index deploy, CRUD/query/listeners | Console documents + app A/B isolation |
| FCM | Permission, token lifecycle, handlers, Center/deep link | Foreground/background/tap; cold start bổ sung |
| Remote Config | Defaults + fetch/activate + behavior thật | Console publish → refresh → UI đổi + Profile values |
| Crashlytics | Flutter/async error hooks; record handled + crash debug/demo controls | Dashboard có hai sự kiện sau restart/upload |
| Analytics | Event plan, không PII; DebugView | Screenshot event và params |
| PDF/Cloudinary | PDF generated, upload unsigned preset hạn chế, URL+metadata | File mở được, report doc thật |

### 8.1 Remote Config đề xuất

- `overview_recent_limit`: default 3, clamp1..10. Thay đổi số dòng usage gần nhất tại S01, không giới hạn dataset tính tổng.
- `budget_warning_percent`: default 80, clamp1..100. Đổi ngưỡng banner khi used/budget đạt ngưỡng; budget null/0 xử lý riêng.
- `report_export_enabled`: default true, optional thứ ba. False disable CTA kèm giải thích; không coi là access control bảo mật.
- Profile hiển thị effective value, source/default/remote và last fetch status/time; refresh để demo publish có thể quan sát được. Dev fetch interval khác production phải log.

### 8.2 Analytics event plan khởi điểm

| Event | Trigger thành công / ngữ cảnh | Params không PII | Flow |
|---|---|---|---|
| `login` | Auth success | method=google | F0 |
| `logout` | Sign-out complete | không | F0 |
| `screen_view` | Route thực sự xuất hiện | screen_name | Tất cả |
| `view_account` | Account detail tải thành công | item_id, provider_id | F3 |
| `create_account` | Firestore confirmed create | item_id, billing_mode | F3 |
| `update_account` | Confirmed update | item_id, changed_group | F3 |
| `delete_account` | Hard delete confirmed | item_id | F3 |
| `archive_account` | Archive confirmed | item_id | F3 |
| `create_usage` | Usage confirmed | item_id, purpose_id, data_source | F1 |
| `update_usage`, `delete_usage` | Mutation confirmed | item_id | F1 |
| `select_purpose` | Chọn purpose từ grid | purpose_id | F1 |
| `analytics_drilldown` | Mở history từ chart/legend | group_by, metric | F2 |
| `quota_snapshot_saved` | Quota write confirmed | window_type, source | F3 |
| `export_pdf` | Upload và metadata hoàn tất | item_count | F4 |
| `notification_open` | Tap mở đích hợp lệ | destination | F5 |

Tất cả tên <= 40 ký tự, lowercase/digits/underscore. Không gửi workTitle, note, email, secret, FCM token hoặc nội dung prompt. Screen event chỉ có một nguồn để tránh auto/manual duplicate. Không cần `item_name` nếu chứa dữ liệu riêng tư; dùng provider label cố định khi cần.

### 8.3 Chọn storage và giới hạn

Cloudinary unsigned preset là hướng demo miễn secret được đề khuyến nghị. Trước build phải xác minh account cho upload/delivery PDF, đúng resource type, MIME/extension, max size (đề xuất5MB), preset restrictions; thử upload và mở URL trên thiết bị trước khi viết UI đầy đủ. Không xem unsigned upload là owner-authenticated storage.

Nếu cấu hình/tier chặn PDF, kiểm tra khả năng bật theo docs hiện hành. Firebase Storage là phương án thay thế nếu chấp nhận billing và rules owner; S3/dịch vụ khác cần chấp thuận giảng viên theo đề. Không tự thêm custom server để vượt giới hạn đề.

### 8.4 Provider integrations P2

Không thiết kế nút “Kết nối Claude/Codex” giả nếu chỉ tạo metadata. P2 phải có capability matrix cho từng provider/product/plan: API endpoint chính thức, scope cần, chỉ số trả được, độ trễ, quota windows, chi phí/điều kiện sử dụng.

Admin/API credentials không đặt trong APK hay Firestore client-readable. Đồng bộ có secret thường cần trusted backend, là thay đổi kiến trúc/phạm vi phải được chấp nhận. Không dùng cookie scraping/private endpoint hay hứa đồng bộ mọi subscription. CSV/manual vẫn là phương thức hợp lệ khi không có quyền API.

## 9. Seed và bộ dữ liệu nghiệm thu

### 9.1 Dataset local hiện có trong source

Nguồn: `createDemoSeed` tại `lib/services/demo_seed.dart`. Khi chưa có dữ liệu local, demo tạo 3 accounts và 12 sessions; Profile có thao tác restore/clear. Model local hiện chưa có UID/isDemo hay provider API sync.

| Account demo | Sessions | Token đã biết | Cost đã ghi | Budget/quota | Remaining budget |
|---|---:|---:|---:|---|---:|
| Claude cá nhân |4|121,000|$5.68|budget$20; quota5h used65%|$14.32|
| Codex học tập |4|141,000|$5.86|budget$25; weekly used40%|$19.14|
| Gemini nghiên cứu |4|24,000|$1.30|budget$5; quota chưa biết|$3.70|
| Tổng |12|286,000|$12.84|budget$50|$37.16|

Một session Gemini chưa biết token/cost; các tổng trên chỉ gồm dữ liệu đã biết. Chi phí là giả định nhập tay để test, không phải pricing hiện hành. Input/output trong seed cộng đúng total; quota snapshot độc lập usage logs.

Kịch bản nghiệm thu trên baseline hiện tại: thêm Codex Test10k/$0.05 → Codex151k/$5.91; toàn bộ dataset296k/$12.89. Sửa cost phiên mới thành$0.07 → tổng$12.91; xóa phiên mới → baseline286k/$12.84. Quota Codex vẫn40% used nếu không có snapshot mới. Không dùng các giá trị fixture cũ50k/$0.20 và100k/$0.40 để nghiệm thu source hiện tại.

### 9.2 Khi nối Firebase (chưa thực hiện)

Bổ sung seed owner-scoped/versioned, phân biệt demo/real, reset chỉ dữ liệu demo đúng UID; không xóa dữ liệu user thật. Thêm account rỗng CRUD Test và userB để kiểm tra delete/rules isolation. Freeze clock hoặc tái sinh kỳ theo test clock để quota/reset không bị stale ngoài ý muốn.

## 10. Kiểm thử, MobAI, AI review và fidelity

### 10.1 Kiểm thử có giá trị

- Unit calculator: null-vs-zero; reported ưu tiên estimated; micros rounding; không double count; budget overrun; percent0/100; unknown quota; window reset stale; khoảng kỳ/timezone; chart totals.
- Unit VM/service bằng fake: save pending/retry cùng ID, lỗi permission, giữ draft khi chọn purpose, auth change dispose, export upload-success/metadata-fail.
- Security Rules emulator: ownership, schema, account references, counter transaction, concurrent delete/create.
- Widget checks trọng yếu: label/state/semantics; keyboard không che CTA; số dài, tên dài, text scale. Không viết snapshot test vô nghĩa cho mọi widget.
- Firebase integration thật: login/listener/notification/RC/Crashlytics/DebugView/PDF; emulator tests không thay bằng chứng console thật.

### 10.2 Mười MobAI scripts bắt buộc

| ID / file dự kiến | Starting state | Outcome phải assert |
|---|---|---|
| M01 `01_google_login.mob` | Logged out, dedicated Google test account | Overview và profile đúng user |
| M02 `02_flow_usage.mob` | Logged in, seed baseline | Phiên Test10k/$0.05 xuất hiện; Codex total$5.91 |
| M03 `03_flow_analytics.mob` | Baseline + dữ liệu test riêng | Chọn purpose Debug → chỉ đúng sessions/tổng; Back giữ filter |
| M04 `04_flow_account.mob` | Không có account tên test | Create account + nhập quota → detail đúng budget/remaining/source |
| M05 `05_error_recovery.mob` | Draft hoặc lỗi mạng có kiểm soát | Lỗi hiển thị; sửa/retry lưu đúng 1 record, draft giữ nguyên |
| M06 `06_account_crud.mob` | Account rỗng test riêng | Create/detail/edit/list/delete từng bước thay đổi thật |
| M07 `07_navigation.mob` | Logged in baseline | 4 tab đúng nội dung, Back đúng, empty/loading/error kiểm tra theo setup |
| M08 `08_profile_remote_config.mob` | Profile + RC demo đã publish | Profile thật, values đúng; recent limit/banner thực sự đổi |
| M09 `09_pdf_export.mob` | Baseline, storage đã cấu hình | Upload success, URL/open action và metadata/report list |
| M10 `10_logout.mob` | Logged in | Login; Back/deep link không mở data |

Mỗi script có seed/reset riêng hoặc setup rõ ràng; không phụ thuộc chạy M02 trước M03. Google extra screens có manual step được ghi nhận nếu không ổn định; không commit credentials. `.mob` do MobAI thực chạy sinh ra và con người đọc/sửa; không tạo file giả rồi báo pass.

Bổ sung manual/integration: usage edit/delete; user A/B; foreground/background FCM và cold start; stale quota; archive history; PDF failure. M07 không thể bao hết mọi trạng thái chỉ bằng tap tab: chỉ rõ dataset và cách kích hoạt từng state.

Healing: đổi label CTA có kiểm soát → ghi failing script/diff healed → bảo đảm assertion outcome giữ nguyên. Bug-catching: tạm làm save không persist → test phải fail do record/tổng không đổi → revert bug → pass; không merge defect. Lưu evidence trước/sau, không bịa kết quả.

### 10.3 AI code review

Feature branch `codex/tokenledger-lab3`, PR vào main; dùng ít nhất một AI review tool. Review cả `firebase/firestore.rules`. Có >= 3 findings thật, >= 1 security/robustness; ghi tool/file/line/mức độ do sinh viên đánh giá/quyết định/lý do/fix commit. Không ép tool tạo lỗi giả để đủ3. Nếu chưa có đủ findings, review sâu lại phần auth/transaction/error handling.

Ít nhất một PR phải được merge trước nộp theo đề. Không merge khi còn fail gates hoặc chưa có quyết định review. Repo nộp tên `PRM393_Lab03_<StudentID>`; xác nhận StudentID và hình thức cá nhân trước tạo remote.

### 10.4 Fidelity

- Mỗi màn: ảnh Lab2 gốc → bản TokenLedger annotated → ảnh app cùng360×800dp, ghi khác biệt content/interaction/platform/layout.
- Thêm ảnh412dp, empty/loading/error thật và text scaling. Khi physical pixels khác dp, ghi device density/viewport; không so ảnh raw sai tỷ lệ.
- Token audit: màu/font/spacing/radius từ theme; liệt kê ngoại lệ có lý do. Giữ mapping chín nhóm Button/Textfield/Card/Navigation/Appbar/Dialog/Loading/Empty/Error thành reusable widgets/states.
- Không đánh fidelity là hoàn hảo chỉ vì palette giống; báo thật screen/layout/behavior đã đổi. Không claim Figma đã update nếu mới chỉ có đề xuất trong docs.

## 11. Lộ trình triển khai và dependency

Ước lượng tham khảo 12–16 ngày làm việc cho một người, không phải deadline của giảng viên. Firebase/MobAI/review tool setup có thể kéo dài; chừa buffer khoảng20%. Không bỏ testing/docs để chạy P1/P2.

| Giai đoạn | Công việc | Dependency | Exit gate / commit |
|---|---|---|---|
| G0 — scope, 0.5–1 ngày | Chốt chủ đề, mapping8 màn / 3 flow, gap log, Figma annotations, hình thức nộp | Tài liệu hiện tại | Decision log có trạng thái thật; commit docs |
| G1 — setup, 1 ngày | Flutter Android, Firebase, SHA-1, Riverpod/MVVM, auth guard | G0 | Login → app rỗng chạy thiết bị; commit setup |
| G2 — core UI, 1–1.5 ngày | Theme + widgets Lab2, route skeleton và states | G1 | So sánh360/412, không code Firebase trong Views; commit UI |
| G3 — accounts, 1–1.5 ngày | Model/services/rules/indexes, S06–S08, quota, CRUD | G2 | F3 real data + rules tests; commit account flow |
| G4 — usage, 1.5–2 ngày | S01–S03/S05/S11, calculator, transactions, retry | G3 | F1 + edit/delete + counters + edge tests; commit usage flow |
| G5 — analytics, 1 ngày | S04/account breakdown, filters, coverage, shared totals | G4 | F2 drilldown đúng seed; commit analytics |
| G6 — services, 2 ngày | FCM, RC, Crashlytics, Analytics, PDF/storage | G3–G5 | Console/file evidence thật; commit integration |
| G7 — test, 1–2 ngày | 10 MobAI, healing/bug, fixes, A/B, accessibility | G6 | Full run pass + report; commit verified tests |
| G8 — review/fidelity, 1 ngày | PR AI review, fix findings, visual audit | G7 | >= 3 findings và audit; commit fixes |
| G9 — delivery, 1 ngày | Report5–10p, video3–5m, README, merged PR, access check | G8 | Release gates đầy đủ, tag submission |

Workflow tổng vẫn theo đề: Read → Set up → Build → Connect → Test → Review → Verify → Document. Auth/Firebase skeleton được làm sớm vì cần chạy flow; documentation cập nhật xuyên suốt, không viết log hồi tưởng thay bằng chứng.

### 11.1 Chức năng P1 sau P0

- CSV import: template có account/purpose/time/token/cost/source; file size/row limit; preview rows valid/invalid; user resolve account mapping; stable external ID/hash chống trùng; commit theo chunk; partial failure retry không nhân đôi; rollback chỉ record import batch đó. Không cộng CSV snapshot tổng với log phiên tương ứng.
- Work templates: tên công việc/purpose/account thường dùng; không auto-invent tokens/cost.
- So sánh công cụ: cùng purpose, cùng kỳ, tách actual/estimated, có sample count và missing coverage; không kết luận hiệu năng nếu thiếu outcome.
- Budget alerts: danh sách cảnh báo trong app, threshold configurable, nhãn quota stale; local banner khác push từ server.

### 11.2 Đường găng và rủi ro

| Rủi ro | Cách giảm / phương án |
|---|---|
| Đổi chủ đề lệch rubric | Mapping/annotation + xác nhận giảng viên, mô tả thật thay đổi |
| Muốn đồng bộ provider ngay | P0 manual có nguồn; P2 capability discovery trước mọi code connector |
| Google login fail | Test SHA-1/package/provider/emulator Google Play ngay G1 |
| Cloudinary không mở PDF | Spike upload/open sớm G1; xử lý cấu hình hoặc chọn storage hợp lệ |
| Remote Config chưa fetch | Defaults/fetch UI/status; demo publish với khoảng fetch phù hợp |
| Crash dashboard trễ | Tạo evidence sớm, restart để gửi; không đợi lúc quay video |
| MobAI không dùng được | Thử sớm; báo giảng viên trước khi thay tool theo đề |
| Counter/transaction/rules quá phức tạp | Làm test G3/G4; không giả vờ hard delete đã an toàn |
| Nhiều dữ liệu làm totals sai | Tách dataset summary và pagination; đưa aggregate lớn sang P2 |
| Kịp app nhưng thiếu evidence | Chụp/log mỗi exit gate, checklist riêng theo rubric |

## 12. Definition of Done và hồ sơ nộp

| Nhóm rubric | Điểm | Điều kiện đạt trong kế hoạch |
|---|---:|---|
| Functional | 25 | >=8 màn, 3 flow đã đổi có log, CRUD/query/realtime/states thật |
| Firebase + analytics | 25 | Auth4, rules6, PDF4, FCM3, RC3, Crash2, Analytics3 |
| Architecture | 10 | MVVM5 + Riverpod/cấu trúc5 |
| UI/fidelity | 10 | Tokens/components4 + screens/states3 + accessibility3 |
| MobAI | 15 | Coverage5 + assertions4 + healing3 + bug3 |
| AI review | 5 | Findings3 + decisions/fixes2 |
| AI implementation + gaps | 5 | >= 6 logs có prompt nguyên văn3 + gaps2 |
| Report + video | 5 | Report3 + video2 |

Tổng100. Đây là mapping tiêu chí, không phải tự chấm điểm đã đạt.

File cần hoàn thiện trong build: `README.md`, `docs/handoff-gaps.md`, `docs/design-change-log.md`, `docs/fidelity-check.md`, `docs/analytics-plan.md`, `docs/implementation-ai-log.md`, `docs/test-report.md`, `docs/code-review.md`, `firebase/firestore.rules`, indexes,10 `.mob`, assets evidence. AI log có >= 6 entry thuộc theme/VM/rules/Firebase/PDF/tests; mỗi entry prompt nguyên văn/output/verification/accepted-modified-rejected/lý do. Không fabricate log hoặc kết quả test.

Release gates: `dart format` sạch; `flutter analyze` không lỗi; tests trọng yếu pass; Android build/install chạy; rules deployed; fresh clone chạy theo README; repo mở được từ private browser window; không secret; report/video/PR merge đầy đủ.

Video3–5 phút cần dựng theo evidence đã có: login/profile;3 flow và error recovery; CRUD+Firestore; PDF URL; FCM; RC publish/react; Crashlytics2 loại; DebugView; full MobAI run (có thể tua nhanh rõ ràng); AI review; logout. Report5–10 trang chứa đủ đề mục PDF, không dùng video thay report.

## 13. Nguồn kỹ thuật đã kiểm tra khi lập kế hoạch

Kiểm tra ngày 19/10/2026; xác minh lại version/API/quyền khi triển khai, không hard-code thông tin giá vào sản phẩm.

- [Claude Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api): API usage/cost có yêu cầu credential/quyền; không suy ra hỗ trợ mọi account subscription.
- [Using Codex with your ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan): usage theo plan và lựa chọn API cần được phân biệt.
- [FCM receive messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages): foreground/background, permission và notification interactions.
- [Cloudinary upload presets](https://cloudinary.com/documentation/upload_presets): cấu hình upload/preset, kiểm tra restrictions thực tế trước dùng.

Các quyết định sản phẩm/calculation/architecture trong plan là đề xuất cho TokenLedger. Chúng không phải lời khẳng định nhà cung cấp có API hoặc token balance đúng theo schema đề xuất.
