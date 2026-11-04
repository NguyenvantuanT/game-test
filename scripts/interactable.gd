class_name Interactable
extends Area3D
## Vùng bấm E. Player phát hiện qua layer `interactable`; node chủ (đèn, TV, cửa)
## nghe `interacted` và tự cập nhật `prompt`.

signal interacted
signal prompt_changed

const LAYER: int = 4  # layer 3 "interactable"

var prompt: String = "":
	set(value):
		if value == prompt:
			return
		prompt = value
		prompt_changed.emit()


static func create(host: Node3D, size: Vector3, center: Vector3, text: String) -> Interactable:
	var area := Interactable.new()
	area.name = "Interactable"
	area.prompt = text
	area.collision_layer = LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.position = center  # gốc = tâm vùng → Player so khoảng cách bằng global_position
	MeshKit.collider(area, size, Vector3.ZERO)
	host.add_child(area)
	return area


func interact() -> void:
	interacted.emit()
