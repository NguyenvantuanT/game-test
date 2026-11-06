# Hàng xóm: 2 nhà + người hàng xóm nói chuyện được

## Mục tiêu & acceptance criteria
- [x] Map rộng thêm về phía đông (+X); đường chính nối dài từ lối vào vườn qua giữa 2 vườn tới xóm; Player không ra ngoài biên mới.
- [x] Có 2 nhà hàng xóm "Nhà bác Ba" và "Nhà cô Lan" cạnh đường, dựng bằng khối, kín (không vào được, Player không đi xuyên); vào sân thì HUD trái hiện đúng tên nhà.
- [x] Mỗi nhà có 1 người hàng xóm dựng bằng khối, tự đi lại và nghỉ trong sân trước, không ra khỏi sân; Player không đi xuyên qua người.
- [x] Đứng gần người hàng xóm → `[E] Nói chuyện`; bấm E thì người đó đứng lại, bong bóng chữ trên đầu hiện câu tiếp theo (quay vòng hết danh sách), sau 4 s thì ẩn và lại đi tiếp.
- [x] Vườn, chuồng, nhà chính và HUD đếm vật phẩm không bị ảnh hưởng.
- [x] `godot --headless --path . --quit` không lỗi script; smoke test hàng xóm pass; `gdlint` + `gdformat --check` sạch (CI).

## Bước
- [x] `MeshKit.prism`; `Neighbor` (CharacterBody3D @tool): hình, đi lại, nói chuyện
- [x] `NeighborHome` (NamedArea @tool) + `scenes/neighbor_home.tscn`; mở rộng map, đặt 2 nhà + đường vào `world.tscn`
- [x] Docs (ARCHITECTURE, README), smoke test, review + evaluator · PR

## Quyết định
- 2026-11-06 Nhà + người hàng xóm (nhà không vào được, người đi lại trước sân, E để nói chuyện) — user chọn.
- 2026-11-06 Mở rộng map sang +X (40 → 56 m) thay vì chen vào map cũ — map cũ đã kín nhà, vườn, chuồng; đường chính z = 13.5 đi lọt giữa 2 vườn.
- 2026-11-06 `NeighborHome` theo khuôn `Pen` (NamedArea @tool tự sinh hình + sinh người), `Neighbor` theo khuôn `Animal` (đi lang thang trong `bounds`) — giữ cách làm quen thuộc của repo. Phần đi lang thang lặp lại ~25 dòng của `Animal`; chưa tách chung vì chỉ 2 chỗ dùng.
- 2026-11-06 Câu thoại hiện bằng Label3D trên đầu, không thêm UI hội thoại vào HUD — đủ cho việc "nói chuyện" cơ bản, không đụng HUD.
- 2026-11-06 Cả 2 nhà đặt phía bắc đường (x = 39.5, 49.5), không đặt nhà quay mặt về bắc ở phía nam đường — camera nhìn từ +Z nên nhà phía nam che mất sân trước, người và câu nói của chính nó (reviewer bắt qua ảnh chụp). Bong bóng thoại `no_depth_test` để mái / biển tên không che.

## Tiến độ
- 2026-11-06 Viết plan; code Neighbor/NeighborHome/World + docs; smoke 32/32; ảnh chụp đúng
- 2026-11-06 Review + evaluator độc lập: không lỗi logic, 1 lỗi hình (nhà phía nam che sân) → dời 2 nhà lên phía bắc đường; chạy lại smoke 32/32 + kiểm tường / HUD / vùng đi 9/9 + ảnh chụp · mở PR

## Còn mở
- Chưa có.

## Evaluator
- 2026-11-06 đạt hết — subagent độc lập: headless không lỗi, smoke 32/32, eval riêng 23/23 (biên map, tường nhà chặn, HUD tên nhà, người ở trong sân 150 s, nói chuyện dừng/ẩn sau 4 s/đi tiếp, vườn + chuồng vẫn đếm). Sau khi dời nhà: smoke 32/32, kiểm tường + HUD + vùng đi 9/9, ảnh chụp 2 nhà rõ. `gdlint`/`gdformat` chưa chạy được ở máy (thiếu gdtoolkit, TD-1) → CI
