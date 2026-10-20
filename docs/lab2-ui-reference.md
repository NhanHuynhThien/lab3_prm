# Nguồn thiết kế Lab2

TokenLedger dùng core UI StudentPay Lab2, chuyển nghiệp vụ từ expense/bills sang AI accounts/usage/purpose/quota. Bản ảnh/tài liệu Lab2 copy vào repo trước đây đã được bỏ khỏi Git để source tree tập trung vào Flutter. Dự án vẫn chạy độc lập; runtime không đọc file Lab2.

[Figma gốc](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336). Source thiết kế trong workspace gốc là `lab2_prm/design/DESIGN.md` và `lab2_prm/handoff/flutter-handoff.md`; các đường dẫn này chỉ là provenance, không phải dependency runtime hoặc link trong repo hiện tại.

## Mapping thiết kế → source hiện tại

| Màn Lab2 | Màn TokenLedger | Source |
|---|---|---|
| Home | Dashboard | `lib/screens/dashboard_screen.dart` |
| Add expense | Usage form | `lib/screens/usage_form_screen.dart` |
| Category | Purpose picker | `lib/screens/purpose_screen.dart` |
| Analytics | Usage analytics | `lib/screens/analytics_screen.dart` |
| Transactions | History/detail sheet | `lib/screens/history_screen.dart` |
| Split bills | AI accounts | `lib/screens/accounts_screen.dart` |
| Create bill | Account form | `lib/screens/account_form_screen.dart` |
| Bill detail | Account detail | `lib/screens/account_detail_screen.dart` |

## Tokens hiện dùng

`lib/theme/app_theme.dart` là implementation hiện hành:

- Primary `#006C49`, accent `#10B981`.
- Canvas/surface `#FAF8FF` / `#FFFFFF`.
- Text/muted `#131B2E` / `#52625C`.
- Mint summary `#E8F7EF`, border `#73867A`, danger `#BA1A1A`.
- Inter:28/36,24/32,18/26,16/24,14/20.
- Spacing4/8/12/16/24/32; card radius20, control12; touch48dp, CTA52dp.
- Mobile4 destinations; desktop sidebar là extension theo yêu cầu.

Logo TokenLedger dùng source SVG và `BrandMark` painter; provider avatars là chữ viết tắt. Android dùng system bars/SafeArea, không vẽ chrome iPhone.

Live Figma annotation và full fidelity screenshots vẫn pending. Xem [design change log](design-change-log.md); không suy việc giữ token thành đã hoàn tất fidelity Lab3.
