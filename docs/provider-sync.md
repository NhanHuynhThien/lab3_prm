# Phân tích công việc và thời gian — 22/10/2026

## Dữ liệu được hiển thị

- Lịch sử local 30 ngày: tổng token chính xác; input/output/cache đọc/cache ghi/reasoning khi log cung cấp; số phiên, công việc, ngày sử dụng.
- Mục đích 9 nhóm với tỷ trọng và drilldown vào công việc. Nhãn **suy luận bằng từ khóa**, không phải sự thật đã xác nhận về ý định. Khác khi thiếu hoặc hòa điểm. Không đặt tên công việc bằng nội dung chat.
- Mỗi công việc: mã hash phiên/công việc, model, token, mốc yêu cầu→token cuối và khoảng thời gian gồm chờ/nghỉ. Không gọi khoảng này là GPU time, thời gian model chạy hay năng suất làm việc.
- Theo ngày UTC với input/output; 7 ngày UTC gần nhất. Thời điểm công việc chuyển sang giờ thiết bị.
- Tối đa 60 công việc gần nhất trong payload; tổng/mục đích/ngày vẫn tính tất cả phần đã đọc. UI xem 10 mục/lần.
- Tiền đã thanh toán và tiền theo công việc giữ **chưa xác định** khi không có hóa đơn/đơn giá đã xác nhận. Không quy đổi quota% hoặc token trong thuê bao thành tiền đã trừ. Chi phí sổ thủ công hiển thị riêng, giữ đến 6 chữ số thập phân khi cần.

## Theo từng nguồn

| Nguồn | Có thể đọc | Giới hạn |
|---|---|---|
| Codex | Token per-response mới; fallback delta cumulative cũ; model; user request để phân loại trong RAM | Log có thể gồm nhiều tài khoản/subagents; không phải usage ChatGPT web. Per-response chống trùng response ID, bỏ inherited thread và không cộng cumulative mirror. Token bao gồm ngữ cảnh lặp/cache, không đồng nghĩa độ dài chat |
| Claude Code | Assistant usage dedupe message/model, input+cache read/write, output; user text để phân loại | Không suy quota hay invoice từ history; tool results không bắt đầu công việc |
| Gemini CLI | Token model/ngày và session hash từ lịch sử | Không suy mục đích hoặc mốc bắt đầu nếu định dạng chưa có; không đại diện web |
| Antigravity | Official `/usage`: nhóm Gemini và Claude/GPT, hai cửa sổ quota mỗi nhóm | Không có token/task/time/invoice IDE từ nguồn hiện tại; không biến quota thành token |
| Gemini web | Takeout: tần suất theo ngày | Không có token/chi phí/thời lượng từ count hoạt động |

## Biên dữ liệu và bảo mật

Companion chỉ bind loopback; token pairing và allowlist origin/host giữ nguyên. Không đọc credential/cookie/provider private endpoints, gọi model hay thay đổi account/billing. Phân loại chạy bằng regex local, không gửi prompt sang Gemini hay dịch vụ khác. Payload chỉ có nhãn enum, số, UTC, model allowlist và mã hash; không có prompt, path, tiêu đề chat hoặc raw session ID. Snapshot được giữ theo phiên owner trong RAM app, không upload provider history lên Firestore.

Giới hạn đọc: tối đa 500 JSONL, ưu tiên thư mục/tên mới; depth7, file16MiB (Gemini8MiB). Symlink bỏ qua. Tệp không đọc được/vượt giới hạn đánh dấu một phần. Tổng là phần đọc được; thiếu trường token giữ null, không đổi0. Old/new schema mixed hoặc context attribution không đủ không thể đảm bảo task taxonomy hoàn hảo; xem nhãn phương pháp. Dữ liệu local không xác minh cùng owner với Google login.

## Ghép nối và chạy companion

Node20+ chỉ cần cho companion, không cần để build Flutter.

```sh
node tool/provider_bridge/setup.mjs
node tool/provider_bridge/server.mjs
adb reverse tcp:8787 tcp:8787
```

Setup tạo mã pairing256bit tại `~/.local/share/tokenledger/bridge-token` (file600/thư mục700), giữ env local và thêm define dùng ghép nối. Không in token hoặc commit `.env.local`. Define có thể trích từ binary; companion chỉ dùng loopback, không public server hay release chia sẻ.

Build với `--dart-define-from-file=.env.local`; mở Kết nối nguồn AI, xác nhận đọc nguồn local rồi kết nối. Owner auto-connect chỉ opt-in/matching email đã cấu hình. Đổi define phải restart/rebuild. App refresh foreground60s, companion cache55s; disconnect/logout xóa snapshot phiên app.

- **Codex:** CLI trong PATH hoặc `TOKENLEDGER_CODEX_BIN`; đăng nhập qua luồng chính thức, không copy auth.json/token vào app. App Server chỉ gọi RPC đọc allowlist.
- **Claude Code:** setup tạo snippet `~/.local/share/tokenledger/claude-statusline-settings.json`. Merge statusLine với settings hiện có; không replace toàn file. Hook `tool/provider_bridge/claude.mjs` chỉ giữ numeric metrics. Lịch sử model/activity từ JSONL local, không invoice web.
- **Gemini CLI:** đọc lịch sử local của CLI đã dùng trên máy; chưa có history thì setup/unknown, không measured0.
- **Antigravity:** cần official `agy` CLI đã đăng nhập. Adapter chỉ chạy `/usage`, không gửi prompt, không tạo model turn. Nhóm quota không chứng minh đã dùng từng model.
- **Gemini web:** user tự xuất Takeout JSON và chọn file trong app; max8MiB/100K rows, dedupe và aggregate30 ngày trong isolate. Không persist nội dung chat hay tự lấy mail/cookie.

Chạy Android120Hz xem [firebase-setup](firebase-setup.md). Kiểm chứng adapter/UI và hiệu năng xem [test-report](test-report.md). Không upload local provider history lên Firestore; local logs có thể gồm nhiều tài khoản, không xác minh trùng Google owner.
