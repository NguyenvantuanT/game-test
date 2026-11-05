@tool
class_name Animal
extends CharacterBody3D
## Con vật trong chuồng: đi lang thang trong `bounds` rồi nghỉ; đói thì bấm E cho ăn, chờ
## PRODUCE_TIME giây thì có sản phẩm (trứng / sữa / len) nổi trên đầu, bấm E thu rồi lại đói.
## Gốc = chân con vật trên mặt đất, mặt trước hướng +Z. Pen tạo qua `setup()`.

signal collected(item: String)

enum Kind { CHICKEN, COW, SHEEP }
enum State { HUNGRY, PRODUCING, READY }

## Các mảng dưới đánh chỉ số theo Kind.
const ITEM_NAMES: Array[String] = ["Trứng", "Sữa", "Len"]
const COLLECT_PROMPTS: Array[String] = ["Nhặt trứng", "Vắt sữa", "Cắt lông"]
const PRODUCE_TIME: Array[float] = [30.0, 60.0, 45.0]
const SPEED: Array[float] = [1.1, 0.6, 0.8]
## Hộp va chạm (rộng X, cao Y, dài Z).
const BODY_SIZE: Array[Vector3] = [
	Vector3(0.36, 0.62, 0.46), Vector3(0.75, 1.3, 1.6), Vector3(0.62, 0.85, 0.95)
]
const FEED_PROMPT: String = "Cho ăn"
const LAYER: int = 1  ## world: Player bị con vật chặn.
const MASK: int = 1 | 2  ## rào, con khác, Player.
const ARRIVE_DISTANCE: float = 0.15
const STUCK_TIME: float = 4.0
const REST_TIME: Vector2 = Vector2(1.0, 3.5)
const EAT_TIME: float = 2.0  ## Đứng yên ăn sau khi được cho ăn.
const TURN_SPEED: float = 8.0
const SPIN_SPEED: float = 1.5  ## Sản phẩm trên đầu xoay chậm cho dễ thấy.
const WOOL_SCALE: Vector2 = Vector2(0.82, 1.15)  ## Lông cừu: vừa cắt → đầy.
const WHITE: Color = Color(0.95, 0.94, 0.9)
const BLACK: Color = Color(0.12, 0.12, 0.12)
const PINK: Color = Color(0.93, 0.66, 0.66)
const ORANGE: Color = Color(0.95, 0.6, 0.15)
const RED: Color = Color(0.85, 0.15, 0.12)
const WOOL: Color = Color(0.92, 0.9, 0.84)
const DARK: Color = Color(0.22, 0.2, 0.2)
const EGG: Color = Color(0.96, 0.9, 0.76)
const BLUE: Color = Color(0.25, 0.45, 0.85)

var kind: Kind = Kind.CHICKEN
var state: State = State.HUNGRY
var produce_left: float = 0.0
## Vùng được đi (toạ độ local của node cha, x → X, y → Z).
var bounds: Rect2 = Rect2()

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _target: Vector3 = Vector3.ZERO
var _rest_left: float = 0.0
var _walk_time: float = 0.0
var _model: Node3D = null
var _wool: Node3D = null
var _product: Node3D = null
var _interactable: Interactable = null


func _ready() -> void:
	var running := not Engine.is_editor_hint()
	set_process(running)
	set_physics_process(running)


## Dựng hình + chọn trạng thái ban đầu ngẫu nhiên (theo `seed_value`, lặp lại được).
func setup(animal_kind: Kind, walk_bounds: Rect2, seed_value: int) -> void:
	kind = animal_kind
	bounds = walk_bounds
	_rng.seed = seed_value
	collision_layer = LAYER
	collision_mask = MASK
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var body := BODY_SIZE[kind]
	MeshKit.collider(self, body, Vector3(0.0, body.y / 2.0 + 0.05, 0.0))
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_product = Node3D.new()
	_product.name = "Product"
	_product.position.y = body.y + 0.35
	add_child(_product)
	match kind:
		Kind.CHICKEN:
			_build_chicken()
		Kind.COW:
			_build_cow()
		Kind.SHEEP:
			_build_sheep()
	var roll := _rng.randf()
	if roll < 0.35:
		state = State.HUNGRY
	elif roll < 0.7:
		state = State.PRODUCING
		produce_left = _rng.randf_range(0.2, 1.0) * PRODUCE_TIME[kind]
	else:
		state = State.READY
	rotation.y = _rng.randf() * TAU
	_rest_left = _rng.randf_range(0.0, REST_TIME.y)
	_pick_target()
	if not Engine.is_editor_hint():
		var reach := body + Vector3(0.4, 0.2, 0.4)
		_interactable = Interactable.create(self, reach, Vector3(0.0, reach.y / 2.0, 0.0), "")
		_interactable.interacted.connect(interact)
	_refresh()


func _process(delta: float) -> void:
	advance(delta)
	_product.rotate_y(SPIN_SPEED * delta)


func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if _rest_left > 0.0:
		_rest_left -= delta
		return
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < ARRIVE_DISTANCE or _walk_time > STUCK_TIME:
		_rest_left = _rng.randf_range(REST_TIME.x, REST_TIME.y)
		_pick_target()
		return
	_walk_time += delta
	var direction := to_target.normalized()
	velocity = direction * SPEED[kind]
	move_and_slide()
	# Kẹp trong chuồng: bị đẩy / xoay cũng không lọt ra cổng.
	position = Vector3(
		clampf(position.x, bounds.position.x, bounds.end.x),
		0.0,
		clampf(position.z, bounds.position.y, bounds.end.y)
	)
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), TURN_SPEED * delta)


