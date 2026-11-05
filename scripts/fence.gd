class_name Fence
extends RefCounted
## Rào gỗ chữ nhật quanh gốc (0, 0) của node cha, chừa cổng ở giữa một cạnh.
## Có collision (layer world) để Player và con vật chỉ qua được cổng. Dùng cho vườn và chuồng.

const THICKNESS: float = 0.08
const POST_SIZE: float = 0.14
const GATE_WIDTH: float = 1.6
const WORLD_LAYER: int = 1
const COLOR: Color = Color(0.55, 0.38, 0.2)


## `gate_side`: hướng ra ngoài của cạnh có cổng (Vector3.LEFT, Vector3.FORWARD, ...).
static func build(parent: Node3D, size: Vector2, gate_side: Vector3, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Fence"
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	parent.add_child(body)
	var half := Vector3(size.x, 0.0, size.y) / 2.0
	# [điểm đầu, vector dọc cạnh, hướng ra ngoài]
	var edges: Array[Array] = [
		[Vector3(-half.x, 0.0, -half.z), Vector3(size.x, 0.0, 0.0), Vector3.FORWARD],
		[Vector3(-half.x, 0.0, half.z), Vector3(size.x, 0.0, 0.0), Vector3.BACK],
		[Vector3(-half.x, 0.0, -half.z), Vector3(0.0, 0.0, size.y), Vector3.LEFT],
		[Vector3(half.x, 0.0, -half.z), Vector3(0.0, 0.0, size.y), Vector3.RIGHT],
	]
	for edge: Array in edges:
		var start: Vector3 = edge[0]
		var span: Vector3 = edge[1]
		if edge[2] != gate_side:
			_segment(parent, body, start, span, height)
			continue
		var part := span * (1.0 - GATE_WIDTH / span.length()) / 2.0
		_segment(parent, body, start, part, height)
		_segment(parent, body, start + span - part, part, height)
	return body


static func _segment(
	parent: Node3D, body: StaticBody3D, start: Vector3, span: Vector3, height: float
) -> void:
	var extent := Vector3(maxf(span.x, THICKNESS), height, maxf(span.z, THICKNESS))
	var center := start + span / 2.0 + Vector3(0.0, height / 2.0, 0.0)
	MeshKit.box(
		parent,
		Vector3(extent.x, height * 0.35, extent.z),
		center + Vector3(0.0, height * 0.15, 0.0),
		COLOR
	)
	MeshKit.collider(body, extent, center)
	for end: Vector3 in [start, start + span]:
		MeshKit.box(
			parent,
			Vector3(POST_SIZE, height, POST_SIZE),
			end + Vector3(0.0, height / 2.0, 0.0),
			COLOR
		)
