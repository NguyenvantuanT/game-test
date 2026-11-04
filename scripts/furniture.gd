@tool
class_name Furniture
extends StaticBody3D
## Đồ đạc trang trí dựng từ khối cơ bản (hình tạm, thay bằng model sau).
## Gốc = tâm chân đồ trên sàn, mặt trước hướng +Z. Collision = 1 box bao quanh (trừ thảm).

enum Kind {
	SOFA,
	COFFEE_TABLE,
	TV_STAND,
	BOOKSHELF,
	RUG,
	PLANT,
	KITCHEN_COUNTER,
	STOVE,
	FRIDGE,
	DINING_TABLE,
	CHAIR,
	BED,
	NIGHTSTAND,
	WARDROBE,
	TOILET,
	VANITY,
	SHOWER,
}

const WOOD: Color = Color(0.55, 0.36, 0.22)
const DARK_WOOD: Color = Color(0.36, 0.23, 0.14)
const WHITE: Color = Color(0.95, 0.95, 0.93)
const STEEL: Color = Color(0.72, 0.74, 0.76)
const BLACK: Color = Color(0.12, 0.12, 0.13)
const FABRIC: Color = Color(0.36, 0.47, 0.6)
const CUSHION: Color = Color(0.45, 0.56, 0.7)
const COUNTER_TOP: Color = Color(0.3, 0.3, 0.32)
const GREEN: Color = Color(0.3, 0.62, 0.3)
const TERRACOTTA: Color = Color(0.75, 0.42, 0.28)
const GLASS: Color = Color(0.7, 0.88, 0.95, 0.3)
const MIRROR: Color = Color(0.8, 0.9, 0.95)
const BOOK_COLORS: Array[Color] = [
	Color(0.75, 0.25, 0.22),
	Color(0.25, 0.45, 0.7),
	Color(0.9, 0.75, 0.3),
	Color(0.35, 0.6, 0.35),
	Color(0.55, 0.35, 0.6),
]

@export var kind: Kind = Kind.SOFA:
	set(value):
		kind = value
		_rebuild()
## Màu nhấn (vải sofa, chăn, thảm). Để trống (alpha 0) = màu mặc định.
@export var accent: Color = Color(0, 0, 0, 0):
	set(value):
		accent = value
		_rebuild()

var _generated: Node3D = null
var _collision: CollisionShape3D = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _generated != null:
		_generated.free()
	if _collision != null:
		_collision.free()
		_collision = null
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)
	var footprint: AABB = call("_build_" + Kind.keys()[kind].to_lower())
	if footprint.size != Vector3.ZERO:
		_collision = MeshKit.collider(self, footprint.size, footprint.get_center())


func _accent(fallback: Color) -> Color:
	return accent if accent.a > 0.0 else fallback


func _box(size: Vector3, center: Vector3, color: Color) -> void:
	MeshKit.box(_generated, size, center, color)


## 4 chân vuông dưới mặt phẳng rộng `w`×`d`, cao `h`.
func _legs(w: float, d: float, h: float, color: Color, inset: float = 0.06) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(
				Vector3(0.06, h, 0.06),
				Vector3(sx * (w / 2.0 - inset), h / 2.0, sz * (d / 2.0 - inset)),
				color
			)


func _bounds(size: Vector3) -> AABB:
	return AABB(Vector3(-size.x / 2.0, 0.0, -size.z / 2.0), size)


func _build_sofa() -> AABB:
	var fabric := _accent(FABRIC)
	_box(Vector3(2.2, 0.42, 0.9), Vector3(0, 0.21, 0), fabric)
	_box(Vector3(2.2, 0.55, 0.22), Vector3(0, 0.62, -0.34), fabric)
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(0.2, 0.62, 0.9), Vector3(sx * 1.0, 0.31, 0), fabric)
		_box(Vector3(0.88, 0.12, 0.62), Vector3(sx * 0.45, 0.48, 0.08), CUSHION)
	return _bounds(Vector3(2.2, 0.9, 0.9))


func _build_coffee_table() -> AABB:
	_box(Vector3(1.1, 0.06, 0.6), Vector3(0, 0.42, 0), WOOD)
	_legs(1.1, 0.6, 0.39, DARK_WOOD)
	_box(Vector3(0.3, 0.04, 0.22), Vector3(0.2, 0.47, 0.05), BOOK_COLORS[0])
	return _bounds(Vector3(1.1, 0.45, 0.6))


