# TokenLedger — task và trạng thái triển khai

Cập nhật 07/11/2026. Đây là **file duy nhất điều khiển tiến độ mobile**. `[x]` có implementation/kiểm tra tương ứng; `[ ]` chưa hoàn thành hoặc còn thiếu nghiệm thu. Checkpoint 22/10 chỉ là lịch sử, không thay E2E của bản hiện tại.

## Phạm vi đã chốt

- Flutter/Riverpod + Google Firebase Auth + Firestore cho dữ liệu cá nhân.
- Không demo login, không seed dữ liệu runtime, không truy cập mail.
- Giữ PDF local; bỏ upload PDF theo yêu cầu user. Đây là ngoại lệ với đề gốc, chưa có bằng chứng giảng viên miễn yêu cầu upload.
- Web admin/backend nằm trong repo riêng [lab3_prm_web_admin](https://github.com/NhanHuynhThien/lab3_prm_web_admin), thư mục độc lập `../lab3_prm_web_admin/`. Stack mới: Next.js + shadcn/ui, Fastify, Supabase PostgreSQL.
- Admin quản lý model/bảng giá/thông báo và tình trạng hệ thống; không đọc chat hoặc sổ token riêng của user.
- Chỉ dùng `.env` cho từng app; không tạo `.env.local`/`.env.example`. Secret backend không được đưa vào Flutter/Next client.

## Công việc đã làm

- [x] 10/11: Sửa 5 lỗi UI từ đợt chụp ảnh: Lịch sử/chi tiết phiên bỏ $0.00 và dòng chi phí cho phiên tự động, nút kỳ ngân sách chỉ khi có ngân sách; Nguồn AI bỏ ô "Phí đã charge" và "Hạn mức · 0"; chi tiết account dùng "Hạn mức hiện tại"; mục "Từng agent" ghi rõ luôn 30 ngày (chưa theo kỳ chọn; viết lại theo kỳ là việc riêng). Rules `superseded` đã deploy; Companion mới đồng bộ lúc 19:21: Codex tháng này 402.3M/532 phiên (trước 259.2M/722, khớp 402.29M đo trên log). 473 Flutter tests pass, analyze sạch. Ảnh trong docs/screenshots/2026-11-10 là trước đợt sửa này (chưa chụp lại, không commit).

- [x] 10/11: Sửa Companion bỏ qua log >16MB (nâng giới hạn 256MB): đo trên máy dev Codex 30 ngày 158M→461M, Claude 592M→883M, hết `partial`. Companion đánh dấu `superseded` các dòng `auto_usage` không còn sinh ra (task đánh số lại khi resume), chỉ khi lần đọc nguồn đó đầy đủ; mobile bỏ qua dòng superseded; rules + 2 ca simulation (166/166 pass). Tổng quan: bộ lọc kỳ lên đầu, thẻ Token/Phiên (ẩn chi phí khi không có), 3 card agent cùng 2 hàng Token trong kỳ / Hạn mức hiện tại, biểu đồ Token 7 ngày. 473 Flutter + 42 Node tests pass, analyze sạch. **Cần deploy rules trước khi chạy Companion mới** (trường `superseded`). Ảnh 21 màn + danh sách lỗi UI còn lại ở `docs/screenshots/2026-11-10/` (không commit vì có email).

- [x] 10/11: Font BeeWise LMS (Google Sans + Nunito, OFL kèm license), card đồng bộ viền + bóng chung, Phân tích gộp một luồng (bỏ tab Agent/Sổ tự ghi, chỉ số một hàng, ẩn Chi phí khi không có), lọc kỳ bằng date range picker (kỳ Tùy chọn), nhãn quota "Đã dùng X% · còn Y%" kèm ngày đặt lại. Analyze sạch, 469 Flutter tests pass; kiểm Phân tích và date picker trên emulator-5554. AGENTS.md đã cập nhật font/card.

- [x] 10/11: Header mobile theo composition BeeWise LMS (thẻ bo góc: avatar Google + chấm đồng bộ, lời chào theo giờ, tên, chip Tự động/Chưa kết nối, nút chuông và lịch sử tròn nền mint), giữ token TokenLedger. Trang Cá nhân bỏ khối avatar/tên lặp với header, gom thành Kết nối (tài khoản + Companion + đăng xuất), Cài đặt (thông báo, múi giờ), Báo cáo, Chẩn đoán. Companion chỉ còn một nút Đồng bộ/Ngắt đồng bộ (bật = đồng bộ ngay rồi realtime theo log CLI), menu bar đồng bộ nhãn và ẩn mục Đồng bộ ngay. Analyze sạch, 467 Flutter tests pass; kiểm ảnh Cá nhân trên emulator-5554. Header/Companion mới chưa annotate Figma.

- [x] 10/11: Dọn UI theo mô hình tự động: bỏ "Thêm tài khoản" và "Ghi sử dụng" (Tổng quan/Phân tích); nút múi giờ đứng lẻ chuyển vào Cá nhân, bộ lọc nguồn chỉ hiện khi có lựa chọn; tab Lưu trữ chỉ hiện khi có account lưu trữ; header chi tiết account không lặp tên; account tự động không hiện $0/"chưa biết chi phí". Giữ "Đặt giới hạn" để cảnh báo. Xóa account QA_20261022_FLOW và phiên QA của nó qua app. Analyze sạch, 467 tests pass; kiểm ảnh Tài khoản/chi tiết account trên emulator-5554.

- [x] 10/11: Gộp mô hình dữ liệu theo hướng tự động. Companion tách log CLI thành từng task theo ngày và upsert vào `users/{uid}/auto_usage` (chỉ trường của Companion); mobile gộp vào cùng `LedgerData` nên Tổng quan/Phân tích/Lịch sử/PDF đọc một sổ. Account ảo `auto-*` lấy quota từ snapshot, không sửa/lưu trữ/xóa tay; phiên tự động chỉ sửa mục đích/tên/ghi chú (màn riêng) và "Ẩn" thay cho xóa. Dashboard bỏ chế độ đổi layout theo agent; form nhập tay không nhận account tự động. Giới hạn token/cảnh báo agent tách theo UID. Thêm rules `auto_usage` + ca simulation trong `tool/firestore_rules_test.cjs`. Analyze sạch, 467 Flutter tests pass. Rules simulation 10/11 (Cloud Rules Test API, không ghi document): 164/164 case pass, gồm 15 case `auto_usage`. User đã deploy rules lên `tokenledger-nhan-20261021` ngày 10/11 (compile + release thành công). Còn chưa kiểm live Companion → Firestore → mobile; giới hạn token vẫn lưu trên máy, chưa lên Firestore.

- [x] 10/11: Viết lại Companion desktop bằng Flutter/Dart (macOS target trong lab3_prm, entry `lib/main_companion.dart`), xóa bản Electron `companion/`. Giữ chức năng: đăng nhập Google qua trình duyệt, consent theo UID, đồng bộ ngay/tạm dừng/tiếp tục/đăng xuất, watcher log CLI + quota 5 phút, retry, menu bar, ẩn khi đóng cửa sổ, đồng bộ khi máy thức dậy, tự khởi động. Nâng `google_sign_in_ios` 6.3.8→6.4.0 (transitive) để Firebase 13 + GoogleSignIn resolve được trên macOS. 19 tests `test/companion` pass, analyze sạch, line limit pass; build macOS debug và mở app không lỗi console. Chưa nghiệm thu login/sync live bằng tài khoản thật, chưa build release/ký; Windows không còn được hỗ trợ.

- [x] 07/11: Companion 0.1.4 bỏ dòng hướng dẫn cuối cửa sổ và thay ô thời gian bằng đồng hồ “Giờ hiện tại”, cập nhật mỗi giây theo giờ máy tính. DMG arm64 build thành công, smoke test xác nhận đồng hồ đổi giây, đúng giờ máy và footer đã bỏ. Đã dọn DMG cũ, cache sinh tự động, gom ba README tài nguyên và rút checklist về nội dung chính; các liên kết tài liệu đã kiểm tra.

- [x] 07/11: Companion 0.1.3 bỏ bộ chọn số giây, theo dõi thay đổi log để tự cập nhật ngầm. Chỉ thao tác “Đồng bộ ngay” hiển thị tiến trình; lượt nền không bật loading hoặc đổi thời gian đồng bộ khi aggregate không đổi. Giữ consent/tài khoản của bản cũ, watcher và retry được dọn khi pause/logout/thoát. 57 Node tests pass, gồm hồi quy trạng thái nền yên lặng, chia sẻ upload với thao tác thủ công và tương thích preferences cũ. DMG 0.1.3 arm64 build thành công, smoke test trên app đóng gói pass và đã kiểm tra ảnh UI bỏ bộ chọn giây. Bản local chưa ký/notarize; chưa đo độ trễ CLI → mobile với mạng thật.

- [x] 07/11: Thêm Companion desktop Electron, cấu hình Firebase public tách khỏi Dart, đăng nhập trình duyệt, consent theo UID, đồng bộ/tạm dừng/đăng xuất và tùy chọn tự khởi động. Đã tạo DMG macOS Apple Silicon, 43 Node tests và 7 Flutter tests liên quan pass, analyze sạch, kiểm tra mở app đóng gói và renderer isolation pass. Android profile build/cài/mở trên emulator-5554 pass. Bản DMG local chưa ký/notarize; Windows và login/sync live bằng giao diện mới cần nghiệm thu riêng.

- [x] Google login thật và workspace keyed theo UID; session change dispose state/listeners. Source: `lib/services/firebase_auth_service.dart`, `lib/widgets/auth_gate.dart`.
- [x] Account/usage/quota CRUD và realtime Firestore owner rules; integer USD micros, unknown khác 0. Nghiệm thu native còn được tách dưới đây.
- [x] Dashboard agent riêng, tổng quan token/nguồn/thời gian/mục đích; provider detail có nhãn nguồn và giới hạn dữ liệu.
- [x] Login theo composition BeeWise, giữ Inter/green/mint TokenLedger; 4 mobile tabs và sidebar desktop.
- [x] Rút ngắn transition/chart; giữ tab state, hạn chế animation ở offstage. Chưa đo FPS trên device thật.
- [x] Companion local cho nguồn CLI/Antigravity/Gemini Takeout do user chủ động chọn. Không lấy cookies hoặc đọc nội dung Gmail.
- [x] Gỡ nút upload/link Cloud PDF, bỏ FirebaseStorage transport khỏi bootstrap; giữ tạo/mở PDF local. Adapter lịch sử còn được cô lập trong service/tests, không có luồng upload UI.
- [x] Đổi cấu hình local Flutter sang `.env`; cập nhật launch, script emulator và bridge setup.
- [x] Dọn docs trùng: gom audit/setup/architecture/provider notes vào file này và README; giữ 7 tài liệu bài yêu cầu, đề chuẩn hóa, license tài nguyên và AGENTS.
- [x] 04/11: Flutter analyze không có issues; toàn bộ 391 tests pass sau thay đổi PDF/bootstrap.
- [x] 05/11: Sửa nhóm P1 nghiệp vụ: biểu đồ 7 ngày không phụ thuộc kỳ lọc, chi phí chưa biết không hiện $0 ở biểu đồ/bảng PDF, cảnh báo ngân sách theo từng tài khoản và số phiên thiếu chi phí trong kỳ, thêm quota trùng tên thì cập nhật, tài khoản lưu trữ không cho sửa quota, tài khoản còn quota không hiện nút xóa, lưu lại được sau lỗi chưa rõ kết quả, khởi động chưa có xác nhận máy chủ không hiện workspace trống. Analyze sạch, 420 tests pass. Chưa kiểm trên thiết bị thật, nhất là offline; không đổi Firestore rules.
- [x] 05/11: Lịch sử có bộ lọc tài khoản/mục đích/nhà cung cấp và xóa bộ lọc; thêm kỳ "Tháng trước" cho Tổng quan, Phân tích, Lịch sử (báo cáo PDF chưa có). Analyze sạch, 429 tests pass; chưa kiểm trên thiết bị thật.
- [x] 05/11: PDF có kỳ Tháng trước, ngày thật của kỳ, mục đích tiếng Việt, giờ theo múi giờ báo cáo, báo lỗi khi lưu/mở thất bại. Quota ưu tiên cửa sổ sắp hết; sửa nhãn account/usage; giới hạn form khớp validation; gom Remote Config/Analytics vào "Thông tin kỹ thuật"; bỏ chữ kỹ thuật và "Mac" khỏi giao diện; Việt hóa picker (thêm `flutter_localizations`). Analyze sạch, 437 tests pass; chưa build Android/web và chưa kiểm trên thiết bị thật sau khi đổi dependency.
- [ ] Lưu ý: main.dart đã nối PlatformApi và hộp thư, nên P0 "Chưa nối runtime" bên dưới cần rà lại khi có backend thật.

## Công việc cần làm và tiêu chí đóng task

| Ưu tiên | Task | Tiêu chí hoàn thành | Trạng thái |
|---|---|---|---|
| P0 | Nối mobile với API platform | Firebase ID token, timeout/retry, owner/session guard; địa chỉ backend `.env`; không secret client | [ ] Chưa nối runtime |
| P0 | Đăng ký thiết bị FCM | Consent, token refresh, multi-device, logout unregister, owner validation | [ ] SDK client có, registry backend mới cần nối |
| P0 | Notification routing | Foreground/background/terminated → 4 route allowlist, chờ auth, inbox owner; test Android thật | [ ] Chưa E2E |
| P0 | Gemini phân tích theo yêu cầu | Consent aggregate, token theo mục đích/kỳ, thời gian gọi, usage trả từ API; thiếu phí ghi unknown | [ ] Backend có contract; mobile chưa gọi |
| P1 | Native 3 core flows | Account CRUD → usage CRUD → analytics/drilldown; Back/draft/error/offline/reload/logout | [ ] Retest hiện hành, chỉ QA riêng |
| P1 | ViewModel cho export/purpose | Views render/forward, business/projection và async state trong VM/services; không tạo VM rỗng | [ ] Chờ rà soát ranh giới ViewModel/services |
| P1 | PDF local native | Tạo/mở file, kỳ/unknown chính xác, session change không lẫn UID; không cloud CTA | [ ] Unit/widget pass; native hiện hành cần kiểm |
| P1 | Remote Config | Đổi 2 key ở console → app fetch/clamp/fallback, ảnh evidence | [ ] Có code, chưa evidence hiện hành |
| P1 | Crashlytics | Handled + test crash theo diagnostic controls → Firebase Console, giải thích admin web source | [ ] Không giả số crash |
| P1 | Analytics | Khớp event contract của đề, screen/item ID và DebugView đúng project | [ ] Còn contract/evidence |
| P1 | Độ mượt/UI/accessibility | Profile frame timing device thật, text scale/TalkBack/keyboard/contrast, Figma 360×800 mỗi màn | [ ] Emulator 120Hz không tự chứng minh FPS |
| P2 | MobAI | 10 `.mob`, dedicated Google account, run/healing/bug-catching thật | [ ] Chưa có bộ hợp lệ |
| P2 | AI PR review | ≥3 findings gồm security/robustness/rules; quyết định/fix/evidence và feature PR | [ ] Local review có, PR evidence còn thiếu |
| P2 | Đóng gói bài | Report 5–10 trang, video 3–5 phút, slide theo hướng dẫn bổ sung; repo access/name đúng | [ ] Chưa đủ để nộp |
| Ngoại lệ | Upload PDF + URL metadata | User đã bỏ; cần xác nhận scope với giảng viên nếu đánh theo đề gốc | Không triển khai |

## Kiến trúc và vận hành cần giữ

`models/` thuần Dart; `services/` SDK/persistence/calculator; `viewmodels/` Riverpod orchestration; `screens/` và `widgets/` UI; `theme/` tokens. Chỉ services gọi Firebase/API. Firestore dùng owner subcollections và atomic transactions, không ghi toàn bộ local snapshot. Async completion phải kiểm UID/epoch; lỗi giữ draft/last-good và Retry.

Project Firebase hiện hành `tokenledger-nhan-20261021`, Spark. Client config nằm trong `lib/firebase_options.dart` và `android/app/google-services.json`; không phải admin credential. Rules/indexes tại `firebase/`, deploy config `firebase.json`. Không tự bật billing, Storage hay mở rules để vượt lỗi. Key Gemini/FCM/Supabase chỉ nằm repo platform local, không nằm mobile.

Companion `tool/provider_bridge/server.mjs` chỉ loopback port 8787 và cần pairing token. `node tool/provider_bridge/setup.mjs` ghi token vào `.env` bị ignore, `adb reverse tcp:8787 tcp:8787` cho device local. Antigravity quota theo official `agy`; Gemini web chỉ metadata từ Takeout user chọn. Không suy quota thành token, giá estimate thành phí đã charge hoặc thời gian request thành thời gian làm việc.

## Tài liệu giữ lại theo đề

[Yêu cầu bài](docs/ASSIGNMENT_REQUIREMENTS.md); [handoff gaps](docs/handoff-gaps.md); [design changes](docs/design-change-log.md); [fidelity](docs/fidelity-check.md); [analytics](docs/analytics-plan.md); [AI log](docs/implementation-ai-log.md); [tests](docs/test-report.md); [code review](docs/code-review.md).
