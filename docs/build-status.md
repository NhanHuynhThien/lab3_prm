# Build status — source hiện hành

Cập nhật20/10/2026. Implementation Flutter/Dart local demo; Firebase tiếp tục pending theo yêu cầu.

## Đã có trong code

-25 Dart source files,3 test files;12 screen files và usage-detail sheet.
- MVVM/Riverpod, local repository/seed/calculator, reporting projections tách khỏi Views.
- Account CRUD/archive/restore, usage CRUD, quota update, analytics và history filters.
- Desktop sidebar, mobile4 tab, IndexedStack giữ state và animation hỗ trợ reduced motion.
- SharedPreferences JSON schemaVersion1; cost integer USD micros; missing token/cost giữ null.
- Seed3 accounts/12 sessions: cost$12.84, token286k,1 phiên thiếu cost/token. Đây là dữ liệu giả định.
- SVG logo/Flutter painter, font Inter và native/web launcher icons.

## Dọn repo20/10

Đã loại khỏi Git: vendor skill files, skill draw cache/lock local, ảnh Lab2 copy, text snapshots, PDF đề bài, ảnh/log inspector và bản logo PNG1024 xuất dư. Giữ bộ skill đã cài ở local, bỏ qua bằng `.gitignore`.

`pubspec.yaml` chỉ bundle font Inter; logo trong UI do Flutter painter vẽ. Source SVG giữ để chỉnh thiết kế, launcher PNG nằm trong `android/` và `web/`.

Hướng dẫn chạy dùng Flutter CLI. Build/cache sinh local không đưa lên GitHub. Không thay chức năng app hoặc bắt đầu Firebase ở lượt cleanup.

## Chưa hoàn tất

Google Auth/Firestore/rules/FCM/RC/Crash/Analytics/PDF cloud, provider sync, MobAI, AI PR review, Figma fidelity đầy đủ và Android build/device testing.

Android SDK chưa có ở lần doctor trước; web build không thay thế APK. Xem [test report](test-report.md) cho verification hiện hành, [architecture](architecture.md) cho source boundaries và [Firebase pending](firebase-pending.md) cho việc tiếp theo.
