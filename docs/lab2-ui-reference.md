# Nguồn UI Lab 2 — bản tham chiếu dùng độc lập

Cập nhật ngày 20/10/2026. Bộ UI gốc: **StudentPay**, final09/10/2026, Figma page `03. Final UI`. TokenLedger đổi chức năng nhưng tiếp tục dùng core thiết kế này. Các snapshot trong repo giúp fresh clone không cần thư mục Lab2 cạnh bên.

## Nguồn và tính toàn vẹn

- [Figma gốc](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336).
- [Handoff nguyên bản](references/lab2/source-flutter-handoff.txt).
- [Design system cuối nguyên bản](references/lab2/source-design-system.txt).
- [Screen spec nguyên bản](references/lab2/source-screen-spec.txt).
- [Manifest nguồn và SHA-256](references/lab2/provenance.json):20 PNG cùng3 text snapshots, copy nguyên bản, không vẽ lại minh chứng lịch sử.

Text snapshots dùng `.txt` để bảo toàn nội dung gốc. Các đường dẫn tương đối bên trong chúng thuộc repo Lab2 lịch sử; dùng các link trong tài liệu này để điều hướng bản local. `DESIGN.md` ở root Lab2 là tài liệu Stitch lịch sử; không dùng nó thay bản `design/DESIGN.md` cuối.

## Mapping tám màn hình

| Lab2 final | TokenLedger | Ảnh gốc 360dp | Ảnh QA 412dp |
|---|---|---|---|
| Home | Dashboard | [01](../assets/design/lab2/01-home-360.png) | [01 QA](../assets/design/lab2/01-home-412.png) |
| Add expense | Usage form | [02](../assets/design/lab2/02-add-expense-360.png) | [02 QA](../assets/design/lab2/02-add-expense-412.png) |
| Category | Purpose picker | [03](../assets/design/lab2/03-category-360.png) | [03 QA](../assets/design/lab2/03-category-412.png) |
| Analytics | Usage analytics | [04](../assets/design/lab2/04-analytics-360.png) | [04 QA](../assets/design/lab2/04-analytics-412.png) |
| Transactions | Usage history | [05](../assets/design/lab2/05-transactions-360.png) | [05 QA](../assets/design/lab2/05-transactions-412.png) |
| Split bills | AI accounts | [06](../assets/design/lab2/06-split-bills-360.png) | [06 QA](../assets/design/lab2/06-split-bills-412.png) |
| Create bill | Account form | [07](../assets/design/lab2/07-create-bill-360.png) | [07 QA](../assets/design/lab2/07-create-bill-412.png) |
| Bill detail | Account detail | [08](../assets/design/lab2/08-bill-detail-360.png) | [08 QA](../assets/design/lab2/08-bill-detail-412.png) |

Tham chiếu thêm: [Empty](../assets/design/lab2/09-empty-analytics.png), [Error overlay](../assets/design/lab2/10-amount-error-overlay.png), [9 component families](../assets/design/lab2/11-components-nine-families.png), [Elevation](../assets/design/lab2/12-elevation-styles.png).

## Tokens phải tiếp tục giữ

| Vai trò | Token cuối |
|---|---|
| CTA / primary | `#006C49` |
| Accent | `#10B981`; không dùng tùy tiện làm nền chữ trắng nhỏ |
| Canvas / surface | `#FAF8FF` / `#FFFFFF` |
| Text / muted | `#131B2E` / `#52625C` |
| Border / mint summary | `#73867A` / `#E8F7EF` |
| Danger / error surface | `#BA1A1A` / `#FFDAD6` |
| Typography | Inter 28/36,24/32,18/26,16/24,14/20 |
| Spacing |4/8/12/16/24/32dp |
| Radius | Card20, input/button12 |
| Touch / CTA | >=48×48dp / cao52dp |
| Canvas QA |360×800,412×800; padding16, content328/380 |

Code hiện hành ở `lib/theme/app_theme.dart`; dashboard thêm frame/divider/chart-neutral tokens có giải thích trong design log. Desktop sidebar là extension; mobile giữ 4 destinations theo Lab2.

## Phần cố ý thay đổi

Nghiệp vụ chia tiền được thay bằng accounts/usage/purposes/budgets/quota. Logo TokenLedger là thiết kế mới; không thay hình nguồn Lab2. Android dùng system bars/SafeArea, không vẽ Dynamic Island iPhone.

Xem [design change log](design-change-log.md) và [handoff gaps](handoff-gaps.md). Live Figma annotation và sự chấp thuận đổi chủ đề từ giảng viên chưa có evidence; không ghi là đã hoàn tất.
