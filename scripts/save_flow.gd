class_name SaveFlow
extends Node
## Luồng lưu game. Mở game: có cấu hình Supabase → đăng nhập (tự vào bằng phiên cũ) rồi nạp bản
## lưu của tài khoản; không có → nạp bản trên máy. Đóng cửa sổ: dừng game, hỏi Lưu và thoát /
## Thoát không lưu / Huỷ. Luôn ghi bản trên máy trước (cờ PENDING), gửi server được thì bỏ cờ;
## gửi lỗi thì lần sau vào có mạng tự gửi bản đó lên trước khi tải.
## World đưa hàm gom / nạp trạng thái qua `setup()`.

const QUIT_ASK: String = "Lưu trước khi thoát?"
const QUIT_EXIT: StringName = &"exit"
const PENDING: String = "pending_upload"

@export var login: LoginScreen = null
## Slot trên máy khi không dùng server (smoke test đổi để không đụng bản lưu thật).
@export var local_slot: String = SaveGame.LOCAL_SLOT
## false = bỏ qua `supabase.cfg`, chỉ lưu trên máy (smoke test, chạy thử offline).
@export var use_cloud: bool = true

## Slot đang dùng: id tài khoản, hoặc `local_slot`; "" = chưa nạp bản lưu nào.
var slot: String = ""

## Đã nạp bản lưu và đang chơi — chỉ khi đó đóng cửa sổ mới hỏi lưu (chưa nạp mà lưu = ghi đè
## tiến độ thật bằng thế giới mới).
var _in_game: bool = false
## Đang gửi bản lưu lúc thoát: đóng cửa sổ lần nữa thì bỏ qua (gửi xong tự thoát).
var _saving: bool = false

var _collect: Callable
var _apply: Callable
var _cloud: CloudSave = null
var _quit_dialog: ConfirmationDialog = null
var _exit_button: Button = null


## `collect() -> Dictionary` gom trạng thái; `apply(data: Dictionary)` nạp trạng thái.
func setup(collect: Callable, apply: Callable) -> void:
	_collect = collect
	_apply = apply
	# Đăng nhập / gửi bản lưu diễn ra lúc game dừng; HTTPRequest (con của CloudSave) phải vẫn chạy.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cloud = CloudSave.new()
	_cloud.name = "CloudSave"
	add_child(_cloud)
	get_tree().set_auto_accept_quit(false)
	_build_quit_dialog()
	login.submitted.connect(_on_submitted)
	login.offline_requested.connect(_on_offline)
	if not use_cloud or not _cloud.is_configured():
		use_cloud = false
		slot = local_slot
		_apply.call(SaveGame.read(slot))
		_in_game = true
		return
	get_tree().paused = true
	login.set_email(str(_cloud.saved_session().get("email", "")))
	login.show_busy("Đang đăng nhập...")
	var result := await _cloud.restore_session()
	if result.ok:
		await _enter_online()
	else:
		# Chưa từng đăng nhập / phiên hết hạn: hiện form, chỉ báo lỗi khi là lỗi mạng.
		_open_login(result.error if result.offline else "", result.offline)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or _quit_dialog == null or _quit_dialog.visible:
		return
	if _saving:
		return
	if not _in_game:
		get_tree().quit()  # chưa nạp bản lưu: không có gì để lưu (bản chờ gửi trên máy vẫn còn)
	else:
		_ask_next_frame()


## Thông báo đóng cửa sổ còn lan xuống chính hộp hỏi (node con): nó tự huỷ + ẩn ở cuối frame này.
## Đợi sang frame sau mới hiện để không bị ẩn ngay.
func _ask_next_frame() -> void:
	await get_tree().process_frame
	_ask(QUIT_ASK, false)


## Lưu ngay vào slot trên máy (không gửi server); "" nếu được, ngược lại là mô tả lỗi.
func save_now() -> String:
	var code := SaveGame.write(slot, _collect.call())
	return "" if code == OK else error_string(code)


func _open_login(message: String, is_error: bool) -> void:
	_in_game = false
	slot = ""
	var last_user := str(_cloud.saved_session().get("user_id", ""))
	var can_offline := is_error and not SaveGame.read(last_user).is_empty()
	login.open(message, is_error, can_offline)


