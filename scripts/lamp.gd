@tool
class_name Lamp
extends StaticBody3D
## Đèn (đèn cây / đèn ngủ): đế, thân, chụp đèn phát sáng + OmniLight ánh ấm. Bấm E bật/tắt.
## Gốc = tâm đế trên mặt đặt.

const LIGHT_COLOR: Color = Color(1.0, 0.82, 0.55)
const SHADE_COLOR: Color = Color(0.96, 0.9, 0.78)
const METAL: Color = Color(0.25, 0.25, 0.27)

@export var height: float = 1.6:
	set(value):
		height = value
		_rebuild()
@export var light_range: float = 5.0
@export var is_on: bool = true:
	set(value):
		is_on = value
		_apply_state()

var _generated: Node3D = null
var _collision: CollisionShape3D = null
var _light: OmniLight3D = null
var _shade_material: StandardMaterial3D = null
var _interactable: Interactable = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()
	if Engine.is_editor_hint():
		return
	_interactable = Interactable.create(
		self, Vector3(0.9, 1.2, 0.9), Vector3(0.0, minf(height, 1.2) / 2.0, 0.0), ""
	)
	_interactable.interacted.connect(toggle)
	_apply_state()


func toggle() -> void:
	is_on = not is_on


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _generated != null:
		_generated.free()
	if _collision != null:
		_collision.free()
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)
	var shade_height := clampf(height * 0.22, 0.18, 0.35)
	var shade_radius := shade_height * 0.75
	var pole_height := height - shade_height
	MeshKit.cylinder(_generated, shade_radius * 0.9, 0.04, Vector3(0.0, 0.02, 0.0), METAL)
	MeshKit.cylinder(_generated, 0.02, pole_height, Vector3(0.0, pole_height / 2.0, 0.0), METAL)
	var shade := CylinderMesh.new()
	shade.top_radius = shade_radius * 0.7
	shade.bottom_radius = shade_radius
	shade.height = shade_height
	_shade_material = MeshKit.unique_material(SHADE_COLOR)
	_shade_material.emission = LIGHT_COLOR
	_shade_material.emission_energy_multiplier = 1.5
	shade.material = _shade_material
	var shade_instance := MeshInstance3D.new()
	shade_instance.mesh = shade
	shade_instance.position = Vector3(0.0, pole_height + shade_height / 2.0, 0.0)
	_generated.add_child(shade_instance)
	_light = OmniLight3D.new()
	_light.light_color = LIGHT_COLOR
	_light.omni_range = light_range
	_light.position = Vector3(0.0, pole_height + shade_height * 0.3, 0.0)
	_generated.add_child(_light)
	_collision = MeshKit.collider(
		self,
		Vector3(shade_radius * 2.0, height, shade_radius * 2.0),
		Vector3(0.0, height / 2.0, 0.0)
	)
	_apply_state()


func _apply_state() -> void:
	if _light != null:
		_light.visible = is_on
		_shade_material.emission_enabled = is_on
	if _interactable != null:
		_interactable.prompt = "Tắt đèn" if is_on else "Bật đèn"
