extends Node2D
class_name CameraController

var camera_speed: float = 1.0
var is_sprinting: bool = false
var is_panning: bool = false
var pan_last_position: Vector2

var main

@onready var settings = $Camera2D/RootUI/ScaleUI/Settings
@onready var sim_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings
@onready var engine_settings = $Camera2D/RootUI/ScaleUI/Settings/Panel/EngineSettings
@onready var plant_spawners_panel = $Camera2D/RootUI/ScaleUI/Settings/Panel/PlantSpawners
@onready var spawner_list = $Camera2D/RootUI/ScaleUI/Settings/Panel/PlantSpawners/ScrollContainer/SpawnerList
@onready var keybinds_panel = $Camera2D/RootUI/ScaleUI/Settings/Panel/KeybindsPanel
@onready var keybind_list = $Camera2D/RootUI/ScaleUI/Settings/Panel/KeybindsPanel/ScrollContainer/KeybindList
@onready var leave_panel = $Camera2D/RootUI/ScaleUI/Settings/Panel/LeavePanel
@onready var sim_settings_list = $Camera2D/RootUI/ScaleUI/Settings/Panel/SimSettings/ScrollContainer/SimSettingsList
@onready var engine_settings_list = $Camera2D/RootUI/ScaleUI/Settings/Panel/EngineSettings/ScrollContainer/EngineSettingsList
@onready var lineage_panel = $UILayer/LineagePanel

const BINDABLE_ACTIONS: Array = [
	["camera_move_up",    "Move Up"],
	["camera_move_down",  "Move Down"],
	["camera_move_left",  "Move Left"],
	["camera_move_right", "Move Right"],
	["speed_up",          "Sprint"],
	["select_speed",      "Speed Select"],
	["spawn_random_cell", "Spawn Cell"],
	["spawn_plant",       "Spawn Plant"],
	["spawn_meat",        "Spawn Meat"],
	["left_click",        "Drag Entity"],
	["open_stats",        "Open Stats"],
	["camera_pan",        "Pan Camera"],
]

var _rebinding_action: String = ""
var _rebind_button: Button = null

func _ready() -> void:
	main = get_parent()
	$Camera2D/RootUI/ScaleUI/VersionLabel.text = VersionControl.version
	_build_sim_settings()
	_build_engine_settings()
	_load_keybinds()
	_build_keybind_list()

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
	if _rebinding_action != "":
		if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
			if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
				_rebind_button.text = _get_action_string(_rebinding_action)
			else:
				InputMap.action_erase_events(_rebinding_action)
				InputMap.action_add_event(_rebinding_action, event)
				_rebind_button.text = _get_action_string(_rebinding_action)
				_save_keybinds()
			_rebinding_action = ""
			_rebind_button = null
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			pan_last_position = event.position
	if event is InputEventMouseMotion and is_panning:
		var zoom = $Camera2D.zoom
		global_position -= (event.position - pan_last_position) / zoom
		pan_last_position = event.position
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

func _build_keybind_list() -> void:
	var toggle = CheckButton.new()
	toggle.text = "Hold to Spawn"
	toggle.button_pressed = main.spawn_hold_mode
	toggle.toggled.connect(func(val: bool): main.spawn_hold_mode = val)
	toggle.custom_minimum_size = Vector2(0, 28)
	keybind_list.add_child(toggle)

	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 8)
	keybind_list.add_child(sep)

	for entry in BINDABLE_ACTIONS:
		var action: String = entry[0]
		var label_text: String = entry[1]
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 28)
		keybind_list.add_child(row)
		var lbl = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(140, 0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)
		var btn = Button.new()
		btn.text = _get_action_string(action)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured = action
		var locked = action in ["left_click", "open_stats", "camera_pan"]
		btn.disabled = locked
		if not locked:
			btn.pressed.connect(func(): _start_rebind(captured, btn))
		if action == "select_speed":
			btn.tooltip_text = "Hold this key and press 1–9 to set camera speed."
		row.add_child(btn)

func _get_action_string(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "None"
	var event = events[0]
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   return "LMB"
			MOUSE_BUTTON_RIGHT:  return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			_: return "Mouse %d" % event.button_index
	return "Unknown"

func _start_rebind(action: String, btn: Button) -> void:
	if _rebinding_action != "":
		_rebind_button.text = _get_action_string(_rebinding_action)
	_rebinding_action = action
	_rebind_button = btn
	btn.text = "[ press key ]"

func _save_keybinds() -> void:
	var data: Dictionary = {}
	for entry in BINDABLE_ACTIONS:
		var action: String = entry[0]
		var events = InputMap.action_get_events(action)
		if events.is_empty():
			continue
		var event = events[0]
		if event is InputEventKey:
			data[action] = {"type": "key", "physical_keycode": event.physical_keycode}
		elif event is InputEventMouseButton:
			data[action] = {"type": "mouse", "button_index": event.button_index}
	SaveManager.save("keybinds", data)

func _load_keybinds() -> void:
	var data = SaveManager.load_file("keybinds")
	if data.is_empty():
		return
	for action in data:
		var entry: Dictionary = data[action]
		var event: InputEvent
		if entry.get("type") == "key":
			var e = InputEventKey.new()
			e.physical_keycode = entry["physical_keycode"]
			event = e
		elif entry.get("type") == "mouse":
			var e = InputEventMouseButton.new()
			e.button_index = entry["button_index"]
			event = e
		if event:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)

