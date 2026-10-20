# Visual handoff — P0 local,21/10/2026

Đối chiếu source checkpoint `d4b6167` trên branch `codex/local-form-safety`. Lượt này chỉ sửa live Figma và tài liệu; không sửa runtime, không chạy lại Flutter tests/build, không emulator/Firebase/push. Kết quả200 tests/analyzer/format/web build trong [test report](test-report.md) được giữ khi83 runtime hashes vẫn khớp.

## Kết quả và bằng chứng live

[Trang08 TokenLedger P0](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-2) chứa8 màn ở360×800 và412×800,3 phần cuộn P0,6 feedback specimens ở360/412, state notes, component specimens và analytics continuation. Đây là text/components/vector có thể chỉnh sửa; không import ảnh chụp nguyên UI làm thiết kế.

| Board | Link / kích thước screenshot đã xem |
|---|---|
|8 core screens360 | [237:33](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-33),1688×1832 |
|8 core screens412 | [237:36](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-36),1896×1832 |
| Model/purpose chips/cycle/timezone, usage và quota | [237:595](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-595),1376×964 |
| Storage/draft/quota/source notes | [237:697](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-697),1376×588 |
| Component specimens | [237:725](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-725),1376×614 |
| Loading/empty/error360 và412 | [240:236](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=240-236),1376×820 |
| Provider/cost-basis continuation | [240:290](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=240-290),1376×364 |

7 local main components nằm ngoài review boards: InputDecoration237:4, UsageRow237:6, PurposeTile237:10, FourDestinations237:13, DataScopePicker237:26, Legend239:229 và EmptyErrorFeedback240:239;120 instances tại lần read-back. Tái sử dụng Button44:1648 và variable/text styles của Lab2. Thêm đúng1 color variable `color/chartTertiary` từ AppColors#9BAD9F, scopes FRAME_FILL/SHAPE_FILL; không sửa palette Lab2 cũ.455 text nodes dùng Inter hoặc Material Icons,0 image fills. Icon font là ngoại lệ có chủ đích với kiểm Inter; không dùng provider logo giả.

8 original frames được bổ sung annotation P0, giữ geometry/text StudentPay.8 handoff cards trên [trang07](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=233-3) cũng có delta mới và link node; board sau cập nhật840×3022 đã xem. Không đổi file visibility hoặc tạo file Figma mới.

## Đối chiếu ba phía

Nguồn Lab2 final360 đã xem ở B13; lượt này xem đủ8 QA412, component states67:10 và9 families144:1934 qua screenshot live. Các frame QA412 tương ứng144:333/411/456/508/573/643/701/756. Ảnh app là Flutter engine render từ lượt full199 đã xuất ảnh, trước regression200; hash runtime giữ nguyên ở checkpoint. Đã xem lại8 core screens360 và412 cùng component gallery360/412. Không gọi các ảnh này là Android/browser screenshots.

