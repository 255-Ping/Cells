extends Node2D
class_name CameraController

var camera_speed: float = 0.25

func _process(_delta: float) -> void:
	_camera_movement()
	
func _camera_movement():
	var input_dir = Input.get_vector("camera_move_left", "camera_move_right", "camera_move_up", "camera_move_down")
	global_position += input_dir * camera_speed
