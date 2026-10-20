# Project context —21/10/2026, P0 local sau A04

## Hiện trạng và constraints

TokenLedger là Flutter Android quản lý AI account/usage/purpose/token/cost/quota, kế thừa core UI StudentPay Lab2. Người dùng cho phép đổi nghiệp vụ và yêu cầu code bốn bước model/migration → form/quota → cycle/timezone → analytics/history. Lecturer acceptance chưa có. Firebase vẫn pending; không tạo project/config/secret/telemetry/provider sync. Không chạy/tạo/sửa emulator vì máy yếu; native hoãn, không dùng ADB làm blocker. Không delegation nếu không có yêu cầu rõ.

Package token_ledger, applicationId com.tokenledger.token_ledger, version0.1.0+1. Môi trường Flutter3.47.4/Dart3.13.3; SDK/licenses xác nhận21/10. APK trước B03–B13 không phải binary hiện hành; không claim native smoke. Source33 lib/14 test files. Verification cuối đọc docs/test-report.md, không suy số test168 baseline B11–B13 là bộ hiện tại.

## Kiến trúc / dữ liệu đã có

Riverpod/MVVM, models Dart thuần, services persistence/calculator/calendar; mutation VM validate/orchestrate, reporting VM derive totals/filter/cycle/shares, widgets render/interact. Không SDK/persistence trong screens. Repository snapshot một instance, chưa multi-window/multi-device hoặc backend atomic CRUD.

Schema2 giữ key tokenledger.demo.v1 để đọc schema1. Migration pure parse/validate trước; backup raw đúng vào tokenledger.demo.v1.migration-v1-backup trước replace; fail giữ raw/backup/error cho Retry. Load dùng chung pending future, save chờ migration. Recovery backup riêng tokenledger.demo.v1.recovery-backup, confirmed recovery không bypass lỗi; chưa restore UI. Dữ liệu cũ chuyển nguồn legacy/cost unspecified hoặc unknown, timezone device/cycle1, một quota→list; không đoán demo từ IDs, model null/defaults[] và không gán actual.

Account CRUD/archive/restore/hard delete khi rỗng; model default nullable/default purposes immutable, quotaWindows immutable, timezone/cycleStartDay1–31 và isDemo/dataSource. Usage CRUD, accountId immutable, model optional, purpose9, UTC timestamps, source/demo/cost basis rõ; archived account chặn new usage nhưng sửa/xóa history. Quota unitpercent/source/sourceLabel/note/observedAt/resetAt; upsert đúng key/tên, rename giữ key, duplicate label bị chặn, delete window có confirm và stale edit route không resurrect. Không cộng% hoặc suy từ usage.

USD integer micros/null-vs-zero, token pair và coverage; actual chỉ user xác nhận, manual/unspecified/unknown khác nhau; breakdown cộng một lần. Không pricing engine/estimate hoặc subscription fee billing. Validation Unicode/bounds/date/quota/reference/safe integer chung. UUIDv4/stable retry IDs, VM write/reload/epoch/dispose guards; DraftGuard gồm model/chips/settings, save fail giữ controllers.

DataScope manual/demo/legacy tách riêng, mặc định ưu tiên nguồn manual rồi legacy rồi demo kể cả metadata-only accounts. Budget metadata có source; loại account không liên quan khỏi tổng budget của nguồn, vẫn dùng account có usage của nguồn đó. Account list quản lý metadata chung, metrics theo nguồn đã chọn. Reset/clear chỉ demo, giữ manual/legacy và referenced account; seed ID collision remap, reset lặp không nhân bản.

## Kỳ và UI

ReportingCalendar service dùng timezone0.11.2, database bundle offline latest.dart (http/http_parser transitive không phải app network integration). New space/default account Asia/Ho_Chi_Minh; migrated device giữ policy cũ. Timestamp serialize UTC, seed dùng native DateTime UTC để không mắc TZDateTime.toLocal theo tz.local. IANA/DST và cycle day29–31 clamp từng tháng, [start,end) UTC; device và UTC tường minh. Dashboard ngân sách Kỳ hiện tại theo từng account; account history drilldown cùng cycle, đổi được sang report range. Reporting timezone settings không sửa instant lịch sử. Date entry theo thiết bị, row/header/detail theo reporting zone.

