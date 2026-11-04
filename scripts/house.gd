@tool
class_name House
extends StaticBody3D
## Ngôi nhà 14×10 m, 4 phòng. Gốc = tâm sàn, mặt trước (cửa chính) hướng +Z.
## Tường sinh từ WALLS: mỗi đoạn tường cắt làm 2 tầng hình — dưới CUT_HEIGHT luôn hiện,
## trên CUT_HEIGHT + mái ẩn khi Player ở trong nhà (cutaway) để camera chéo nhìn thấy phòng.
## Collision tường luôn đủ chiều cao. Đồ đạc, phòng, cửa là node con trong house.tscn.

signal player_inside_changed(inside: bool)

const SIZE: Vector2 = Vector2(14.0, 10.0)
const WALL_HEIGHT: float = 3.0
const WALL_THICKNESS: float = 0.2
const CUT_HEIGHT: float = 1.0
const DOOR_TOP: float = 2.2
const WINDOW_BOTTOM: float = 1.0
const WINDOW_TOP: float = 2.2

const WALL_COLOR: Color = Color(0.93, 0.87, 0.74)
const GLASS_COLOR: Color = Color(0.6, 0.82, 0.95, 0.35)
const FRAME_COLOR: Color = Color(0.98, 0.98, 0.96)

## Đoạn tường: [điểm đầu (x,z), điểm cuối (x,z), lỗ]. Lỗ: [vị trí tâm tính từ điểm đầu,
## rộng, đáy, đỉnh]. Đáy 0 = lối đi / cửa, đáy > 0 = cửa sổ.
const WALLS: Array = [
	# Ngoài — trước (z = +5): cửa chính, cửa sổ phòng khách, cửa sổ bếp
	[
		Vector2(-7, 5),
		Vector2(7, 5),
		[[5.0, 1.2, 0.0, DOOR_TOP], [2.0, 1.6, 1.0, 2.2], [11.0, 1.6, 1.0, 2.2]]
	],
	# Ngoài — sau (z = -5): cửa sổ phòng ngủ, cửa sổ nhỏ phòng tắm
	[Vector2(-7, -5), Vector2(7, -5), [[1.5, 1.4, 1.0, 2.2], [12.0, 0.8, 1.5, 2.2]]],
	# Ngoài — trái (x = -7): cửa sổ phòng ngủ
	[Vector2(-7, -5), Vector2(-7, 5), [[2.5, 1.6, 1.0, 2.2]]],
	# Ngoài — phải (x = +7): cửa sổ bếp
	[Vector2(7, -5), Vector2(7, 5), [[7.5, 1.6, 1.0, 2.2]]],
	# Trong — ngang (z = 0): lối vào phòng ngủ, cửa phòng tắm
	[Vector2(-7, 0), Vector2(7, 0), [[5.5, 1.0, 0.0, DOOR_TOP], [11.5, 1.0, 0.0, DOOR_TOP]]],
	# Trong — phòng khách | bếp (x = 1): mở rộng
	[Vector2(1, 0), Vector2(1, 5), [[2.5, 3.0, 0.0, 2.4]]],
	# Trong — phòng ngủ | phòng tắm (x = 3)
	[Vector2(3, -5), Vector2(3, 0), []],
]

## Sàn từng phòng: [tâm (x,z), kích thước, màu].
const FLOORS: Array = [
	[Vector2(-3, 2.5), Vector2(8, 5), Color(0.66, 0.48, 0.32)],  # phòng khách — gỗ
	[Vector2(4, 2.5), Vector2(6, 5), Color(0.86, 0.86, 0.82)],  # bếp — gạch
	[Vector2(-2, -2.5), Vector2(10, 5), Color(0.6, 0.44, 0.3)],  # phòng ngủ — gỗ
	[Vector2(5, -2.5), Vector2(4, 5), Color(0.78, 0.88, 0.92)],  # phòng tắm — gạch xanh
]

var _lower: Node3D = null
var _upper: Node3D = null

@onready var _roof: Node3D = $Roof
@onready var _interior: Area3D = $Interior


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	_interior.body_entered.connect(_on_interior_body.bind(true))
	_interior.body_exited.connect(_on_interior_body.bind(false))


