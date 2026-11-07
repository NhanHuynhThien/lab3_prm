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