Analytics cost/token/session, initial cost nếu có knowncost kể cả0, otherwise count; purpose ring/legend/sector và account/provider drilldown cùng query/source/range. History dùng unified query account/purpose/provider/search/period, nhóm ngày, search/filter/Back/Retry giữ context. Source/cost basis/model/demo flag có trong detail.

Mobile4 destinations, desktop framed-sheet/sidebar/IndexedStack; giữ Lab2 Inter/#006C49/#FAF8FF/#E8F7EF/card20/control12/touch48/CTA52/AppMotion/reduced motion. Components hiện hành được mở rộng, không có .agents/skills trong checkout và không cài/sửa vendor tooling. UI matrix360/412/768/1440×800 scales1/1.3/2, keyboard/SafeArea/stress và semantics/state tests. Logo SVG/painter/native/PWA/maskable đã audit trước, không regenerate.

## Evidence và pending

B01–B14 có local/annotation baseline; SD01–SD05 và analytics/history local SD08 đã code, chi tiết docs/local-p0-upgrade.md. Tests mới schema_v2_test và scope_forms_test kiểm migration/retry/race/UTC/IANA/DST/leap/cycle/provenance/immutable/defaults/quota/retention/budget source và form360/412/Back/retry/provider/day grouping/donut. Final run/build counts và môi trường xem test-report, không claim tests thay native/backend.

B13 đã xem8 Figma final360/annotate original frames và page233:2/board233:3 có16 cards. Link trong fidelity-check.md. Upgrade hiện tại chưa sửa live Figma; annotations chưa có field mới. QA412 chỉ metadata; full QA412/state/component review/8 TokenLedger mockups/final fidelity vẫn pending. Bản copy Lab2/PDF/inspector artifacts/vendor skills đã cleanup20/10; build không cần sibling Lab2/Node/skills.

Chưa Auth/Firestore/rules/UID/streams/atomic counters/backend isolation, FCM/Notifications/RC/Crash/Analytics/PDF/Reports. Không fake Google login hoặc provider sync. Full router/auth/deep links, native TalkBack/IME/MobAI/AI PR review/report/video/lecturer access/submission chưa đạt. SD06 estimate hoãn, SD07 Firebase pending; A01/A02/A07 và G0–G9 nghiệm thu vẫn chưa đủ. AI log12 prompt nguồn thực (entry12 là Git-only), chất lượng/rubric chưa tự đạt từ số lượng.

## Git và hướng tiếp tục

Origin https://github.com/NhanHuynhThien/lab3_prm.git, branch codex/local-form-safety. Refs đọc tại A06: HEAD/local main/remote main4aeb7b719b95c0b4aa21f02bc0f05329b909cdf2. Checkpoint commit local chứa B01–B13/A03–A06/upgrade và tài liệu này theo yêu cầu21/10; SHA đọc bằng git log -1 --oneline. Chưa push; refs A06 là baseline lịch sử, đọc Git thực trước publication. Private là trạng thái đã ghi trước, không phải kiểm quyền mới; không đổi visibility/mời người khác. Không dùng SHA nền chứng minh source chưa commit. Repo trống/chưa có Git chỉ đúng trước20/10.

Đọc README, build-status, architecture, TASK_CHECKLIST, scope-decisions, local-p0-upgrade, lab2-ui-reference/design-change-log và firebase-pending. Khi có yêu cầu Firebase mới: Auth/owner-scoped stream/atomic repository/rules trước services; không upload toàn snapshot làm merge backend. Hiện tiếp tục phần độc lập/final docs/visual acceptance theo yêu cầu, không tự mở backend hoặc emulator.