## Cho thời gian sản xuất trôi `delta` giây. Tách khỏi `_process` để test tua nhanh được.
func advance(delta: float) -> void:
	if state == State.PRODUCING:
		produce_left = maxf(0.0, produce_left - delta)
		if produce_left == 0.0:
			state = State.READY
	_refresh()


## Việc bấm E sẽ làm; "" = đang chờ, chưa có gì để làm.
func action_prompt() -> String:
	match state:
		State.HUNGRY:
			return FEED_PROMPT
		State.READY:
			return COLLECT_PROMPTS[kind]
	return ""


func interact() -> void:
	match state:
		State.HUNGRY:
			feed()
		State.READY:
			collect()


func feed() -> void:
	if state != State.HUNGRY:
		return
	state = State.PRODUCING
	produce_left = PRODUCE_TIME[kind]
	_rest_left = maxf(_rest_left, EAT_TIME)
	_refresh()


func collect() -> void:
	if state != State.READY:
		return
	state = State.HUNGRY
	_refresh()
	collected.emit(ITEM_NAMES[kind])


func _pick_target() -> void:
	_walk_time = 0.0
	_target = Vector3(
		_rng.randf_range(bounds.position.x, bounds.end.x),
		0.0,
		_rng.randf_range(bounds.position.y, bounds.end.y)
	)


func _refresh() -> void:
	if _model == null:
		return
	_product.visible = state == State.READY
	if _wool != null:
		var full := 1.0
		if state == State.HUNGRY:
			full = 0.0
		elif state == State.PRODUCING:
			full = 1.0 - produce_left / PRODUCE_TIME[kind]
		_wool.scale = Vector3.ONE * lerpf(WOOL_SCALE.x, WOOL_SCALE.y, full)
	if _interactable != null:
		_interactable.prompt = action_prompt()


func _build_chicken() -> void:
	MeshKit.box(_model, Vector3(0.34, 0.3, 0.42), Vector3(0.0, 0.32, 0.0), WHITE)
	MeshKit.box(_model, Vector3(0.12, 0.16, 0.12), Vector3(0.0, 0.42, -0.24), WHITE)  # đuôi
	MeshKit.box(_model, Vector3(0.2, 0.2, 0.2), Vector3(0.0, 0.52, 0.2), WHITE)
	MeshKit.box(_model, Vector3(0.05, 0.08, 0.14), Vector3(0.0, 0.66, 0.2), RED)  # mào
	MeshKit.box(_model, Vector3(0.07, 0.06, 0.09), Vector3(0.0, 0.5, 0.34), ORANGE)  # mỏ
	for side: float in [-1.0, 1.0]:
		MeshKit.cylinder(_model, 0.025, 0.18, Vector3(side * 0.08, 0.09, 0.0), ORANGE)
	var egg := MeshKit.sphere(_product, 0.1, Vector3.ZERO, EGG)
	egg.scale = Vector3(1.0, 1.3, 1.0)


func _build_cow() -> void:
	MeshKit.box(_model, Vector3(0.7, 0.62, 1.3), Vector3(0.0, 0.85, 0.0), WHITE)
	MeshKit.box(_model, Vector3(0.72, 0.4, 0.35), Vector3(0.0, 0.92, 0.2), BLACK)  # đốm
	MeshKit.box(_model, Vector3(0.72, 0.3, 0.3), Vector3(0.0, 0.8, -0.4), BLACK)
	MeshKit.box(_model, Vector3(0.42, 0.42, 0.45), Vector3(0.0, 1.1, 0.82), WHITE)
	MeshKit.box(_model, Vector3(0.4, 0.2, 0.14), Vector3(0.0, 0.98, 1.1), PINK)  # mõm
	MeshKit.box(_model, Vector3(0.3, 0.14, 0.3), Vector3(0.0, 0.48, -0.3), PINK)  # bầu sữa
	for side: float in [-1.0, 1.0]:
		MeshKit.box(_model, Vector3(0.06, 0.16, 0.06), Vector3(side * 0.18, 1.38, 0.82), WHITE)
		for end: float in [-1.0, 1.0]:
			MeshKit.box(
				_model, Vector3(0.15, 0.55, 0.15), Vector3(side * 0.25, 0.275, end * 0.45), WHITE
			)
	MeshKit.cylinder(_product, 0.09, 0.26, Vector3.ZERO, WHITE)
	MeshKit.cylinder(_product, 0.06, 0.06, Vector3(0.0, 0.16, 0.0), BLUE)


func _build_sheep() -> void:
	_wool = Node3D.new()
	_wool.name = "Wool"
	_wool.position.y = 0.6
	_model.add_child(_wool)
	MeshKit.box(_wool, Vector3(0.6, 0.5, 0.8), Vector3.ZERO, WOOL)
	MeshKit.box(_model, Vector3(0.28, 0.3, 0.3), Vector3(0.0, 0.72, 0.5), DARK)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(_model, Vector3(0.1, 0.06, 0.16), Vector3(side * 0.19, 0.78, 0.46), DARK)
		for end: float in [-1.0, 1.0]:
			MeshKit.box(_model, Vector3(0.1, 0.4, 0.1), Vector3(side * 0.18, 0.2, end * 0.26), DARK)
	MeshKit.sphere(_product, 0.14, Vector3.ZERO, WOOL)
	MeshKit.sphere(_product, 0.1, Vector3(0.14, -0.03, 0.0), WOOL)
	MeshKit.sphere(_product, 0.1, Vector3(-0.14, -0.03, 0.0), WOOL)
