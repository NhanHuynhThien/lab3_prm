# Test report — 22/10/2026

Chuẩn [Lab3 PDF17trang](ASSIGNMENT_REQUIREMENTS.md). Phân biệt unit/widget, build, native SDK và console/MobAI evidence. Repo chưa đạt mọi gate; xem [requirements audit](requirements-audit.md).

## 1. Verification vừa chạy

| Kiểm tra | Kết quả |
|---|---|
| `flutter test` | **391 passed**, 33s; sau chỉnh icon/header/bảng token |
| `node --test tool/provider_bridge/*.test.mjs` | **26 passed** |
| `flutter analyze` | **No issues found** |
| Dart format | Đã format source/test thay đổi |
| Line limit | Toàn bộ Dart lib/test ≤300 dòng tại lần kiểm |
| Android profile APK | **Build pass**,42s; đã cài bằng `adb install -r` và mở Lab3 |
| Web release | **Build pass**,27.5s |

Logs local `/tmp/tokenledger-{flutter-tests,node-tests,analyze,apk-build,web-build}.log`; không phải artifacts được clone hay screenshot Console. Build có warnings Kotlin future migration/Cupertino font reference; không có lỗi build. Chưa claim production signing hoặc release delivery.

Coverage regression: auth/UID isolation, Firestore repository/mutations/receipts, validation/draft/Retry, models/calculators/periods/null-vs-zero, quota stale, provider schemas/allowlists/dedupe, AI activity purpose/time/cache, Antigravity groups, Gemini import, responsive360/412/1440/text1/2, reduced motion và report owner lifecycle.

Đã bắt lỗi overflow ở text2 sau nâng chi tiết USD/thống kê và sửa responsive layout. Node kiểm new Codex per-response không cộng cumulative mirror/inherited thread, metadata user request, cache subset, missing metrics, 30-day bounds, 60task cap và không lộ prompt/raw session ID.

## 2. Môi trường native và phạm vi

Pixel10Pro AVD `TokenLedger_Pixel_10_Pro_120Hz`, Android36 Google APIs ARM64,1280×2856/density480 (~426.7dp), host GPU/Metal. `dumpsys display` xác nhận fps/vsync/renderFrameRate120; font_scale1.0. AVD cũ archive ngoài active list. Profile mode, bridge127.0.0.1:8787 qua ADB reverse.

User cho phép ADB/UIAutomator và Google login bằng tài khoản cá nhân để QA, không thao tác Gmail/credential/billing/security. Chỉ tạo/sửa dữ liệu QA: account `QA_20261022_FLOW`, usage `QA_usage_updated_20261022`, input1000/output500,cost0.001234USD,purposeKiểmthử. Không sửa dữ liệu khác của user. Đây chưa thay dedicated MobAI account yêu cầu trong đề.

## Kết quả đã quan sát

| ID | Flow/màn | Kết quả |
|---|---|---|
| N01 | Signed-out Login | Pass: chỉ Google login; logo/composition mới, không demo entry |
| N02 | Google native picker→workspace | Pass: chọn tài khoản user, auth thành công,4tabs hiện |
| N03 | Auto-connect sources | Pass:2sources ready (Codex+Antigravity),unknownsources không giả0 |
| N04 | Ghi sử dụng khi0account | Pass: empty explanation + thêmaccount action |
| N05 | AccountForm empty validation | Pass: tên rỗng bị chặn, không write |
| N06 | DirtyBack→Tiếp tục sửa | Pass: cảnh báo, tênQA được giữ |
| N07 | Tạo account từ usageempty | Pass: Firestore success; quay lạiUsageForm với accountQA chọn sẵn |
| N08 | Purpose picker | Pass:9mục, chọnKiểmthử quaylạiform đúng |
| N09 | Token một vế | Chặn đúng; **UXfail** lỗi nằm dướifold. Đã chuyển persistentfootererror, cần native retest bản mới |
| N10 | Save usage known metrics | Pass: successFirestore; history có1session/1500token |
| N11 | Detail/read | Input1000/output500/date/purpose đúng. **UXprecisionfail**0.001234USD hiển thị$0.00; đã dùngpreciseMoney, native retestpending |
| N12 | Update usage | Pass: form reload giữ0.001234 và1000/500, lưu tên mới đúng; detail cập nhật |
| N13 | Cold restart/reload data | Pass: user re-login trên Pixel10Pro; accountQA và usage1500tokens vẫn có từ Firestore |
| N14 | Analytics→purpose/provider/account filteredhistory | Pending |
| N15 | Accountdetail/edit/archive/restore/guard/deleteempty | Pending |
| N16 | Quota create/edit/delete/resetstale | Pending |
| N17 | Profile identity/logout/login/stateisolation | Pending |
| N18 | Notifications | Pass mở empty center từ chuông thanh đầu trang. Permission/push/tap routing/background chưa kiểm đủ |
| N19 | RC effective/defaults/refresh/liveconsolechange | Pending |
| N20 | PDF period/localopen/uploadfailure/recovery/metadata | Pending; storage+metadata gaps |
| N21 | Gemini/Claude setup/errors/import picker | Pending; không dùng realchatfile nếu user chưa chọn |
| N22 |360/412dp,text2,keyboard,Back,scroll | Pending native; widgetmatrix pass riêng |
| N23 | Antigravity nhómmodel/cửa sổ/limitedanalysis | Đã bổ sung groupmetadata + riêng panel4windows, chờ native bảnmới |
| N24 | Logout→Login và re-login reload | Pending cuối lượt; không xóa Googleaccount thiết bị |

