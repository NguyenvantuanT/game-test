# ARCHITECTURE

Bản đồ cấp cao. Mọi đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại — đổi tên file thì sửa ở đây.

Trạng thái: 1 map top-down (nhà + 2 vườn), nhân vật đi dạo. Hình khối tạm vẽ bằng `_draw()`, chưa có sprite.

## Layer (hướng phụ thuộc chỉ đi xuống)

```
Scene / Node (gameplay, UI)        ← gọi xuống bằng method, báo lên bằng signal
Autoload / service (state, save)   ← không tham chiếu node cụ thể trong scene
Resource / data (.tres, class_name) ← không phụ thuộc node hay autoload
```

Pack godot chưa có rule layer → hướng phụ thuộc review tay.

## Domain

| Domain | Scene | Script | Ghi chú |
|---|---|---|---|
| World (map, HUD) | `scenes/world.tscn` | `scripts/world.gd` | Map 1600×1000, tường biên sinh trong code, HUD hiện tên khu vực |
| Player | `scenes/player.tscn` | `scripts/player.gd` | `CharacterBody2D` floating, action `move_*` (WASD + mũi tên) |
| House | `scenes/house.tscn` | `scripts/house.gd` | `StaticBody2D`, chỉ là vật cản |
| Garden | `scenes/garden.tscn` | `scripts/garden.gd` | `Area2D`, signal `player_entered/exited`; 2 instance trong world |

Collision layer: 1 = world (nhà, tường biên), 2 = player. Garden chỉ mask layer 2.

## Entry points

- Config project: `project.godot` — main scene `scenes/world.tscn`, input map `move_*`.
