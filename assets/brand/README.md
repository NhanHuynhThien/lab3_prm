# TokenLedger identity

Logo được thiết kế riêng cho app: đường viền lục giác gợi token, nét T và nhánh L bên trong gợi sổ ghi nhận. Cùng biểu tượng dùng cho app header, login, launcher và favicon.

- `tokenledger-mark.svg`: vector gốc, viewBox100×100, nền primary#006C49, nét trắng, nhánh L mint#A6E9C8.
- `tokenledger-icon-1024.png`: PNG1024px dùng cho preview và export.
- `lib/widgets/brand_mark.dart`: CustomPainter vẽ cùng geometry, không phụ thuộc mạng hay SVG plugin.
- Android launcher: `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Web/PWA: `web/favicon.png`, `web/icons/`; maskable icons có safe perimeter.

Giữ tỷ lệ1:1, khoảng trống quanh mark ít nhất12% chiều rộng. Không thêm gradient/shadow, không ép méo, không dùng logo TokenLedger làm logo chính thức của Claude/OpenAI/Google. Provider avatar trong app chỉ là chữ viết tắt trung tính.

Thiết kế này là code-native vector gốc, không dùng ảnh sinh AI hay hình của nhà cung cấp. Inter đi kèm giấy phép OFL trong `assets/fonts/OFL.txt`.
