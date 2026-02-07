extends Node2D
class_name CameraController

var camera_speed: float = 0.5
var main

func _ready() -> void:
	main = get_parent()
	$HSlider.value = 1.0

func _process(_delta: float) -> void:
	_camera_movement()
	
func _camera_movement():
	var input_dir = Input.get_vector("camera_move_left", "camera_move_right", "camera_move_up", "camera_move_down")
	global_position += input_dir * camera_speed

func _on_h_slider_value_changed(value: float) -> void:
	main.cell_mutation_rate = value
	$HSlider/Label.text = str("Cell Mutation Rate: ", main.cell_mutation_rate, "x")
