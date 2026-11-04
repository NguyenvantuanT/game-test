@tool
class_name House
extends StaticBody3D
## Ngôi nhà 14×10 m, 2 tầng (sàn tầng 2 ở LEVEL_HEIGHT). Gốc = tâm sàn tầng 1, mặt trước
## (cửa chính) hướng +Z.
## Tầng 1: phòng khách, bếp, phòng ngủ, phòng tắm. Tầng 2: phòng thờ (trước), sảnh cầu thang
## (giữa), 2 phòng ngủ (hai bên), nhà vệ sinh (sau). Cầu thang sát tường giữa phía phòng ngủ
## tầng 1, lên từ -X sang +X, đỉnh trổ lên sảnh tầng 2.
## Tường sinh từ WALLS theo tầng; mỗi đoạn tách hình ở CUT_HEIGHT của tầng đó. Cutaway theo
## tầng Player đứng: tầng 1 → ẩn mái, cả tầng 2, nửa trên tường tầng 1; tầng 2 → ẩn mái, nửa
## trên tường tầng 2. Collision luôn đủ. Đồ đạc, phòng, cửa là node con trong house.tscn
## (đồ tầng 2 nằm dưới `Upstairs`, ẩn cùng tầng 2).

signal player_inside_changed(inside: bool)

const VIEW_OUTSIDE: int = -1

const SIZE: Vector2 = Vector2(14.0, 10.0)
const LEVEL_HEIGHT: float = 3.0
const WALL_HEIGHT: float = 3.0
const WALL_THICKNESS: float = 0.2
const SLAB_THICKNESS: float = 0.15
const CUT_HEIGHT: float = 1.0
const DOOR_TOP: float = 2.2

const WALL_COLOR: Color = Color(0.93, 0.87, 0.74)
const GLASS_COLOR: Color = Color(0.6, 0.82, 0.95, 0.35)
const FRAME_COLOR: Color = Color(0.98, 0.98, 0.96)
const STAIR_COLOR: Color = Color(0.82, 0.79, 0.74)
const TREAD_COLOR: Color = Color(0.5, 0.33, 0.2)
const RAIL_COLOR: Color = Color(0.32, 0.2, 0.12)

## Cầu thang: chân ở STAIR_FROM_X, đỉnh ở STAIR_TO_X (cao LEVEL_HEIGHT), chiếm STAIR_Z theo Z.
## Ô trống trên sàn tầng 2 trùng đúng vùng này.
const STAIR_FROM_X: float = -2.2
const STAIR_TO_X: float = 1.4
const STAIR_Z: Vector2 = Vector2(-1.3, -0.1)
const STAIR_STEPS: int = 12
## Dốc collision bắt đầu trước bậc đầu một đoạn để Player bước lên từ mặt sàn (không vướng mép).
const STAIR_RAMP_LEAD: float = 0.15
const RAIL_HEIGHT: float = 0.95
const RAIL_THICKNESS: float = 0.06

## Tường theo tầng. Đoạn tường: [điểm đầu (x,z), điểm cuối (x,z), lỗ]. Lỗ: [vị trí tâm tính
## từ điểm đầu, rộng, đáy, đỉnh] — tính từ sàn tầng đó. Đáy 0 = lối đi / cửa, > 0 = cửa sổ.
const WALLS: Array = [
	[
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
		# Trong — ngang (z = 0): lối vào phòng ngủ (cạnh chân cầu thang), cửa phòng tắm
		[Vector2(-7, 0), Vector2(7, 0), [[4.0, 1.0, 0.0, DOOR_TOP], [11.5, 1.0, 0.0, DOOR_TOP]]],
		# Trong — phòng khách | bếp (x = 1): mở rộng
		[Vector2(1, 0), Vector2(1, 5), [[2.5, 3.0, 0.0, 2.4]]],
		# Trong — phòng ngủ | phòng tắm (x = 3)
		[Vector2(3, -5), Vector2(3, 0), []],
	],
	[
		# Ngoài — trước: 2 cửa sổ phòng thờ (giữa để trống cho bàn thờ)
		[Vector2(-7, 5), Vector2(7, 5), [[3.5, 1.6, 1.0, 2.2], [10.5, 1.6, 1.0, 2.2]]],
		# Ngoài — sau: cửa sổ phòng ngủ 2, cửa sổ nhỏ nhà vệ sinh, cửa sổ phòng ngủ 3
		[
			Vector2(-7, -5),
			Vector2(7, -5),
			[[2.25, 1.4, 1.0, 2.2], [7.0, 0.8, 1.5, 2.2], [11.75, 1.4, 1.0, 2.2]]
		],
		# Ngoài — trái: cửa sổ phòng ngủ 2, cửa sổ phòng thờ
		[Vector2(-7, -5), Vector2(-7, 5), [[3.0, 1.4, 1.0, 2.2], [8.25, 1.2, 1.0, 2.2]]],
		# Ngoài — phải: cửa sổ phòng ngủ 3, cửa sổ phòng thờ
		[Vector2(7, -5), Vector2(7, 5), [[3.0, 1.4, 1.0, 2.2], [8.25, 1.2, 1.0, 2.2]]],
		# Trong — phòng thờ | phía sau (z = 1.5): lối vào phòng thờ, thẳng bàn thờ
		[Vector2(-7, 1.5), Vector2(7, 1.5), [[7.0, 1.4, 0.0, DOOR_TOP]]],
		# Trong — phòng ngủ 2 | sảnh + nhà vệ sinh (x = -2.5): cửa phòng ngủ 2
		[Vector2(-2.5, -5), Vector2(-2.5, 1.5), [[5.7, 1.0, 0.0, DOOR_TOP]]],
		# Trong — sảnh + nhà vệ sinh | phòng ngủ 3 (x = 2.5): cửa phòng ngủ 3
		[Vector2(2.5, -5), Vector2(2.5, 1.5), [[5.7, 1.0, 0.0, DOOR_TOP]]],
		# Trong — sảnh | nhà vệ sinh (z = -2): cửa nhà vệ sinh, cạnh đỉnh cầu thang
		[Vector2(-2.5, -2), Vector2(2.5, -2), [[4.45, 0.8, 0.0, DOOR_TOP]]],
	],
]

