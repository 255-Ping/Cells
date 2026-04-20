extends Node2D
class_name CameraController

var camera_speed: float = 1.0
var is_sprinting: bool = false

var main

@onready var settings = $Camera2D/RootUI/ScaleUI/Settings
@onready var sim_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings
@onready var engine_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/EngineSettings

func _ready() -> void:
	main = get_parent()
	$Camera2D/RootUI/ScaleUI/VersionLabel.text = VersionControl.version

func _process(_delta: float) -> void:
	_camera_movement()
	_check_sprinting()
	
func _camera_movement():
	var input_dir = Input.get_vector("camera_move_left", "camera_move_right", "camera_move_up", "camera_move_down")
	if is_sprinting:
		global_position += input_dir * (camera_speed * 3)
		return
	global_position += input_dir * camera_speed

func _check_sprinting():
	if Input.is_action_just_pressed("speed_up"):
		is_sprinting = true
	if Input.is_action_just_released("speed_up"):
		is_sprinting = false
		
func _input(event):
	if Input.is_action_pressed("select_speed"):
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_1: set_camera_speed(1.0)
				KEY_2: set_camera_speed(2.0)
				KEY_3: set_camera_speed(3.0)
				KEY_4: set_camera_speed(4.0)
				KEY_5: set_camera_speed(5.0)
				KEY_6: set_camera_speed(6.0)
				KEY_7: set_camera_speed(7.0)
				KEY_8: set_camera_speed(8.0)
				KEY_9: set_camera_speed(9.0)
				
func set_camera_speed(value: float):
	print("Camera Speed set to ", value)
	camera_speed = value

func _on_button_pressed() -> void:
	settings.visible = !settings.visible

func _on_sim_settings_button_pressed() -> void:
	sim_settings.visible = !sim_settings.visible
	engine_settings.visible = false

func _on_engine_settings_button_pressed() -> void:
	engine_settings.visible = !engine_settings.visible 
	sim_settings.visible = false

func _on_mut_rate_slider_value_changed(value: float) -> void:
	main.cell_mutation_rate = value
	$Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings/MutRateSlider.tooltip_text = str(main.cell_mutation_rate)

func _on_max_cells_box_value_changed(value: float) -> void:
	main.max_cells = value

func _on_max_plant_slider_value_changed(value: float) -> void:
	main.max_plant = value
	
func _on_max_meat_slider_value_changed(value: float) -> void:
	main.max_meat = value

func _on_mut_chance_slider_value_changed(value: float) -> void:
	main.cell_mutation_rate = value
	$Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings/MutChanceSlider.tooltip_text = str(main.cell_mutation_rate)

func _on_max_fps_box_value_changed(value: float) -> void:
	Engine.max_fps = roundi(value)

func _on_world_radius_box_value_changed(value: float) -> void:
	WorldWrapper.set_world_radius(value)
