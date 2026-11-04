@tool
class_name Door
extends Node3D
## Cửa bản lề. Gốc = bản lề trên sàn; cánh cửa trải theo +X, rộng `width`.
## Mở = xoay +90° quanh Y (cánh quay về -Z, vào trong). Cánh là AnimatableBody3D nên
## đóng thì chặn Player. Bấm E mở/đóng; vùng bấm đứng yên giữa khung cửa.

const HEIGHT: float = 2.15
const THICKNESS: float = 0.06
const OPEN_ANGLE: float = PI / 2.0
const SWING_TIME: float = 0.35
const PANEL_COLOR: Color = Color(0.45, 0.28, 0.15)
const KNOB_COLOR: Color = Color(0.85, 0.72, 0.3)

@export var width: float = 1.0
@export var is_open: bool = false

var _leaf: AnimatableBody3D = null
var _interactable: Interactable = null
var _tween: Tween = null


func _ready() -> void:
	_leaf = AnimatableBody3D.new()
	_leaf.name = "Leaf"
	_leaf.collision_layer = 1
	_leaf.collision_mask = 0
	add_child(_leaf)
	var panel_center := Vector3(width / 2.0, HEIGHT / 2.0, 0.0)
	var panel_size := Vector3(width - 0.02, HEIGHT, THICKNESS)
	MeshKit.box(_leaf, panel_size, panel_center, PANEL_COLOR)
	for side: float in [-1.0, 1.0]:
		MeshKit.sphere(
			_leaf, 0.04, Vector3(width - 0.12, 1.0, side * (THICKNESS / 2.0 + 0.03)), KNOB_COLOR
		)
	MeshKit.collider(_leaf, panel_size, panel_center)
	_leaf.rotation.y = OPEN_ANGLE if is_open else 0.0
	if Engine.is_editor_hint():
		return
	_interactable = Interactable.create(
		self, Vector3(width, 2.0, 1.6), Vector3(width / 2.0, 1.0, 0.0), ""
	)
	_interactable.interacted.connect(toggle)
	_update_prompt()


func toggle() -> void:
	is_open = not is_open
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_leaf, "rotation:y", OPEN_ANGLE if is_open else 0.0, SWING_TIME)
	_update_prompt()


func _update_prompt() -> void:
	_interactable.prompt = "Đóng cửa" if is_open else "Mở cửa"
