# ARCHITECTURE

Bản đồ cấp cao. Mọi đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại — đổi tên file thì sửa ở đây.

Trạng thái: 1 map 3D (nhà + 2 vườn), camera chéo cố định, nhân vật đi dạo. Hình khối tạm (BoxMesh/PrismMesh/SphereMesh), chưa có model thật. Bản 2D cũ ở commit `8aacf97`.

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
| World (map, HUD) | `scenes/world.tscn` | `scripts/world.gd` | Map 40×25 m trên mặt XZ, gốc (0,0). Mặt biên `WorldBoundaryShape3D` sinh trong code, HUD hiện tên khu vực |
| Player | `scenes/player.tscn` | `scripts/player.gd` | `CharacterBody3D`, action `move_*`; Camera3D chéo là con của Player, chỉ `Model` xoay |
| House | `scenes/house.tscn` | `scripts/house.gd` | `StaticBody3D`, khối dựng trong .tscn, cửa hướng +Z |
| Garden | `scenes/garden.tscn` | `scripts/garden.gd` | `Area3D` @tool: đất, rào có collision (cổng phía -X), cây, Label3D sinh trong code; signal `player_entered/exited` |

Collision layer: 1 = world (nhà, tường biên), 2 = player. Garden chỉ mask layer 2.

## Entry points

- Config project: `project.godot` — main scene `scenes/world.tscn`, input map `move_*`.
