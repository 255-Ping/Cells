extends Node2D
class_name CameraController

var camera_speed: float = 1.0
var is_sprinting: bool = false

var main

@onready var settings = $Camera2D/RootUI/ScaleUI/Settings
@onready var sim_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings
@onready var engine_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/EngineSettings
@onready var plant_spawners_panel = $Camera2D/RootUI/ScaleUI/Settings/Panel/PlantSpawners
@onready var spawner_list = $Camera2D/RootUI/ScaleUI/Settings/Panel/PlantSpawners/ScrollContainer/SpawnerList

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
	plant_spawners_panel.visible = false

func _on_engine_settings_button_pressed() -> void:
	engine_settings.visible = !engine_settings.visible
	sim_settings.visible = false
	plant_spawners_panel.visible = false

func _on_plant_spawners_button_pressed() -> void:
	plant_spawners_panel.visible = !plant_spawners_panel.visible
	sim_settings.visible = false
	engine_settings.visible = false
	if plant_spawners_panel.visible:
		_rebuild_spawner_list()

func _on_add_spawner_button_pressed() -> void:
	main.add_plant_spawner(WorldWrapper.world_radius, 50, 0.5, Vector2.ZERO)
	_rebuild_spawner_list()

func _rebuild_spawner_list() -> void:
	for child in spawner_list.get_children():
		child.queue_free()
	for i in main.plant_spawners.size():
		_add_spawner_card(main.plant_spawners[i], i)

func _add_spawner_card(spawner: Node, index: int) -> void:
	var card = PanelContainer.new()
	var vbox = VBoxContainer.new()
	card.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "Spawner " + str(index + 1)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var remove_btn = Button.new()
	remove_btn.text = "X"
	remove_btn.pressed.connect(func():
		var idx = main.plant_spawners.find(spawner)
		if idx >= 0:
			main.remove_plant_spawner(idx)
		_rebuild_spawner_list()
	)
	header.add_child(title)
	header.add_child(remove_btn)
	vbox.add_child(header)

	# Position
	var pos_row = HBoxContainer.new()
	var x_label = Label.new(); x_label.text = "X:"
	var x_box = SpinBox.new()
	x_box.min_value = -5000; x_box.max_value = 5000; x_box.step = 10
	x_box.value = spawner.position.x
	x_box.custom_minimum_size = Vector2(70, 0)
	x_box.value_changed.connect(func(v): spawner.position.x = v)
	var y_label = Label.new(); y_label.text = "Y:"
	var y_box = SpinBox.new()
	y_box.min_value = -5000; y_box.max_value = 5000; y_box.step = 10
	y_box.value = spawner.position.y
	y_box.custom_minimum_size = Vector2(70, 0)
	y_box.value_changed.connect(func(v): spawner.position.y = v)
	pos_row.add_child(x_label); pos_row.add_child(x_box)
	pos_row.add_child(y_label); pos_row.add_child(y_box)
	vbox.add_child(pos_row)

	# Radius / Density
	var rd_row = HBoxContainer.new()
	var r_label = Label.new(); r_label.text = "Radius:"
	var r_box = SpinBox.new()
	r_box.min_value = 10; r_box.max_value = 5000; r_box.step = 10
	r_box.value = spawner.radius
	r_box.custom_minimum_size = Vector2(70, 0)
	r_box.value_changed.connect(func(v): spawner.set_radius(v))
	var d_label = Label.new(); d_label.text = "Density:"
	var d_box = SpinBox.new()
	d_box.min_value = 1; d_box.max_value = 5000
	d_box.value = spawner.plant_density
	d_box.custom_minimum_size = Vector2(70, 0)
	d_box.value_changed.connect(func(v): spawner.plant_density = roundi(v))
	rd_row.add_child(r_label); rd_row.add_child(r_box)
	rd_row.add_child(d_label); rd_row.add_child(d_box)
	vbox.add_child(rd_row)

	# Nutrition
	var n_row = HBoxContainer.new()
	var n_label = Label.new(); n_label.text = "Nutrition:"
	var n_slider = HSlider.new()
	n_slider.min_value = 0.1; n_slider.max_value = 3.0; n_slider.step = 0.05
	n_slider.value = spawner.plant_nutrition
	n_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_slider.value_changed.connect(func(v): spawner.plant_nutrition = v)
	n_row.add_child(n_label); n_row.add_child(n_slider)
	vbox.add_child(n_row)

	# Spawn interval
	var si_row = HBoxContainer.new()
	var si_label = Label.new(); si_label.text = "Spawn Interval:"
	var si_box = SpinBox.new()
	si_box.min_value = 0.1; si_box.max_value = 60.0; si_box.step = 0.1
	si_box.value = spawner.spawn_interval
	si_box.custom_minimum_size = Vector2(70, 0)
	si_box.value_changed.connect(func(v): spawner.spawn_interval = v)
	si_row.add_child(si_label); si_row.add_child(si_box)
	vbox.add_child(si_row)

	spawner_list.add_child(card)

func _on_mut_rate_slider_value_changed(value: float) -> void:
	main.cell_mutation_rate = value
	$Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings/MutRateSlider.tooltip_text = str(main.cell_mutation_rate)

func _on_max_cells_box_value_changed(value: float) -> void:
	main.max_cells = value

func _on_max_plant_slider_value_changed(value: float) -> void:
	main.max_plant = roundi(value)

func _on_max_meat_slider_value_changed(value: float) -> void:
	main.max_meat = value

func _on_mut_chance_slider_value_changed(value: float) -> void:
	main.cell_mutation_rate = value
	$Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings/MutChanceSlider.tooltip_text = str(main.cell_mutation_rate)

func _on_max_fps_box_value_changed(value: float) -> void:
	Engine.max_fps = roundi(value)

func _on_world_radius_box_value_changed(value: float) -> void:
	WorldWrapper.set_world_radius(value)
