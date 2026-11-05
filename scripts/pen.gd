@tool
class_name Pen
extends NamedArea
## Chuồng nuôi: nền đất, `Fence` có cổng phía -Z, máng ăn sát rào +Z, biển tên trên cổng
## và `animal_count` con `Animal` cùng loài. Gốc = tâm chuồng trên mặt đất.
## Hình sinh trong code theo export; con vật bắt đầu ở trạng thái ngẫu nhiên (seed theo tên).

const FENCE_HEIGHT: float = 0.9
const FLOOR_HEIGHT: float = 0.03
const TRIGGER_HEIGHT: float = 2.5
const WALL_MARGIN: float = 0.3  ## Khoảng con vật cách rào.
const TROUGH_SIZE: Vector3 = Vector3(1.6, 0.3, 0.4)
const TROUGH_COLOR: Color = Color(0.45, 0.3, 0.16)
const HAY_COLOR: Color = Color(0.9, 0.78, 0.35)

@export var size: Vector2 = Vector2(5.5, 6.0):
	set(value):
		size = value
		_rebuild()
@export var animal_kind: Animal.Kind = Animal.Kind.CHICKEN:
	set(value):
		animal_kind = value
		_rebuild()
@export_range(1, 8) var animal_count: int = 3:
	set(value):
		animal_count = value
		_rebuild()
@export var floor_color: Color = Color(0.62, 0.52, 0.32):
	set(value):
		floor_color = value
		_rebuild()

var _generated: Node3D = null
## Shape của Area3D phải là con trực tiếp, nên tách khỏi `_generated`.
var _trigger: CollisionShape3D = null
var _animals: Array[Animal] = []


func _ready() -> void:
	super()
	_rebuild()


func _on_display_name_changed() -> void:
	_rebuild()


## Các con vật đang có (bản sao — smoke test dùng để duyệt từng con).
func animals() -> Array[Animal]:
	return _animals.duplicate()


## Xoá và dựng lại toàn bộ phần sinh tự động (không lưu vào .tscn vì không có owner).
func _rebuild() -> void:
	if not is_node_ready():
		return
	if _generated != null:
		_generated.free()
	if _trigger != null:
		_trigger.free()
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)
	_trigger = MeshKit.collider(
		self, Vector3(size.x, TRIGGER_HEIGHT, size.y), Vector3(0.0, TRIGGER_HEIGHT / 2.0, 0.0)
	)
	MeshKit.box(
		_generated,
		Vector3(size.x, FLOOR_HEIGHT, size.y),
		Vector3(0.0, FLOOR_HEIGHT / 2.0, 0.0),
		floor_color
	)
	Fence.build(_generated, size, Vector3.FORWARD, FENCE_HEIGHT)
	_build_trough()
	_build_animals()
	_build_sign()


func _build_trough() -> void:
	var body := StaticBody3D.new()
	body.name = "Trough"
	body.collision_layer = Fence.WORLD_LAYER
	body.collision_mask = 0
	body.position = Vector3(0.0, 0.0, size.y / 2.0 - TROUGH_SIZE.z)
	_generated.add_child(body)
	var center := Vector3(0.0, TROUGH_SIZE.y / 2.0, 0.0)
	MeshKit.box(body, TROUGH_SIZE, center, TROUGH_COLOR)
	MeshKit.box(
		body,
		Vector3(TROUGH_SIZE.x - 0.1, 0.04, TROUGH_SIZE.z - 0.1),
		Vector3(0.0, TROUGH_SIZE.y, 0.0),
		HAY_COLOR
	)
	MeshKit.collider(body, TROUGH_SIZE, center)


func _build_animals() -> void:
	_animals.clear()
	var body := Animal.BODY_SIZE[animal_kind]
	var reach := maxf(body.x, body.z) / 2.0 + WALL_MARGIN
	var half := size / 2.0
	# Chừa chỗ máng ăn ở phía +Z.
	var bounds := Rect2(
		-half.x + reach,
		-half.y + reach,
		size.x - reach * 2.0,
		size.y - reach * 2.0 - TROUGH_SIZE.z * 2.0
	)
	var base_seed := hash(display_name)
	for i in animal_count:
		var animal := Animal.new()
		animal.name = "Animal_%d" % i
		# Xếp một hàng ngang giữa chuồng, sau đó tự đi lang thang.
		var t := (i + 0.5) / animal_count
		animal.position = Vector3(
			lerpf(bounds.position.x, bounds.end.x, t), 0.0, bounds.get_center().y
		)
		_generated.add_child(animal)
		animal.setup(animal_kind, bounds, base_seed + i)
		animal.collected.connect(collected.emit)
		_animals.append(animal)


func _build_sign() -> void:
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 16
	label.pixel_size = 0.01
	label.position = Vector3(0.0, 2.0, -size.y / 2.0)
	_generated.add_child(label)
