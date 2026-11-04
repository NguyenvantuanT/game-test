# Tech debt tracker

Nợ kỹ thuật + xung đột rule ↔ code đã biết. Agent đọc file này thay vì đoán; `harness-gardening` cập nhật định kỳ. Xong thì xoá dòng (git giữ lịch sử).

| ID | Ở đâu | Vấn đề | Hướng xử lý | Trạng thái |
|---|---|---|---|---|
| TD-1 | máy dev | Chưa cài gdtoolkit → hook bỏ qua `gdlint`/`gdformat` | `pip install gdtoolkit` | open |
| TD-2 | `project.godot` | Khai feature 4.5 nhưng editor đang dùng 4.7.2 | Mở bằng editor 4.7 để nâng config, hoặc cài lại 4.5 — chờ quyết định | open |
