class_name Player
extends CharacterBody2D
## Nhân vật top-down đi 4 hướng (WASD / phím mũi tên). Camera đi theo.

const RADIUS: float = 14.0
const BODY_COLOR: Color = Color(0.95, 0.75, 0.3)
const OUTLINE_COLOR: Color = Color(0.35, 0.22, 0.1)
const EYE_COLOR: Color = Color(0.15, 0.1, 0.05)

@export var speed: float = 220.0

var _facing: Vector2 = Vector2.DOWN

@onready var _camera: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO and not direction.is_equal_approx(_facing):
		_facing = direction
		queue_redraw()


## Giới hạn camera trong vùng map (toạ độ world).
func set_camera_limits(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 2.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	var side := _facing.orthogonal() * 5.0
	var front := _facing * 6.0
	draw_circle(front + side, 2.5, EYE_COLOR)
	draw_circle(front - side, 2.5, EYE_COLOR)
