class_name MeshKit
extends RefCounted
## Dựng nhanh khối cơ bản (hình tạm) cho tường, đồ đạc. Material dùng chung theo màu
## (chỉ đọc, không sửa lúc chạy). Cần material riêng để đổi (đèn, TV) → `unique_material`.

static var _materials: Dictionary = {}


static func material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.85
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.1
		_materials[color] = mat
	return _materials[color]


static func unique_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	return mat


static func box(parent: Node, size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, center, color)


static func cylinder(
	parent: Node, radius: float, height: float, center: Vector3, color: Color
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _add(parent, mesh, center, color)


static func sphere(parent: Node, radius: float, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(parent, mesh, center, color)


## Box collision; `body` phải là CollisionObject3D (shape là con trực tiếp).
static func collider(body: CollisionObject3D, size: Vector3, center: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = center
	body.add_child(collision)
	return collision


static func _add(
	parent: Node, mesh: PrimitiveMesh, center: Vector3, color: Color
) -> MeshInstance3D:
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	parent.add_child(instance)
	return instance
