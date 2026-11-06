extends Node3D
## Scene chính 3D: bãi cỏ, ngôi nhà (vào được), 2 khu vườn, 3 chuồng nuôi, 2 nhà hàng xóm,
## nhân vật và HUD.
## Map nằm trên mặt XZ từ (0, 0) tới MAP_SIZE (mét).
## HUD: tên khu vực = NamedArea (phòng, vườn) vào gần nhất; gợi ý `[E] ...` từ Player;
## góc phải đếm vật phẩm thu được (NamedArea.collected từ vườn, chuồng); hộp hội thoại khi nói
## chuyện với hàng xóm (Player đứng yên tới khi đóng).
## Lưu game: `SaveFlow` (đăng nhập, tải / gửi, hỏi khi thoát) gọi `save_data` / `load_data`.

const MAP_SIZE: Vector2 = Vector2(56.0, 25.0)
const OUTSIDE_TEXT: String = "Sân nhà"

## Các vùng Player đang đứng trong, theo thứ tự vào (vùng chồng nhau ở ngưỡng cửa).
var _area_stack: Array[NamedArea] = []
## Số đã thu theo tên vật phẩm; thứ tự hiện trên HUD = `_item_order()`.
var _counts: Dictionary[String, int] = {}

@onready var _player: Player = $Player
@onready var _house: House = $House
@onready var _area_label: Label = %AreaLabel
@onready var _prompt_label: Label = %Prompt
@onready var _count_label: Label = %CountLabel
@onready var _dialogue: DialogueBox = %DialogueBox
@onready var _save_flow: SaveFlow = $SaveFlow


func _ready() -> void:
	_build_map_bounds()
	for node: Node in get_tree().get_nodes_in_group(NamedArea.GROUP):
		var area := node as NamedArea
		area.player_entered.connect(_on_area_entered)
		area.player_exited.connect(_on_area_exited)
		area.collected.connect(_on_collected)
		if area is NeighborHome:
			(area as NeighborHome).talk_requested.connect(_on_talk_requested)
	_dialogue.closed.connect(_set_player_active.bind(true))
	if OS.is_debug_build():
		for problem: String in Dialogues.problems():
			push_error("Kịch bản hội thoại: " + problem)
	_house.player_inside_changed.connect(_player.set_camera_close)
	_player.focus_changed.connect(_on_focus_changed)
	_refresh_area_label()
	_save_flow.setup(save_data, load_data)


## Số đã thu theo tên vật phẩm, vd "Rau", "Trứng" (smoke test đọc để kiểm HUD).
func item_count(item: String) -> int:
	return _counts.get(item, 0)


## Mặt phẳng vô hình quanh mép map để nhân vật không đi ra ngoài.
func _build_map_bounds() -> void:
	var bounds := StaticBody3D.new()
	bounds.name = "MapBounds"
	var far := Vector3(MAP_SIZE.x, 0.0, MAP_SIZE.y)
	var edges: Array[Array] = [
		[Vector3.ZERO, Vector3.RIGHT],
		[Vector3.ZERO, Vector3.BACK],
		[far, Vector3.LEFT],
		[far, Vector3.FORWARD],
	]
	for edge: Array in edges:
		var shape := WorldBoundaryShape3D.new()
		shape.plane = Plane(edge[1], edge[0])
		var collision := CollisionShape3D.new()
		collision.shape = shape
		bounds.add_child(collision)
	add_child(bounds)


func _on_area_entered(area: NamedArea) -> void:
	_area_stack.erase(area)
	_area_stack.append(area)
	_refresh_area_label()


func _on_area_exited(area: NamedArea) -> void:
	_area_stack.erase(area)
	_refresh_area_label()


func _refresh_area_label() -> void:
	_area_label.text = OUTSIDE_TEXT if _area_stack.is_empty() else _area_stack[-1].display_name


func _on_collected(item: String) -> void:
	_counts[item] = item_count(item) + 1
	_refresh_count_label()


func _refresh_count_label() -> void:
	var parts := PackedStringArray()
	for item: String in _item_order():
		parts.append("%s: %d" % [item, item_count(item)])
	_count_label.text = " · ".join(parts)


static func _item_order() -> Array[String]:
	var items: Array[String] = Garden.ITEM_NAMES.duplicate()
	items.append_array(Animal.ITEM_NAMES)
	return items


func _on_focus_changed(prompt: String) -> void:
	_prompt_label.visible = not prompt.is_empty()
	_prompt_label.text = "[E] " + prompt


func _on_talk_requested(neighbor: Neighbor) -> void:
	if _dialogue.open(neighbor):
		_set_player_active(false)


## Khoá / mở Player khi hội thoại mở / đóng; gợi ý `[E]` ẩn trong lúc nói chuyện.
func _set_player_active(active: bool) -> void:
	_player.set_physics_process(active)
	_player.set_process_unhandled_input(active)
	_prompt_label.visible = active and _prompt_label.text != "[E] "


## Trạng thái cần lưu: số đồ + trạng thái từng vùng (vườn, chuồng) theo đường dẫn node.
func save_data() -> Dictionary:
	var areas := {}
	for node: Node in get_tree().get_nodes_in_group(NamedArea.GROUP):
		var area := node as NamedArea
		var state := area.save_state()
		if not state.is_empty():
			areas[str(get_path_to(area))] = state
	return {"version": SaveGame.VERSION, "counts": _counts.duplicate(), "areas": areas}


## Nạp bản lưu (từ file / server: kiểm kiểu từng mục, mục lạ hoặc sai kiểu bỏ qua).
func load_data(data: Dictionary) -> void:
	if not SaveGame.is_valid(data):
		return
	var counts: Variant = data.get("counts")
	if counts is Dictionary:
		for item: String in _item_order():
			_counts[item] = maxi(0, int(SaveGame.number(counts, item)))
	var areas: Variant = data.get("areas")
	if areas is Dictionary:
		for key: Variant in areas:
			var area := get_node_or_null(NodePath(str(key))) as NamedArea
			if area != null and areas[key] is Array:
				area.load_state(areas[key])
	_refresh_count_label()
