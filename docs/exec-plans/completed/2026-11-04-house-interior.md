# Nhà vào được, đầy đủ tiện nghi

## Mục tiêu & acceptance criteria
- [ ] Nhà lớn hơn (14×10 m), 4 phòng: phòng khách, bếp + bàn ăn, phòng ngủ, phòng tắm; có tường ngăn, cửa thông phòng, cửa sổ
- [ ] Vào liền mạch: bước vào trong → mái + nửa trên tường ẩn, camera lại gần; ra ngoài → hiện lại
- [ ] HUD hiện tên phòng đang đứng ("Phòng khách"...), ra sân → "Sân nhà"; vườn vẫn hoạt động như cũ
- [ ] Đồ đạc là vật cản: sofa, bàn trà, kệ TV, kệ sách, thảm, cây cảnh · tủ bếp + bồn rửa, bếp nấu, tủ lạnh, bàn ăn + 4 ghế · giường, tủ đầu giường, tủ quần áo · bồn cầu, lavabo + gương, vòi sen
- [ ] Đến gần + bấm E: mở/đóng cửa chính và cửa phòng tắm (cửa đóng thì chặn), bật/tắt đèn cây + đèn ngủ, bật/tắt TV. HUD hiện gợi ý `[E] ...`
- [ ] Smoke test có cửa sổ pass; `check.sh`, `docs-check.sh`, `gdlint`, `gdformat --check` pass

## Bước
- [x] Helper chung: `MeshKit` (dựng khối), `NamedArea` (vùng có tên), `Interactable` (vùng bấm E); Garden kế thừa NamedArea
- [x] House: tường sinh từ dữ liệu (lỗ cửa/cửa sổ), sàn từng phòng, mái; vùng trong nhà ẩn mái + nửa trên tường
- [x] Đồ đạc: `furniture.gd` (trang trí) + `lamp.gd`, `tv.gd`, `door.gd` (tương tác)
- [x] Player: vùng tương tác, phím E, camera lại gần khi trong nhà; World: HUD phòng + gợi ý
- [ ] Smoke test, docs, PR

## Quyết định
- 2026-11-04 Vào nhà liền mạch, không tách scene — vì user chọn; giữ một map, không cần chuyển cảnh/lưu trạng thái
- 2026-11-04 Cắt tường ở 1 m khi trong nhà (cutaway) thay vì chỉ ẩn mái — camera chéo bị tường 3 m che mất nửa phòng
- 2026-11-04 Đồ đạc dựng bằng code từ khối cơ bản (tạm), một script `furniture.gd` theo `kind` — tránh hàng chục file .tscn khi chưa có model thật

## Tiến độ
- 2026-11-04 Xong code: helper, house (tường sinh từ dữ liệu, cutaway), 17 loại đồ đạc, cửa/đèn/TV, Player tương tác + camera, HUD stack khu vực. Smoke test có cửa sổ 23/23 pass (cửa chặn khi đóng, vào 4 phòng đúng tên, mái ẩn/hiện, camera gần/xa, đèn/TV bật tắt, vườn vẫn chạy). gdformat/gdlint/check/docs-check pass

## Còn mở
- Đèn/vùng bấm có thể bị nhắm xuyên tường nếu đứng sát tường ngoài (InteractArea là hình cầu, không raycast) — chấp nhận ở bản tạm
- Chưa có test GUT (chưa cài `addons/gut`); kiểm bằng smoke test scratchpad

## Evaluator
- 2026-11-04 đang chạy — tiêu chí bỏ tick tới khi có kết quả