func _on_submitted(email: String, password: String, is_sign_up: bool) -> void:
	login.show_busy("Đang đăng ký..." if is_sign_up else "Đang đăng nhập...")
	var result: CloudSave.Result = null
	if is_sign_up:
		result = await _cloud.sign_up(email, password)
	else:
		result = await _cloud.sign_in(email, password)
	if result.ok:
		await _enter_online()
	else:
		_open_login(result.error, true)


## Mất mạng: chơi bằng bản trên máy của tài khoản đăng nhập gần nhất; lưu chỉ ghi máy + cờ chờ
## gửi (bỏ access token: chưa tải được bản server thì không được ghi đè nó).
func _on_offline() -> void:
	_cloud.forget_access_token()
	slot = str(_cloud.saved_session().get("user_id", ""))
	_apply.call(SaveGame.read(slot))
	_resume()


func _enter_online() -> void:
	var id := _cloud.user_id
	var local := SaveGame.read(id)
	if local.get(PENDING, false) == true:
		# Lần trước lưu mà chưa gửi được: bản trên máy là mới nhất.
		login.show_busy("Đang gửi bản lưu lần trước lên server...")
		var sent := await _cloud.upload(_without_pending(local))
		slot = id
		if sent.ok:
			_mark_sent(local)
		_apply.call(local)
		_resume()
		return
	login.show_busy("Đang tải bản lưu...")
	var got := await _cloud.download()
	if not got.ok:
		# Không tải được thì không cho chơi online: lưu đè lên server có thể làm mất tiến độ.
		_open_login(got.error, true)
		return
	var data: Dictionary = got.data if got.data is Dictionary else {}
	slot = id
	_apply.call(data)
	if SaveGame.is_valid(data):
		SaveGame.write(slot, data)  # bản trên máy theo kịp server, dùng khi mất mạng
	_resume()


func _resume() -> void:
	_in_game = true
	login.visible = false
	get_tree().paused = false


func _build_quit_dialog() -> void:
	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.name = "QuitDialog"
	_quit_dialog.title = "Thoát game"
	_quit_dialog.process_mode = Node.PROCESS_MODE_ALWAYS  # vẫn chạy khi game dừng
	_quit_dialog.cancel_button_text = "Huỷ"
	_exit_button = _quit_dialog.add_button("", true, QUIT_EXIT)
	_quit_dialog.confirmed.connect(_save_and_quit)
	_quit_dialog.custom_action.connect(func(_action: StringName) -> void: get_tree().quit())
	_quit_dialog.canceled.connect(_on_quit_canceled)
	add_child(_quit_dialog)


func _on_quit_canceled() -> void:
	if not login.visible:
		get_tree().paused = false


## `after_failed_upload`: bản trên máy đã ghi, chỉ chưa gửi được → nút Thử gửi lại / Thoát.
func _ask(text: String, after_failed_upload: bool) -> void:
	get_tree().paused = true
	_quit_dialog.dialog_text = text
	_quit_dialog.ok_button_text = "Thử gửi lại" if after_failed_upload else "Lưu và thoát"
	_exit_button.text = "Thoát (đã lưu trên máy)" if after_failed_upload else "Thoát không lưu"
	_quit_dialog.popup_centered()


func _save_and_quit() -> void:
	var data: Dictionary = _collect.call()
	if use_cloud:
		data[PENDING] = true
	var code := SaveGame.write(slot, data)
	if code != OK:
		_ask.call_deferred("Không lưu được trên máy (%s). Thử lại?" % error_string(code), false)
		return
	if not _cloud.is_signed_in():
		get_tree().quit()  # chỉ lưu trên máy (không cấu hình server / đang chơi offline)
		return
	login.show_busy("Đang lưu lên server...")
	_saving = true
	var sent := await _cloud.upload(_without_pending(data))
	_saving = false
	if sent.ok:
		_mark_sent(data)
		get_tree().quit()
		return
	login.visible = false
	_ask.call_deferred(
		(
			"Đã lưu trên máy nhưng chưa gửi lên server được.\n%s\n" % sent.error
			+ "Lần sau mở game có mạng sẽ tự gửi."
		),
		true
	)


func _without_pending(data: Dictionary) -> Dictionary:
	var copy := data.duplicate()
	copy.erase(PENDING)
	return copy


func _mark_sent(data: Dictionary) -> void:
	data.erase(PENDING)
	var code := SaveGame.write(slot, data)
	if code != OK:
		push_warning("Không bỏ được cờ chờ gửi (%s), lần sau gửi lại." % error_string(code))
