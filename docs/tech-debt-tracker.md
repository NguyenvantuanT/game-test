# Tech debt tracker

Nợ kỹ thuật + xung đột rule ↔ code đã biết. Agent đọc file này thay vì đoán; `harness-gardening` cập nhật định kỳ. Xong thì xoá dòng (git giữ lịch sử).

| ID | Ở đâu | Vấn đề | Hướng xử lý | Trạng thái |
|---|---|---|---|---|
| TD-1 | máy dev | Chưa cài gdtoolkit → hook bỏ qua `gdlint`/`gdformat`. Agent đang chạy tạm bằng venv trong scratchpad, CI vẫn chạy đủ | `pip install gdtoolkit` | open |
| TD-3 | `scripts/crop.gd`, `scripts/animal.gd`, `scripts/neighbor.gd`, `scripts/house.gd`… | Chưa có test trong repo: logic lớn của cây (`Crop.advance`), con vật (`Animal.advance`, đi lang thang), hàng xóm (đi lang thang trong sân, `DialogueBox` chọn nhánh), cutaway, cầu thang chỉ được kiểm bằng smoke test ở scratchpad của agent → người khác / CI không chạy lại được | Cài GUT vào `addons/gut`, chuyển smoke test thành `test/` (bắt đầu với `Crop.advance`: khô không lớn, phân x2, hết nước giữa chừng, chín dừng ở 1.0) | open |
| TD-2 | `project.godot` | Khai feature 4.5 nhưng editor đang dùng 4.7.2 | Mở bằng editor 4.7 để nâng config, hoặc cài lại 4.5 — chờ quyết định | open |
