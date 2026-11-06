class_name LoginScreen
extends Control
## Màn hình phủ cả HUD: đăng nhập / đăng ký bằng email để lưu game theo tài khoản, hoặc chơi
## offline (khi không tới được server và máy còn bản lưu của tài khoản trước). Chỉ hiển thị +
## báo signal; SaveFlow gọi CloudSave. Chạy cả khi game đang dừng (paused).

signal submitted(email: String, password: String, is_sign_up: bool)
signal offline_requested

const BACKDROP_COLOR: Color = Color(0.05, 0.08, 0.06, 0.85)
const PANEL_COLOR: Color = Color(0.1, 0.12, 0.11)
const ERROR_COLOR: Color = Color(1.0, 0.55, 0.5)
const INFO_COLOR: Color = Color(1.0, 1.0, 1.0, 0.75)
const FIELD_WIDTH: float = 360.0

var _email: LineEdit = null
var _password: LineEdit = null
var _status: Label = null
var _buttons: Array[Button] = []
var _offline: Button = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	# Khung nền đặc: biển tên 3D trong map không xuyên qua form.
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = FIELD_WIDTH
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Đăng nhập để lưu game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	_email = LineEdit.new()
	_email.placeholder_text = "Email"
	box.add_child(_email)
	_password = LineEdit.new()
	_password.placeholder_text = "Mật khẩu (ít nhất 6 ký tự)"
	_password.secret = true
	_password.text_submitted.connect(func(_text: String) -> void: _submit(false))
	box.add_child(_password)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for is_sign_up: bool in [false, true]:
		var button := Button.new()
		button.text = "Đăng ký" if is_sign_up else "Đăng nhập"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_submit.bind(is_sign_up))
		row.add_child(button)
		_buttons.append(button)
	_offline = Button.new()
	_offline.text = "Chơi offline (lưu trên máy)"
	_offline.pressed.connect(offline_requested.emit)
	box.add_child(_offline)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)


## Hiện form; `message` báo lỗi (đỏ) nếu `is_error`, ngược lại là thông tin.
func open(message: String = "", is_error: bool = false, can_play_offline: bool = false) -> void:
	visible = true
	_set_busy(false)
	_offline.visible = can_play_offline
	_show_status(message, is_error)
	if _email.text.is_empty():
		_email.grab_focus()
	else:
		_password.grab_focus()


## Hiện màn hình chờ (khoá nút) khi đang gọi server.
func show_busy(message: String) -> void:
	visible = true
	_set_busy(true)
	_offline.visible = false
	_show_status(message, false)


func set_email(value: String) -> void:
	_email.text = value


func _submit(is_sign_up: bool) -> void:
	if _buttons[0].disabled:
		return
	var email := _email.text.strip_edges()
	if not email.contains("@"):
		_show_status("Nhập email hợp lệ.", true)
		return
	if _password.text.length() < 6:
		_show_status("Mật khẩu ít nhất 6 ký tự.", true)
		return
	submitted.emit(email, _password.text, is_sign_up)


func _set_busy(busy: bool) -> void:
	for button: Button in _buttons:
		button.disabled = busy
	_email.editable = not busy
	_password.editable = not busy


func _show_status(message: String, is_error: bool) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", ERROR_COLOR if is_error else INFO_COLOR)
