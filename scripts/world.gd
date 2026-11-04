extends Node2D
## Scene chính: map cỏ, ngôi nhà, 2 khu vườn, nhân vật và HUD tên khu vực.

const MAP_RECT: Rect2i = Rect2i(0, 0, 1600, 1000)
const OUTSIDE_TEXT: String = "Sân nhà"

var _current_garden: Garden = null

@onready var _player: Player = $Player
@onready var _gardens: Node2D = $Gardens
@onready var _area_label: Label = %AreaLabel


func _ready() -> void:
	_player.set_camera_limits(MAP_RECT)
	_build_map_bounds()
	for garden: Garden in _gardens.get_children():
		garden.player_entered.connect(_on_garden_entered)
		garden.player_exited.connect(_on_garden_exited)
	_area_label.text = OUTSIDE_TEXT


## Tường vô hình quanh mép map để nhân vật không đi ra ngoài.
func _build_map_bounds() -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "MapBounds"
	var rect := Rect2(MAP_RECT)
	var edges: Array[Array] = [
		[rect.position, Vector2.DOWN],
		[rect.end, Vector2.UP],
		[rect.position, Vector2.RIGHT],
		[rect.end, Vector2.LEFT],
	]
	for edge: Array in edges:
		var shape := WorldBoundaryShape2D.new()
		shape.normal = edge[1]
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = edge[0]
		bounds.add_child(collision)
	add_child(bounds)


func _on_garden_entered(garden: Garden) -> void:
	_current_garden = garden
	_area_label.text = garden.display_name


func _on_garden_exited(garden: Garden) -> void:
	if garden == _current_garden:
		_current_garden = null
		_area_label.text = OUTSIDE_TEXT