func _build_tv_stand() -> AABB:
	_box(Vector3(1.6, 0.5, 0.45), Vector3(0, 0.25, 0), DARK_WOOD)
	for sx: float in [-0.4, 0.4]:
		_box(Vector3(0.7, 0.36, 0.02), Vector3(sx, 0.25, 0.23), WOOD)
	return _bounds(Vector3(1.6, 0.5, 0.45))


func _build_bookshelf() -> AABB:
	_box(Vector3(1.0, 2.0, 0.35), Vector3(0, 1.0, 0), DARK_WOOD)
	var book_index := 0
	for shelf in 4:
		var y := 0.18 + shelf * 0.47
		var x := -0.42
		while x < 0.4:
			var width := 0.06 + (book_index % 3) * 0.02
			var height := 0.28 + (book_index % 4) * 0.03
			_box(
				Vector3(width, height, 0.26),
				Vector3(x + width / 2.0, y + height / 2.0, 0.06),
				BOOK_COLORS[book_index % BOOK_COLORS.size()]
			)
			x += width + 0.015
			book_index += 1
	return _bounds(Vector3(1.0, 2.0, 0.35))


func _build_rug() -> AABB:
	_box(Vector3(2.4, 0.012, 1.6), Vector3(0, 0.028, 0), _accent(Color(0.75, 0.35, 0.3)))
	_box(Vector3(2.0, 0.014, 1.2), Vector3(0, 0.03, 0), Color(0.92, 0.85, 0.7))
	return AABB()


func _build_plant() -> AABB:
	MeshKit.cylinder(_generated, 0.2, 0.4, Vector3(0, 0.2, 0), TERRACOTTA)
	MeshKit.sphere(_generated, 0.32, Vector3(0, 0.72, 0), GREEN)
	MeshKit.sphere(_generated, 0.22, Vector3(0.12, 1.0, 0.05), GREEN)
	return _bounds(Vector3(0.5, 1.2, 0.5))


func _build_kitchen_counter() -> AABB:
	_box(Vector3(2.4, 0.88, 0.6), Vector3(0, 0.44, 0), WHITE)
	_box(Vector3(2.45, 0.05, 0.65), Vector3(0, 0.905, 0.01), COUNTER_TOP)
	for i in 4:
		_box(
			Vector3(0.55, 0.7, 0.02), Vector3(-0.9 + i * 0.6, 0.42, 0.305), Color(0.88, 0.88, 0.86)
		)
	_box(Vector3(0.6, 0.03, 0.4), Vector3(-0.5, 0.92, 0.02), STEEL)
	MeshKit.cylinder(_generated, 0.02, 0.3, Vector3(-0.5, 1.07, -0.22), STEEL)
	_box(Vector3(0.03, 0.03, 0.16), Vector3(-0.5, 1.21, -0.15), STEEL)
	return _bounds(Vector3(2.45, 0.93, 0.65))


func _build_stove() -> AABB:
	_box(Vector3(0.7, 0.9, 0.62), Vector3(0, 0.45, 0), STEEL)
	_box(Vector3(0.56, 0.4, 0.02), Vector3(0, 0.38, 0.315), BLACK)
	_box(Vector3(0.68, 0.02, 0.6), Vector3(0, 0.91, 0), BLACK)
	for sx: float in [-0.17, 0.17]:
		for sz: float in [-0.14, 0.14]:
			MeshKit.cylinder(_generated, 0.09, 0.02, Vector3(sx, 0.93, sz), Color(0.3, 0.3, 0.3))
	return _bounds(Vector3(0.7, 0.94, 0.62))


func _build_fridge() -> AABB:
	_box(Vector3(0.8, 1.9, 0.7), Vector3(0, 0.95, 0), WHITE)
	_box(Vector3(0.78, 0.02, 0.02), Vector3(0, 1.25, 0.36), STEEL)
	for y: float in [0.8, 1.55]:
		_box(Vector3(0.04, 0.3, 0.04), Vector3(0.3, y, 0.38), STEEL)
	return _bounds(Vector3(0.8, 1.9, 0.75))