## Sàn theo tầng: [Rect2 trên mặt XZ (x, z, rộng, sâu), màu]. Tầng 1 chỉ là lớp phủ (đất có
## collision); tầng 2 là sàn bê tông có collision, các mảnh sảnh chừa ô cầu thang.
const FLOORS: Array = [
	[
		[Rect2(-7, 0, 8, 5), Color(0.66, 0.48, 0.32)],  # phòng khách — gỗ
		[Rect2(1, 0, 6, 5), Color(0.86, 0.86, 0.82)],  # bếp — gạch
		[Rect2(-7, -5, 10, 5), Color(0.6, 0.44, 0.3)],  # phòng ngủ — gỗ
		[Rect2(3, -5, 4, 5), Color(0.78, 0.88, 0.92)],  # phòng tắm — gạch xanh
	],
	[
		[Rect2(-7, 1.5, 14, 3.5), Color(0.72, 0.5, 0.34)],  # phòng thờ — gỗ đỏ
		[Rect2(-7, -5, 4.5, 6.5), Color(0.62, 0.46, 0.31)],  # phòng ngủ 2 — gỗ
		[Rect2(2.5, -5, 4.5, 6.5), Color(0.62, 0.46, 0.31)],  # phòng ngủ 3 — gỗ
		[Rect2(-2.5, -5, 5, 3), Color(0.78, 0.88, 0.92)],  # nhà vệ sinh — gạch xanh
		# Sảnh cầu thang (x -2.5..2.5, z -2..1.5) trừ ô cầu thang
		[Rect2(-2.5, -0.1, 5, 1.6), Color(0.84, 0.82, 0.78)],
		[Rect2(-2.5, -2, 5, 0.7), Color(0.84, 0.82, 0.78)],
		[Rect2(-2.5, -1.3, 0.3, 1.2), Color(0.84, 0.82, 0.78)],
		[Rect2(1.4, -1.3, 1.1, 1.2), Color(0.84, 0.82, 0.78)],
	],
]

## Gốc hình từng tầng (sàn, nửa dưới tường, lan can) và nửa trên tường (ẩn khi cutaway).
var _level_roots: Array[Node3D] = []
var _uppers: Array[Node3D] = []
var _player: Player = null
## Tầng đang nhìn: VIEW_OUTSIDE, 0 hoặc 1.
var _view: int = VIEW_OUTSIDE

@onready var _roof: Node3D = $Roof
@onready var _upstairs: Node3D = $Upstairs
@onready var _interior: Area3D = $Interior


func _ready() -> void:
	_build()
	set_physics_process(false)
	if Engine.is_editor_hint():
		return
	_interior.body_entered.connect(_on_interior_body.bind(true))
	_interior.body_exited.connect(_on_interior_body.bind(false))


func _physics_process(_delta: float) -> void:
	_set_view(level_at(_player.global_position.y))


## Tầng (0 / 1) ứng với độ cao toàn cục `y`: quá nửa LEVEL_HEIGHT tính là tầng 2.
func level_at(y: float) -> int:
	return 1 if y - global_position.y > LEVEL_HEIGHT * 0.5 else 0


