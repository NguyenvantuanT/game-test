@tool
class_name Garden
extends Area2D
## Một khu vườn: luống đất có rào, các hàng cây. Báo khi Player đi vào / ra.
## Gốc toạ độ = góc trên-trái của luống. Collision sinh trong code theo `size`
## (mỗi instance một shape riêng, tránh dùng chung resource).

signal player_entered(garden: Garden)
signal player_exited(garden: Garden)

const FENCE_COLOR: Color = Color(0.55, 0.38, 0.2)
const LABEL_COLOR: Color = Color(1.0, 1.0, 1.0)
const LABEL_SIZE: int = 20
const PLANT_SPACING: float = 36.0
const PLANT_RADIUS: float = 9.0
const EDGE_MARGIN: float = 24.0

@export var display_name: String = "Vườn":
	set(value):
		display_name = value
		queue_redraw()
@export var size: Vector2 = Vector2(320.0, 220.0):
	set(value):
		size = value
		queue_redraw()
@export var soil_color: Color = Color(0.45, 0.3, 0.18):
	set(value):
		soil_color = value
		queue_redraw()
@export var plant_color: Color = Color(0.3, 0.7, 0.25):
	set(value):
		plant_color = value
		queue_redraw()
@export_range(1, 10) var row_count: int = 4:
	set(value):
		row_count = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = size / 2.0
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _draw() -> void:
	var bed := Rect2(Vector2.ZERO, size)
	draw_rect(bed, soil_color)
	draw_rect(bed, FENCE_COLOR, false, 6.0)

	var row_gap := size.y / (row_count + 1)
	var per_row := maxi(1, floori((size.x - EDGE_MARGIN * 2.0) / PLANT_SPACING) + 1)
	var start_x := (size.x - (per_row - 1) * PLANT_SPACING) / 2.0
	for row in row_count:
		var y := row_gap * (row + 1)
		for col in per_row:
			draw_circle(Vector2(start_x + col * PLANT_SPACING, y), PLANT_RADIUS, plant_color)

	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(0.0, -12.0),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		LABEL_SIZE,
		LABEL_COLOR
	)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited.emit(self)
