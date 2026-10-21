# Firebase — hiện trạng và việc còn lại theo L3/Final

## Analytics/Remote Config và manual web checks —21/10/2026

Người dùng xác nhận toàn bộ đợt manual web1–7 đạt: account edit/budget, usage totals/purpose drilldown, unknown data, validation/Back draft, archive/restore/history guard, empty-account delete, multi-quota/bounds; trước đó đã xác nhận reload/A-B isolation và offline/Retry. Đây là user-reported web evidence, không phải Android/ARTEMIS/concurrency stress hoặc console do agent kiểm.

Đã thêm Analytics13.0.0 và RemoteConfig7.0.0, typed/noPII event allowlist, UID-serialized lifecycle/dedupe/success-only cloud mutations và tab/account/usage detail events; demo no-op. Remote Config defaults overview_recent_limit3/budget_warning_percent80, parse/clamp/cache/fallback/retry/single-flight; dashboard recent rows/warning thực thay đổi qua projections, không cắt dataset hoặc đổi tiền/token. Profile có effective values/source/check time/refresh và Analytics SDK status; Crashlytics vẫn chưa nối. Đọc [plan Analytics](analytics-plan.md) và [implementation/manual guide](analytics-remote-config.md).

Verification cuối xem test-report; không coi SDK state hoặc fake tests là DebugView/console evidence. Remote Config publish→app before-after, DebugView mỗi event, Android/ARTEMIS vẫn pending; PDF export/upload events chỉ planned. FCM/Crash/PDF và Final modules chưa làm. Không Android emulator/billing/deploy hoặc push trong lượt này. Các câu SDK Analytics/RC còn pending ở checkpoint dưới đây đã được cập nhật implementation mới; giữ history/results đúng thời điểm.


Cập nhật21/10/2026. Baseline: [ASSIGNMENT_REQUIREMENTS](ASSIGNMENT_REQUIREMENTS.md). Topic TokenLedger được giảng viên chấp thuận theo user; Storage/roles/môi trường kiểm thử chưa được miễn trừ. Không dùng tên file pending để suy mọi Firebase còn chưa làm.

## Đã có implementation

- Firebase Core/Auth/Google Android+web/config đúng tokenledger-lab3, guard/Profile và UID-keyed workspace. Người dùng xác nhận Google web login/reload/logout/Users; native còn chờ.
- Cloud Firestore7.0.0, owner-scoped streams/account/usage/quota/settings, atomic CRUD/counters/revisions/receipts/label reservations. Cloud VM ghép dữ liệu, last-good/cache/pending/error/retry/draft, dispose listener/state/routes khi đổi UID; không tự upload local snapshot/seed.
- Rules default deny/owner/schema/relations đã deploy;5 indexes READY.299 Flutter tests/142 Rules API cases đã pass trước lượt docs; không thay manual CRUD/A-B/native/ARTEMIS hoặc Final Emulator.
- SharedPreferences/schema2 chỉ dùng demo riêng. Bản nộp cần no runtime mock/demo entry theo REQ-L3-03; chưa bỏ entry trong lượt docs này.

## Lab3 còn thiếu hoặc cần kiểm chứng

1. REQ-L3-13–15: Android Auth/native picker, SDK CRUD/reload/realtime/A-B/permission/network/concurrency/lifecycle và evidence project thật; preserve drafts, null/micros/history/privacy.
2. REQ-L3-16–18: generate PDF đúng filter/data, L3 Cloud Storage owner upload/progress/URL/storage.rules/evidence. Chốt REQ-SCOPE-04 trước triển khai vì Final loại Storage và lưu/share PDF trên device+metadata Firestore. Cloudinary không tự được chấp thuận thay đề.
3. REQ-L3-19–21: FCM3 app states/Android13 permission/token binding/logout, Center/inbox/dedupe/tap routes/target access và console tests.
4. REQ-L3-22–24: analytics-plan≥7events trước code, typed params/questions/flows/noPII/userID, service instrumentation/DebugView mọi event;1 ARTEMIS analytics assertion.
5. REQ-L3-25: Crashlytics real-path non-fatal+test crash, UID/custom key/sanitized hooks, dashboard evidence.
6. REQ-L3-26–27: RC≥2 behaviour-changing values/defaults/fetch errors/no rebuild, Profile demo area+before/after; firebase/remote-config-defaults.json.
7. REQ-L3-28–47: ARTEMIS≥10cases×3+Pro15–30m/native/error, AI PR review5findings/3separate fixes, docs/evidence/report8–12p/slides12–15/video5–10m/access. Không MobAI/.mob/healing giả làm yêu cầu mới.

## Final còn thiếu — không coi là P1 tùy chọn

- FIN-01–09: gap review/roles/users.role/no self-role update/first Admin console, data-model+transitions/migration/privacy, shared packages/core, AppCheck Firestore+AI Logic, RC/Analytics cả hai clients và Crash mobile.
- FIN-10–18: admin Google role guard, management1mobile entity/review queue+reason/dashboard3aggregation figures+chart/announcement form, mobile realtime inbox, Hosting URL, docs+sequence+measured latency và cross-role3deployed runs.
- FIN-19–25: Gemini Firebase AI Logic/AppCheck/RC model-prompt-flag, structured model/user preview-edit-confirm/noPII/quota-network fallback/AI events,3real examples+failure; level3 optional bonus.
- FIN-26–36: Emulator allowed+denied per role/collection, ARTEMIS cross-role+AI3runs, web checklist screenshots, Final AI review≥3findings, release/report10–15p/slides12–15/video8–12m/access.
- Final no custom server/Functions/Cloud Storage/App Hosting/Cloud Run; device PDF+Firestore metadata. Chốt role/entity flow với giảng viên; topic approval không tự duyệt flow này.

## Ranh giới thao tác

Lượt này docs-only, không SDK/runtime/telemetry/deploy/billing/Google user changes. Không chạy/tạo/sửa Android emulator; Firebase Emulator rules tests cần môi trường nhẹ được thống nhất trước khi thực chạy. Config client public được giữ; service-account/model/provider secrets không commit. Không thêm provider sync, payment/chat/scraping hoặc upload toàn snapshot để merge cloud. Chi tiết triển khai đã có: [Auth](firebase-auth-setup.md), [contract](firestore-data-contract.md), [workspace](firestore-workspace.md), [test evidence](test-report.md).