func _build() -> void:
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	for level in WALLS.size():
		var root := Node3D.new()
		root.name = "Level%d" % (level + 1)
		generated.add_child(root)
		var upper := Node3D.new()
		upper.name = "WallsUpper"
		root.add_child(upper)
		_level_roots.append(root)
		_uppers.append(upper)
		_build_floors(level, root)
		for wall: Array in WALLS[level]:
			_build_wall(level, wall[0], wall[1], wall[2])
	_build_stairs(_level_roots[0])
	_build_stairwell_railings(_level_roots[1])


func _build_floors(level: int, parent: Node3D) -> void:
	var top := level * LEVEL_HEIGHT
	for floor_data: Array in FLOORS[level]:
		var rect: Rect2 = floor_data[0]
		var center := rect.get_center()
		if level == 0:
			MeshKit.box(
				parent,
				Vector3(rect.size.x, 0.02, rect.size.y),
				Vector3(center.x, 0.011, center.y),
				floor_data[1]
			)
			continue
		var size := Vector3(rect.size.x, SLAB_THICKNESS, rect.size.y)
		var position_3d := Vector3(center.x, top - SLAB_THICKNESS / 2.0, center.y)
		MeshKit.box(parent, size, position_3d, floor_data[1])
		MeshKit.collider(self, size, position_3d)


func _build_wall(level: int, from: Vector2, to: Vector2, openings: Array) -> void:
	var base := level * LEVEL_HEIGHT
	var length := from.distance_to(to)
	var axis := (to - from).normalized()
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cursor := 0.0
	for opening: Array in sorted:
		var start: float = opening[0] - opening[1] / 2.0
		var end: float = opening[0] + opening[1] / 2.0
		_wall_piece(level, from, axis, cursor, start, base, base + WALL_HEIGHT)
		_wall_piece(level, from, axis, start, end, base, base + opening[2])
		_wall_piece(level, from, axis, start, end, base + opening[3], base + WALL_HEIGHT)
		if opening[2] > 0.0:
			_window_glass(level, from, axis, start, end, base + opening[2], base + opening[3])
		cursor = end
	_wall_piece(level, from, axis, cursor, length, base, base + WALL_HEIGHT)


## Một khối tường từ s0..s1 dọc trục, cao bottom..top (toạ độ nhà); tách hình ở mức cắt
## của tầng `level`.
func _wall_piece(
	level: int, from: Vector2, axis: Vector2, s0: float, s1: float, bottom: float, top: float
) -> void:
	if s1 - s0 <= 0.001 or top - bottom <= 0.001:
		return
	MeshKit.collider(
		self,
		_piece_size(axis, s1 - s0, top - bottom),
		_piece_center(from, axis, s0, s1, bottom, top)
	)
	var cut := level * LEVEL_HEIGHT + CUT_HEIGHT
	if bottom < cut:
		var lower_top := minf(top, cut)
		MeshKit.box(
			_level_roots[level],
			_piece_size(axis, s1 - s0, lower_top - bottom),
			_piece_center(from, axis, s0, s1, bottom, lower_top),
			WALL_COLOR
		)
	if top > cut:
		var upper_bottom := maxf(bottom, cut)
		MeshKit.box(
			_uppers[level],
			_piece_size(axis, s1 - s0, top - upper_bottom),
			_piece_center(from, axis, s0, s1, upper_bottom, top),
			WALL_COLOR
		)