| Lab2 original | TokenLedger360 /412 | Đối chiếu với app và lý do khác biệt nghiệp vụ |
|---|---|---|
| Home59:2 | [237:40](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-40) / [237:318](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-318) | Mint summary/progress; budget$37.16, spent$12.84/$50,286k/12 phiên. Cycle/source thay số dưVND; không phải provider balance |
| Add expense59:49 | [237:71](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-71) / [237:349](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-349) | Form cuộn/CTA52; account/title/model/token pair/USD/basis thay preset tiền. Field phía dưới ở continuation, không suy missing thành0 |
| Category59:78 | [237:108](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-108) / [237:386](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-386) | Grid3 cột/card20/selected mint;9 work purposes. Tap trả về ngay, bỏ Done theo flow form thực |
| Analytics59:121 | [237:144](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-144) / [237:422](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-422) | Donut/legend/segmented control; seed$12.84, Lập trình28.8%/$3.70, Nghiên cứu19.5%/$2.50; thêm source/timezone/provider/basis |
| Transactions59:160 | [237:183](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-183) / [237:461](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-461) | Search/range/day heading/row metrics; dùng usage/query/source/report zone. Detail/edit/delete giữ lịch sử account archived |
| Split bills59:202 | [237:218](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-218) / [237:496](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-496) | Cards/search/active-archive; Claude$5.68/121k/4 phiên/$20 budget. Không payments/member balances |
| Create bill59:236 | [237:252](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-252) / [237:530](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-530) | Input/footer; model/purpose chips/IANA/cycle/budget thay split members; không password/API key |
| Bill detail59:279 | [237:286](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-286) / [237:564](https://www.figma.com/design/C7FiWYzVXUS8G2cnK5AGos/PRM393-Lab2-SE192382_SE192336?node-id=237-564) | Summary/list/actions; Codex$19.14 còn/$5.86/141k/4 phiên, quota tuần40% dùng/60% còn. Snapshot windows độc lập, không cộng% |

Ảnh app tại `.taste-skill/sd-local-ui/<screen>-<width>-1.0-false.png`, với screen dashboard/usage/purpose/analytics/history/accounts/account-form/account-detail. Gallery là `components-360.png` và `components-412.png`. Đây là local ignored artifacts, không phải assets runtime hoặc file được clone. Bằng chứng live là các node links; screenshot URL tạm thời không dùng làm link bàn giao lâu dài.

## Môi trường và kiểm tra

App captures: Windows/Flutter3.47.4/Dart3.13.3,360/412×800 logical pixels, DPR1, simulated insets top/bottom24dp, Inter/MaterialIcons thật, fixed clock21/10/2026 lúc10:00, seed giả định, text scale1, reduced motion cho ảnh ổn định. Ma trận tests trước đó gồm768/1440, chữ1.3/2, stress data, keyboard300dp; không chạy lại trong lượt Figma/docs.

Figma screens:360/412×800, neutral24dp safe spaces; footer84 bao gồm CTA52 +padding16 hai phía. Screen-only như capture trong test; navigation4 destinations có specimen riêng. Board annotations không có mật độ thiết bị thật. Viewport cố ý clip phần cuộn, continuation hiển thị field P0 phía dưới.

Đã sửa lỗi dựng Figma khi xem ảnh: horizontal row height làm hai hàng chồng nhau; source picker bị ép chiều cao; donut một màu/caption ngoài chưa đúng seed; legend/row xếp dọc; segmented text wrap; purpose defaults là field thay chips; timezone/cycle/budget sai thứ tự; busy button dùng faded primary thay disabled. Kiểm bounds cuối còn thấy stroke1px làm segment cuối tràn, đã trừ stroke khỏi available width và xem lại Analytics360/412. Read-back sau sửa:0 horizontal overflow trong các auto-layout containers,455 text/120 instances/7 components/8 top-level boards kể cả masters. Một lần setter constraints dùng RIGHT thay MAX bị tool từ chối/rollback; đã đọc lại canvas và sửa, không ghi lỗi đó là kết quả đạt.

Source audit dùng tìm kiếm colors/fontFamily/radius/duration và đọc theme/components/tests: palette/font/motion tập trung trong theme; logo mint#A6E9C8 là màu brand cố ý theo SVG; radius4/8 cho progress/focus/provider/list compact surfaces và các literal12/20 trùng tokens là ngoại lệ hiện có, không redesign trong lượt tài liệu.9 families/states đã có tests/gallery thật ở fidelity-check: Button, Textfield, Card, Navigation, Appbar, Dialog, Loading, Empty, Error. Touch48/CTA52, keyboard/text scales/contrast/brand/reduced motion dựa trên bộ kiểm200 đã ghi; không suy screenshot Figma chứng minh interaction/accessibility.

Có thể tái tạo app captures bằng lệnh sau; chưa chạy lại ở lượt này:

```sh
flutter test test/ui_audit_test.dart test/component_audit_test.dart --no-pub --concurrency=1 --dart-define=UI_AUDIT_IMAGES=true --dart-define=UI_AUDIT_OUTPUT=.taste-skill/sd-local-ui
```

## Giới hạn và nghiệm thu

Mockups là annotated handoff theo các section/semantics/source data, chưa phải bản pixel-perfect. Flutter Material có floating labels/counters/dropdown icons/ellipsis/focus/ripple và typography shaping khác bộ dựng Figma. History rows trong mockup rút gọn icon/trailing alignment; dashboard metrics rút gọn thành summary; form specimen dùng padding16 trong khi body form thực24; Purpose tile ở412 chưa mô phỏng toàn bộ thay đổi aspect ratio theo text scaler. Đây là sai khác của bản handoff cần tinh chỉnh nếu yêu cầu chấm pixel, không phải đề xuất sửa runtime cho giống mockup. Không sửa app đã kiểm thử để che khác biệt này.

F11–F13 và FIDELITY-01–06 được ghi nhận hoàn tất **đối chiếu/audit/đồng bộ trong scope local d4b6167**; không có điểm similarity đo được, reviewer/lecturer sign-off hoặc xác nhận visual acceptance cuối. GATE-08/G8 và bài nộp vẫn pending. Native TalkBack/IME/MobAI/Android screenshots, backend/Google Auth/FCM/PDF, live browser interaction, AI PR review và quyền giảng viên chưa có bằng chứng mới. Firebase vẫn pending; không khởi động máy ảo.
