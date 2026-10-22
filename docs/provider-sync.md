# Đồng bộ provider: Codex, Claude, Google AI

Verification lượt UI:355/355 Flutter tests26s,12/12 Node tests pass,
analyzer sạch2.5s,154files format0changed, tất cả Dart<=300lines.
APK debug9.3s/web release18.3s build pass; APK install/start thành công.
Log chính Android PID5269 xác nhận `Provider sync: 1 ready sources; 6 model rows.`
Google session đã restore và owner auto-connect hoạt động thật trên emulator;
không coi log này là nghiệm thu mọi màn hình, Claude/Gemini/Antigravity/invoice.
Ảnh render QA với snapshot Codex thật đã xem ở412 text1 và360 text2;
6 cấu hình360/412/1440 text1/2 pass. Xem docs/provider-sync.md.


## Auto-connect cho bản local đã được owner cho phép

Sau khi owner xác nhận nguồn trên Mac thuộc cùng email Google, có thể đặt
PROVIDER_BRIDGE_OWNER_EMAIL trong .env.local JSON thành email đó. Build với
--dart-define-from-file=.env.local. App chỉ auto-connect khi email Firebase
khớp (không phân biệt hoa/thường) và mã ghép nối hợp lệ. Để trống flag trong
.env.example nên fresh clone vẫn ghép nối thủ công. Flag này là cấu hình cài
local đã được chủ máy đồng ý, không phải tính năng tự phát hiện subscription
qua Google OAuth. Không phân phối APK chứa pairing token của máy cá nhân.

Snapshot vẫn chỉ ở RAM/session; đổi UID hoặc logout xóa state. Ngắt kết nối
không tự bật lại trong cùng phiên; lần mở app mới với opt-in sẽ kết nối lại.
Tổng quan/Tài khoản/Phân tích hiện nguồn AI trước sổ ghi tay; nguồn AI còn hiển
thị khi Firestore đọc lỗi. Bộ chọn Antigravity chỉ thể hiện chưa hỗ trợ.
Nguồn hiện có vẫn là Codex App Server, Claude Code statusline, Gemini CLI.
Chưa có đồng bộ Antigravity hoặc Gemini web trong bản UI này.


Thiết kế 21/10/2026, trước triển khai. Người dùng yêu cầu đồng bộ và dùng cả
desktop/CLI/web. Đây là extension local ngoài core Flutter/Firebase của Lab3;
không thay Firebase config/rules/billing hoặc coi đây là backend Final.

## Phạm vi có nguồn kiểm chứng

| Provider | Nguồn tự động | Phạm vi/giới hạn |
|---|---|---|
| Codex | App Server `account/read`, `account/rateLimits/read`, `account/usage/read` | Tài khoản CLI đã đăng nhập trên máy; quota account, tokens theo summary server khi hỗ trợ; không suy tiền từ quota |
| Claude | Status line chính thức của Claude Code gửi JSON qua stdin | Quota5h/7d khi SDK cấp, context tokens hiện tại, estimated API-equivalent session cost; không phải invoice hoặc tổng token web |
| Google AI | Gemini CLI recorded sessions `tokens` | Token các phiên CLI lưu trên máy, 30 ngày; không chứng minh đang có AI Pro, không bao gồm Gemini website/AI Studio/Antigravity |

Không có nguồn public đã xác minh trong lượt này để tự đọc toàn bộ hóa đơn,
quota và usage Gemini web/Google AI Pro bằng Google Sign-In. Không tự tạo cookie
scraper/private API, gửi password hoặc dùng API key để giả làm subscription.

