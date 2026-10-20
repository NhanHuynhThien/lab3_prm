# Handoff gaps — khi dựng scaffold

| Gap | Quyết định trong code | Kiểm chứng / phần còn lại |
|---|---|---|
| Root DESIGN.md lịch sử khác final | Dùng `lab2_prm/design/DESIGN.md` cho màu/type/radius | Theme manual review; live Figma pending |
| Không có Flutter Lab2 code | Xây reusable theme/widgets trước screens |25 source Dart files + 3 test files ở trạng thái scaffold hiện tại |
| Prototype chỉ preset tiền | Form account/usage thật, nullable metrics, validation, draft giữ khi chọn purpose | Widget test save/error; discard-draft dialog khi Back còn pending |
| Nghiệp vụ mới khác hóa đơn | Map8 màn sang account/usage/purpose/analytics | DC02–DC06; giảng viên acceptance pending |
| Login/profile chưa thiết kế đủ | Demo entry/profile cùng tokens, Google pending | Không claim Auth tích hợp |
| Backend chưa cấu hình | Interface repository + local implementation | Firebase pending theo yêu cầu |
| iOS chrome trong final | Dùng platform appbar/SafeArea, không vẽ iPhone UI | Android native test pending do thiếu SDK |
| Token/quota/cost chưa có định nghĩa | USD micros, missing khác0, quota snapshot nhập tay độc lập | Calculator/VM tests |
| Timezone và quota cycle | Local demo theo timezone thiết bị/tháng dương lịch; stale quota khi reset | IANA timezone/cycle tùy chỉnh còn pending |
| Desktop layout chưa có Lab2 | Framed-sheet sidebar responsive; mobile4 tab | Browser screenshots và widget360/412/768/1440 |
| Visual inspector dựa vào DOM | Flutter dùng CanvasKit, DOM inspector không thấy canvas text/h1 | Dùng ảnh thật + Flutter widget tests; không claim DOM gate pass |

## Portability sau publication 20/10

Repo dùng [lab2-ui-reference](lab2-ui-reference.md) và Figma gốc thay các bản copy ảnh/text nguồn. Flutter build chỉ đọc source/font/platform assets; không phụ thuộc sibling Lab2 hoặc bộ skill local.
