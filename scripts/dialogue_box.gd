class_name DialogueBox
extends PanelContainer
## Hộp hội thoại dưới màn hình: tên người nói, câu nói, các lựa chọn đánh số. Chọn bằng phím số,
## chuột, hoặc mũi tên + E / Enter; Esc thôi nói chuyện bất cứ lúc nào. `open()` bắt đầu ở
## `Dialogues.START`; lựa chọn trỏ tới `Dialogues.END` thì đóng, trả người hàng xóm về đi lại
## và báo `closed`.

signal closed

const SPEAKER_COLOR: Color = Color(1.0, 0.85, 0.4)
const PANEL_COLOR: Color = Color(0.08, 0.08, 0.1, 0.85)
const HINT_TEXT: String = "1–4 / E: chọn  ·  Esc: thôi nói chuyện"
const HINT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)

## Nút kịch bản đang hiện ("" = đang đóng).
var current: String = ""

var _neighbor: Neighbor = null
var _nodes: Dictionary = {}
var _speaker: Label = null
var _text: Label = null
var _options: VBoxContainer = null


func _ready() -> void:
	visible = false
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL_COLOR
	panel.set_corner_radius_all(8)
	panel.set_content_margin_all(16)
	add_theme_stylebox_override("panel", panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", SPEAKER_COLOR)
	_speaker.add_theme_font_size_override("font_size", 20)
	box.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 22)
	box.add_child(_text)
	_options = VBoxContainer.new()
	box.add_child(_options)
	var hint := Label.new()
	hint.text = HINT_TEXT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.add_theme_font_size_override("font_size", 14)
	box.add_child(hint)


## Mở kịch bản của `neighbor`; false nếu đang mở sẵn hoặc không có kịch bản.
func open(neighbor: Neighbor) -> bool:
	if visible:
		return false
	if not Dialogues.ALL.has(neighbor.dialogue_id):
		push_error("Không có kịch bản '%s'" % neighbor.dialogue_id)
		return false
	var script_data: Dictionary = Dialogues.ALL[neighbor.dialogue_id]
	_neighbor = neighbor
	_neighbor.talking = true
	_nodes = script_data["nodes"]
	_speaker.text = script_data["speaker"]
	visible = true
	_show(Dialogues.START)
	return true


## Chọn lựa chọn thứ `index` (0 = đầu tiên) của nút đang hiện.
func choose(index: int) -> void:
	if current.is_empty():
		return
	var options: Array = _nodes[current]["options"]
	if index < 0 or index >= options.size():
		return
	var next: String = options[index][1]
	if next == Dialogues.END:
		_close()
	else:
		_show(next)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	var digit := -1 if key == null or not key.pressed or key.echo else _digit(key)
	if digit >= 0 and digit < Dialogues.MAX_OPTIONS:
		choose(digit)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
		# E = bấm nút đang chọn (Enter / Space đã có sẵn qua ui_accept).
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused != null and focused.get_parent() == _options:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()


func _show(id: String) -> void:
	current = id
	var node: Dictionary = _nodes[id]
	_text.text = node["text"]
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	var options: Array = node["options"]
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i][0]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(choose.bind(i))
		_options.add_child(button)
	(_options.get_child(0) as Button).grab_focus()


func _close() -> void:
	current = ""
	visible = false
	_neighbor.talking = false
	_neighbor = null
	closed.emit()


## Phím số hàng trên (theo vị trí, đúng cả bàn phím AZERTY) hoặc numpad → 0..8; -1 nếu không.
static func _digit(key: InputEventKey) -> int:
	if key.physical_keycode >= KEY_1 and key.physical_keycode <= KEY_9:
		return key.physical_keycode - KEY_1
	if key.keycode >= KEY_KP_1 and key.keycode <= KEY_KP_9:
		return key.keycode - KEY_KP_1
	return -1
