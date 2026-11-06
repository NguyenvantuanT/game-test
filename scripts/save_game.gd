class_name SaveGame
extends RefCounted
## Bản lưu trên máy: JSON ở `user://saves/<slot>.json` (slot = id tài khoản, hoặc LOCAL_SLOT khi
## không dùng server). Ghi ra file tạm rồi đổi tên — tắt máy giữa chừng vẫn còn bản cũ.
## Dữ liệu: {"version", "counts": {tên đồ: số}, "areas": {đường dẫn vùng: [trạng thái]}}.

const VERSION: int = 1
const DIR: String = "user://saves"
const LOCAL_SLOT: String = "local"


static func path_for(slot: String) -> String:
	return "%s/%s.json" % [DIR, slot.validate_filename()]


## Ghi `data` vào slot; trả về OK hoặc mã lỗi.
static func write(slot: String, data: Dictionary) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(DIR)
	if made != OK:
		return made
	var path := path_for(slot)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if not stored:
		return ERR_FILE_CANT_WRITE
	return DirAccess.rename_absolute(tmp, path)


## Đọc slot; {} nếu chưa có, hỏng hoặc khác version (hỏng thì cảnh báo, không xoá file).
static func read(slot: String) -> Dictionary:
	var path := path_for(slot)
	if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".tmp"):
		# Sập máy giữa lúc đổi tên (Windows xoá file đích trước): bản mới còn ở file tạm.
		DirAccess.rename_absolute(path + ".tmp", path)
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not is_valid(data):
		push_warning("Bản lưu hỏng hoặc khác version, bỏ qua: " + path)
		return {}
	return data


static func is_valid(data: Variant) -> bool:
	return data is Dictionary and number(data, "version") == VERSION


## Số trong dữ liệu đọc từ file / server (JSON trả float); sai kiểu → `fallback`.
static func number(data: Dictionary, key: String, fallback: float = 0.0) -> float:
	var value: Variant = data.get(key)
	return float(value) if value is float or value is int else fallback
