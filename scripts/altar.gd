@tool
class_name Altar
extends StaticBody3D
## Bàn thờ gia tiên 2 cấp: tủ gỗ đỏ, ảnh thờ, bát hương, mâm ngũ quả, lọ hoa, đôi nến.
## Gốc = tâm chân trên sàn, mặt trước hướng +Z. Bấm E thắp / tắt hương: đầu nhang + ngọn nến
## sáng, OmniLight ánh đỏ ấm.

const WOOD: Color = Color(0.42, 0.11, 0.07)
const DARK_WOOD: Color = Color(0.3, 0.07, 0.04)
const GOLD: Color = Color(0.85, 0.68, 0.25)
const CERAMIC: Color = Color(0.92, 0.9, 0.84)
const ASH: Color = Color(0.6, 0.58, 0.55)
const INCENSE: Color = Color(0.72, 0.2, 0.15)
const CANDLE: Color = Color(0.8, 0.12, 0.1)
const PHOTO: Color = Color(0.22, 0.2, 0.19)
const FLAME: Color = Color(1.0, 0.62, 0.25)
const LIGHT_COLOR: Color = Color(1.0, 0.55, 0.3)
const FRUIT_COLORS: Array[Color] = [
	Color(0.95, 0.75, 0.15),
	Color(0.85, 0.2, 0.15),
	Color(0.4, 0.65, 0.25),
	Color(0.95, 0.5, 0.15),
	Color(0.6, 0.25, 0.45),
]
const INCENSE_X: Array[float] = [-0.03, 0.0, 0.03]
const CANDLE_X: Array[float] = [-0.72, 0.72]

@export var is_lit: bool = false:
	set(value):
		is_lit = value
		_apply_state()

## Ngọn nến, đầu nhang, đèn — chỉ hiện khi thắp.
var _lit: Node3D = null
var _interactable: Interactable = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()
	if not Engine.is_editor_hint():
		_interactable = Interactable.create(
			self, Vector3(1.8, 1.2, 1.4), Vector3(0.0, 0.8, 0.5), ""
		)
		_interactable.interacted.connect(toggle)
	_apply_state()


func toggle() -> void:
	is_lit = not is_lit


func _build() -> void:
	var shape := Node3D.new()
	shape.name = "Generated"
	add_child(shape)
	# Tủ thờ + mặt bàn + cấp trên đặt ảnh
	MeshKit.box(shape, Vector3(1.6, 0.85, 0.6), Vector3(0, 0.425, 0), WOOD)
	for sx: float in [-0.38, 0.38]:
		MeshKit.box(shape, Vector3(0.7, 0.6, 0.02), Vector3(sx, 0.42, 0.305), DARK_WOOD)
		MeshKit.sphere(shape, 0.025, Vector3(sx * 0.15, 0.42, 0.33), GOLD)
	MeshKit.box(shape, Vector3(1.7, 0.05, 0.66), Vector3(0, 0.875, 0), DARK_WOOD)
	MeshKit.box(shape, Vector3(1.3, 0.22, 0.26), Vector3(0, 1.01, -0.2), WOOD)
	for sx: float in [-0.3, 0.3]:
		MeshKit.box(shape, Vector3(0.26, 0.34, 0.03), Vector3(sx, 1.29, -0.25), GOLD)
		MeshKit.box(shape, Vector3(0.2, 0.27, 0.01), Vector3(sx, 1.29, -0.232), PHOTO)
	# Bát hương + 3 nén nhang
	MeshKit.cylinder(shape, 0.09, 0.1, Vector3(0, 0.95, 0.08), CERAMIC)
	MeshKit.cylinder(shape, 0.08, 0.01, Vector3(0, 1.0, 0.08), ASH)
	for x: float in INCENSE_X:
		MeshKit.cylinder(shape, 0.005, 0.22, Vector3(x, 1.11, 0.08), INCENSE)
	# Mâm ngũ quả
	MeshKit.cylinder(shape, 0.15, 0.03, Vector3(0.42, 0.915, 0.1), GOLD)
	for i in FRUIT_COLORS.size():
		var angle := TAU * i / FRUIT_COLORS.size()
		var offset := Vector3(cos(angle) * 0.07, 0.0, sin(angle) * 0.07)
		MeshKit.sphere(shape, 0.05, Vector3(0.42, 0.97, 0.1) + offset, FRUIT_COLORS[i])
	# Lọ hoa
	MeshKit.cylinder(shape, 0.05, 0.22, Vector3(-0.42, 1.01, 0.1), CERAMIC)
	for i in 3:
		MeshKit.sphere(
			shape,
			0.045,
			Vector3(-0.42 + (i - 1) * 0.05, 1.16 + (i % 2) * 0.03, 0.1),
			FRUIT_COLORS[i]
		)
	# Đôi chân nến
	for x: float in CANDLE_X:
		MeshKit.cylinder(shape, 0.03, 0.2, Vector3(x, 1.0, 0.12), GOLD)
		MeshKit.cylinder(shape, 0.02, 0.08, Vector3(x, 1.14, 0.12), CANDLE)
	MeshKit.collider(self, Vector3(1.7, 1.46, 0.66), Vector3(0, 0.73, 0))
	_build_lit()


func _build_lit() -> void:
	_lit = Node3D.new()
	_lit.name = "Lit"
	add_child(_lit)
	var glow := MeshKit.unique_material(FLAME)
	glow.emission_enabled = true
	glow.emission = FLAME
	glow.emission_energy_multiplier = 3.0
	for x: float in INCENSE_X:
		MeshKit.sphere(_lit, 0.01, Vector3(x, 1.225, 0.08), FLAME).material_override = glow
	for x: float in CANDLE_X:
		MeshKit.sphere(_lit, 0.02, Vector3(x, 1.2, 0.12), FLAME).material_override = glow
	var light := OmniLight3D.new()
	light.light_color = LIGHT_COLOR
	light.light_energy = 0.8
	light.omni_range = 3.5
	light.position = Vector3(0, 1.3, 0.35)
	_lit.add_child(light)


func _apply_state() -> void:
	if _lit != null:
		_lit.visible = is_lit
	if _interactable != null:
		_interactable.prompt = "Tắt hương" if is_lit else "Thắp hương"
