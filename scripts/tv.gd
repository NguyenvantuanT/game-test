@tool
class_name Tv
extends StaticBody3D
## TV đặt trên kệ: màn hình phát sáng khi bật + ánh xanh nhẹ hắt ra trước. Bấm E bật/tắt.
## Gốc = tâm chân đế, màn hình hướng +Z.

const SCREEN_SIZE: Vector2 = Vector2(1.3, 0.75)
const FRAME_COLOR: Color = Color(0.1, 0.1, 0.11)
const OFF_COLOR: Color = Color(0.05, 0.06, 0.07)
const ON_COLOR: Color = Color(0.45, 0.7, 1.0)

@export var is_on: bool = false:
	set(value):
		is_on = value
		_apply_state()

var _screen_material: StandardMaterial3D = null
var _light: OmniLight3D = null
var _interactable: Interactable = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var screen_y := 0.1 + SCREEN_SIZE.y / 2.0
	MeshKit.box(generated, Vector3(0.4, 0.03, 0.2), Vector3(0.0, 0.015, 0.0), FRAME_COLOR)
	MeshKit.box(generated, Vector3(0.06, 0.1, 0.04), Vector3(0.0, 0.05, -0.02), FRAME_COLOR)
	MeshKit.box(
		generated,
		Vector3(SCREEN_SIZE.x + 0.06, SCREEN_SIZE.y + 0.06, 0.05),
		Vector3(0.0, screen_y, -0.02),
		FRAME_COLOR
	)
	var screen := BoxMesh.new()
	screen.size = Vector3(SCREEN_SIZE.x, SCREEN_SIZE.y, 0.01)
	_screen_material = MeshKit.unique_material(OFF_COLOR)
	_screen_material.roughness = 0.2
	_screen_material.emission = ON_COLOR
	_screen_material.emission_energy_multiplier = 1.4
	screen.material = _screen_material
	var screen_instance := MeshInstance3D.new()
	screen_instance.mesh = screen
	screen_instance.position = Vector3(0.0, screen_y, 0.01)
	generated.add_child(screen_instance)
	_light = OmniLight3D.new()
	_light.light_color = ON_COLOR
	_light.light_energy = 0.6
	_light.omni_range = 3.0
	_light.position = Vector3(0.0, screen_y, 0.6)
	generated.add_child(_light)
	MeshKit.collider(
		self,
		Vector3(SCREEN_SIZE.x + 0.06, SCREEN_SIZE.y + 0.16, 0.2),
		Vector3(0.0, (SCREEN_SIZE.y + 0.16) / 2.0, 0.0)
	)
	if not Engine.is_editor_hint():
		_interactable = Interactable.create(
			self, Vector3(1.6, 1.4, 1.6), Vector3(0.0, 0.2, 0.6), ""
		)
		_interactable.interacted.connect(toggle)
	_apply_state()


func toggle() -> void:
	is_on = not is_on


func _apply_state() -> void:
	if _screen_material == null:
		return
	_screen_material.emission_enabled = is_on
	_light.visible = is_on
	if _interactable != null:
		_interactable.prompt = "Tắt TV" if is_on else "Bật TV"
