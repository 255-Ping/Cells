extends Node2D
class_name CameraController

var camera_speed: float = 0.5
var main

func _ready() -> void:
	main = get_parent()
	$Camera2D/RootUI/ScaleUI/VersionLabel.text = VersionControl.version

func _process(_delta: float) -> void:
	#print("test")
	_camera_movement()
	
func _camera_movement():
	var input_dir = Input.get_vector("camera_move_left", "camera_move_right", "camera_move_up", "camera_move_down")
	global_position += input_dir * camera_speed
