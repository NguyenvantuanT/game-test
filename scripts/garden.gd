@tool
class_name Garden
extends NamedArea
## Một khu vườn 3D: luống đất, `Fence` có cổng phía -X, các hàng cây (`Crop`), biển tên.
## Gốc toạ độ = tâm luống trên mặt đất. Hình và collision sinh trong code theo export.
## Cây bắt đầu ở giai đoạn ngẫu nhiên (seed theo tên vườn → lần chạy nào cũng giống nhau).

enum PlantKind { VEGETABLE, FLOWER }

## Tên vật phẩm theo PlantKind (World đếm lên HUD).
const ITEM_NAMES: Array[String] = ["Rau", "Hoa"]

const SOIL_HEIGHT: float = 0.12
const FENCE_HEIGHT: float = 0.7
const PLANT_SPACING: float = 0.9
const EDGE_MARGIN: float = 0.6
const TRIGGER_HEIGHT: float = 2.0

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
var _crops: Array[Crop] = []


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
	Fence.build(_generated, size, Vector3.LEFT, FENCE_HEIGHT)
	_build_plants()
	_build_sign()


## Các cây đang có (bản sao — smoke test dùng để duyệt từng cây).
func crops() -> Array[Crop]:
	return _crops.duplicate()


func _build_plants() -> void:
	_crops.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(display_name)
	var inner := size - Vector2.ONE * EDGE_MARGIN * 2.0
	var per_row := maxi(1, floori(inner.x / PLANT_SPACING) + 1)
	var start_x := -(per_row - 1) * PLANT_SPACING / 2.0
	var row_gap := size.y / (row_count + 1)
	for row in row_count:
		var z := -size.y / 2.0 + row_gap * (row + 1)
		for col in per_row:
			var crop := Crop.new()
			crop.name = "Crop_%d_%d" % [row, col]
			crop.position = Vector3(start_x + col * PLANT_SPACING, SOIL_HEIGHT, z)
			_generated.add_child(crop)
			# ~1/6 cây đã chín sẵn để vào vườn là có thể thu hoạch ngay.
			crop.setup(plant_kind == PlantKind.FLOWER, soil_color, plant_color, rng.randf() * 1.2)
			crop.harvested.connect(_on_crop_harvested)
			_crops.append(crop)


func _on_crop_harvested() -> void:
	collected.emit(ITEM_NAMES[plant_kind])


func _build_sign() -> void:
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 16
	label.pixel_size = 0.01
	label.position = Vector3(0.0, 1.8, -size.y / 2.0)
	_generated.add_child(label)
