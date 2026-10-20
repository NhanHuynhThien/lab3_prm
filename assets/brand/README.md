# TokenLedger logo source

`tokenledger-mark.svg` là vector gốc: hexagon token, nét T và nhánh L gợi ledger. Màu primary#006C49, trắng và nhánh mint#A6E9C8.

UI vẽ bằng `lib/widgets/brand_mark.dart`, không load SVG/PNG từ asset bundle. Giữ SVG để chỉnh geometry nhất quán với painter.

Launcher icons cần cho platform nằm tại:

- `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- `web/favicon.png` và `web/icons/`.

Bản PNG1024 xuất rời đã bỏ vì không dùng trong app. Không ép méo logo hoặc trình bày nó thành logo chính thức của nhà cung cấp AI. Font license giữ tại `assets/fonts/OFL.txt`.