func _on_keybinds_button_pressed() -> void:
	var was_visible = keybinds_panel.visible
	_hide_all_panels()
	keybinds_panel.visible = !was_visible

func _on_leave_button_pressed() -> void:
	var was_visible = leave_panel.visible
	_hide_all_panels()
	leave_panel.visible = !was_visible

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/main_menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_lineage_button_pressed() -> void:
	if lineage_panel.visible:
		lineage_panel.visible = false
	else:
		lineage_panel.open()

func _on_button_pressed() -> void:
	settings.visible = !settings.visible

func _hide_all_panels() -> void:
	sim_settings.visible = false
	engine_settings.visible = false
	plant_spawners_panel.visible = false
	keybinds_panel.visible = false
	leave_panel.visible = false

func _on_sim_settings_button_pressed() -> void:
	var was_visible = sim_settings.visible
	_hide_all_panels()
	sim_settings.visible = !was_visible

func _on_engine_settings_button_pressed() -> void:
	var was_visible = engine_settings.visible
	_hide_all_panels()
	engine_settings.visible = !was_visible

func _on_plant_spawners_button_pressed() -> void:
	var was_visible = plant_spawners_panel.visible
	_hide_all_panels()
	plant_spawners_panel.visible = !was_visible
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

func _build_sim_settings() -> void:
	_make_spinbox_row(sim_settings_list, "Max Cells",              main.max_cells,            1,   1000, 1,    func(v): main.max_cells = roundi(v))
	_make_spinbox_row(sim_settings_list, "Max Plants",             main.max_plant,            1,   5000, 1,    func(v): main.max_plant = roundi(v))
	_make_spinbox_row(sim_settings_list, "Max Meat",               main.max_meat,             1,   5000, 1,    func(v): main.max_meat = roundi(v))
	_make_spinbox_row(sim_settings_list, "World Radius",           WorldWrapper.world_radius, 50,  2000, 10,   func(v): WorldWrapper.set_world_radius(v))
	_make_slider_row( sim_settings_list, "Mutation Chance",        main.cell_mutation_chance, 0.0, 1.0,  0.01, func(v): main.cell_mutation_chance = v)
	_make_slider_row( sim_settings_list, "Mutation Rate",          main.cell_mutation_rate,   0.0, 25.0, 0.1,  func(v): main.cell_mutation_rate = v)
	_make_spinbox_row(sim_settings_list, "Meat Spoil (s, 0=off)",  main.meat_spoil_time,      0,   3600, 1,    func(v): main.meat_spoil_time = v)
	_make_spinbox_row(sim_settings_list, "Plant Spoil (s, 0=off)", main.plant_spoil_time,     0,   3600, 1,    func(v): main.plant_spoil_time = v)

func _make_spinbox_row(parent: Control, label_text: String, default_val: float, min_val: float, max_val: float, step_val: float, on_change: Callable) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var box = SpinBox.new()
	box.min_value = min_val
	box.max_value = max_val
	box.step = step_val
	box.value = default_val
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.value_changed.connect(on_change)
	row.add_child(box)

func _make_slider_row(parent: Control, label_text: String, default_val: float, min_val: float, max_val: float, step_val: float, on_change: Callable) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var val_lbl = Label.new()
	val_lbl.text = str(snappedf(default_val, step_val))
	val_lbl.custom_minimum_size = Vector2(40, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)
	slider.value_changed.connect(func(v: float):
		on_change.call(v)
		val_lbl.text = str(snappedf(v, step_val))
	)

func _build_engine_settings() -> void:
	_make_spinbox_row(engine_settings_list, "Max FPS", Engine.max_fps, 20, 9999, 1, func(v):
		Engine.max_fps = roundi(v)
		PerformanceMonitor.set_target_fps(v)
	)
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	engine_settings_list.add_child(row)
	var lbl = Label.new()
	lbl.text = "Window Mode"
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var opt = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_item("Windowed", 0)
	opt.add_item("Fullscreen", 1)
	opt.add_item("Fullscreen Windowed", 2)
	opt.item_selected.connect(func(index: int):
		match index:
			0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	)
	row.add_child(opt)
