# ARCHITECTURE

Bản đồ cấp cao. Mọi đường dẫn trong backtick được `docs-check.sh` kiểm tra tồn tại — đổi tên file thì sửa ở đây.

Trạng thái: 1 map 3D (nhà 2 tầng vào được + 2 vườn + 3 chuồng nuôi + 2 nhà hàng xóm), camera chéo cố định, nhân vật đi dạo, bấm E tương tác (cửa, đèn, TV, bàn thờ), làm vườn (tưới, bón phân, thu hoạch), chăn nuôi (cho ăn, thu trứng / sữa / len), nói chuyện với hàng xóm (hội thoại rẽ nhánh có lựa chọn, kịch bản viết sẵn). Hình khối tạm (BoxMesh/PrismMesh/SphereMesh), chưa có model thật. Bản 2D cũ ở commit `8aacf97`.

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
| World (map, HUD) | `scenes/world.tscn` | `scripts/world.gd` | Map 56×25 m trên mặt XZ, gốc (0,0). Mặt biên `WorldBoundaryShape3D` sinh trong code. HUD: tên NamedArea vào gần nhất (stack, ngưỡng cửa chồng nhau) + gợi ý `[E] ...` + đếm vật phẩm theo tên (nghe `NamedArea.collected` của mọi vùng; thứ tự = `Garden.ITEM_NAMES` + `Animal.ITEM_NAMES`) |
| Player | `scenes/player.tscn` | `scripts/player.gd` | `CharacterBody3D`, action `move_*` + `interact`; `InteractArea` chọn `Interactable` gần nhất, báo `focus_changed`. Camera3D chéo là con, `set_camera_close()` khi vào nhà |
| House | `scenes/house.tscn` | `scripts/house.gd` | 14×10 m, 2 tầng (sàn tầng 2 cao 3 m). Tầng 1: khách, bếp, ngủ, tắm; tầng 2: phòng thờ (trước), sảnh cầu thang (giữa), 2 phòng ngủ, nhà vệ sinh (sau). Tường/sàn sinh từ `WALLS`/`FLOORS` theo tầng. Cầu thang: bậc là hình, collision là dốc trơn; ô cầu thang tầng 2 có lan can. Cutaway theo tầng Player đứng (độ cao > 1.5 m = tầng 2): tầng 1 ẩn mái + cả tầng 2 (`Upstairs` + hình sinh) + nửa trên tường tầng 1; tầng 2 ẩn mái + nửa trên tường tầng 2. Phòng = `NamedArea` trong .tscn |
| Đồ đạc | (trong `scenes/house.tscn`) | `scripts/furniture.gd` | `StaticBody3D` @tool dựng theo `kind`, gốc = chân đồ, mặt trước +Z |
| Đồ tương tác | (trong `scenes/house.tscn`) | `scripts/door.gd`, `scripts/lamp.gd`, `scripts/tv.gd`, `scripts/altar.gd` | Tự tạo `Interactable`, nghe `interacted`, cập nhật `prompt`. Cửa = `AnimatableBody3D` xoay, đóng thì chặn |
| Garden | `scenes/garden.tscn` | `scripts/garden.gd` | `NamedArea` @tool: đất, `Fence` cổng phía -X, các hàng `Crop`, Label3D sinh trong code. Giai đoạn ban đầu random, seed theo tên vườn. Thu hoạch → `collected("Rau"/"Hoa")` |
| Pen (chuồng nuôi) | `scenes/pen.tscn` | `scripts/pen.gd` | `NamedArea` @tool: nền, `Fence` cổng phía -Z, máng ăn (+Z), biển tên, `animal_count` con `Animal` cùng `animal_kind`. 3 chuồng 5.5×6 m dưới node `Farm` trong world, nối lối đi `FarmLane` |
| Animal (con vật) | (Pen sinh) | `scripts/animal.gd` | `CharacterBody3D` @tool, layer world (chặn Player), floating; lang thang tới điểm ngẫu nhiên rồi nghỉ, vị trí kẹp trong `bounds`. Đói → E cho ăn → chờ (gà 30 s, cừu 45 s, bò 60 s) → sản phẩm nổi trên đầu → E thu → `collected`. `advance(delta)` để test tua. Không lưu trạng thái |
| NeighborHome (nhà hàng xóm) | `scenes/neighbor_home.tscn` | `scripts/neighbor_home.gd` | `NamedArea` @tool: sân, nhà kín 6×4.5 m (StaticBody3D layer world, mái lăng trụ, cửa / cửa sổ chỉ là hình) ở nửa sau sân, biển tên, 1 `Neighbor`. Mặt trước +Z, xoay node để quay ra đường. 2 nhà 9×10 m cạnh nhau dưới node `Neighbors` (x = 39.5, 49.5), phía bắc đường `ToNeighbors` (z = 13.5), sân trước quay về phía camera (nhà phía nam đường sẽ che sân của chính nó) |
| Neighbor (người hàng xóm) | (NeighborHome sinh) | `scripts/neighbor.gd` | `CharacterBody3D` @tool, layer world, floating; đi lang thang trong sân trước giống `Animal`. E → `talk_requested` (NeighborHome chuyển tiếp lên World); `talking` = đứng yên. Kịch bản theo `dialogue_id` |
| Hội thoại | (`DialogueBox` trong HUD của `scenes/world.tscn`) | `scripts/dialogues.gd`, `scripts/dialogue_box.gd` | `Dialogues`: kịch bản viết sẵn (const Dictionary, không AI) — nút = câu nói + 1–4 lựa chọn [câu Player, nút tiếp]; bắt đầu `start`, `""` = kết thúc; `problems()` kiểm nút hỏng (World push_error lúc debug). `DialogueBox`: tên người nói, câu, nút lựa chọn đánh số; chọn bằng phím 1–4 / chuột / mũi tên + E hoặc Enter; Esc đóng bất cứ lúc nào. World khoá Player (physics + input) và ẩn gợi ý `[E]` khi hộp mở |
| Crop (cây trong vườn) | (Garden sinh) | `scripts/crop.gd` | @tool, mỗi cây 1 `Interactable`. Chỉ lớn khi ẩm (tưới giữ 30 s), phân x2 tốc độ 30 s, ~90 s tới chín. E: thu hoạch > tưới > bón. `advance(delta)` để test tua thời gian. Không collision, không lưu trạng thái |
| Lưu game | (`SaveFlow` trong `scenes/world.tscn`, `LoginScreen` trong HUD) | `scripts/save_flow.gd`, `scripts/save_game.gd`, `scripts/cloud_save.gd`, `scripts/login_screen.gd` | `SaveFlow` (chạy cả khi paused): có `supabase.cfg` → dừng game, đăng nhập (tự vào bằng phiên cũ) → nạp bản của tài khoản; không có → nạp `SaveGame` slot `local`. Đóng cửa sổ → dừng game, hỏi Lưu và thoát / Thoát không lưu / Huỷ. `SaveGame`: JSON `user://saves/<slot>.json` có `version`, ghi file tạm rồi đổi tên, cờ `pending_upload` khi chưa gửi được. `CloudSave`: Supabase Auth + bảng `saves` qua HTTPRequest, tự làm mới token. World gom / nạp qua `save_data()` / `load_data()` (số đồ + `NamedArea.save_state()` của vườn, chuồng → `Crop` / `Animal`). Quyết định + schema: `docs/design-docs/2026-11-06-cloud-save.md` |
| Helper | — | `scripts/mesh_kit.gd`, `scripts/named_area.gd`, `scripts/interactable.gd`, `scripts/fence.gd` | `MeshKit` dựng khối + cache material theo màu (chỉ đọc); `NamedArea` vùng có tên (group `named_areas`, signal `collected(item)`); `Fence` rào có cổng ở một cạnh (vườn, chuồng); `Interactable` vùng bấm E (layer 3) |

Collision layer: 1 = world (tường, đồ đạc, cửa, rào, con vật, nhà và người hàng xóm, biên map), 2 = player, 3 = interactable. NamedArea chỉ mask layer 2; `InteractArea` của Player chỉ mask layer 3.

## Entry points

- Config project: `project.godot` — main scene `scenes/world.tscn`, input map `move_*`, `interact` (E).
