@tool
class_name NeighborHome
extends NamedArea
## Nhà hàng xóm: khoảnh sân `size`, căn nhà kín (không vào được) ở nửa sau sân, biển tên trên
## mái và một `Neighbor` đi lại trong sân trước (bấm E → `talk_requested`, World mở hội thoại).
## Gốc = tâm sân trên mặt đất, mặt trước (cửa) hướng +Z — xoay node để quay ra đường.
## Hình sinh trong code theo export.

signal talk_requested(neighbor: Neighbor)

const TRIGGER_HEIGHT: float = 3.0
const YARD_HEIGHT: float = 0.02
const HOUSE_SIZE: Vector3 = Vector3(6.0, 2.8, 4.5)
const ROOF_HEIGHT: float = 1.4
const ROOF_OVERHANG: float = 0.3
const BACK_MARGIN: float = 1.0  ## Sân sau nhà.
const WALK_MARGIN: float = 0.6  ## Khoảng người đi cách nhà và mép sân.
const MIN_SIZE: Vector2 = Vector2(7.0, 9.0)
const DOOR_SIZE: Vector2 = Vector2(1.0, 2.0)
const WINDOW_SIZE: Vector2 = Vector2(1.0, 0.9)
const DOOR_COLOR: Color = Color(0.45, 0.28, 0.15)
const GLASS_COLOR: Color = Color(0.6, 0.82, 0.95)

@export var size: Vector2 = Vector2(10.0, 10.0):
	set(value):
		size = value.max(MIN_SIZE)
		_rebuild()
@export var yard_color: Color = Color(0.62, 0.58, 0.4):
	set(value):
		yard_color = value
		_rebuild()
@export var wall_color: Color = Color(0.9, 0.84, 0.66):
	set(value):
		wall_color = value
		_rebuild()
@export var roof_color: Color = Color(0.7, 0.3, 0.2):
	set(value):
		roof_color = value
		_rebuild()
@export var shirt_color: Color = Color(0.3, 0.5, 0.8):
	set(value):
		shirt_color = value
		_rebuild()
## Khoá kịch bản hội thoại trong `Dialogues.ALL`.
@export var dialogue_id: String = ""

var _generated: Node3D = null
## Shape của Area3D phải là con trực tiếp, nên tách khỏi `_generated`.
var _trigger: CollisionShape3D = null
var _neighbor: Neighbor = null


func _ready() -> void:
	super()
	_rebuild()


func _on_display_name_changed() -> void:
	_rebuild()


## Người hàng xóm của nhà (smoke test dùng).
func neighbor() -> Neighbor:
	return _neighbor


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
		Vector3(size.x, YARD_HEIGHT, size.y),
		Vector3(0.0, YARD_HEIGHT / 2.0, 0.0),
		yard_color
	)
	var front_z := _build_house()
	_build_neighbor(front_z)


## Dựng nhà sát mép sau sân; trả về z của mặt trước nhà.
func _build_house() -> float:
	var back_z := -size.y / 2.0 + BACK_MARGIN
	var front_z := back_z + HOUSE_SIZE.z
	var center := Vector3(0.0, HOUSE_SIZE.y / 2.0, back_z + HOUSE_SIZE.z / 2.0)
	var body := StaticBody3D.new()
	body.name = "House"
	body.collision_layer = Fence.WORLD_LAYER
	body.collision_mask = 0
	_generated.add_child(body)
	MeshKit.box(body, HOUSE_SIZE, center, wall_color)
	MeshKit.collider(body, HOUSE_SIZE, center)
	# Lăng trụ quay 90° để nóc chạy dọc mặt trước (song song X).
	var roof := MeshKit.prism(
		body,
		Vector3(
			HOUSE_SIZE.z + ROOF_OVERHANG * 2.0, ROOF_HEIGHT, HOUSE_SIZE.x + ROOF_OVERHANG * 2.0
		),
		Vector3(center.x, HOUSE_SIZE.y + ROOF_HEIGHT / 2.0, center.z),
		roof_color
	)
	roof.rotation.y = PI / 2.0
	# Cửa và cửa sổ chỉ là hình dán trên mặt trước.
	var face_z := front_z + 0.02
	MeshKit.box(
		body,
		Vector3(DOOR_SIZE.x, DOOR_SIZE.y, 0.04),
		Vector3(0.0, DOOR_SIZE.y / 2.0, face_z),
		DOOR_COLOR
	)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(
			body,
			Vector3(WINDOW_SIZE.x, WINDOW_SIZE.y, 0.04),
			Vector3(side * HOUSE_SIZE.x / 3.5, 1.5, face_z),
			GLASS_COLOR
		)
	var sign_label := Label3D.new()
	sign_label.text = display_name
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.font_size = 72
	sign_label.outline_size = 16
	sign_label.pixel_size = 0.01
	sign_label.position = Vector3(0.0, HOUSE_SIZE.y + ROOF_HEIGHT + 0.6, center.z)
	_generated.add_child(sign_label)
	return front_z


func _build_neighbor(front_z: float) -> void:
	var reach := maxf(Neighbor.BODY_SIZE.x, Neighbor.BODY_SIZE.z) / 2.0 + WALK_MARGIN
	var half := size / 2.0
	var bounds := Rect2(
		-half.x + reach, front_z + reach, size.x - reach * 2.0, half.y - front_z - reach * 2.0
	)
	_neighbor = Neighbor.new()
	_neighbor.name = "Neighbor"
	_neighbor.position = Vector3(bounds.get_center().x, 0.0, bounds.get_center().y)
	_generated.add_child(_neighbor)
	_neighbor.setup(dialogue_id, bounds, shirt_color, hash(display_name))
	_neighbor.talk_requested.connect(talk_requested.emit)