func _build() -> void:
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	_lower = Node3D.new()
	_lower.name = "WallsLower"
	generated.add_child(_lower)
	_upper = Node3D.new()
	_upper.name = "WallsUpper"
	generated.add_child(_upper)
	for floor_data: Array in FLOORS:
		var center: Vector2 = floor_data[0]
		var extent: Vector2 = floor_data[1]
		MeshKit.box(
			generated,
			Vector3(extent.x, 0.02, extent.y),
			Vector3(center.x, 0.011, center.y),
			floor_data[2]
		)
	for wall: Array in WALLS:
		_build_wall(wall[0], wall[1], wall[2])


func _build_wall(from: Vector2, to: Vector2, openings: Array) -> void:
	var length := from.distance_to(to)
	var axis := (to - from).normalized()
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cursor := 0.0
	for opening: Array in sorted:
		var start: float = opening[0] - opening[1] / 2.0
		var end: float = opening[0] + opening[1] / 2.0
		_wall_piece(from, axis, cursor, start, 0.0, WALL_HEIGHT)
		_wall_piece(from, axis, start, end, 0.0, opening[2])
		_wall_piece(from, axis, start, end, opening[3], WALL_HEIGHT)
		if opening[2] > 0.0:
			_window_glass(from, axis, start, end, opening[2], opening[3])
		cursor = end
	_wall_piece(from, axis, cursor, length, 0.0, WALL_HEIGHT)


## Một khối tường từ s0..s1 dọc trục, cao bottom..top; tách hình ở CUT_HEIGHT.
func _wall_piece(
	from: Vector2, axis: Vector2, s0: float, s1: float, bottom: float, top: float
) -> void:
	if s1 - s0 <= 0.001 or top - bottom <= 0.001:
		return
	MeshKit.collider(
		self,
		_piece_size(axis, s1 - s0, top - bottom),
		_piece_center(from, axis, s0, s1, bottom, top)
	)
	if bottom < CUT_HEIGHT:
		var lower_top := minf(top, CUT_HEIGHT)
		MeshKit.box(
			_lower,
			_piece_size(axis, s1 - s0, lower_top - bottom),
			_piece_center(from, axis, s0, s1, bottom, lower_top),
			WALL_COLOR
		)
	if top > CUT_HEIGHT:
		var upper_bottom := maxf(bottom, CUT_HEIGHT)
		MeshKit.box(
			_upper,
			_piece_size(axis, s1 - s0, top - upper_bottom),
			_piece_center(from, axis, s0, s1, upper_bottom, top),
			WALL_COLOR
		)


func _window_glass(
	from: Vector2, axis: Vector2, s0: float, s1: float, bottom: float, top: float
) -> void:
	var center := _piece_center(from, axis, s0, s1, bottom, top)
	var along_x := absf(axis.x) > 0.5
	var glass_size := _piece_size(axis, s1 - s0, top - bottom)
	var sill_size := _piece_size(axis, s1 - s0 + 0.1, 0.06)
	if along_x:
		glass_size.z = 0.04
		sill_size.z = WALL_THICKNESS + 0.1
	else:
		glass_size.x = 0.04
		sill_size.x = WALL_THICKNESS + 0.1
	var parent := _upper if bottom >= CUT_HEIGHT else _lower
	MeshKit.box(parent, glass_size, center, GLASS_COLOR)
	MeshKit.box(parent, sill_size, Vector3(center.x, bottom, center.z), FRAME_COLOR)


func _piece_size(axis: Vector2, length: float, height: float) -> Vector3:
	if absf(axis.x) > 0.5:
		return Vector3(length, height, WALL_THICKNESS)
	return Vector3(WALL_THICKNESS, height, length)


func _piece_center(
	from: Vector2, axis: Vector2, s0: float, s1: float, bottom: float, top: float
) -> Vector3:
	var mid := from + axis * (s0 + s1) / 2.0
	return Vector3(mid.x, (bottom + top) / 2.0, mid.y)


func _on_interior_body(body: Node3D, inside: bool) -> void:
	if not body is Player:
		return
	_roof.visible = not inside
	_upper.visible = not inside
	player_inside_changed.emit(inside)
