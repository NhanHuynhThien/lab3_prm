# Build status và visual review

Scaffold và ảnh gốc: 19/10/2026. Cập nhật tài liệu: 20/10/2026. Phạm vi: scaffold Flutter hoạt động, local demo, logo và dashboard/animation. Firebase hoãn theo yêu cầu.

## Kiến trúc và luồng hiện có

- Flutter3.47.5/Dart3.13.4; Riverpod3.4.3 và SharedPreferences2.5.6 theo pubspec.lock.
- Model/ViewModel/Service/View tách lớp; services giữ persistence và calculator. Không Firebase calls trong views.
- 12 screen files và 1 usage-detail sheet: Login, Shell, Overview, Accounts, AccountForm, AccountDetail, QuotaForm, UsageForm, Purpose, History/detail sheet, Analytics, Profile.
- Account CRUD/archive/restore, usage CRUD và quota update local; persist reload qua SharedPreferences.
- First launch có seed 3 accounts/12 sessions, known cost$12.84/token286,000,1 session missing cost/token. Dữ liệu hoàn toàn giả định, nguồn `lib/services/demo_seed.dart`.
- Primary action Ghi sử dụng luôn truy cập từ Overview; mọi navigation có Back platform.

## Hướng thiết kế

Áp dụng skill `design-taste-frontend` vừa cài. App style **framed-sheet**, seed1978369971, giữ palette/type Lab2, không redraw. Nền lavender/mint và radii của Lab2 là ngoại lệ được giữ theo yêu cầu UI kế thừa.

Câu hỏi của Overview: “AI đang hỗ trợ công việc nào, đang dùng bao nhiêu ngân sách và còn hạn mức nào?” Câu hỏi Account: “Một công cụ đang dùng vào đâu và còn gì?” Câu hỏi Analytics: “Mục đích nào dùng nhiều cost/token/session nhất?”

Face: logo token hexagon T/L + màu emerald của Lab2 trên dữ liệu chính. Signature: quota window có nguồn/observed/reset, tách khỏi token log và budget; không dựng một con số remaining token giả cho mọi provider.

## Animation

- Tweened bars/donut/progress khi metric/data đổi.
- Counter tiền interpolate khi giá trị được cập nhật.
- Fade chuyển tab, platform route transitions; Material press/hover/focus, dialog và bottom sheet.
- AppMotion tắt duration khi hệ thống disable animations; không có loop animation trang trí.

## Visual review vòng đầu

Đã xem screenshots browser tại1440/768/390 và xem trực tiếp Login/Overview/AccountDetail/UsageForm mobile trong IAB.

1. Main question có câu trả lời: budget còn lại ở card mint; cost/token/session và missing coverage cùng data source.
2. Edge alignment: margin/panel padding thống nhất; sidebar chữ overflow ở test1440 đã sửa Flexible/Expanded. Summary columns đã cân lại height.
3. Color: emerald dùng cho primary series/progress/CTA; không gradient/glass/glow. Dùng mint/lavender vì giữ core Lab2.
4. Reconcile: account costs$5.68+$5.86+$1.30=$12.84; budget$50−$12.84=$37.16; token121k+141k+24k=286k. Không tính phiên thiếu thành0 có dữ liệu.
5. Zero/missing: bar value0 không có chiều cao giả; unknown được ghi rõ. Quota không biết/stale không được đọc thành còn 100%.
6. Legend/mapping: ring và legend từ cùng shares dataset; tap tới history có filter. Không có deltas tăng trưởng bịa.
7. Phone: sidebar thay bằng4-tab bar, form content scroll và footer ngoài keyboard area; helper/error cho multi-line sau khi thấy truncation.

Phần còn hạn chế: dashboard mobile cần cuộn để xem các block dưới; typography/text scaling2.0 chưa nghiệm thu mọi màn; chưa chụp từng màn ở cả360/412 để hoàn tất fidelity Lab3. Chưa có role-based admin; “quản trị” hiện là quản lý dữ liệu cá nhân local.

## Inspector của skill

Đã chạy source lint/real-browser inspector. Lint không hỗ trợ Dart. Inspector có1 FAIL `no-title` và1 WARN `hero-void`, vì canvas Flutter không cung cấp HTML text/h1 cho script DOM khi accessibility chưa bật. Ảnh vẫn render dashboard thật. Không thêm hidden HTML hoặc tắt check để báo pass. Kết quả DOM này không được dùng như bằng chứng fidelity/accessibility của Flutter; dùng widget tests + screenshot review.

Thư mục `assets/evidence/taste-inspect/` giữ report và ảnh. Preview local: `http://127.0.0.1:4183/?demo=1` sau khi chạy server theo README. Các ảnh là minh chứng scaffold, không thay thế Figma comparison và evidence Firebase/MobAI của bài nộp.

## Build/platform

Web release build thành công. `flutter doctor` báo thiếu Android SDK và Xcode chưa đầy đủ; không thay đổi cấu hình hệ thống hoặc cài Android Studio trong task này. Chưa tạo APK; Android source/manifest/launcher đã dựng. Firebase/cloud/export/provider API đồng bộ vẫn pending.

## Cập nhật tài liệu/agent và portability — 20/10/2026

Đã bổ sung `AGENTS.md`, `.agents/README.md`, project context/workflows, kiến trúc chi tiết, docs index và nguồn Lab2 dùng độc lập.20 PNG +3 text snapshots giữ nguyên nội dung/hash, đọc theo `docs/lab2-ui-reference.md` và provenance manifest. README không cần đường dẫn sibling Lab2 để chạy sau clone.

Repo đích `NhanHuynhThien/lab3_prm` được kiểm tra là private và trống trước publication; không thay visibility hoặc quyền truy cập. Không thay source Dart/runtime và không bắt đầu Firebase trong lượt docs/push. Kết quả verification mới ghi trong test-report; web release/ảnh inspector19/10 giữ nguyên mốc lịch sử.
