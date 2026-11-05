# ARCHITECTURE

Bản đồ cấp cao. Mọi đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại — đổi tên file thì sửa ở đây.

Trạng thái: 1 map 3D (nhà 2 tầng vào được + 2 vườn), camera chéo cố định, nhân vật đi dạo, bấm E tương tác (cửa, đèn, TV, bàn thờ), làm vườn (tưới, bón phân, thu hoạch). Hình khối tạm (BoxMesh/PrismMesh/SphereMesh), chưa có model thật. Bản 2D cũ ở commit `8aacf97`.

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
| World (map, HUD) | `scenes/world.tscn` | `scripts/world.gd` | Map 40×25 m trên mặt XZ, gốc (0,0). Mặt biên `WorldBoundaryShape3D` sinh trong code. HUD: tên NamedArea vào gần nhất (stack, ngưỡng cửa chồng nhau) + gợi ý `[E] ...` + đếm rau/hoa đã thu hoạch (nghe `Garden.crop_harvested`) |
| Player | `scenes/player.tscn` | `scripts/player.gd` | `CharacterBody3D`, action `move_*` + `interact`; `InteractArea` chọn `Interactable` gần nhất, báo `focus_changed`. Camera3D chéo là con, `set_camera_close()` khi vào nhà |
| House | `scenes/house.tscn` | `scripts/house.gd` | 14×10 m, 2 tầng (sàn tầng 2 cao 3 m). Tầng 1: khách, bếp, ngủ, tắm; tầng 2: phòng thờ (trước), sảnh cầu thang (giữa), 2 phòng ngủ, nhà vệ sinh (sau). Tường/sàn sinh từ `WALLS`/`FLOORS` theo tầng. Cầu thang: bậc là hình, collision là dốc trơn; ô cầu thang tầng 2 có lan can. Cutaway theo tầng Player đứng (độ cao > 1.5 m = tầng 2): tầng 1 ẩn mái + cả tầng 2 (`Upstairs` + hình sinh) + nửa trên tường tầng 1; tầng 2 ẩn mái + nửa trên tường tầng 2. Phòng = `NamedArea` trong .tscn |
| Đồ đạc | (trong `scenes/house.tscn`) | `scripts/furniture.gd` | `StaticBody3D` @tool dựng theo `kind`, gốc = chân đồ, mặt trước +Z |
| Đồ tương tác | (trong `scenes/house.tscn`) | `scripts/door.gd`, `scripts/lamp.gd`, `scripts/tv.gd`, `scripts/altar.gd` | Tự tạo `Interactable`, nghe `interacted`, cập nhật `prompt`. Cửa = `AnimatableBody3D` xoay, đóng thì chặn |
| Garden | `scenes/garden.tscn` | `scripts/garden.gd` | `NamedArea` @tool: đất, rào có collision (cổng phía -X), các hàng `Crop`, Label3D sinh trong code. Giai đoạn ban đầu random, seed theo tên vườn |
| Crop (cây trong vườn) | (Garden sinh) | `scripts/crop.gd` | @tool, mỗi cây 1 `Interactable`. Chỉ lớn khi ẩm (tưới giữ 30 s), phân x2 tốc độ 30 s, ~90 s tới chín. E: thu hoạch > tưới > bón. `advance(delta)` để test tua thời gian. Không collision, không lưu trạng thái |
| Helper | — | `scripts/mesh_kit.gd`, `scripts/named_area.gd`, `scripts/interactable.gd` | `MeshKit` dựng khối + cache material theo màu (chỉ đọc); `NamedArea` vùng có tên (group `named_areas`); `Interactable` vùng bấm E (layer 3) |

Collision layer: 1 = world (tường, đồ đạc, cửa, biên map), 2 = player, 3 = interactable. NamedArea chỉ mask layer 2; `InteractArea` của Player chỉ mask layer 3.

## Entry points

- Config project: `project.godot` — main scene `scenes/world.tscn`, input map `move_*`, `interact` (E).
