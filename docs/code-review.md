# Code review — Codex,22/10/2026

**Local source review, chưa phải PR review evidence hoàn chỉnh theo PDF §11,tr11.** Tool: Codex trong chat này; base main `0dee633` + working tree22/10. Không tạo PR/commit hoặc screenshot tool review giả. Severity do người review đánh giá. [Compliance audit](requirements-audit.md).

| ID | File:line tại lúc review | Severity/type | Finding | Quyết định/lý do | Fix/evidence |
|---|---|---|---|---|---|
| CR-01 | `lib/services/report_management_service.dart:52,72,109,116` | High, robustness/owner scope | generate/upload có await nhưng dùng owner/index mutable; authchange clears list, có thể gắn kết quả cũ sang owner mới hoặc RangeError | Accepted: session isolation là invariant bắt buộc; capture UID+epoch, reject stalecompletion | Fixed source: captureUID+epoch/check sau await/progress; owner lifecycle3tests pass, native upload vẫn cần Storage |
| CR-02 | `lib/services/report_management_service.dart:25,81,120`;`firebase/firestore.rules:227` | High, missing persistence | reports/cache chỉ RAM, URL/fileName/time/owner chưa Firestore; finaldeny-all cũng chưa cho reportmetadata | Accepted: PDF §6.4 yêu cầu persistentmetadata; cần ownerrepo/rules và reload test | Pending |
| CR-03 | `lib/widgets/notification_center_sheet.dart:130`;`lib/services/notification_service.dart:33` | High, broken flow | tap inbox chỉ pop; emitted route stream không ai subscribe; initialnotify không mở màn liên quan | Accepted: §6.5 bắt buộc tap navigation; allowlist + authready/entityownercheck | Pending |
| CR-04 | `lib/services/analytics_service.dart:18,23,28,44`;`lib/services/report_management_service.dart:84` | Medium, spec mismatch | CRUD eventnames/parameters khác đề; screen_view chỉ4tabs; export chưaupload đãlog, thiếu export_pdf/item_count | Accepted: align §6.8, giữ không gửi tên/notes/rawPII; stableIDs và safeentitylabel thay item_name tựdo | Pending |
| CR-05 | `firebase/storage.rules:5`;`firebase.json` | Medium, security/robustness | ownerrestriction có, nhưng không MIME/maxsize và storage deploymapping; không bảo vệ storage như configREADME claim | Accepted hardening khi chọn FirebaseStorage: PDFonly/limit, separatedelete, deployrules rồi verify. Không mởrules để bypass | Pending storageoption |
| CR-06 | `lib/widgets/auth_gate.dart` workspace overrides | High, integration | childProviderContainer độc lập từngUID trước đây chỉshareAnalytics/RC; notification/storage/crash/report rơi về defaultnulltransport | Accepted: shareactualserviceboundaries từroot | Fixed workingtree: explicit overrides; full367tests pass. Console acceptance vẫn pending |
| CR-07 | `lib/screens/shell_screen.dart` mobileheader | Medium, accessibility/layout | BrandLockup không bounded trongRow, overflow5.6px ở360/text2 sau typographychange | Accepted: constrain withExpanded/Align | Fixed workingtree; full367tests pass, native widths pending |

## Firestore Rules review thực tế

Đã đọc `firebase/firestore.rules` trọn file: owner(uid), payload/schema validators, getAfter/receipt liên kết atomicupdates, accounts/usage/quota/settings/mutations, catchall deny. **Không thấy allowall/testmode**. Reviewed relevant paths134–227; rule file tồn tại không tự chứng minh deployedversion/environment.

- OwnerUID và immutableprovenance được kiểm trong create/update; usage accountId không đổi; counters/receipt liên kết parent transaction. Giữ những bảo vệ này khi thêm reportmetadata.
- Reportmetadata chưa cópath nên defaultdeny hiện đúng chính sách; đó là missingcapability, không phải lý do hạ security.
- Tính năng mới phải thêm owner+schema+timestamp validation và tests deniedunauth/crossuser, không dựa vào dấu UID trên UI.
- Lượt này không deploy/change rules hoặc chạy destructive crossuser request bằng tài khoản cá nhân. Evidence lịch sử RulesAPI simulation không thay E2E/nativeconsole.

## Còn để đóng gate review

Featurebranch + PR vào main, AItool review cả app/rules, rawoutput/screenshots, sinh viên tự đọc và chốt findings, acceptedfixes với commit hoặc before/after và regression evidence. PR#1 từng merge không mặc nhiên chứng minh sourcehiện tại đã review. Các pending trong bảng phải được sửa/verify hoặc ghi quyết định rõ trước nộp.
