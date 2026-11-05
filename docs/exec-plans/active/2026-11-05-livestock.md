# Khu chăn nuôi: gà, bò, cừu

## Mục tiêu & acceptance criteria
- [ ] Phía nam nhà có 3 chuồng rào riêng "Chuồng gà", "Chuồng bò", "Chuồng cừu", mỗi chuồng có cổng phía -Z và lối đi nối với đường chính; vào chuồng thì HUD trái hiện đúng tên chuồng.
- [ ] Gà (5), bò (2), cừu (3) dựng bằng khối, tự đi lang thang và nghỉ trong chuồng, không ra khỏi rào; Player không đi xuyên qua con vật.
- [ ] Đứng gần con vật đang đói → `[E] Cho ăn`; cho ăn xong prompt trống, sau gà 30 s / cừu 45 s / bò 60 s thì có sản phẩm nổi trên đầu (trứng / chai sữa / cuộn len; lông cừu dày dần).
- [ ] Có sản phẩm → `[E] Nhặt trứng` / `Vắt sữa` / `Cắt lông`; bấm E thì sản phẩm biến mất, con vật đói lại, HUD phải tăng đúng mục.
- [ ] HUD phải hiện `Rau · Hoa · Trứng · Sữa · Len`; thu hoạch vườn vẫn đếm đúng (không hỏng tính năng vườn).
- [ ] `gdlint` + `gdformat --check` sạch; `godot --headless --path . --quit` không lỗi script; smoke test vườn + chăn nuôi pass.

## Bước
- [x] Tách rào ra `Fence` dùng chung; Garden dùng `Fence`, phát `collected(item)` (signal chung trên NamedArea)
- [x] `Animal` (CharacterBody3D @tool): hình theo loài, đi lang thang, vòng đói → sản xuất → có sản phẩm
- [x] `Pen` (NamedArea @tool) + `scenes/pen.tscn`; đặt 3 chuồng + lối đi vào `world.tscn`
- [x] World đếm theo tên vật phẩm, HUD 5 mục
- [ ] Docs (ARCHITECTURE, README), smoke test, reviewer, evaluator, PR

## Quyết định
- 2026-11-05 Branch `feat/livestock` chồng lên `feat/garden-farming` (PR #5 chưa merge) — vì dùng lại rào và HUD đếm của vườn; merge PR #5 xong thì rebase lên main.
- 2026-11-05 1 khu, 3 chuồng riêng; cho ăn + thu sản phẩm; con vật đi lang thang — user chọn.
- 2026-11-05 Con vật là vật cản (layer world), vị trí bị kẹp trong vùng đi của chuồng — để chắc chắn không lọt ra cổng.
- 2026-11-05 Trạng thái ban đầu ngẫu nhiên với seed theo tên chuồng — vào là có việc làm ngay, lần chạy nào cũng giống nhau.

## Tiến độ
- 2026-11-05 Viết plan; code Fence/Animal/Pen/World + docs; smoke chăn nuôi 43/43, vườn 35/35 · đang chờ reviewer + evaluator · sau đó PR

## Còn mở
- Chưa có.

## Evaluator
