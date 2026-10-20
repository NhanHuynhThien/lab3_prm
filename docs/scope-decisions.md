# Quyết định phạm vi và khoảng cách plan/source — A03–A06

Ngày 21/10/2026. Đối chiếu [plan gốc](IMPLEMENTATION_PLAN.md) mục 1, 4–6, [checklist](TASK_CHECKLIST.md), [kiến trúc](architecture.md), models/services/ViewModels/screens và tests hiện có. Đây là quyết định kỹ thuật theo yêu cầu làm A03–A06; không phải phản hồi giảng viên hoặc nghiệm thu Lab3.

**Cập nhật implementation sau A04:** [local-p0-upgrade](local-p0-upgrade.md) ghi schema2/migration và code SD01–SD05, analytics/history local SD08. Bảng A04 bên dưới giữ snapshot quyết định ban đầu, các câu “chưa có” tại đó không còn là hiện trạng code. Backend/SD07 và estimate/SD06 vẫn pending/hoãn; không đổi scope rubric.

## A03 — Phạm vi dữ liệu

P0 là ứng dụng Android quản lý dữ liệu cá nhân: account metadata, ghi usage thủ công theo mục đích, token/cost có thể chưa biết, ngân sách USD và quota snapshot nhập tay. Bản local là bước triển khai của P0. Auth/Firestore và các services/evidence trong plan vẫn thuộc P0 Lab3 nhưng **pending theo yêu cầu**, không bị loại vì bản demo đã chạy.

| Thuật ngữ | Ý nghĩa / giới hạn |
|---|---|
| User đăng nhập | Chủ dữ liệu TokenLedger qua Google/Firebase trong kế hoạch; hiện chỉ demo entry, chưa có UID/role |
| Provider | Nhà cung cấp, ví dụ Anthropic/OpenAI/Google; không phải account hoặc model |
| Product | Công cụ/sản phẩm, ví dụ Claude/Codex; metadata người dùng nhập, không xác nhận quyền truy cập |
| AI account | Bản ghi riêng cho một tài khoản/công cụ; nhiều account có thể cùng provider/product. Không chứa password/API key/access token/cookie |
| Model | Model dùng cho một phiên, khác product; modelId optional đã implement sau A04. Không suy model từ tên provider |
| Usage session | Bản ghi công việc trên một account, purpose, thời điểm, token/cost/note; không phải login session hoặc cuộc chat AI |
| AI token | Đơn vị sử dụng input/output. Tổng knownTokens chỉ là volume ghi nhận, không phải quota còn lại |
| Auth token | Credential xác thực, không phải AI token; demo không thu thập credential provider |
| Budget | Hạn mức tiền tự đặt; remainingBudget không phải provider balance hoặc hóa đơn thực |
| Quota snapshot | Giá trị quan sát tại observedAt, có window/resetAt; stale sau reset, không suy từ usage và không cộng % giữa accounts/windows |

USD integer micros là currency duy nhất P0; 1 USD = 1.000.000 micros. Null khác measured zero. Input/output cùng biết hoặc cùng trống. Cost seed là giả định, không phải giá provider hiện hành. Plan/thuê bao trên account là metadata, chưa có trường phí thuê bao hoặc tính hóa đơn. Không tự cộng phí vào usage.

CSV/import, work templates, forecast và VND/FX là P1; provider sync qua API chính thức là P2. Chat, payment, cookie scraping, secret backend giả và admin đa user ngoài phạm vi hiện tại. Google login app không tự cấp quyền đọc Claude/Codex.

Bằng chứng source hiện tại: [models](../lib/models/ledger.dart), [repository](../lib/services/ledger_repository.dart), [reporting VM](../lib/viewmodels/reporting_viewmodel.dart), [usage form](../lib/screens/usage_form_screen.dart), [analytics](../lib/screens/analytics_screen.dart). Các file này chứng minh giới hạn local, không phải schema Firestore trong plan.

## A04 — Quyết định từng khoảng cách (snapshot trước khi code)

Không chuyển một yêu cầu P0 sang P1 chỉ vì source thiếu. Những mục dưới đây vẫn là backlog; tick A04 xác nhận **đã chốt cách xử lý**, không xác nhận đã code chúng. Không có thay đổi rubric nào được coi là đã được giảng viên chấp nhận.

