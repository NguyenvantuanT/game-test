class_name Player
extends CharacterBody3D
## Nhân vật đi 4 hướng trên mặt đất (WASD / phím mũi tên), bấm E tương tác vật gần nhất.
## Camera chéo cố định là con của Player nên đi theo mà không xoay;
## chỉ node `Model` xoay theo hướng đi.

## Prompt của vật đang nhắm ("" = không có gì để tương tác).
signal focus_changed(prompt: String)

const CAMERA_FAR: Vector3 = Vector3(0.0, 10.0, 8.0)
const CAMERA_NEAR: Vector3 = Vector3(0.0, 7.0, 5.6)
const CAMERA_TWEEN_TIME: float = 0.4

@export var speed: float = 5.0
@export var turn_speed: float = 12.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _focus: Interactable = null
var _camera_tween: Tween = null

@onready var _model: Node3D = $Model
@onready var _camera: Camera3D = $Camera3D
@onready var _interact_area: Area3D = $InteractArea


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= _gravity * delta
	move_and_slide()
	if direction != Vector3.ZERO:
		var target_yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _focus != null:
		_focus.interact()
		get_viewport().set_input_as_handled()


## Gọi khi vào / ra khỏi nhà: kéo camera lại gần cho dễ nhìn trong phòng.
func set_camera_close(close: bool) -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_camera_tween.tween_property(
		_camera, "position", CAMERA_NEAR if close else CAMERA_FAR, CAMERA_TWEEN_TIME
	)


## Nhắm vật gần nhất đang có việc để làm. Vật có prompt rỗng (vd cây đã tưới + bón)
## bị bỏ qua, để không che vật bên cạnh đang cần bấm E.
func _update_focus() -> void:
	var nearest: Interactable = null
	var best := INF
	for area: Area3D in _interact_area.get_overlapping_areas():
		var candidate := area as Interactable
		if candidate == null or candidate.prompt.is_empty():
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best:
			best = distance
			nearest = candidate
	if nearest == _focus:
		return
	if _focus != null:
		_focus.prompt_changed.disconnect(_emit_focus)
	_focus = nearest
	if _focus != null:
		_focus.prompt_changed.connect(_emit_focus)
	_emit_focus()


func _emit_focus() -> void:
	focus_changed.emit(_focus.prompt if _focus != null else "")
