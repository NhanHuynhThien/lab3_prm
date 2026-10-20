# Nâng cấp P0 local sau A04 —21/10/2026

Theo yêu cầu “làm cho tôi” sau thứ tự model/migration → form/quota → cycle/timezone → analytics/history. Đây là implementation local của SD01–SD05 và phần analytics/history SD08 trong [scope decisions](scope-decisions.md); Firebase/SD07, S13/S14, full auth/deep links và bài nộp chưa được triển khai.

## Dữ liệu và migration

Schema JSON mới là **2**, vẫn dùng key `tokenledger.demo.v1` để tìm dữ liệu cũ; tên key không phải schema version hiện tại. Không xóa hoặc chuyển key khiến app nhầm dữ liệu cũ thành lần mở đầu.

| Entity | Trường mới / hành vi |
|---|---|
| AIAccount | defaultModelId nullable, defaultPurposes immutable, quotaWindows immutable, timezone IANA, cycleStartDay1–31, isDemo/dataSource |
| UsageSession | modelId nullable, dataSource manual/demo/legacy, isDemo, costBasis manual/actual/unspecified/unknown |
| QuotaSnapshot | windowKey ổn định, unit=percent, source, sourceLabel và note, observedAt/resetAt; từng window có stale riêng |
| LedgerData | reportingTimezone; mặc định không gian mới Asia/Ho_Chi_Minh |

Load schema1: parse và validate toàn snapshot trước; đưa quota cũ vào một window; model/default purposes để chưa biết/trống; giữ chính sách timezone `device`, ngày kỳ1. Usage cũ là `legacy`, known cost là `unspecified`, cost null là `unknown`; không suy demo từ seed IDs hoặc tự xác nhận actual. Dữ liệu cũ vẫn xem trong bộ chọn **Dữ liệu cũ**.

Trước ghi schema2 phải sao lưu **đúng raw blob** vào `tokenledger.demo.v1.migration-v1-backup` dạng `{"value": raw}`. Backup fail không replace; replace fail giữ backup và lỗi để Retry. Load song song dùng chung một future migration; save chờ migration hoàn tất để không bị migration chậm ghi đè thay đổi mới. Load schema2 không chạy migration lại. Corrupt/unsupported version không bị biến thành seed hoặc dữ liệu trống. Recovery backup hiện có dùng key riêng, không ghi đè migration backup.

Timestamp được serialize UTC; migration giữ instant theo cách parse dữ liệu local cũ trên thiết bị. Schema1 không có offset thì không thể suy timezone gốc của máy khác: giữ `device`, không lặng lẽ gán Asia/Ho_Chi_Minh. Không thêm restore/import UI hoặc migration nhiều thiết bị. Snapshot repository vẫn có giới hạn concurrency giữa nhiều cửa sổ/thiết bị.

## Form và quota

Account form cho sửa/xóa model mặc định, chọn nhiều mục đích gợi ý, timezone và ngày đầu kỳ. Usage mới gợi ý account thuộc nguồn đang xem, tránh tự chọn nhầm account seed khi đã có account manual; nhận model/purpose từ account; người dùng được sửa hoặc để model trống. Đổi account chỉ cập nhật gợi ý chưa được sửa tay; sửa defaults không viết lại phiên đã lưu. Edit usage giữ accountId, source và demo flag; cho chọn loại chi phí nhưng không tự tính estimate. Save fail giữ controller/draft/operation ID và createdAt của account mới qua retry khi clock tiến; immutable createdAt so theo instant sau UTC reload. Back khi chỉ đổi chip cũng có xác nhận.

Account detail liệt kê từng quota, nguồn/ghi chú/quan sát/reset, mở sửa đúng window, thêm và xóa có confirmation. Cập nhật cùng key hoặc thêm tên đã tồn tại thay snapshot đó, giữ các window khác; rename giữ key và không cho hai nhãn cửa sổ trùng. Form sửa một window đã bị xóa không tạo lại nó. Quota quá reset giữ số quan sát cũ và báo stale; không tự về100%. P0 chỉ nhập **%**, không có phép suy token/messages/credits từ phần trăm. Ngày/giờ quota và usage được nhập theo giờ thiết bị, lưu UTC; báo cáo hiển thị theo timezone đã chọn.

## Kỳ, nguồn và báo cáo

