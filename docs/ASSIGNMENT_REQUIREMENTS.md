# Yêu cầu Lab 3 hiện hành — PDF 17 trang

Đối chiếu ngày22/10/2026 theo file **PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf** do người dùng chỉ định. SHA-256: `563eb49ef0eca4d860b4edd67c4c818d08728fa657c3c07231ee7229a197589c`. Đã đọc toàn bộ17 trang và xem ảnh các trang5,6,9,11,12 để kiểm bảng/yêu cầu.

Các bản tổng hợp trước từng lẫn đề18trang/ARTEMIS và Final; đã dọn khỏi docs. **Không dùng các scope đó làm rubric cho PDF này.** Checklist dưới đây là yêu cầu, không phải tuyên bố đã hoàn thành; xem [audit source](../TASKS.md) cho trạng thái.

## 1. Kiến trúc và chức năng — trang2–8

| ID | Yêu cầu | Nguồn |
|---|---|---|
| L3-01 | Flutter/Dart chạy Android có Google Play services hoặc thiết bị thật; Firebase project của sinh viên, Analytics enabled; không secrets | tr1,8 |
| L3-02 | ≥8 màn Lab2, thêm Login/Profile; 3 flows end-to-end bằng dữ liệu thật, Back/navigation và error/recovery đúng; thay thiết kế có log và annotate Figma | tr2,4–5 |
| L3-03 | MVVM + Provider **hoặc** Riverpod nhất quán; Models Dart thuần/Firestore conversion; chỉ Services gọi Firebase/API; VM state/business, Views chỉ render/forward actions | tr3–4 |
| L3-04 | `lib/{theme,models,services,viewmodels,screens,widgets,utils}`, mỗi screen specification có view file + VM; tokens→ThemeData, component→reusable widget | tr4 |
| L3-05 | Google Sign-In thật, Profile photo/name/email, logout, signed-out chỉ Login; Android SHA-1 | tr5 §6.2 |
| L3-06 | Firestore per-user, ≥2 collections/subcollections; full main-entity CRUD; ≥1 filter/sort query và realtime listener; seed **hoặc cách tạo dữ liệu test**; owner-only rules lưu `firebase/firestore.rules` và deploy | tr5 §6.3 |
| L3-07 | PDF dữ liệu user + summary/list, nhận diện cùng app; upload object storage; URL/fileName/creationTime/owner **lưu Firestore**; app có URL/open | tr5 §6.4 |
| L3-08 | Chọn storage: Cloudinary là free path được khuyến nghị (unsigned preset PDF/maxsize, không API secret); Firebase Storage cần Blaze/billing; S3/khác chỉ khi lecturer duyệt + presigned service | tr5–6 |
| L3-09 | FCM từ Console foreground/background, Android13 permission, Notification Center; tap mở màn liên quan | tr6 §6.5 |
| L3-10 | ≥2 RC defaults + fetch, đổi hành vi thật, Profile effective values; evidence console change→publish→app đổi | tr6 §6.6 |
| L3-11 | Crashlytics handled-exception **và** test-crash controls; cả hai có dashboard evidence | tr6 §6.7 |
| L3-12 | Analytics plan event/trigger/params/Lab2flow; event names lowercase/digits/underscore ≤40; DebugView evidence | tr6–7 §6.8 |
| L3-13 | `login(method)`, `logout`, `screen_view(screen_name)`, `view_<entity>(item_id,item_name)`, `create_/update_/delete_<entity>(item_id)`, `export_pdf(item_count)` **sau export+upload**, ≥2 own events | tr7 |
| L3-14 | Async loading/error cho network/permission/upload; analyze sạch, dart format; access do Rules bảo vệ (client Firebase IDs có thể commit) | tr8 |

Không bắt buộc runtime demo: form tạo account/usage thật đáp ứng cách tạo dữ liệu test. Không xóa chẩn đoán Crashlytics với lý do “bỏ demo” vì §6.7 bắt buộc hai controls này.

## 2. Design fidelity — trang8

