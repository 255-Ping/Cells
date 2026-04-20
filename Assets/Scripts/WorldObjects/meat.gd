extends RigidBody2D
class_name Meat

var size: float
var health: float
var species_uuid: String = "meat"
var parent_species_uuid: String = "0"
var origin_species_uuid: String = ""
var spoil_timer: float = 0.0

var main
var _panel_anchor: Node2D
var stats_panel: Panel
var _health_bar: ProgressBar
var _spoil_bar: ProgressBar
var _info_label: Label

func _ready() -> void:
	await get_tree().process_frame
	WorldWrapper.register(self)
	PerformanceMonitor.performance_level_changed.connect(_on_perf_changed)
	main = get_tree().current_scene
	health = 5 * size
	spoil_timer = main.meat_spoil_time
	$CollisionPolygon2D.scale = Vector2(size, size)
	$HitBox.scale = Vector2(size, size)
	_build_stats_panel()

func _process(delta: float) -> void:
	if main.meat_spoil_time > 0:
		spoil_timer -= delta
		if spoil_timer <= 0:
			main.current_meat -= 1
			queue_free()
			return
	_panel_anchor.global_rotation = 0.0
	if stats_panel.visible:
		_update_stats_panel()

func _build_stats_panel() -> void:
	var font: Font = load("res://Assets/Fonts/VCR_OSD_MONO_1.001.ttf")
	_panel_anchor = Node2D.new()
	add_child(_panel_anchor)
	stats_panel = Panel.new()
	stats_panel.visible = false
	stats_panel.z_index = 1000
	stats_panel.offset_left = -130.0
	stats_panel.offset_top = 10.0
	stats_panel.offset_right = 130.0
	stats_panel.offset_bottom = 100.0
	_panel_anchor.add_child(stats_panel)

	var vbox = VBoxContainer.new()
	vbox.scale = Vector2(0.5, 0.5)
	vbox.position = Vector2(2, 2)
	vbox.custom_minimum_size = Vector2(130, 0)
	vbox.add_theme_constant_override("separation", 6)
	stats_panel.add_child(vbox)

	_info_label = Label.new()
	_info_label.add_theme_font_override("font", font)
	_info_label.add_theme_font_size_override("font_size", 16)
	_info_label.custom_minimum_size = Vector2(0, 22)
	vbox.add_child(_info_label)

	_health_bar = _make_bar(vbox, "Health", Color(0.85, 0.2, 0.2), font)
	_spoil_bar  = _make_bar(vbox, "Fresh",  Color(0.2,  0.8, 0.4), font)

func _make_bar(parent: Control, label_text: String, bar_color: Color, font: Font) -> ProgressBar:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 22)
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(38, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15)
	bg.corner_radius_top_left = 3; bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3; bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.corner_radius_top_left = 3; fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3; fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return bar

func _update_stats_panel() -> void:
	_info_label.text = str("nutrition: ", snappedf(size, 0.01), "   origin: ", origin_species_uuid if origin_species_uuid != "" else "unknown")
	_health_bar.max_value = 5.0 * size
	_health_bar.value = health
	if main.meat_spoil_time > 0:
		_spoil_bar.max_value = main.meat_spoil_time
		_spoil_bar.value = spoil_timer
		_spoil_bar.visible = true
	else:
		_spoil_bar.visible = false

func take_damage(amount: float, _attacker_node: Node):
	health -= amount
	if health <= 0:
		main.current_meat -= 1
		queue_free()
		
func _on_perf_changed(level):
	match level:
		PerformanceMonitor.Level.HIGH:
			set_collision_layer_value(1, true)
		PerformanceMonitor.Level.MEDIUM:
			set_collision_layer_value(1, false)
		PerformanceMonitor.Level.LOW:
			set_collision_layer_value(1, false)
		PerformanceMonitor.Level.CRITICAL:
			set_collision_layer_value(1, false)

func _exit_tree():
	WorldWrapper.unregister(self)