func _window_glass(
	level: int, from: Vector2, axis: Vector2, s0: float, s1: float, bottom: float, top: float
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
	var cut := level * LEVEL_HEIGHT + CUT_HEIGHT
	var parent := _uppers[level] if bottom >= cut else _level_roots[level]
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


## Bậc đặc (hình) + dốc trơn (collision) + tay vịn có collision ở cạnh hở (-Z).
func _build_stairs(parent: Node3D) -> void:
	var run := (STAIR_TO_X - STAIR_FROM_X) / STAIR_STEPS
	var rise := LEVEL_HEIGHT / STAIR_STEPS
	var width := STAIR_Z.y - STAIR_Z.x
	var mid_z := (STAIR_Z.x + STAIR_Z.y) / 2.0
	for i in STAIR_STEPS:
		var height := rise * (i + 1)
		var x := STAIR_FROM_X + run * (i + 0.5)
		MeshKit.box(
			parent,
			Vector3(run, height - 0.03, width),
			Vector3(x, (height - 0.03) / 2.0, mid_z),
			STAIR_COLOR
		)
		MeshKit.box(
			parent, Vector3(run + 0.02, 0.03, width), Vector3(x, height - 0.015, mid_z), TREAD_COLOR
		)
	var start := Vector2(STAIR_FROM_X - STAIR_RAMP_LEAD, 0.0)
	var end := Vector2(STAIR_TO_X, LEVEL_HEIGHT)
	var ramp := ConvexPolygonShape3D.new()
	ramp.points = PackedVector3Array(
		[
			Vector3(start.x, 0.0, STAIR_Z.x),
			Vector3(start.x, 0.0, STAIR_Z.y),
			Vector3(end.x, 0.0, STAIR_Z.x),
			Vector3(end.x, 0.0, STAIR_Z.y),
			Vector3(end.x, end.y, STAIR_Z.x),
			Vector3(end.x, end.y, STAIR_Z.y),
		]
	)
	var ramp_collision := CollisionShape3D.new()
	ramp_collision.name = "StairRamp"
	ramp_collision.shape = ramp
	add_child(ramp_collision)
	_sloped_rail(parent, start, end, STAIR_Z.x - RAIL_THICKNESS / 2.0, rise / run)


## Tay vịn dốc theo cầu thang ở mặt phẳng z = `z`, từ `start` tới `end` (x, y của mặt dốc).
func _sloped_rail(parent: Node3D, start: Vector2, end: Vector2, z: float, slope: float) -> void:
	var length := start.distance_to(end)
	var angle := atan2(end.y - start.y, end.x - start.x)
	var mid := (start + end) / 2.0
	var center := Vector3(mid.x, mid.y + RAIL_HEIGHT / 2.0, z)
	var collision := MeshKit.collider(self, Vector3(length, RAIL_HEIGHT, RAIL_THICKNESS), center)
	collision.rotation.z = angle
	var handrail := MeshKit.box(
		parent,
		Vector3(length, 0.05, RAIL_THICKNESS + 0.02),
		Vector3(mid.x, mid.y + RAIL_HEIGHT, z),
		RAIL_COLOR
	)
	handrail.rotation.z = angle
	var post_count := STAIR_STEPS / 2 + 1
	for i in post_count:
		var x := lerpf(STAIR_FROM_X, STAIR_TO_X, float(i) / (post_count - 1))
		var floor_y := clampf((x - STAIR_FROM_X) * slope, 0.0, LEVEL_HEIGHT)
		MeshKit.box(
			parent,
			Vector3(0.04, RAIL_HEIGHT, 0.04),
			Vector3(x, floor_y + RAIL_HEIGHT / 2.0, z),
			RAIL_COLOR
		)


## Lan can quanh ô cầu thang trên sàn tầng 2, chừa đầu +X (đỉnh cầu thang).
func _build_stairwell_railings(parent: Node3D) -> void:
	var y := LEVEL_HEIGHT
	var half := RAIL_THICKNESS / 2.0
	var north := STAIR_Z.y + half
	var south := STAIR_Z.x - half
	var west := STAIR_FROM_X - half
	_railing(parent, Vector3(west, y, north), Vector3(STAIR_TO_X, y, north))
	_railing(parent, Vector3(west, y, south), Vector3(STAIR_TO_X, y, south))
	_railing(parent, Vector3(west, y, south), Vector3(west, y, north))


## Lan can thẳng từ `from` tới `to` (chân, song song trục X hoặc Z), có collision.
func _railing(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	var mid := (from + to) / 2.0
	var size := Vector3(length, RAIL_HEIGHT, RAIL_THICKNESS)
	if absf(to.z - from.z) > absf(to.x - from.x):
		size = Vector3(RAIL_THICKNESS, RAIL_HEIGHT, length)
	MeshKit.collider(self, size, mid + Vector3.UP * (RAIL_HEIGHT / 2.0))
	var top_size := size + Vector3(0.02, 0.0, 0.02)
	top_size.y = 0.05
	MeshKit.box(parent, top_size, mid + Vector3.UP * RAIL_HEIGHT, RAIL_COLOR)
	var post_count := maxi(2, ceili(length / 0.3) + 1)
	for i in post_count:
		var post := from.lerp(to, float(i) / (post_count - 1))
		MeshKit.box(
			parent,
			Vector3(0.03, RAIL_HEIGHT, 0.03),
			post + Vector3.UP * (RAIL_HEIGHT / 2.0),
			RAIL_COLOR
		)


func _set_view(view: int) -> void:
	if view == _view:
		return
	_view = view
	_roof.visible = view == VIEW_OUTSIDE
	_uppers[0].visible = view != 0
	_level_roots[1].visible = view != 0
	_upstairs.visible = view != 0
	_uppers[1].visible = view != 1


func _on_interior_body(body: Node3D, inside: bool) -> void:
	if not body is Player:
		return
	_player = body as Player if inside else null
	set_physics_process(inside)
	_set_view(level_at(body.global_position.y) if inside else VIEW_OUTSIDE)
	player_inside_changed.emit(inside)
