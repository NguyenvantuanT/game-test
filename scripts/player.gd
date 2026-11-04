class_name Player
extends CharacterBody3D
## Nhân vật đi 4 hướng trên mặt đất (WASD / phím mũi tên).
## Camera chéo cố định là con của Player nên đi theo mà không xoay;
## chỉ node `Model` xoay theo hướng đi.

@export var speed: float = 5.0
@export var turn_speed: float = 12.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _model: Node3D = $Model


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= _gravity * delta
	move_and_slide()
	if direction != Vector3.ZERO:
		var target_yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)
