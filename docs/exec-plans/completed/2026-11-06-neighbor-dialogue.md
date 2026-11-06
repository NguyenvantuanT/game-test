# Hội thoại rẽ nhánh với hàng xóm

## Mục tiêu & acceptance criteria
- [x] Đứng gần người hàng xóm bấm E → hộp thoại dưới màn hình hiện tên người nói, câu nói và 1–4 lựa chọn đánh số; Player đứng yên, người hàng xóm đứng lại, gợi ý `[E]` ẩn.
- [x] Chọn được bằng phím số 1–4, chuột, hoặc mũi tên + E / Enter; lựa chọn dẫn sang nút tiếp theo đúng kịch bản; lựa chọn kết thúc thì đóng hộp, Player đi lại được, người hàng xóm đi tiếp.
- [x] Bác Ba và cô Lan có kịch bản riêng, nhiều nhánh, quay lại câu hỏi đầu được; kịch bản không có nút hỏng (`Dialogues.problems()` rỗng — kiểm lúc chạy bản debug).
- [x] Không dùng AI / mạng: kịch bản là dữ liệu viết sẵn trong `scripts/dialogues.gd`.
- [x] Headless không lỗi script; smoke test hội thoại + hàng xóm pass; vườn, chuồng vẫn đếm.

## Bước
- [x] `Dialogues` (kịch bản + kiểm lỗi), `DialogueBox` (HUD), nối Neighbor → NeighborHome → World; bỏ bong bóng chữ
- [x] Smoke test, ảnh chụp, docs, review + evaluator

## Quyết định
- 2026-11-06 Hội thoại rẽ nhánh có lựa chọn, không dùng AI — user yêu cầu (giảm xử lý).
- 2026-11-06 Kịch bản là `const` Dictionary trong GDScript, không phải JSON — không cần đọc file / cấu hình export, sai cú pháp thì lỗi ngay lúc parse; lỗi tham chiếu nút do `Dialogues.problems()` bắt.
- 2026-11-06 Phím số đọc `physical_keycode` (+ numpad) — đúng cả bàn phím AZERTY (reviewer).
- 2026-11-06 Bỏ bong bóng chữ trên đầu (`lines`) — hộp thoại thay thế, giữ một cách nói chuyện duy nhất.

## Tiến độ
- 2026-11-06 Viết plan; code Dialogues/DialogueBox, nối Neighbor → NeighborHome → World, bỏ bong bóng; smoke hội thoại 48/48; ảnh chụp hộp thoại đúng
- 2026-11-06 Review + evaluator độc lập: sửa `open()` khi đang mở (người cũ kẹt `talking`), phím số theo vị trí + numpad, smoke hàng xóm cũ còn dùng bong bóng → cập nhật; chạy lại smoke hàng xóm 19/19, hội thoại 48/48, tường/vùng đi 9/9, eval riêng 45/45 ×3
- 2026-11-06 User chơi thử: bấm E mãi không thoát được hội thoại cô Lan (E luôn chọn lựa chọn 1, lối ra duy nhất ở `start`) → thêm Esc đóng bất cứ lúc nào, dòng gợi ý phím, câu chào về ở mọi nút cuối nhánh; smoke hội thoại 67/67, hàng xóm 19/19

## Còn mở
- Chưa có.

## Evaluator
- 2026-11-06 đạt hết — subagent độc lập: E mở ở `start` không tự chọn, phím số / mũi tên + E / Enter / Space / chuột đều sang đúng nút, END đóng và trả lại điều khiển, Player + người đứng yên khi nói, Ba 9 nút / Lan 7 nút đều tới được từ start, `problems()` rỗng; lần đầu chưa đạt AC5 (smoke hàng xóm cũ không parse) → đã sửa, chạy lại: smoke hàng xóm 19/19, hội thoại 48/48, eval 45/45. `gdlint` chưa chạy được ở máy (TD-1) → CI
