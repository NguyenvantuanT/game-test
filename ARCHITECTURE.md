# ARCHITECTURE

Bản đồ cấp cao. Mọi đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại — đổi tên file thì sửa ở đây.

Trạng thái: project trống, chưa có scene/script. Cập nhật file này khi thêm scene chính đầu tiên.

## Layer (hướng phụ thuộc chỉ đi xuống)

```
Scene / Node (gameplay, UI)        ← gọi xuống bằng method, báo lên bằng signal
Autoload / service (state, save)   ← không tham chiếu node cụ thể trong scene
Resource / data (.tres, class_name) ← không phụ thuộc node hay autoload
```

Pack godot chưa có rule layer → hướng phụ thuộc review tay.

## Domain

Chưa có domain. Thêm 1 dòng/domain khi có code: domain · scene · script/data · ghi chú.

## Entry points

- Config project: `project.godot` (chưa đặt `run/main_scene`).
