@tool
class_name Crop
extends Node3D
## Một cây trong vườn: lớn dần khi đất ẩm, phân bón làm lớn nhanh gấp đôi, chín thì thu hoạch.
## Gốc = gốc cây trên mặt luống. Garden tạo qua `setup()`; bấm E: thu hoạch > tưới > bón phân.

signal harvested

const GROW_TIME: float = 90.0  ## Giây từ mầm tới chín khi đất luôn ẩm, không phân.
const WATER_TIME: float = 30.0
const FERTILIZER_TIME: float = 30.0
const FERTILIZER_BOOST: float = 2.0
const STAGE_COUNT: int = 4  ## mầm, đang lớn, sắp chín, chín
const STAGE_SCALE: Array[float] = [0.35, 0.6, 0.85, 1.0]
const PATCH_RADIUS: float = 0.32
const STEM_HEIGHT: float = 0.4
const STEM_COLOR: Color = Color(0.25, 0.55, 0.2)
const UNRIPE_COLOR: Color = Color(0.45, 0.7, 0.25)
const FRUIT_COLOR: Color = Color(0.85, 0.15, 0.1)
const FERTILIZER_COLOR: Color = Color(0.95, 0.95, 0.9)
const FERTILIZER_SPOTS: Array[Vector2] = [
	Vector2(0.18, 0.05), Vector2(-0.12, 0.16), Vector2(-0.1, -0.17), Vector2(0.1, -0.2)
]
## Nằm sát mặt tán (tâm (0, 0.2, 0), bán kính 0.26), lệch về +Z/trên cho camera chéo thấy rõ.
const FRUIT_SPOTS: Array[Vector3] = [
	Vector3(0.2, 0.26, 0.16), Vector3(-0.2, 0.3, 0.14), Vector3(0.0, 0.42, 0.12)
]
const INTERACT_SIZE: Vector3 = Vector3(0.8, 1.0, 0.8)

## 0 = mầm mới gieo, 1 = chín.
var progress: float = 0.0
var water_left: float = 0.0
var fertilizer_left: float = 0.0

var _is_flower: bool = false
var _dry_color: Color = Color.BROWN
var _wet_color: Color = Color.BROWN
var _patch_material: StandardMaterial3D = null
var _plant: Node3D = null
var _fruits: Array[MeshInstance3D] = []  ## Rau: quả; hoa: nụ (chưa chín) và bông (chín).
var _fertilizer: Node3D = null
var _interactable: Interactable = null
## Trạng thái đang hiển thị, để chỉ cập nhật hình / gợi ý khi đổi.
var _shown_key: int = -1


func _ready() -> void:
	set_process(not Engine.is_editor_hint())


## Dựng hình. `soil` = màu luống; `color` = màu tán rau / bông hoa.
func setup(is_flower: bool, soil: Color, color: Color, start_progress: float) -> void:
	_is_flower = is_flower
	_dry_color = soil.lightened(0.12)
	_wet_color = soil.darkened(0.45)
	progress = clampf(start_progress, 0.0, 1.0)
	_patch_material = MeshKit.unique_material(_dry_color)
	var patch := MeshKit.cylinder(self, PATCH_RADIUS, 0.02, Vector3(0.0, 0.01, 0.0), Color.WHITE)
	patch.material_override = _patch_material
	_fertilizer = Node3D.new()
	_fertilizer.name = "Fertilizer"
	add_child(_fertilizer)
	for spot: Vector2 in FERTILIZER_SPOTS:
		MeshKit.sphere(_fertilizer, 0.03, Vector3(spot.x, 0.03, spot.y), FERTILIZER_COLOR)
	_plant = Node3D.new()
	_plant.name = "Plant"
	add_child(_plant)
	if _is_flower:
		MeshKit.cylinder(
			_plant, 0.03, STEM_HEIGHT, Vector3(0.0, STEM_HEIGHT / 2.0, 0.0), STEM_COLOR
		)
		_fruits.append(MeshKit.sphere(_plant, 0.08, Vector3(0.0, STEM_HEIGHT, 0.0), UNRIPE_COLOR))
		_fruits.append(MeshKit.sphere(_plant, 0.16, Vector3(0.0, STEM_HEIGHT, 0.0), color))
	else:
		MeshKit.sphere(_plant, 0.26, Vector3(0.0, 0.2, 0.0), color)
		for spot: Vector3 in FRUIT_SPOTS:
			_fruits.append(MeshKit.sphere(_plant, 0.08, spot, FRUIT_COLOR))
	if not Engine.is_editor_hint():
		_interactable = Interactable.create(
			self, INTERACT_SIZE, Vector3(0.0, INTERACT_SIZE.y / 2.0, 0.0), ""
		)
		_interactable.interacted.connect(interact)
	_refresh()


func _process(delta: float) -> void:
	advance(delta)


## Cho thời gian trôi `delta` giây. Tách khỏi `_process` để test tua nhanh được.
func advance(delta: float) -> void:
	var wet_time := minf(delta, water_left)
	var boosted := minf(wet_time, fertilizer_left)
	progress = minf(1.0, progress + (wet_time + boosted * (FERTILIZER_BOOST - 1.0)) / GROW_TIME)
	water_left = maxf(0.0, water_left - delta)
	# Phân chỉ hao khi đất ẩm (lúc khô cây không lớn nên phân cũng không tác dụng).
	fertilizer_left = maxf(0.0, fertilizer_left - wet_time)
	_refresh()


func is_ripe() -> bool:
	return progress >= 1.0


func is_wet() -> bool:
	return water_left > 0.0


func is_fertilized() -> bool:
	return fertilizer_left > 0.0


## 0 = mầm … STAGE_COUNT - 1 = chín.
func stage() -> int:
	if is_ripe():
		return STAGE_COUNT - 1
	return mini(floori(progress * (STAGE_COUNT - 1)), STAGE_COUNT - 2)


## Việc bấm E sẽ làm; "" = không có gì để làm.
func action_prompt() -> String:
	if is_ripe():
		return "Thu hoạch"
	if not is_wet():
		return "Tưới cây"
	if not is_fertilized():
		return "Bón phân"
	return ""


func interact() -> void:
	if is_ripe():
		harvest()
	elif not is_wet():
		water()
	elif not is_fertilized():
		fertilize()


func water() -> void:
	water_left = WATER_TIME
	_refresh()


func fertilize() -> void:
	fertilizer_left = FERTILIZER_TIME
	_refresh()


func harvest() -> void:
	if not is_ripe():
		return
	progress = 0.0
	water_left = 0.0
	fertilizer_left = 0.0
	_refresh()
	harvested.emit()


func _refresh() -> void:
	if _plant == null:
		return
	var current := stage()
	var key := current * 4 + int(is_wet()) * 2 + int(is_fertilized())
	if key == _shown_key:
		return
	_shown_key = key
	_plant.scale = Vector3.ONE * STAGE_SCALE[current]
	_patch_material.albedo_color = _wet_color if is_wet() else _dry_color
	_fertilizer.visible = is_fertilized()
	var ripe := current == STAGE_COUNT - 1
	if _is_flower:
		_fruits[0].visible = current == STAGE_COUNT - 2  # nụ
		_fruits[1].visible = ripe  # bông nở
	else:
		for fruit: MeshInstance3D in _fruits:
			fruit.visible = current >= STAGE_COUNT - 2
			fruit.material_override = MeshKit.material(FRUIT_COLOR if ripe else UNRIPE_COLOR)
	if _interactable != null:
		_interactable.prompt = action_prompt()
