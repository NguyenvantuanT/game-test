@tool
class_name Garden
extends NamedArea
## Một khu vườn 3D: luống đất, hàng rào có cổng phía -X, các hàng cây, biển tên.
## Gốc toạ độ = tâm luống trên mặt đất. Hình và collision sinh trong code theo export.

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
	super()
	_rebuild()


func _on_display_name_changed() -> void:
	_rebuild()


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
		Vector3(size.x, SOIL_HEIGHT, size.y),
		Vector3(0.0, SOIL_HEIGHT / 2.0, 0.0),
		soil_color
	)
	_build_fence()
	_build_plants()
	_build_sign()


## Rào 4 cạnh, cạnh -X chừa cổng ở giữa. Có collision (layer world) để chỉ vào được qua cổng.
func _build_fence() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	_generated.add_child(body)
	var half := size / 2.0
	var side_len := (size.y - GATE_WIDTH) / 2.0
	var segments: Array[AABB] = [
		AABB(Vector3(-half.x, 0.0, -half.y), Vector3(size.x, 0.0, 0.0)),  # sau
		AABB(Vector3(-half.x, 0.0, half.y), Vector3(size.x, 0.0, 0.0)),  # trước
		AABB(Vector3(half.x, 0.0, -half.y), Vector3(0.0, 0.0, size.y)),  # phải
		AABB(Vector3(-half.x, 0.0, -half.y), Vector3(0.0, 0.0, side_len)),  # trái, trên cổng
		AABB(Vector3(-half.x, 0.0, GATE_WIDTH / 2.0), Vector3(0.0, 0.0, side_len)),  # trái, dưới
	]
	for segment: AABB in segments:
		var extent := Vector3(
			maxf(segment.size.x, FENCE_THICKNESS),
			FENCE_HEIGHT,
			maxf(segment.size.z, FENCE_THICKNESS)
		)
		var center := segment.position + segment.size / 2.0 + Vector3(0.0, FENCE_HEIGHT / 2.0, 0.0)
		MeshKit.box(
			_generated,
			Vector3(extent.x, FENCE_HEIGHT * 0.35, extent.z),
			center + Vector3(0.0, FENCE_HEIGHT * 0.15, 0.0),
			FENCE_COLOR
		)
		MeshKit.collider(body, extent, center)
		for end: Vector3 in [segment.position, segment.position + segment.size]:
			MeshKit.box(
				_generated,
				Vector3(POST_SIZE, FENCE_HEIGHT, POST_SIZE),
				end + Vector3(0.0, FENCE_HEIGHT / 2.0, 0.0),
				FENCE_COLOR
			)


func _build_plants() -> void:
	var inner := size - Vector2.ONE * EDGE_MARGIN * 2.0
	var per_row := maxi(1, floori(inner.x / PLANT_SPACING) + 1)
	var start_x := -(per_row - 1) * PLANT_SPACING / 2.0
	var row_gap := size.y / (row_count + 1)
	var is_flower := plant_kind == PlantKind.FLOWER
	var stem_height := 0.4
	for row in row_count:
		var z := -size.y / 2.0 + row_gap * (row + 1)
		for col in per_row:
			var x := start_x + col * PLANT_SPACING
			if is_flower:
				MeshKit.cylinder(
					_generated,
					0.03,
					stem_height,
					Vector3(x, SOIL_HEIGHT + stem_height / 2.0, z),
					STEM_COLOR
				)
				MeshKit.sphere(
					_generated, 0.16, Vector3(x, SOIL_HEIGHT + stem_height, z), plant_color
				)
			else:
				MeshKit.sphere(_generated, 0.26, Vector3(x, SOIL_HEIGHT + 0.2, z), plant_color)


func _build_sign() -> void:
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 16
	label.pixel_size = 0.01
	label.position = Vector3(0.0, 1.8, -size.y / 2.0)
	_generated.add_child(label)