| ID | Plan / source hiện tại | Quyết định và việc cần làm | Kiểm chứng khi triển khai |
|---|---|---|---|
| SD01 | S02/Usage có modelId optional, account defaultModelId; hiện chưa có field/UI | Giữ trong P0 theo plan. Model optional, không bắt nhập giả; gợi ý từ account được đổi theo phiên | Model khác product; JSON cũ thiếu field vẫn đọc; edit/retry giữ giá trị; D01/ACCOUNT-02/USAGE-03 |
| SD02 | Account purposeIds/default purposes; hiện chỉ purpose của session | Giữ P0. Account defaults là gợi ý có thể đổi, không viết lại phiên cũ | Create/edit/default/clear, purpose picker/Back/draft; ACCOUNT-02/USAGE-04 |
| SD03 | Nhiều quota windows độc lập; hiện một QuotaSnapshot/account, window dạng text, % used | Giữ P0 nhiều windows và source/note. Replace đúng window, không cộng snapshots/%; numeric token/message/credit allowance chỉ thêm với đơn vị và dữ liệu rõ | Migration snapshot cũ thành một window, backup, cùng/khác window, stale/unknown/0/100, archive; QUOTA-01/03/D10 |
| SD04 | Cycle/timezone, lưu UTC/query timezone; hiện tháng dương lịch theo timezone thiết bị, ISO theo DateTime gốc | Giữ giới hạn demo hiện tại; P0 cuối vẫn cần timezone/cycle rõ theo plan (mặc định Asia/Ho_Chi_Minh). Không claim storage đã normalize UTC; không lặng lẽ đổi timezone dữ liệu cũ | Migration và policy ngày cũ, UTC/local biên kỳ/năm/leap/reset, kỳ tùy chỉnh; CALC-04/D11 |
| SD05 | dataSource/costBasis/isDemo; hiện seed và manual chung LedgerData, costMicros nullable | Giữ P0 provenance và demo isolation trước cloud/report. Known cost là chi phí nhập tay, chưa phân loại reported/estimated; không tự gán costBasis actual cho dữ liệu cũ | Mapping/migration có nguồn, unknown/zero, seed không trộn dữ liệu thật, report coverage; C05/D08/SEED-02 |
| SD06 | Plan có estimated cost từ pricing snapshot; chưa có pricing engine/snapshot | Hoãn **triển khai chế độ estimate**; manual known cost hoặc unknown đủ cho đường P0 hiện tại. Không hứa tính tự động trong UI. Nếu bật estimate: phải chốt riêng nguồn giá/model/scope/effectiveAt, integer rounding/precedence và snapshot bất biến | Không dùng seed làm pricing; không cộng reported+estimated; CALC-02/03 phần pricing còn pending. Nếu đề gốc yêu cầu estimate bắt buộc, A02 phải mở lại quyết định trước nghiệm thu |
| SD07 | Backend models/ownership/rules/services đầy đủ; hiện repository snapshot local schema1 | Giữ P0 Lab3, chờ yêu cầu tiếp tục Firebase. Thiết kế streams/atomic CRUD/UID, không upload toàn snapshot để merge | C01–C15 và E/F/G; tests user A/B, rules/counter races, console evidence thật |
| SD08 | Group provider, history nhóm ngày, metric mặc định theo coverage, S13/S14 và router/auth/deep links | Giữ yêu cầu plan; hiện chỉ metric selector, purpose/account drilldown, search/time filters và Navigator demo. Donut slice chưa tương tác, legend/account rows có drilldown | D03–D07, UI-11, USAGE-11, ANALYSIS-01/02/04/07; Notifications/Reports khi E triển khai |

SD06 là giới hạn kỹ thuật có điều kiện, không phải miễn trừ rubric. A01/A02 còn chờ đề gốc/phản hồi thật; nếu chúng thay đổi phạm vi, cập nhật quyết định này và checklist trước khi code. SD01–SD05 cần thiết kế migration/schema mới trước sửa model; không cần đổi schema1 trong lượt docs này.

## A05 — Cách đọc trạng thái

- `[x]` chỉ phạm vi ghi ngay trong task; các task kết hợp local + backend chưa đủ giữ `[ ]` và ghi phần local đã có.
- B01–B14 đã kiểm chứng local/annotation; B15/B16 native hoãn theo người dùng. 168 tests baseline B11–B13 (200 tests sau upgrade) không thay Auth/Firestore/MobAI/Android hay final fidelity.
- Handoff có HG01–HG10 cùng trạng thái/verification; change log, fidelity draft và AI log đã tồn tại. Không còn ghi các file này là chưa tạo.
- G0–G9 chưa đạt nghiệm thu đầy đủ; bảng gate phân biệt local đã có, phần pending và trạng thái chưa commit. A03–A06 hoàn tất không làm A01/A02/A07 tự hoàn tất.

## A06 — Nguồn hiện hành và lịch sử

Snapshot/text/ảnh nguồn Lab2, PDF đề bài và vendor skills từng được copy rồi cleanup khỏi Git ngày 20/10. Đó là lịch sử, không phải file cần khôi phục để chạy app. Dùng [Lab2 reference](lab2-ui-reference.md), theme source và Figma gốc. Live annotations đã thực hiện B13: [board 233:3](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3); full QA412/state/component/mockup/fidelity vẫn pending. Bộ UI skills không có trong checkout hiện tại; optional tooling, không phải dependency Flutter.

Git đọc thực ngày 21/10/2026: branch `codex/local-form-safety`; HEAD và local main `4aeb7b719b95c0b4aa21f02bc0f05329b909cdf2`; `git ls-remote --heads origin` trả remote main cùng SHA. Origin là repo [lab3_prm](https://github.com/NhanHuynhThien/lab3_prm). Đây là refs snapshot, không chứng minh visibility/access hiện tại; private là trạng thái đã ghi từ publication trước. B01–B13 và lượt A03–A06 vẫn ở working tree, chưa commit/push. Không dùng SHA nền làm commit chứng minh source/tests mới. “Repo trống/chưa có Git” chỉ đúng trước publication 20/10.

Doctor 19/10 thiếu Android SDK là lịch sử. Doctor 21/10 xác nhận SDK/licenses; debug APK được build trước B03–B13, không phải binary hiện hành. Theo yêu cầu không chạy/tạo/sửa emulator; native smoke/TalkBack/IME hoãn. Flutter 3.47.4/Dart 3.13.3 và kết quả168 tests baseline và200 tests upgrade/analyzer/web build xem [test report](test-report.md), không phải lần chạy mới ở lượt docs này.

## Rà soát hoàn thành

A03: phạm vi và thuật ngữ đã chốt. A04: SD01–SD08 có quyết định, lý do, backlog và cách kiểm chứng; không bỏ yêu cầu thiếu hoặc thêm engine giá. A05: checklist/gaps/log/gates đồng bộ. A06: nguồn thiết kế, toolchain và Git hiện hành tách khỏi lịch sử. Kiểm tra cuối gồm local links, task IDs, Markdown fences, portability, Git diff whitespace và runtime hash không đổi; kết quả ghi ở test-report. Không build lại app, không Firebase/emulator/commit/push.
