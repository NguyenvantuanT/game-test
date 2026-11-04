@tool
class_name House
extends StaticBody2D
## Ngôi nhà — vật cản tĩnh, vẽ bằng hình khối tạm.
## Gốc toạ độ = góc trên-trái của tường; mái nhô lên phía trên.
## Collision chỉ phủ phần tường (xem CollisionShape2D trong house.tscn).

const WALL_SIZE: Vector2 = Vector2(240.0, 160.0)
const ROOF_HEIGHT: float = 90.0
const ROOF_OVERHANG: float = 20.0
const DOOR_SIZE: Vector2 = Vector2(44.0, 64.0)
const WINDOW_SIZE: Vector2 = Vector2(44.0, 36.0)

const WALL_COLOR: Color = Color(0.93, 0.87, 0.74)
const ROOF_COLOR: Color = Color(0.72, 0.25, 0.2)
const DOOR_COLOR: Color = Color(0.45, 0.28, 0.15)
const WINDOW_COLOR: Color = Color(0.6, 0.82, 0.95)
const OUTLINE_COLOR: Color = Color(0.3, 0.2, 0.15)


func _draw() -> void:
	var walls := Rect2(Vector2.ZERO, WALL_SIZE)
	draw_rect(walls, WALL_COLOR)
	draw_rect(walls, OUTLINE_COLOR, false, 3.0)

	var roof := PackedVector2Array(
		[
			Vector2(-ROOF_OVERHANG, 0.0),
			Vector2(WALL_SIZE.x / 2.0, -ROOF_HEIGHT),
			Vector2(WALL_SIZE.x + ROOF_OVERHANG, 0.0),
		]
	)
	draw_colored_polygon(roof, ROOF_COLOR)
	roof.append(roof[0])
	draw_polyline(roof, OUTLINE_COLOR, 3.0)

	var door := Rect2(
		Vector2((WALL_SIZE.x - DOOR_SIZE.x) / 2.0, WALL_SIZE.y - DOOR_SIZE.y), DOOR_SIZE
	)
	draw_rect(door, DOOR_COLOR)
	draw_circle(door.position + Vector2(DOOR_SIZE.x - 9.0, DOOR_SIZE.y / 2.0), 3.0, WALL_COLOR)

	for x: float in [28.0, WALL_SIZE.x - 28.0 - WINDOW_SIZE.x]:
		var window := Rect2(Vector2(x, 36.0), WINDOW_SIZE)
		draw_rect(window, WINDOW_COLOR)
		draw_rect(window, OUTLINE_COLOR, false, 3.0)
		draw_line(window.get_center() - Vector2(0.0, WINDOW_SIZE.y / 2.0), window.get_center() + Vector2(0.0, WINDOW_SIZE.y / 2.0), OUTLINE_COLOR, 2.0)
