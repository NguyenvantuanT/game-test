extends Node3D
## Scene chính 3D: bãi cỏ, ngôi nhà (vào được), 2 khu vườn, nhân vật và HUD.
## Map nằm trên mặt XZ từ (0, 0) tới MAP_SIZE (mét).
## HUD: tên khu vực = NamedArea (phòng, vườn) vào gần nhất; gợi ý `[E] ...` từ Player;
## góc phải đếm số rau / hoa đã thu hoạch từ các Garden.

const MAP_SIZE: Vector2 = Vector2(40.0, 25.0)
const OUTSIDE_TEXT: String = "Sân nhà"

## Các vùng Player đang đứng trong, theo thứ tự vào (vùng chồng nhau ở ngưỡng cửa).
var _area_stack: Array[NamedArea] = []
var _harvest_count: Dictionary[Garden.PlantKind, int] = {
	Garden.PlantKind.VEGETABLE: 0,
	Garden.PlantKind.FLOWER: 0,
}

@onready var _player: Player = $Player
@onready var _house: House = $House
@onready var _area_label: Label = %AreaLabel
@onready var _prompt_label: Label = %Prompt
@onready var _harvest_label: Label = %HarvestLabel


func _ready() -> void:
	_build_map_bounds()
	for node: Node in get_tree().get_nodes_in_group(NamedArea.GROUP):
		var area := node as NamedArea
		area.player_entered.connect(_on_area_entered)
		area.player_exited.connect(_on_area_exited)
		var garden := area as Garden
		if garden != null:
			garden.crop_harvested.connect(_on_crop_harvested)
	_house.player_inside_changed.connect(_player.set_camera_close)
	_player.focus_changed.connect(_on_focus_changed)
	_refresh_area_label()
	_refresh_harvest_label()


## Số đã thu hoạch theo loại (smoke test đọc để kiểm HUD).
func harvest_count(kind: Garden.PlantKind) -> int:
	return _harvest_count.get(kind, 0)


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


func _on_crop_harvested(kind: Garden.PlantKind) -> void:
	_harvest_count[kind] = _harvest_count.get(kind, 0) + 1
	_refresh_harvest_label()


func _refresh_harvest_label() -> void:
	_harvest_label.text = (
		"Rau: %d · Hoa: %d"
		% [_harvest_count[Garden.PlantKind.VEGETABLE], _harvest_count[Garden.PlantKind.FLOWER]]
	)


func _on_focus_changed(prompt: String) -> void:
	_prompt_label.visible = not prompt.is_empty()
	_prompt_label.text = "[E] " + prompt