### Native mới đã quan sát

- Tổng quan căn giữa; logo ChatGPT/Codex cùng hàng tên; chuông cạnh lịch sử trên topbar, nút ghi usage nằm dưới tiêu đề. Screenshot native đã xem.
- Phân tích Codex nhận log thật: exact input/output/cache/reasoning, purpose distribution, daily stats; không đổi unknown cost thành0. Mở **Xem từng công việc và thời lượng** đến màn chi tiết; có model, mã hash, start/end, elapsed và giới hạn tính thời gian.
- Header/picker dùng logo bundle; Notification Center empty mở/Back đúng. 60 công việc gần nhất, thông báo số omitted và phân bổ vẫn từ toàn bộ phần log đọc được.
- Bảng token vừa sửa căn trái/giá trị rõ và summary icon cạnh con số đã build/cài; native ảnh sau lần cài cuối chưa chụp lại. Không gán screenshot phiên bản trước cho bản cuối.

Ảnh QA nằm trong `/tmp/tokenledger-native-qa/` có thể chứa email/usage; không tự publish vào assets/Git. Helper UIAutomator ban đầu clear field bằngCtrl+A không đúng, đã đổiMOVE_END+DEL và sửa tên QA; đó không phải bug input của app.

## 3. Hiệu năng đã đo

- AVD cũ SwiftShader CPU:166frames,budget16.67ms,buildP959.534ms,rasterP9557.002ms,158overbudget; có startup, không benchmark đồng nhất.
- Host Metal trên AVD cũ:205frames,buildP95.921ms,rasterP954.835ms,1overbudget.
- Pixel10Pro120Hz mẫu warm:610frames,budget8.33ms,buildP95.682ms,rasterP957.478ms,21overbudget. Mẫu mới sau thêm analytics:208frames,buildP95.692ms,rasterP958.318ms,9overbudget; một số mẫu route/scroll nhỏ cóP95>8.33ms.

Đã giảm bottleneck SwiftShader; **không khẳng định hoàn toàn không giật hoặc mọi frame120FPS**. FrameAuditService chỉ bật profile với `UI_PERFORMANCE_AUDIT=true`, không PII/network. Motion giảm/lazy tabs/TickerMode/chart timing xem design log.

## 4. Evidence còn thiếu

Native CRUD/quota/archive/restore/delete/Back/offline và logout/isolation đủ từng flow;360/412dp/text2/IME/TalkBack thực tế; PDF upload+URL+Firestore metadata; FCM foreground/background/tap; live RC before-after; handled/fatal Crash dashboard; Analytics DebugView đúng event contract.

10MobAI scripts/run trên dedicated account, healing và real bug-catching chưa có. AI local review không thay feature PR review. Final fidelity đối chiếu cùng360×800, report5–10trang/video3–5phút còn thiếu.

Các manual web checks ngày21/10 do **user báo** gồm CRUD/budget/totals/purpose/unknown/validation/Back/archive/quota/reload/A-B/offline. Không chuyển thành agent-controlled native hoặc Console evidence.

## 5. Cleanup trước push —22/10/2026

`flutter clean` đã dọn artifacts và `flutter pub get` resolve lại. Format dry-run0changed; analyzer sạch2.4s; Node26/26pass; Dart lib/test≤300lines; git diff --check và doc links sạch. Quét280Git candidates không phát hiện các mẫu private/provider/Bearer/OAuth secrets và không có file>5MiB; `.env.local` không track. Đây là pattern scan, không khẳng định kiểm toán toàn bộ lịch sửGit.

Không chạy lại Flutter suite/native build trong cleanup config/comment/docs;391Flutter và các build ở mục1 thuộc checkpoint runtime trước cleanup. Cache build đã dọn nên APK/web phải build lại khi cần xuất binary mới.
