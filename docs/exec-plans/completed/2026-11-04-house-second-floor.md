# Nhà 2 tầng

## Mục tiêu & acceptance criteria
- [x] Tầng 1 giữ nguyên 4 phòng + đồ đạc (chỉ dời lối vào phòng ngủ để chừa chân cầu thang)
- [x] Cầu thang đi bộ lên/xuống được giữa 2 tầng (không dịch chuyển tức thời); ô cầu thang tầng 2 có lan can, không rơi xuống được
- [x] Tầng 2: phòng thờ phía trước (bàn thờ, bấm E thắp/tắt hương), sảnh cầu thang ở giữa, 2 phòng ngủ hai bên (giường, tủ đầu giường + đèn ngủ, tủ quần áo, cửa), nhà vệ sinh phía sau (bồn cầu, lavabo, vòi sen, cửa đóng thì chặn)
- [x] Cutaway theo tầng: đứng tầng 1 → ẩn mái + cả tầng 2 + nửa trên tường tầng 1; đứng tầng 2 → ẩn mái + nửa trên tường tầng 2; ra ngoài → hiện hết
- [x] HUD hiện tên phòng tầng 2 ("Phòng thờ", "Phòng ngủ 2", "Phòng ngủ 3", "Nhà vệ sinh", "Cầu thang")
- [x] Smoke test pass; `gdlint`, `gdformat --check`, docs-check pass

## Bước
- [x] House: tường/sàn theo tầng, sàn tầng 2 có ô cầu thang, cầu thang + lan can, cutaway theo tầng
- [x] Bàn thờ `altar.gd`; tầng 2 trong `house.tscn` (phòng, đồ đạc, cửa, đèn)
- [x] Smoke test, docs, PR — 4fda524, PR #3

## Quyết định
- 2026-11-04 Cầu thang sát tường giữa phía phòng ngủ tầng 1, lên từ -X sang +X; lối vào phòng ngủ tầng 1 dời sang x = -3 — vì đây là chỗ duy nhất không chặn cửa/đồ đạc có sẵn và đỉnh cầu thang rơi đúng giữa tầng 2
- 2026-11-04 Collision cầu thang là một dốc trơn (ConvexPolygonShape3D), bậc chỉ là hình — CharacterBody3D không tự bước bậc
- 2026-11-04 Tầng hiện tại xác định bằng độ cao Player (quá nửa LEVEL_HEIGHT = tầng 2) khi ở trong `Interior`

## Tiến độ
- 2026-11-04 Xong code + docs. Smoke test headless (scratchpad) 24/24 pass: đi bộ lên/xuống cầu thang, lan can chặn, 5 tên phòng tầng 2, thắp/tắt hương, cửa WC đóng chặn/mở vào được, cutaway 3 trạng thái, tầng 1 vẫn đúng. Ảnh chụp có cửa sổ ngoài nhà / tầng 1 / tầng 2 ổn. gdlint + gdformat --check pass · bước tiếp: evaluator, commit, PR

## Còn mở

## Evaluator
- 2026-11-04 đạt hết — smoke 24/24 + script kiểm thêm 6/6 (đi bộ từ phòng khách lên tầng 2, lan can 3 phía, vào phòng ngủ 3, 1518 điểm lưới không bấm E trúng đồ khác tầng); diff tầng 1 chỉ dời lối phòng ngủ; gdlint/gdformat/docs-check pass; không lỗi runtime; ảnh ngoài nhà/tầng 1/tầng 2/bàn thờ khớp