Nguồn: [Codex App Server](https://developers.openai.com/codex/app-server/),
[Claude status line](https://code.claude.com/docs/en/statusline),
[Gemini recording schema](https://github.com/google-gemini/gemini-cli/blob/main/packages/core/src/services/chatRecordingTypes.ts),
[Google AI plans](https://ai.google.dev/gemini-api/docs/google-ai-plans).

## Luồng

1. Chạy companion Node local; bind127.0.0.1, pairing token ngẫu nhiên, chỉ GET
   snapshot sau Bearer auth, CORS allowlist localhost:4183. Không public/LAN.
2. App mở màn Kết nối nguồn, xác nhận dữ liệu của CLI/máy được chọn rồi pair.
   Token pairing chỉ giữ RAM của workspace; sign-out/đổi UID/disconnect hủy timer,
   state và token. Không ghi provider secret hoặc dữ liệu vào Firestore.
3. Snapshot thay thế theo provider, không append vào manual ledger. Mỗi nguồn
   có status/observedAt/coverage; refresh60s khi foreground, single-flight,
   timeout và last-good khi mất kết nối. Quota quá reset hoặc quá15m là stale.
4. Dashboard hiển thị section dữ liệu đồng bộ riêng. Không trộn subtotal này
   vào manual records hoặc gọi estimate là phí đã charge. Unknown giữ null.
5. Nếu thiếu CLI/hook/history thì provider hiện cách nối nguồn; Google không
   tự mang nhãn Pro chỉ vì cùng email. Quota không cộng giữa buckets/providers.

Companion không gọi model, tạo conversation, mua credit hoặc đổi tài khoản.
Codex dùng CLI tự quản lý auth; không đọc/in auth.json/keychain/secret.
Claude hook chỉ persist allowlist numeric metrics, không raw stdin/prompts.
Gemini reader bỏ prompts/tool outputs, symlinks và giới hạn size/file count.

## Checklist triển khai

- [x] Companion bearer/CORS/Host checks, timeouts, cache và read-only sources.
- [x] Codex adapter thực qua App Server; test id matching/errors/cleanup.
- [x] Claude adapter/hook allowlist, stale/absent quota, estimate semantics.
- [x] Gemini reader JSON/JSONL, update/dedupe, 30-day coverage, missing source.
- [x] Flutter typed parser/HTTP service/scoped VM, lifecycle/last-good/disconnect.
- [x] Screen pair/refresh/provider cards + dashboard entry, giữ Lab2.
- [x] Tests Node + Flutter, analyzer, build Android/web; không claim fake
  fixtures là account người dùng hoặc đồng bộ đủ website.

Live acceptance cần nguồn Claude Code/Gemini CLI chưa có trên máy hiện tại;
không cài/chuyển tài khoản provider hoặc overwrite status line cũ tự động.

## Thiết lập và sử dụng

Node20+ chỉ cần cho companion phát triển trên máy, không cần để build Flutter.
Chạy từ root repo:

```sh
node tool/provider_bridge/setup.mjs
node tool/provider_bridge/server.mjs
```

Lệnh setup giữ các biến env cũ, thêm `PROVIDER_BRIDGE_TOKEN` vào `.env.local`
được ignore, tạo pairing token256bit trong thư mục user chmod700/file600.
Token này chỉ ghép dịch vụ loopback, không phải OAuth/API key. Define được nhúng
vào bản app nên không dùng cho server công khai hoặc release chia sẻ. Release
chưa hỗ trợ HTTP companion; Android debug chỉ cho cleartext localhost/127.0.0.1.

Giữ terminal companion mở. Terminal khác:

```sh
flutter run -d web-server --web-hostname localhost --web-port 4183 --dart-define-from-file=.env.local
```

Đăng nhập Google → Tổng quan/Tài khoản → **Kết nối và xem số liệu**. Xác nhận
muốn đọc tài khoản CLI của máy rồi **Kết nối nguồn trên máy**. Mã đã có sẵn
nếu build với env local; nếu không, dán từ file
`~/.local/share/tokenledger/bridge-token`. Mặc định snapshot có đủ3 nguồn:
ChatGPT/Codex, Claude và Gemini; không cần thêm account nhập tay để xem chúng.
Tự refresh60s khi foreground; **Cập nhật ngay** có cache tối đa55s ở companion.
Đổi env phải rebuild/restart, hot reload không thay compile-time defines.

Android Emulator trên cùng Mac:

```sh
adb reverse tcp:8787 tcp:8787
flutter run -d emulator-5554 --dart-define-from-file=.env.local
```

### Codex

Companion dùng `codex` trong PATH hoặc `TOKENLEDGER_CODEX_BIN` trỏ tới CLI.
Đăng nhập CLI qua luồng chính thức của Codex nếu chưa có session. Không copy
auth.json/access token vào app. Snapshot thực đã đọc trên máy21/10: plan nguồn
trả `team`,2 quota windows, lifetime tokens và6 tên model trong local history.
Chỉ ghi metadata tổng quát làm evidence; không đưa logs/identity người dùng lên Git.

### Claude

`setup.mjs` tạo snippet sẵn tại
`~/.local/share/tokenledger/claude-statusline-settings.json`. Với Claude Code
đã cài, merge trường `statusLine` từ snippet vào `~/.claude/settings.json` hoặc
project settings. Không replace toàn settings; nếu đã có statusLine, giữ hoặc
chủ động kết hợp script hiện tại. Hook chạy
`tool/provider_bridge/claude.mjs`, chỉ giữ numeric metrics trong file local,
không lưu prompt/transcript/credential. Phiên Claude mới sẽ cập nhật nguồn.
Nếu phiên bản Code không có rate_limits thì quota vẫn unknown.

Model usage được đọc riêng từ assistant usage records trong
`~/.claude/projects/**/*.jsonl`: dedupe message ID, cộng fresh/cache input và
output. Status line báo **input context hiện tại**, không phải lifetime tokens.
Estimated session cost không gán hết cho model đang chọn khi đã đổi model.
Claude website/desktop không tự có dữ liệu nếu không cung cấp nguồn Code tương ứng.

### Gemini / Google AI Pro

Dùng Gemini CLI chính thức với tài khoản phù hợp để có session recordings ở
`~/.gemini/tmp/**/chats/session-*.json{,l}`. Reader hiểu legacy JSON và JSONL
append/update/rewind, lấy token/model trong30ngày. Không đọc oauth_creds.json,
cookies hoặc prompts để gửi đi. Không gắn nhãn AI Pro nếu nguồn chưa xác nhận.
Quota/hoá đơn AI Pro và toàn bộ usage Gemini website vẫn chưa có adapter public
được kiểm chứng trong lượt này; UI hiện unknown thay vì lấy quota API để thay thế.

## Ý nghĩa bảng model và số tiền

- Mặc định3 provider đều được truy vấn. Nguồn thiếu credentials/history/hook
  vẫn xuất hiện với hướng dẫn, không sinh số liệu mẫu.
- Model history là30ngày trên máy, có thể gồm nhiều tài khoản đã từng dùng.
  Không chứng minh cùng chủ sở hữu với Google login hoặc tài khoản CLI hiện tại.
- Codex model counters dùng chênh lệch cumulative token_count sau turn_context;
  không cộng lại event lặp. Cache input là thành phần đã nằm trong input Codex.
- CLI total/lifetime/account quota/model history khác coverage, không cộng chúng.
- Bảng model hiện số token nguyên chính xác. Thiếu model thì không suy từ tên gói.
  Giá tiền/model không có nguồn vẫn null; không dùng bảng giá API để giả invoice.
- Nguồn local bị giới hạn500files/provider,16MiB/file Codex/Claude và8MiB/file
  Gemini; coverage báo partial khi vượt. Không đọc symlink hoặc credentials.
- Đổi UID/logout dispose workspace: hủy timer/token/state. Muốn xem trên UID
  khác phải ghép lại có xác nhận. Không tự persist lên Firebase hoặc upload
  model history vào Analytics.

## Verification

Node tests:

```sh
node --test tool/provider_bridge/bridge.test.mjs
flutter test test/provider_sync_test.dart test/provider_sync_ui_test.dart
```

Tests dùng fixtures rõ ràng; chỉ lần đọc Codex CLI thực được ghi là live evidence.
Claude/Gemini hiện chưa có nguồn trên Mac; chưa claim nghiệm thu đồng bộ web,
invoice, background phone hoặc cloud cross-device.

Kết quả cuối21/10: **346/346 Flutter tests**, **12/12 Node tests**; analyzer sạch,
147files lib/test format0changed và<=300dòng. Android debug APK build11.6s,
web release20.6s. Dart HTTP service đã đọc snapshot thật từ companion:
Codex ready/6model/2quota windows; Claude/Gemini setup. APK mới đã cài trên
AVD, adb reverse8787 đã nối. Android Studio mở lại đúng project và Run main.dart
đã có `--dart-define-from-file=.env.local` trong cấu hình IDE local (ignored).
Không có OAuth/invoice/manual native provider acceptance mới từ các checks này.