ReportingCalendar service dùng IANA qua [timezone0.11.2](https://pub.dev/packages/timezone/versions/0.11.2). Database được bundle từ `data/latest.dart`, không tải timezone qua mạng lúc chạy. `UTC` được xử lý tường minh; `device` chỉ là chính sách tương thích cũ. Không đặt công thức kỳ/ngân sách trong widget.

Ngân sách từng account tính trong `[start,end)` theo timezone và cycleStartDay của account. Ngày29–31 clamp độc lập vào ngày cuối từng tháng, gồm tháng nhuận; không cộng fixed30days. Dashboard cộng ngân sách/chi phí từng kỳ account và ghi nhãn **Kỳ hiện tại**, vì các account có thể khác kỳ. Báo cáo tháng/7ngày và nhóm ngày dùng reportingTimezone; đổi timezone chỉ đổi cách xem, không sửa instant lịch sử. IANA xử lý DST; không giả định mỗi ngày24 giờ. Kỳ bắt đầu tại midnight theo quy tắc thư viện của zone (giờ trùng/khuyết theo database).

Bộ chọn nguồn dùng riêng manual/demo/legacy. Mặc định ưu tiên manual nếu có phiên, sau đó legacy, rồi demo; user chọn tường minh được giữ khi điều hướng. Không cộng ba tập này vào một tổng. Metadata budget cũng có nguồn; account cũ không liên quan không làm tăng ngân sách của tập manual. Account được đưa vào ngân sách nguồn khi metadata thuộc nguồn đó hoặc có phiên của nguồn đó. Account metadata vẫn quản lý được qua danh sách chung; số liệu theo nguồn đang chọn. Reset/clear chỉ tác động dữ liệu đã gắn demo; giữ manual/legacy và account còn được các phiên đó tham chiếu. Seed IDs trùng dữ liệu giữ lại được remap; reset nhiều lần không nhân đôi demo.

Analytics thêm nhóm provider và drilldown; purpose legend và sector donut mở lịch sử cùng filter/kỳ/nguồn. Chỉ số ban đầu là cost khi có known cost (kể cả0); nếu toàn unknown thì dùng số phiên. Chọn metric thủ công vẫn được giữ. Cost breakdown tách số tiền user xác nhận actual, manual và chưa phân loại; tổng chỉ cộng mỗi phiên một lần, null không thành measured0. Không có pricing engine hoặc mode estimated.

History nhóm ngày, row và detail cùng timezone báo cáo; source/cost basis/model/demo flag hiển thị trong detail. Search/filter giữ khi đi settings/Back/Retry. Múi giờ báo cáo chỉnh được từ các màn có bộ chọn nguồn; lỗi lưu giữ draft và không báo thành công.

## Thiết kế và kiểm chứng

Giữ Inter/palette/radius/spacing/touch/CTA Lab2, framed-sheet, IndexedStack, AppMotion/reduced motion, Material form/FilterChip/Panel/Dialog đã có. Không có UI skill local trong checkout; lượt này mở rộng components hiện hành theo Lab2 reference, không cài vendor tooling hoặc sửa live Figma. Annotation B13 là lịch sử, chưa được coi là đã đồng bộ với các field mới; cần cập nhật ở final fidelity.

Tests mới: schema_v2_test kiểm migration/backup/retry/concurrency/provenance/UTC/DST/cycle/immutable collections/quota upsert/delete/demo isolation/reset; scope_forms_test kiểm field mới/retry/Back/default clear/source notes/settings/provider/day groups/donut ở360/412. Full suite còn bao gồm ma trận360/412/768/1440×800, scale1/1.3/2, keyboard/SafeArea và accessibility/states. Kết quả thực chạy cuối ghi trong [test report](test-report.md); không suy web/widget tests thành Android/MobAI/Firebase evidence. Không emulator, commit hoặc push ở lượt này.

Final verification: pub get pass; format47 files0 changed; analyzer sạch; **200/200 tests pass140s**; web JS release build pass57.7s. Lượt199 có xuất và xem ảnh Flutter; lượt200 kiểm cùng ma trận không xuất ảnh lặp.83 runtime file hashes không đổi giữa lượt cuối và sau build.21 Markdown links/fences/portability/IDs và git diff whitespace sạch. Chi tiết môi trường/coverage/giới hạn ở test-report; không native/Firebase/MobAI evidence mới, chưa commit/push.
