# Tài nguyên TokenLedger

Nguồn logo, biểu tượng và quy tắc sử dụng tài nguyên. Giấy phép font tại [OFL.txt](fonts/OFL.txt).

## TokenLedger logo source

`tokenledger-mark.svg` là vector gốc: hexagon token, nét T và nhánh L gợi ledger. Màu primary#006C49, trắng và nhánh mint#A6E9C8.

UI vẽ bằng `lib/widgets/brand_mark.dart`, không load SVG/PNG từ asset bundle. Giữ SVG để chỉnh geometry nhất quán với painter.

Launcher icons cần cho platform nằm tại:

- `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- `web/favicon.png` và `web/icons/`.

Bản PNG1024 xuất rời đã bỏ vì không dùng trong app. Không ép méo logo hoặc trình bày nó thành logo chính thức của nhà cung cấp AI. Font license giữ tại `assets/fonts/OFL.txt`.

### Audit B13 —21/10/2026

Geometry chuẩn là viewBox100×100, nền radius26, hexagon `(50,18) → (77,34) → (77,66) → (50,82) → (23,66) → (23,34)`, stroke5 đầu/nối tròn, nét T `(36,39) → (64,39)` và `(50,39) → (50,65)`, nhánh mint `(50,65) → (64,57)`. SVG và Flutter painter đã được đối chiếu bằng contract/raster tests. Không thay logo hoặc sinh lại icons trong lượt này vì các assets hiện có khớp geometry.

`test/brand_audit_test.dart` kiểm SVG, các điểm glyph painter, toàn bộ5 Android densities, favicon, PWA192/512, tên app và maskable variants. PNG so với painter resize theo cùng kích thước, có dung sai antialias/resampling (mean error<8/255 cho premultiplied RGB); không gọi là pixel-identical. Maskable dùng glyph khoảng78% đặt giữa nền primary đặc, giữ phần glyph trong safe circle40% cạnh; shape không bị ép méo.

ProviderAvatar chỉ là grapheme đầu của tên sản phẩm (hỗ trợ emoji ghép), có semantics nói rõ là chữ viết tắt, không phải logo chính thức. BrandMark riêng có label `Logo TokenLedger`.

## Google sign-in asset

`google-g.png` is the official full-color Google G downloaded on 2026-10-21
from https://developers.google.com/static/identity/images/g-logo.png.

Use only to identify Google Sign-In, with a white button, readable action label,
fixed aspect ratio, and no recoloring. Do not incorporate it into TokenLedger's
app logo. Source and branding guidance:
https://developers.google.com/identity/branding-guidelines.

The app retains Lab2's bundled Inter font and 12dp control corners. This is a
custom Flutter button with an official icon, not a Google-rendered SDK button.

## Provider marks

Provider marks identify the corresponding source. TokenLedger is an independent
student project; these marks do not imply endorsement. Assets retain original colors. OpenAI light-mode CSS fill is inlined for the Flutter SVG renderer; path geometry is unchanged.

- OpenAI: https://cdn.oaistatic.com/assets/favicon-l4nq08hd.svg
- Claude: https://assets.claude.com/95a868946ac8a31e5ff832e2899f294aa368b836.png
- Gemini: https://www.gstatic.com/lamda/images/gemini_sparkle_4g_512_lt_f94943af3be039176192d.png
- Antigravity: installed official Antigravity IDE app, Resources/app/out/media/jetski-logo-black.svg.

Retrieved 22 October 2026. Bundled locally for offline UI; no runtime requests.
