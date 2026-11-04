@tool
class_name NamedArea
extends Area3D
## Vùng có tên (phòng, khu vườn). Báo khi Player vào / ra; World gom qua group
## `named_areas` để hiện tên lên HUD. Shape: con CollisionShape3D trực tiếp (trong .tscn
## hoặc lớp con tự sinh).

signal player_entered(area: NamedArea)
signal player_exited(area: NamedArea)

const GROUP: StringName = &"named_areas"
const PLAYER_LAYER: int = 2

@export var display_name: String = "":
	set(value):
		display_name = value
		_on_display_name_changed()


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Lớp con override để cập nhật hình khi đổi tên (vd biển tên vườn).
func _on_display_name_changed() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_entered.emit(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_exited.emit(self)