- Mọi màn: ảnh Figma cạnh app **cùng360×800dp**, sai khác/lý do trong `docs/fidelity-check.md`.
- Colors/type/space/radius từ `lib/theme/`; tìm hardcoded values và liệt kê ngoại lệ có lý do.
- Mỗi component Lab2 có widget tái sử dụng/variants/states, screens dùng widget đó.
- Loading/empty/error screenshots từ tình huống thật.
- Contrast, touch≥48×48dp, layout360/412 trên running app.
- `docs/handoff-gaps.md`: điểm handoff không rõ/sai/thiếu và cách giải quyết. Design changes cũng log + update/annotate Figma.

## 3. Quy trình, MobAI và review — trang3,9–11,16–17

- Workflow Read spec→Setup→Build→Connect→Test→Review→Verify→Document, commits theo giai đoạn.
- `docs/implementation-ai-log.md`: ≥6 entries **prompt nguyên văn**, output, verification, accepted/modified/rejected + lý do; disclose mọi AI tool.
- **10 `.mob` scripts trong `mobai_tests/`**: (1) Google dedicated test account; (2–4)3 flows; (5)error/recovery; (6)create/edit/delete main entity; (7)mọi top-level destination; (8)Profile+RC; (9)PDF **upload succeeds**+URL/open; (10)logout→Login.
- Scripts có visible assertions, sinh viên đọc/sửa, documented clean starting state; không commit credentials. Ghi manual sign-in step nếu không automate được.
- **Healing**: deliberate UI change→fail→script patch + đánh giá có làm yếu assertion không. **Bug-catching**: real defect→testfail→fix→pass, evidence đủ.
- Không dùng được MobAI: báo giảng viên **trước khi** đổi tool. Flutter unit/widget suite không thay yêu cầu này.
- AI review feature branch/PR vào main, ≥3 findings thật (≥1security/robustness), review `firestore.rules`; `docs/code-review.md` có tool/file:line/severity/decision/reason, accepted fixes và screenshots.
- ≥1merged PR, meaningful history; số `[N]` commits/days trong PDF chưa điền, không tự suy. Repo mở được khi nộp, nếu không toàn bài0 đến khi sửa theo late policy. Có thể vấn đáp5–10phút.

## 4. Deliverables — trang11–13,17

```text
PRM393_Lab03_<StudentID>/
  README.md                    topic, Lab2 Figma + flutter-handoff, run/setup
  lib/                         MVVM như §5
  android/                     gồm google-services.json
  firebase/firestore.rules
  firebase/storage.rules       nếu dùng Firebase Storage
  mobai_tests/                 10 scripts thật
  docs/handoff-gaps.md
  docs/design-change-log.md
  docs/fidelity-check.md
  docs/analytics-plan.md
  docs/implementation-ai-log.md
  docs/test-report.md
  docs/code-review.md
  assets/                      runtime + app/console/DebugView/test/review evidence
```

- Report **5–10 trang**: overview/persona/flows, MVVM, Firebase/storage/rules, từng feature, Analytics/Crash/RC evidence, fidelity/design changes, MobAI/results/2exercises, AI implementation/review, challenges/lessons.
- Video **3–5 phút**: login/logout,3flows/error, CRUD+Firestore, PDF/upload/URL, Console push, live RC, Crash2types, DebugView, full MobAI run, AI review.
- PDF này **không yêu cầu slides**, không ARTEMIS, không ngưỡng5findings/3separatefixcommits. Đừng nhập yêu cầu Final vào Lab3.

## 5. Rubric100 điểm — trang13–16

| Nhóm | Điểm |
|---|---:|
| Chức năng: screens5, flows10, data10 | 25 |
| Firebase: Auth4, Firestore6, PDF4, push3, RC3, Crash2, Analytics3 | 25 |
| Architecture: separation5, state/structure5 | 10 |
| Design/UI: tokens4, fidelity3, accessibility3 | 10 |
| MobAI: coverage5, assertions4, healing3, bug-catching3 | 15 |
| AI review: findings3, decisions/fixes2 | 5 |
| AI implementation3 + handoff feedback2 | 5 |
| Report3 + video2 | 5 |

Không tự chấm điểm từ test counts hoặc folder existence. Mỗi criterion cần implementation và bằng chứng đúng môi trường.
