@tool
class_name Garden
extends Area3D
## Một khu vườn 3D: luống đất, hàng rào có cổng phía -X, các hàng cây, biển tên.
## Gốc toạ độ = tâm luống trên mặt đất. Hình và collision sinh trong code theo export
## (mỗi instance resource riêng, không dùng chung). Báo khi Player đi vào / ra.

signal player_entered(garden: Garden)
signal player_exited(garden: Garden)

enum PlantKind { VEGETABLE, FLOWER }

const SOIL_HEIGHT: float = 0.12
const FENCE_HEIGHT: float = 0.7
const FENCE_THICKNESS: float = 0.08
const POST_SIZE: float = 0.14
const GATE_WIDTH: float = 1.6
const PLANT_SPACING: float = 0.9
const EDGE_MARGIN: float = 0.6
const TRIGGER_HEIGHT: float = 2.0
const FENCE_COLOR: Color = Color(0.55, 0.38, 0.2)
const STEM_COLOR: Color = Color(0.25, 0.55, 0.2)
const WORLD_LAYER: int = 1

@export var display_name: String = "Vườn":
	set(value):
		display_name = value
		_rebuild()
@export var size: Vector2 = Vector2(8.0, 5.5):
	set(value):
		size = value
		_rebuild()
@export var soil_color: Color = Color(0.45, 0.3, 0.18):
	set(value):
		soil_color = value
		_rebuild()
@export var plant_color: Color = Color(0.3, 0.7, 0.25):
	set(value):
		plant_color = value
		_rebuild()
@export var plant_kind: PlantKind = PlantKind.VEGETABLE:
	set(value):
		plant_kind = value
		_rebuild()
@export_range(1, 10) var row_count: int = 4:
	set(value):
		row_count = value
		_rebuild()

var _generated: Node3D = null
## Shape của Area3D phải là con trực tiếp, nên tách khỏi `_generated`.
var _trigger: CollisionShape3D = null


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


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
	_build_trigger()
	_build_soil()
	_build_fence()
	_build_plants()
	_build_sign()


func _build_trigger() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, TRIGGER_HEIGHT, size.y)
	_trigger = CollisionShape3D.new()
	_trigger.name = "Trigger"
	_trigger.shape = shape
	_trigger.position.y = TRIGGER_HEIGHT / 2.0
	add_child(_trigger)


func _build_soil() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, SOIL_HEIGHT, size.y)
	mesh.material = _material(soil_color)
	_add_mesh(mesh, Vector3(0.0, SOIL_HEIGHT / 2.0, 0.0))


## Rào 4 cạnh, cạnh -X chừa cổng ở giữa. Có collision (layer world) để chỉ vào được qua cổng.
func _build_fence() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	_generated.add_child(body)
	var half := size / 2.0
	var material := _material(FENCE_COLOR)
	var side_len := (size.y - GATE_WIDTH) / 2.0
	var segments: Array[AABB] = [
		AABB(Vector3(-half.x, 0.0, -half.y), Vector3(size.x, 0.0, 0.0)),  # sau
		AABB(Vector3(-half.x, 0.0, half.y), Vector3(size.x, 0.0, 0.0)),  # trước
		AABB(Vector3(half.x, 0.0, -half.y), Vector3(0.0, 0.0, size.y)),  # phải
		AABB(Vector3(-half.x, 0.0, -half.y), Vector3(0.0, 0.0, side_len)),  # trái, trên cổng
		AABB(Vector3(-half.x, 0.0, GATE_WIDTH / 2.0), Vector3(0.0, 0.0, side_len)),  # trái, dưới cổng
	]
	for segment: AABB in segments:
		var extent := Vector3(
			maxf(segment.size.x, FENCE_THICKNESS), FENCE_HEIGHT, maxf(segment.size.z, FENCE_THICKNESS)
		)
		var center := segment.position + segment.size / 2.0 + Vector3(0.0, FENCE_HEIGHT / 2.0, 0.0)
		var rail := BoxMesh.new()
		rail.size = Vector3(extent.x, FENCE_HEIGHT * 0.35, extent.z)
		rail.material = material
		_add_mesh(rail, center + Vector3(0.0, FENCE_HEIGHT * 0.15, 0.0))
		var shape := BoxShape3D.new()
		shape.size = extent
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = center
		body.add_child(collision)
		for end: Vector3 in [segment.position, segment.position + segment.size]:
			var post := BoxMesh.new()
			post.size = Vector3(POST_SIZE, FENCE_HEIGHT, POST_SIZE)
			post.material = material
			_add_mesh(post, end + Vector3(0.0, FENCE_HEIGHT / 2.0, 0.0))


func _build_plants() -> void:
	var inner := size - Vector2.ONE * EDGE_MARGIN * 2.0
	var per_row := maxi(1, floori(inner.x / PLANT_SPACING) + 1)
	var start_x := -(per_row - 1) * PLANT_SPACING / 2.0
	var row_gap := size.y / (row_count + 1)
	var head := SphereMesh.new()
	var stem: CylinderMesh = null
	var head_y: float
	if plant_kind == PlantKind.FLOWER:
		head.radius = 0.16
		head.height = 0.32
		stem = CylinderMesh.new()
		stem.top_radius = 0.03
		stem.bottom_radius = 0.03
		stem.height = 0.4
		stem.material = _material(STEM_COLOR)
		head_y = SOIL_HEIGHT + stem.height
	else:
		head.radius = 0.28
		head.height = 0.42
		head_y = SOIL_HEIGHT + head.height / 2.0
	head.material = _material(plant_color)
	for row in row_count:
		var z := -size.y / 2.0 + row_gap * (row + 1)
		for col in per_row:
			var x := start_x + col * PLANT_SPACING
			_add_mesh(head, Vector3(x, head_y, z))
			if stem != null:
				_add_mesh(stem, Vector3(x, SOIL_HEIGHT + stem.height / 2.0, z))


func _build_sign() -> void:
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 16
	label.pixel_size = 0.01
	label.position = Vector3(0.0, 1.8, -size.y / 2.0)
	_generated.add_child(label)


func _add_mesh(mesh: Mesh, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	_generated.add_child(instance)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_entered.emit(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_exited.emit(self)