func _build_dining_table() -> AABB:
	_box(Vector3(1.6, 0.06, 0.9), Vector3(0, 0.75, 0), WOOD)
	_legs(1.6, 0.9, 0.72, DARK_WOOD, 0.1)
	MeshKit.cylinder(_generated, 0.1, 0.03, Vector3(0, 0.795, 0), WHITE)
	MeshKit.sphere(_generated, 0.06, Vector3(0, 0.84, 0), Color(0.9, 0.4, 0.2))
	return _bounds(Vector3(1.6, 0.78, 0.9))


func _build_chair() -> AABB:
	_box(Vector3(0.44, 0.05, 0.44), Vector3(0, 0.45, 0), WOOD)
	_legs(0.44, 0.44, 0.43, DARK_WOOD, 0.04)
	_box(Vector3(0.44, 0.45, 0.05), Vector3(0, 0.7, -0.2), WOOD)
	return _bounds(Vector3(0.44, 0.9, 0.44))


func _build_bed() -> AABB:
	_box(Vector3(1.6, 0.35, 2.1), Vector3(0, 0.175, 0), WOOD)
	_box(Vector3(1.5, 0.2, 2.0), Vector3(0, 0.45, 0), WHITE)
	_box(Vector3(1.6, 1.0, 0.08), Vector3(0, 0.5, -1.05), DARK_WOOD)
	for sx: float in [-0.37, 0.37]:
		_box(Vector3(0.6, 0.12, 0.35), Vector3(sx, 0.61, -0.75), Color(0.98, 0.98, 1.0))
	_box(Vector3(1.54, 0.06, 1.35), Vector3(0, 0.58, 0.3), _accent(Color(0.4, 0.55, 0.75)))
	return _bounds(Vector3(1.6, 1.0, 2.14))


func _build_nightstand() -> AABB:
	_box(Vector3(0.5, 0.55, 0.4), Vector3(0, 0.275, 0), WOOD)
	_box(Vector3(0.44, 0.2, 0.02), Vector3(0, 0.38, 0.205), DARK_WOOD)
	_box(Vector3(0.1, 0.02, 0.02), Vector3(0, 0.38, 0.22), STEEL)
	return _bounds(Vector3(0.5, 0.55, 0.42))


func _build_wardrobe() -> AABB:
	_box(Vector3(1.4, 2.1, 0.6), Vector3(0, 1.05, 0), WOOD)
	_box(Vector3(0.02, 2.0, 0.02), Vector3(0, 1.05, 0.305), DARK_WOOD)
	for sx: float in [-0.08, 0.08]:
		_box(Vector3(0.03, 0.25, 0.03), Vector3(sx, 1.1, 0.32), STEEL)
	return _bounds(Vector3(1.4, 2.1, 0.62))


func _build_toilet() -> AABB:
	MeshKit.cylinder(_generated, 0.18, 0.4, Vector3(0, 0.2, 0.05), WHITE)
	MeshKit.cylinder(_generated, 0.21, 0.04, Vector3(0, 0.42, 0.08), Color(0.9, 0.9, 0.9))
	_box(Vector3(0.42, 0.42, 0.18), Vector3(0, 0.6, -0.24), WHITE)
	return _bounds(Vector3(0.45, 0.8, 0.7))


func _build_vanity() -> AABB:
	_box(Vector3(0.9, 0.8, 0.5), Vector3(0, 0.4, 0), WOOD)
	_box(Vector3(0.92, 0.04, 0.52), Vector3(0, 0.82, 0), WHITE)
	MeshKit.cylinder(_generated, 0.18, 0.08, Vector3(0, 0.87, 0.04), WHITE)
	MeshKit.cylinder(_generated, 0.015, 0.18, Vector3(0, 0.93, -0.17), STEEL)
	_box(Vector3(0.7, 0.8, 0.03), Vector3(0, 1.55, -0.235), MIRROR)
	return _bounds(Vector3(0.92, 0.86, 0.52))


func _build_shower() -> AABB:
	_box(Vector3(1.0, 0.06, 1.0), Vector3(0, 0.03, 0), WHITE)
	_box(Vector3(1.0, 1.9, 0.03), Vector3(0, 1.0, 0.485), GLASS)
	_box(Vector3(0.03, 1.9, 1.0), Vector3(-0.485, 1.0, 0), GLASS)
	MeshKit.cylinder(_generated, 0.015, 1.0, Vector3(0.4, 1.5, -0.44), STEEL)
	MeshKit.cylinder(_generated, 0.1, 0.03, Vector3(0.4, 2.0, -0.35), STEEL)
	return _bounds(Vector3(1.0, 2.0, 1.0))
