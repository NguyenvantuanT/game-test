extends Node3D
## Scene chính 3D: bãi cỏ, ngôi nhà, 2 khu vườn, nhân vật và HUD tên khu vực.
## Map nằm trên mặt XZ từ (0, 0) tới MAP_SIZE (mét).

const MAP_SIZE: Vector2 = Vector2(40.0, 25.0)
const OUTSIDE_TEXT: String = "Sân nhà"

var _current_garden: Garden = null

@onready var _gardens: Node3D = $Gardens
@onready var _area_label: Label = %AreaLabel


func _ready() -> void:
	_build_map_bounds()
	for garden: Garden in _gardens.get_children():
		garden.player_entered.connect(_on_garden_entered)
		garden.player_exited.connect(_on_garden_exited)
	_area_label.text = OUTSIDE_TEXT


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


func _on_garden_entered(garden: Garden) -> void:
	_current_garden = garden
	_area_label.text = garden.display_name


func _on_garden_exited(garden: Garden) -> void:
	if garden == _current_garden:
		_current_garden = null
		_area_label.text = OUTSIDE_TEXT
