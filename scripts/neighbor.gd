@tool
class_name Neighbor
extends CharacterBody3D
## Người hàng xóm: đi lại trong `bounds` (sân trước) rồi nghỉ. Bấm E → báo `talk_requested`;
## World mở hộp thoại theo kịch bản `dialogue_id` (xem `Dialogues`) và bật `talking` để người
## đứng lại cho tới khi đóng. Gốc = chân trên mặt đất, mặt trước hướng +Z. NeighborHome tạo
## qua `setup()`.

signal talk_requested(neighbor: Neighbor)

const TALK_PROMPT: String = "Nói chuyện"
const SPEED: float = 1.0
## Hộp va chạm (rộng X, cao Y, dài Z).
const BODY_SIZE: Vector3 = Vector3(0.5, 1.7, 0.4)
const LAYER: int = 1  ## world: Player bị người chặn, như con vật.
const MASK: int = 1 | 2  ## nhà, biên, Player.
const ARRIVE_DISTANCE: float = 0.15
const STUCK_SLACK: float = 1.5  ## Giây dư so với thời gian đi tới đích, quá thì coi là kẹt.
const REST_TIME: Vector2 = Vector2(2.0, 5.0)
const TURN_SPEED: float = 8.0
const SKIN: Color = Color(0.94, 0.78, 0.62)
const HAIR: Color = Color(0.15, 0.12, 0.1)
const PANTS: Color = Color(0.25, 0.27, 0.35)

## Khoá trong `Dialogues.ALL`.
var dialogue_id: String = ""
## Vùng được đi (toạ độ local của node cha, x → X, y → Z).
var bounds: Rect2 = Rect2()
## Đang nói chuyện với Player: đứng yên.
var talking: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _target: Vector3 = Vector3.ZERO
var _rest_left: float = 0.0
var _walk_time: float = 0.0
var _walk_limit: float = 0.0


func _ready() -> void:
	# Chỉ chạy sau `setup()` (đã có hình) và không chạy trong editor.
	set_physics_process(false)


## Dựng hình + vị trí nghỉ ban đầu ngẫu nhiên (theo `seed_value`, lặp lại được).
func setup(script_id: String, walk_bounds: Rect2, shirt_color: Color, seed_value: int) -> void:
	dialogue_id = script_id
	bounds = walk_bounds
	_rng.seed = seed_value
	collision_layer = LAYER
	collision_mask = MASK
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	MeshKit.collider(self, BODY_SIZE, Vector3(0.0, BODY_SIZE.y / 2.0 + 0.05, 0.0))
	_build_model(shirt_color)
	rotation.y = _rng.randf() * TAU
	_rest_left = _rng.randf_range(0.0, REST_TIME.y)
	_pick_target()
	if not Engine.is_editor_hint():
		var reach := BODY_SIZE + Vector3(0.8, 0.2, 0.8)
		var interactable := Interactable.create(
			self, reach, Vector3(0.0, reach.y / 2.0, 0.0), TALK_PROMPT
		)
		interactable.interacted.connect(func() -> void: talk_requested.emit(self))
		set_physics_process(true)


func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if talking:
		return
	if _rest_left > 0.0:
		_rest_left -= delta
		return
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < ARRIVE_DISTANCE or _walk_time > _walk_limit:
		_rest_left = _rng.randf_range(REST_TIME.x, REST_TIME.y)
		_pick_target()
		return
	_walk_time += delta
	var direction := to_target.normalized()
	# `direction` ở toạ độ của nhà; velocity cần hướng global (nhà có thể bị xoay).
	var home_basis := (get_parent() as Node3D).global_basis
	velocity = home_basis * direction * SPEED
	move_and_slide()
	# Kẹp trong sân: bị Player đẩy cũng không ra khỏi sân.
	position = Vector3(
		clampf(position.x, bounds.position.x, bounds.end.x),
		0.0,
		clampf(position.z, bounds.position.y, bounds.end.y)
	)
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), TURN_SPEED * delta)


func _pick_target() -> void:
	_walk_time = 0.0
	_target = Vector3(
		_rng.randf_range(bounds.position.x, bounds.end.x),
		0.0,
		_rng.randf_range(bounds.position.y, bounds.end.y)
	)
	_walk_limit = position.distance_to(_target) / SPEED + STUCK_SLACK


func _build_model(shirt_color: Color) -> void:
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(model, Vector3(0.16, 0.8, 0.2), Vector3(side * 0.11, 0.4, 0.0), PANTS)
		MeshKit.box(model, Vector3(0.1, 0.6, 0.14), Vector3(side * 0.29, 1.12, 0.0), shirt_color)
		MeshKit.box(model, Vector3(0.09, 0.1, 0.1), Vector3(side * 0.29, 0.77, 0.0), SKIN)  # tay
		MeshKit.box(model, Vector3(0.05, 0.05, 0.02), Vector3(side * 0.07, 1.58, 0.15), HAIR)  # mắt
	MeshKit.box(model, Vector3(0.46, 0.62, 0.26), Vector3(0.0, 1.11, 0.0), shirt_color)
	MeshKit.box(model, Vector3(0.28, 0.3, 0.28), Vector3(0.0, 1.57, 0.0), SKIN)
	MeshKit.box(model, Vector3(0.3, 0.1, 0.3), Vector3(0.0, 1.74, -0.01), HAIR)
	MeshKit.box(model, Vector3(0.3, 0.2, 0.06), Vector3(0.0, 1.62, -0.14), HAIR)
