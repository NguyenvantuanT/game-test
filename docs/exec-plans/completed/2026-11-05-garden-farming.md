# Làm vườn: tưới cây, bón phân, thu hoạch

## Mục tiêu & acceptance criteria
- [x] Mỗi cây trong vườn rau (32 cây) và vườn hoa (24 cây) là một cây riêng có trạng thái: tiến độ lớn, độ ẩm, phân bón. Lúc vào game, các cây ở nhiều giai đoạn khác nhau và có vài cây đã chín
- [x] Cây chỉ lớn khi đất còn ẩm. Một lần tưới giữ ẩm 30 s, hết thì cây đứng yên tới khi tưới lại. Bón phân làm cây lớn nhanh gấp đôi trong 30 s. Khi được tưới liên tục, cây đi từ mầm tới chín trong khoảng 90 s, có bón phân thì nhanh hơn
- [x] Đứng gần cây và bấm E sẽ làm việc theo thứ tự ưu tiên: cây chín → "Thu hoạch"; đất khô → "Tưới cây"; chưa bón phân → "Bón phân". Cây không còn gì để làm thì bị bỏ qua, không che cây bên cạnh. HUD hiện `[E] ...` đúng việc của cây gần nhất đang có việc; quanh đó không cây nào có việc thì không hiện gợi ý
- [x] Nhìn là biết trạng thái: cây to dần theo 4 giai đoạn (mầm, đang lớn, sắp chín, chín); khi chín, rau có quả và hoa nở; đất quanh gốc sẫm màu khi ẩm; có hạt phân trắng khi đang có phân
- [x] Thu hoạch xong, cây quay về mầm, đất khô, hết phân. HUD góc trên phải đếm số rau và hoa đã thu hoạch
- [x] Nhà, cửa, đèn, TV, bàn thờ và HUD tên khu vực vẫn hoạt động như cũ. Smoke test có cửa sổ pass; `check.sh`, `docs-check.sh`, `gdlint`, `gdformat --check` pass

## Bước
- [x] `crop.gd` (logic + hình từng cây), Garden sinh Crop thay cho hình tĩnh; Crop phát `harvested`, Garden phát lại thành `crop_harvested(kind)`
- [x] HUD đếm thu hoạch ở World, docs (ARCHITECTURE, README), smoke test
- [x] Evaluator, reviewer, PR

## Quyết định
- 2026-11-05 Tưới là bắt buộc để cây lớn, phân chỉ làm cây lớn nhanh hơn — user chọn
- 2026-11-05 Chăm từng cây, không chăm cả luống — user chọn; mỗi cây có Interactable riêng (0.8×1×0.8 m), Player sẵn có cơ chế chọn vật gần nhất
- 2026-11-05 Chín sau ~90 s nếu tưới liên tục — user chọn mức 1–2 phút để chơi thử thấy được cả vòng
- 2026-11-05 Thu hoạch xong thì cây tự mọc lại từ mầm, chỉ đếm trên HUD, chưa có túi đồ — user chọn; túi đồ / bán để việc sau
- 2026-11-05 Một phím E cho cả 3 việc, theo thứ tự ưu tiên thu hoạch > tưới > bón — không thêm phím, khớp các đồ tương tác đã có
- 2026-11-05 Trạng thái ban đầu random với seed cố định theo vườn — vào game là có việc để làm ngay, và smoke test chạy lại vẫn ra cùng kết quả
- 2026-11-05 Cây không có collision — Player phải đi được giữa các hàng (khoảng cách 0.9–1.4 m) để tới từng cây
- 2026-11-05 Chưa lưu trạng thái vườn khi thoát game — chưa có hệ thống save
- 2026-11-05 Player bỏ qua Interactable có prompt rỗng khi chọn vật để nhắm (sửa tiêu chí 3 theo) — reviewer chỉ ra cây đã chăm xong che cây bên cạnh cách 0.9 m; user đồng ý. Đồ trong nhà luôn có prompt nên không đổi
- 2026-11-05 Phân chỉ hao khi đất ẩm — đất khô cây không lớn, phân hao lúc đó là mất không (reviewer)

## Tiến độ
- 2026-11-05 Xong code + docs. Smoke test có cửa sổ (scratchpad `smoke_garden.gd`) 32/32: số cây, giai đoạn ban đầu, phím E thật thu hoạch → tưới → bón, HUD đếm, toán lớn (khô không lớn, 90 s chín, phân 45 s), 4 giai đoạn to dần, nụ/bông hoa. Smoke nhà 2 tầng 24/24 vẫn pass. gdlint/gdformat/check/docs-check pass · bước tiếp: evaluator, reviewer, PR
- 2026-11-05 Reviewer: không lỗi chặn. Đã sửa: phân chỉ hao khi ẩm, Player bỏ qua vật hết việc, HUD đếm dùng `.get`, `crops()` trả bản sao, ghi TD-3 (chưa có test trong repo). Smoke vườn 35/35, nhà 24/24. gdlint/gdformat chạy bằng venv tạm trong scratchpad (TD-1) · bước tiếp: evaluator trên code đã sửa, PR

## Còn mở
- Chưa có test GUT (chưa cài `addons/gut`); kiểm bằng smoke test trong scratchpad — đã ghi TD-3

## Evaluator
- 2026-11-05 đạt hết — eval.gd riêng chạy có cửa sổ fails=0 (32/24 cây, chín 90.5 s / có phân 45.5 s, đi bộ qua cổng + phím E thật: thu hoạch > tưới > bón, cây hết việc bị bỏ qua, HUD ẩn khi hết việc, đếm "Rau: 5 · Hoa: 1"), smoke nhà 24/24, gdlint/gdformat/check/docs-check pass
