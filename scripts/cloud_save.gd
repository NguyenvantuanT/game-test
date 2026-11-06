class_name CloudSave
extends Node
## Lưu game theo tài khoản trên Supabase: đăng ký / đăng nhập bằng email (Auth REST), tải / gửi
## bản lưu ở bảng `saves` (PostgREST, RLS: mỗi người chỉ thấy dòng của mình). Phiên đăng nhập
## (refresh token) giữ ở `user://session.json` để lần sau tự vào. Cấu hình ở `res://supabase.cfg`
## (thiếu → `is_configured()` false, game chỉ lưu trên máy).
## Mọi hàm mạng là coroutine trả `Result`; lỗi đã dịch sang tiếng Việt để hiện cho người chơi.

const CONFIG_PATH: String = "res://supabase.cfg"
const SESSION_PATH: String = "user://session.json"
const TIMEOUT: float = 15.0
const AUTH_ERRORS: Dictionary = {
	"invalid_credentials": "Sai email hoặc mật khẩu.",
	"user_already_exists": "Email này đã có tài khoản, hãy đăng nhập.",
	"email_exists": "Email này đã có tài khoản, hãy đăng nhập.",
	"weak_password": "Mật khẩu quá yếu (ít nhất 6 ký tự).",
	"validation_failed": "Email hoặc mật khẩu không hợp lệ.",
	"email_address_invalid": "Email không hợp lệ.",
	"email_not_confirmed": "Email chưa được xác nhận.",
	"over_request_rate_limit": "Thử quá nhiều lần, đợi một lát rồi thử lại.",
	"over_email_send_rate_limit": "Thử quá nhiều lần, đợi một lát rồi thử lại.",
	"signup_disabled": "Server đang tắt đăng ký tài khoản mới.",
}


## Kết quả một lần gọi: `ok`, `error` (câu cho người chơi), `offline` (không tới được server),
## `status` (mã HTTP), `data` (JSON trả về).
class Result:
	var ok: bool = false
	var status: int = 0
	var error: String = ""
	var offline: bool = false
	var data: Variant = null


var user_id: String = ""
var email: String = ""

var _url: String = ""
var _key: String = ""
var _access_token: String = ""
var _refresh_token: String = ""


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		_url = str(config.get_value("supabase", "url", "")).trim_suffix("/")
		_key = str(config.get_value("supabase", "publishable_key", ""))


func is_configured() -> bool:
	return not _url.is_empty() and not _key.is_empty()


func is_signed_in() -> bool:
	return not _access_token.is_empty()


## Phiên đã lưu từ lần trước (để biết tài khoản nào khi mất mạng); {} nếu chưa có.
func saved_session() -> Dictionary:
	if not FileAccess.file_exists(SESSION_PATH):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
	return data if data is Dictionary else {}


## Vào lại bằng phiên đã lưu (không hỏi mật khẩu).
func restore_session() -> Result:
	var session := saved_session()
	var token := str(session.get("refresh_token", ""))
	if token.is_empty():
		var none := Result.new()
		none.error = "Chưa đăng nhập."
		return none
	return await _auth("token?grant_type=refresh_token", {"refresh_token": token})


func sign_in(user_email: String, password: String) -> Result:
	return await _auth(
		"token?grant_type=password", {"email": user_email.strip_edges(), "password": password}
	)


func sign_up(user_email: String, password: String) -> Result:
	var result := await _auth(
		"signup", {"email": user_email.strip_edges(), "password": password}
	)
	if result.ok and not is_signed_in():
		# Project bật xác nhận email: server không trả phiên.
		result.ok = false
		result.error = "Đã tạo tài khoản. Mở email để xác nhận rồi đăng nhập."
	return result


## Chơi offline: bỏ access token (không gửi được gì) nhưng giữ phiên trên máy để lần sau tự vào.
func forget_access_token() -> void:
	_access_token = ""


func sign_out() -> void:
	_access_token = ""
	_refresh_token = ""
	user_id = ""
	DirAccess.remove_absolute(SESSION_PATH)


