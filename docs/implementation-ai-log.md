# AI implementation log — dữ liệu thật của phiên làm việc

Ngày 19/10/2026. Tool: Codex; shell/Flutter/Dart; cua_repl IAB; local taste-skill draw/lint/inspect. Không gọi AI provider để phân tích usage trong app. Không có subagent, Firebase console, MobAI hoặc AI PR review trong lượt này.

## Entry1 — phạm vi đổi nghiệp vụ

Prompt người dùng nguyên văn:

> Bạn có thể build hơn nhưng do mình đổi chủ đề về quản lí token nên chức năng cũng sẽ có sự thay đổi nha

Output: mapping StudentPay → TokenLedger, accounts/usage/purpose/quota thay expense/bill; P0/P1/P2 và checklist triển khai.

Verification: đọc đủ17 trang PDF; đối chiếu final design tokens/handoff/screenspec Lab2 và các ảnh final. Decision: accepted về hướng nghiệp vụ; lecturer acceptance/live Figma annotations vẫn pending.

## Entry2 — scaffold và logo

Prompt người dùng nguyên văn:

> Build và dựng khug sườn cho mình. Mình cho phép bạn DESIGN LOGO app luôn. FireBase thì pending lại

Output: Flutter Android/web, MVVM+Riverpod, local repository/seed/calculator, UI và CRUD local; logo vector T/L token hexagon + PNG/launcher/PWA.

Verification: analyzer, calculator/VM/widget tests, web release build, mở app trên browser; source/code đọc và sửa qua các lượt tool. Decision: modified: không giả Auth/Firebase, dùng demo entry ghi rõ local persistence, để integration contract và backlog backend.

## Entry3 — taste-skill, animation và dashboard

Prompt người dùng nguyên văn:

> 1. Cài thêm npx skills add Leonxlnx/taste-skill để làm đẹp UI
> 2. Bổ sung thêm animation và nâng cấp dashoboard quản trị cho mình luôn nha

Output: cài 13 skills vào project, app-screen draw framed-sheet seed1978369971; sidebar desktop/4-tab mobile, chart/progress/amount/tab/route animation và visual review.

Verification: đã đọc app-screen workflow; chạy draw/lint/inspect. Dart không được source linter hỗ trợ; inspector CanvasKit có no-title/hero-void DOM limitations, không báo pass giả. Đọc ảnh desktop/tablet/mobile và sửa layout/helper text/zero bars.

Decision: modified: giữ màu/Inter/radius/component Lab2 thay vì thay trọn token palette theo skill. Không dùng fake financial metrics hoặc role-based admin chưa có backend.

## Entry4 — cập nhật tài liệu/agent và publication

Prompt người dùng nguyên văn:

> cập nhật .md và .agent chi tiết sau đó push vào repo này cho mình
> [https://github.com/NhanHuynhThien/lab3_prm.git](https://github.com/NhanHuynhThien/lab3_prm.git)

Ngày 20/10/2026. Output: README/docs index/architecture/portable Lab2 references; AGENTS.md và `.agents/` context/workflows; chuẩn bị initial source publication. Không chỉnh vendor skills và không bắt đầu Firebase.

Verification: đọc code thực tế, kiểm tra remote private/empty, kiểm tra links/provenance/ignore/secret patterns, chạy format/analyzer/tests theo report 20/10. Remote commit phải đối chiếu bằng Git trước khi báo push thành công; không ghi SHA tưởng tượng trong log.

Decision: accepted. Giữ private visibility và lịch sử commit thật; phần Firebase/MobAI/Android/PR review vẫn pending.

## Trạng thái theo rubric

Mới có 4 prompt nguồn thực; chưa đủ tối thiểu 6 entry của bài nộp. Các lượt tiếp theo (Firebase/rules/PDF/tests/review) phải ghi prompt thực và verification tại lúc thực hiện. Không chia nhỏ một prompt thành các prompt tưởng tượng để đủ số lượng.