## Tải bản lưu của tài khoản; `data` = {} nếu tài khoản chưa có bản lưu.
func download() -> Result:
	var path := "/rest/v1/saves?select=data&user_id=eq." + user_id.uri_encode()
	var result := await _rest(path, HTTPClient.METHOD_GET, [], "")
	if result.ok:
		var rows: Variant = result.data
		result.data = rows[0].get("data", {}) if rows is Array and not rows.is_empty() else {}
	return result


## Ghi đè bản lưu của tài khoản (tạo mới nếu chưa có).
func upload(save: Dictionary) -> Result:
	var body := {"user_id": user_id, "data": save}  # updated_at do trigger trên server đặt
	return await _rest(
		"/rest/v1/saves?on_conflict=user_id",
		HTTPClient.METHOD_POST,
		["Prefer: resolution=merge-duplicates,return=minimal"],
		JSON.stringify(body)
	)


## Gọi PostgREST bằng phiên hiện tại; access token hết hạn (401) → làm mới phiên, thử lại 1 lần.
func _rest(path: String, method: HTTPClient.Method, extra: Array[String], body: String) -> Result:
	var result := await _request(path, method, _rest_headers(extra), body)
	if result.status == 401 and not _refresh_token.is_empty():
		var refreshed := await _auth(
			"token?grant_type=refresh_token", {"refresh_token": _refresh_token}
		)
		if refreshed.ok:
			result = await _request(path, method, _rest_headers(extra), body)
	return result


func _auth(path: String, body: Dictionary) -> Result:
	var result := await _request(
		"/auth/v1/" + path,
		HTTPClient.METHOD_POST,
		["apikey: " + _key, "Content-Type: application/json"],
		JSON.stringify(body)
	)
	if not result.ok or not result.data is Dictionary:
		return result
	var data: Dictionary = result.data
	if data.has("access_token"):
		_access_token = str(data["access_token"])
		_refresh_token = str(data.get("refresh_token", ""))
		var user: Dictionary = data.get("user", {})
		user_id = str(user.get("id", ""))
		email = str(user.get("email", ""))
		_store_session()
	return result


func _rest_headers(extra: Array[String]) -> PackedStringArray:
	var headers := PackedStringArray(
		[
			"apikey: " + _key,
			"Authorization: Bearer " + _access_token,
			"Content-Type: application/json",
		]
	)
	headers.append_array(extra)
	return headers


## Phiên giữ trên máy: refresh token (để tự vào lại), id + email (để chơi offline đúng slot).
func _store_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Không lưu được phiên đăng nhập: %s" % FileAccess.get_open_error())
		return
	file.store_string(
		JSON.stringify({"refresh_token": _refresh_token, "user_id": user_id, "email": email})
	)


func _request(
	path: String, method: HTTPClient.Method, headers: PackedStringArray, body: String
) -> Result:
	var result := Result.new()
	if not is_configured():
		result.error = "Chưa cấu hình server."
		return result
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var started := http.request(_url + path, headers, method, body)
	var response: Array = [started]
	if started == OK:
		response = await http.request_completed
	http.queue_free()
	if started != OK or response[0] != HTTPRequest.RESULT_SUCCESS:
		result.offline = true
		result.error = "Không kết nối được server. Kiểm tra mạng rồi thử lại."
		return result
	var code: int = response[1]
	result.status = code
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	result.data = JSON.parse_string(text) if not text.is_empty() else null
	result.ok = code >= 200 and code < 300
	if not result.ok:
		result.error = _error_text(code, result.data)
	return result


static func _error_text(code: int, data: Variant) -> String:
	var info: Dictionary = data if data is Dictionary else {}
	var error_code := str(info.get("error_code", ""))
	if AUTH_ERRORS.has(error_code):
		return AUTH_ERRORS[error_code]
	if code == 401 or code == 403:
		return "Phiên đăng nhập hết hạn, hãy đăng nhập lại."
	var detail := str(info.get("msg", info.get("message", info.get("error_description", ""))))
	push_warning("Supabase lỗi %d: %s" % [code, detail])
	return "Server đang lỗi (mã %d), thử lại sau." % code
