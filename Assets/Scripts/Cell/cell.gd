extends CharacterBody2D
class_name Cell

const FONT = preload("res://Assets/Fonts/VCR_OSD_MONO_1.001.ttf")

var rng = RandomNumberGenerator.new()
var gcs = GenerateCellStats.new()

#Node Variables
@onready var collision_node = $CollisionPolygon2D
@onready var vision_node = $VisionRange
@onready var hit_box_node = $HitBox

#Performance Variables
var performance_level: String = "HIGH"

var can_move: bool = true
var can_attack: bool = true
var can_birth: bool = true
var should_update_stat_panel: bool = true
var should_check_hunger: bool = true

#Identity Variables
var cell_uuid: String
var species_uuid: String
var origin_species_uuid: String = "0"
var diet_type: String
var birth_type: String
var parent: Node
var parent_species_uuid: String

#Targeting Variables
var targets: Array[Node2D]
var attackable_targets: Array[Node2D]

#Movement Variables
var current_x_movement: float
var desired_x_movement: float
var current_y_movement: float
var desired_y_movement: float
var movement_change: float
var damaged: float
var attacker: Node

#Growth Stats
var current_growth: float = 0.0
var growth_speed: float
var growth_hunger: float

#Birth Stats (Needed for Growth)
var birth_scale: float
var birth_damage: float
var birth_max_health: float
var birth_movement_speed: float
var birth_max_hunger: float
var birth_hunger: float
var birth_hunger_reserve: float

#Current Stats (with Growth Calculated)
var current_scale: float
var current_damage: float
var current_damage_cooldown: float
var current_max_health: float
var current_health: float
var current_movement_speed: float
var current_max_hunger: float
var current_hunger: float
var current_hunger_drain: float

#Birth Stats (Hunger Drain)
var birth_hunger_drain: float

#New Birth Stats
var birth_vision_range: float
var birth_defense: float
var birth_lifespan: float
var birth_flee_threshold: float
var birth_litter_size: int
var birth_regen_rate: float

#New Current Stats
var current_vision_range: float
var current_defense: float
var current_lifespan: float
var current_flee_threshold: float
var current_litter_size: int
var current_regen_rate: float
var current_age: float = 0.0

#Static Stats
var color: Color
var damage_cooldown: float

#Main class variable
var main

@onready var stats_panel = $Panel
var _name_label: Label
var _info_label: Label
var _health_bar: ProgressBar
var _hunger_bar: ProgressBar
var _hunger_drain_bar: ProgressBar
var _growth_bar: ProgressBar
var _dmg_cooldown_bar: ProgressBar
var _speed_label: Label
var _damage_label: Label
var _species_label: Label
var _parent_species_label: Label
var _defense_bar: ProgressBar
var _vision_bar: ProgressBar
var _age_bar: ProgressBar
var _regen_bar: ProgressBar
var _flee_litter_label: Label

################
#READY FUNCTION#
################
func _ready() -> void:
	WorldWrapper.register(self)
	PerformanceMonitor.performance_level_changed.connect(_on_perf_changed)
	main = get_parent()
	cell_uuid = gcs.create_uuid() #Generate new cell uuid
	
#Cell is CREATED
	if birth_type == "miracle":
		diet_type = ["carnivore", "omnivore", "herbivore"][rng.randi() % 3]
		species_uuid = gcs.create_uuid() #Generate new species uuid
		parent_species_uuid = gcs.create_uuid()
		color = Color(rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),1.0)
		growth_speed = rng.randf_range(0.000025,0.001)
		movement_change = rng.randf_range(0.00001,0.01)
		birth_damage = rng.randf_range(0.5,3)
		damage_cooldown = rng.randf_range(0.5,3)
		birth_max_health = rng.randf_range(1,4)
		birth_movement_speed = rng.randf_range(0.5,5)
		birth_scale = rng.randf_range(0.5,1.25)
		birth_max_hunger = rng.randf_range(5,15)
		birth_hunger_drain = rng.randf_range(0.05,0.005)
		growth_hunger = rng.randf_range(1,3)
		birth_hunger = rng.randf_range(1.5, birth_max_hunger * 0.75)
		birth_hunger_reserve = rng.randf_range(0.1, 0.5)
		birth_vision_range = rng.randf_range(0.5, 2.5)
		birth_defense = rng.randf_range(0.0, 1.5)
		birth_lifespan = rng.randf_range(30.0, 120.0)
		birth_flee_threshold = rng.randf_range(0.0, 0.7)
		birth_litter_size = rng.randi_range(1, 4)
		birth_regen_rate = rng.randf_range(0.0, 0.05)

#Cell is BORN
	elif birth_type.contains("born"):
		if !parent:
			queue_free()
		if birth_type.contains("mutate"):
			species_uuid = gcs.create_uuid()
			parent_species_uuid = parent.species_uuid
			color.r = gcs.create_rand_stat_from_stat(parent.color.r, 0.075 * main.cell_mutation_rate)
			color.g = gcs.create_rand_stat_from_stat(parent.color.g, 0.075 * main.cell_mutation_rate)
			color.b = gcs.create_rand_stat_from_stat(parent.color.b, 0.075 * main.cell_mutation_rate)
			var diets = ["herbivore", "omnivore", "carnivore"]
			diet_type = diets[rng.randi() % diets.size()]
			growth_speed = gcs.create_rand_stat_from_stat(parent.growth_speed, 0.0005 * main.cell_mutation_rate)
			movement_change = gcs.create_rand_stat_from_stat(parent.movement_change, 0.005 * main.cell_mutation_rate)
			birth_damage = gcs.create_rand_stat_from_stat(parent.birth_damage, 0.4 * main.cell_mutation_rate)
			damage_cooldown = gcs.create_rand_stat_from_stat(parent.damage_cooldown, 0.4 * main.cell_mutation_rate)
			birth_max_health = gcs.create_rand_stat_from_stat(parent.birth_max_health, 0.4 * main.cell_mutation_rate)
			birth_movement_speed = gcs.create_rand_stat_from_stat(parent.birth_movement_speed, 0.4 * main.cell_mutation_rate)
			birth_scale = gcs.create_rand_stat_from_stat(parent.birth_scale, 0.15 * main.cell_mutation_rate)
			birth_max_hunger = gcs.create_rand_stat_from_stat(parent.birth_max_hunger, 0.15 * main.cell_mutation_rate)
			birth_hunger_drain = gcs.create_rand_stat_from_stat(parent.birth_hunger_drain, 0.005 * main.cell_mutation_rate)
			growth_hunger = gcs.create_rand_stat_from_stat(parent.growth_hunger, 0.05 * main.cell_mutation_rate)
			birth_hunger = gcs.create_rand_stat_from_stat(parent.birth_hunger, 0.05 * main.cell_mutation_rate)
			birth_hunger_reserve = gcs.create_rand_stat_from_stat(parent.birth_hunger_reserve, 0.1 * main.cell_mutation_rate)
			birth_vision_range = maxf(0.1, gcs.create_rand_stat_from_stat(parent.birth_vision_range, 0.3 * main.cell_mutation_rate))
			birth_defense = maxf(0.0, gcs.create_rand_stat_from_stat(parent.birth_defense, 0.3 * main.cell_mutation_rate))
			birth_lifespan = maxf(5.0, gcs.create_rand_stat_from_stat(parent.birth_lifespan, 15.0 * main.cell_mutation_rate))
			birth_flee_threshold = clampf(gcs.create_rand_stat_from_stat(parent.birth_flee_threshold, 0.15 * main.cell_mutation_rate), 0.0, 0.95)
			birth_litter_size = maxi(1, roundi(gcs.create_rand_stat_from_stat(parent.birth_litter_size, 0.6 * main.cell_mutation_rate)))
			birth_regen_rate = maxf(0.0, gcs.create_rand_stat_from_stat(parent.birth_regen_rate, 0.015 * main.cell_mutation_rate))
		else:
			species_uuid = parent.species_uuid
			parent_species_uuid = parent.parent_species_uuid
			color.r = gcs.create_rand_stat_from_stat(parent.color.r, 0.0005 * main.cell_mutation_rate)
			color.g = gcs.create_rand_stat_from_stat(parent.color.g, 0.0005 * main.cell_mutation_rate)
			color.b = gcs.create_rand_stat_from_stat(parent.color.b, 0.0005 * main.cell_mutation_rate)
			diet_type = parent.diet_type
			growth_speed = gcs.create_rand_stat_from_stat(parent.growth_speed, 0.000005 * main.cell_mutation_rate)
			movement_change = gcs.create_rand_stat_from_stat(parent.movement_change, 0.00005 * main.cell_mutation_rate)
			birth_damage = gcs.create_rand_stat_from_stat(parent.birth_damage, 0.005 * main.cell_mutation_rate)
			damage_cooldown = gcs.create_rand_stat_from_stat(parent.damage_cooldown, 0.005 * main.cell_mutation_rate)
			birth_max_health = gcs.create_rand_stat_from_stat(parent.birth_max_health, 0.005 * main.cell_mutation_rate)
			birth_movement_speed = gcs.create_rand_stat_from_stat(parent.birth_movement_speed, 0.005 * main.cell_mutation_rate)
			birth_scale = gcs.create_rand_stat_from_stat(parent.birth_scale, 0.001 * main.cell_mutation_rate)
			birth_max_hunger = gcs.create_rand_stat_from_stat(parent.birth_max_hunger, 0.001 * main.cell_mutation_rate)
			birth_hunger_drain = gcs.create_rand_stat_from_stat(parent.birth_hunger_drain, 0.000005 * main.cell_mutation_rate)
			growth_hunger = gcs.create_rand_stat_from_stat(parent.growth_hunger, 0.00005 * main.cell_mutation_rate)
			birth_hunger = gcs.create_rand_stat_from_stat(parent.birth_hunger, 0.00005 * main.cell_mutation_rate)
			birth_hunger_reserve = gcs.create_rand_stat_from_stat(parent.birth_hunger_reserve, 0.0005 * main.cell_mutation_rate)
			birth_vision_range = maxf(0.1, gcs.create_rand_stat_from_stat(parent.birth_vision_range, 0.003 * main.cell_mutation_rate))
			birth_defense = maxf(0.0, gcs.create_rand_stat_from_stat(parent.birth_defense, 0.003 * main.cell_mutation_rate))
			birth_lifespan = maxf(5.0, gcs.create_rand_stat_from_stat(parent.birth_lifespan, 0.1 * main.cell_mutation_rate))
			birth_flee_threshold = clampf(gcs.create_rand_stat_from_stat(parent.birth_flee_threshold, 0.001 * main.cell_mutation_rate), 0.0, 0.95)
			birth_litter_size = maxi(1, roundi(gcs.create_rand_stat_from_stat(parent.birth_litter_size, 0.005 * main.cell_mutation_rate)))
			birth_regen_rate = maxf(0.0, gcs.create_rand_stat_from_stat(parent.birth_regen_rate, 0.0001 * main.cell_mutation_rate))

#Apply stats to cell
	$CollisionPolygon2D/Sprite2D.modulate = Color(color)
	current_damage = birth_damage
	current_damage_cooldown = damage_cooldown
	current_max_health = birth_max_health
	current_health = birth_max_health
	current_scale = birth_scale
	current_movement_speed = birth_movement_speed
	current_max_hunger = birth_max_hunger
	current_hunger = birth_hunger * 0.5
	current_hunger_drain = birth_hunger_drain
	current_vision_range = birth_vision_range
	current_defense = birth_defense
	current_lifespan = birth_lifespan
	current_flee_threshold = birth_flee_threshold
	current_litter_size = birth_litter_size
	current_regen_rate = birth_regen_rate
	scale = Vector2(current_scale, current_scale)
	vision_node.scale = Vector2(current_vision_range, current_vision_range)
	queue_redraw()
	var _sname := ""
	if not LineageTracker.species.has(species_uuid):
		if birth_type == "miracle":
			_sname = NameGenerator.new_name()
		else:
			var _pdata: Dictionary = LineageTracker.species.get(parent_species_uuid, {})
			_sname = NameGenerator.mutate_name(_pdata.get("name", ""))
	LineageTracker.register_birth(species_uuid, parent_species_uuid, color, diet_type, _sname)
	_build_stats_panel()

##################
#PROCESS FUNCTION#
##################
func _process(delta: float) -> void:
	if can_move:
		_move(delta)
	if can_attack:
		_attack(delta)
	_grow(delta)
	if should_check_hunger:
		_hunger_check(delta)
	_age(delta)
	_regen(delta)
	if can_birth:
		_check_for_birth()
	if should_update_stat_panel:
		_update_stats_panel()

	if current_health <= 0:
		if current_hunger <= 0:
			main.summon_meat(global_position, current_scale * 0.3, species_uuid)
		else:
			main.summon_meat(global_position, current_scale * 0.6, species_uuid)
		queue_free()
		
#######################
#UPDATE STATS UI PANEL#
#######################
func _build_stats_panel() -> void:
	var font: Font = FONT
	var vbox = VBoxContainer.new()
	vbox.scale = Vector2(0.075, 0.075)
	vbox.position = Vector2(4, 4)
	vbox.custom_minimum_size = Vector2(2267, 0)
	vbox.add_theme_constant_override("separation", 12)
	stats_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_override("font", font)
	_name_label.add_theme_font_size_override("font_size", 72)
	_name_label.custom_minimum_size = Vector2(0, 110)
	vbox.add_child(_name_label)

	_info_label = Label.new()
	_info_label.add_theme_font_override("font", font)
	_info_label.add_theme_font_size_override("font_size", 64)
	_info_label.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(_info_label)

	_health_bar      = _make_bar(vbox, "Health",    Color(0.85, 0.2,  0.2 ), font)
	_hunger_bar      = _make_bar(vbox, "Hunger",    Color(0.9,  0.6,  0.1 ), font)
	_hunger_drain_bar= _make_bar(vbox, "H.Drain",   Color(0.8,  0.45, 0.05), font)
	_growth_bar      = _make_bar(vbox, "Growth",    Color(0.2,  0.8,  0.3 ), font)
	_dmg_cooldown_bar= _make_bar(vbox, "Atk.Speed", Color(0.6,  0.1,  0.7 ), font)
	_defense_bar     = _make_bar(vbox, "Defense",   Color(0.3,  0.5,  0.9 ), font)
	_vision_bar      = _make_bar(vbox, "Vision",    Color(0.95, 0.95, 0.3 ), font)
	_age_bar         = _make_bar(vbox, "Age",       Color(0.6,  0.35, 0.75), font)
	_regen_bar       = _make_bar(vbox, "Regen",     Color(0.2,  0.9,  0.65), font)

	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(sep)

	_speed_label = _make_stat_label(vbox, font)
	_damage_label = _make_stat_label(vbox, font)
	_flee_litter_label = _make_stat_label(vbox, font)
	_species_label = _make_stat_label(vbox, font)
	_parent_species_label = _make_stat_label(vbox, font)

func _make_bar(container: Control, label_text: String, bar_color: Color, font: Font) -> ProgressBar:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 260)
	row.add_theme_constant_override("separation", 20)
	container.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(380, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 56)
	row.add_child(lbl)

	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return bar

func _make_stat_label(container: Control, font: Font) -> Label:
	var lbl = Label.new()
	lbl.custom_minimum_size = Vector2(0, 160)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 56)
	container.add_child(lbl)
	return lbl

func _update_stats_panel() -> void:
	if !_info_label:
		return
	var _sp_data: Dictionary = LineageTracker.species.get(species_uuid, {})
	_name_label.text = _sp_data.get("name", "unknown")
	_info_label.text = str(diet_type.to_upper(), "  |  sz: ", snappedf(current_scale, 0.01), "  |  hp: ", snappedf(current_health, 0.1), "/", snappedf(current_max_health, 0.1))
	_health_bar.max_value = current_max_health
	_health_bar.value = current_health
	_hunger_bar.max_value = current_max_hunger
	_hunger_bar.value = current_hunger
	_hunger_drain_bar.max_value = maxf(birth_hunger_drain * 4.0, 0.0001)
	_hunger_drain_bar.value = current_hunger_drain
	_growth_bar.max_value = 1.0
	_growth_bar.value = current_growth
	_dmg_cooldown_bar.max_value = maxf(damage_cooldown, 0.001)
	_dmg_cooldown_bar.value = damage_cooldown - current_damage_cooldown
	_defense_bar.max_value = maxf(birth_defense * 3.0, 0.1)
	_defense_bar.value = current_defense
	_vision_bar.max_value = 6.0
	_vision_bar.value = current_vision_range
	_age_bar.max_value = current_lifespan
	_age_bar.value = current_age
	_regen_bar.max_value = maxf(birth_regen_rate * 4.0, 0.0001)
	_regen_bar.value = current_regen_rate
	_speed_label.text = str("Speed:   ", snappedf(current_movement_speed, 0.01), "  (birth: ", snappedf(birth_movement_speed, 0.01), ")")
	_damage_label.text = str("Damage: ", snappedf(current_damage, 0.01), "  (birth: ", snappedf(birth_damage, 0.01), ")")
	_flee_litter_label.text = str("Flee: ", snappedf(current_flee_threshold * 100.0, 1.0), "%hp   Litter: ", current_litter_size)
	_species_label.text = str("Species:  ", species_uuid)
	_parent_species_label.text = str("Parent:    ", parent_species_uuid)
		
func _draw() -> void:
	if not stats_panel.visible:
		return
	var radius := 25.0 * current_vision_range
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.18), 1.0, true)

func _check_for_birth() -> void:
	if current_hunger >= birth_hunger * (1.0 + birth_hunger_reserve):
		for i in current_litter_size:
			if main.summon_cell(global_position, "born", self):
				current_hunger -= birth_hunger
			else:
				break

func _age(delta: float) -> void:
	current_age += delta
	if current_age >= current_lifespan:
		if current_hunger <= 0:
			main.summon_meat(global_position, current_scale * 0.3, species_uuid)
		else:
			main.summon_meat(global_position, current_scale * 0.6, species_uuid)
		queue_free()

func _regen(delta: float) -> void:
	if current_regen_rate > 0 and current_hunger > current_max_hunger * 0.5:
		current_health = minf(current_health + current_regen_rate * delta, current_max_health)
	
func _grow(delta: float):
	#Check for max growth
	if current_growth >= 1:
		return
	#Check if hunger is greater than the amount needed to grow
	if current_hunger > growth_hunger:
		#Apply growth amount
		current_growth += growth_speed * delta
		#Apply new current stats
		current_movement_speed = birth_movement_speed * (current_growth + 1)
		current_scale = birth_scale * (current_growth + 1)
		current_max_hunger = birth_max_hunger * (current_growth + 1)
		current_max_health = birth_max_health * (current_growth + 1)
		current_damage = birth_damage * (current_growth + 1)
		current_hunger_drain = birth_hunger_drain * (current_growth + 1)
		current_vision_range = birth_vision_range * (current_growth + 1)
		current_defense = birth_defense * (current_growth + 1)
		current_lifespan = birth_lifespan * (current_growth + 1)
		current_regen_rate = birth_regen_rate * (current_growth + 1)
		scale = Vector2(current_scale, current_scale)
		vision_node.scale = Vector2(current_vision_range, current_vision_range)
		queue_redraw()
		#Check if hunger greater than 0 to drain
		if current_hunger > 0:
			current_hunger -= current_hunger_drain * delta
		
func _hunger_check(delta: float):
	#Check if hunger less than 0 for damage
	if current_hunger <= 0:
		current_health -= current_hunger_drain * delta
		return
	#Check for velocity to remove hunger
	var velocity_average = (abs(velocity.x) + abs(velocity.y)) / 2
	if velocity_average > 0:
		#Remove hunger
		current_hunger -= (current_hunger_drain * delta) * (velocity_average * 0.1)
	
func _attack(delta: float):
	if current_damage_cooldown > 0:
		current_damage_cooldown -= delta
		return
	if attackable_targets.size() > 0:
		current_damage_cooldown = damage_cooldown
		for target in attackable_targets:
			target.take_damage(current_damage, self)
			if target.is_in_group("cell"):
				current_hunger -= current_hunger_drain * delta
			elif current_hunger < current_max_hunger and target.is_in_group("plant"):
				current_hunger += current_damage * 0.25
			elif current_hunger < current_max_hunger and target.is_in_group("meat"):
				current_hunger += current_damage * 0.75

	
func take_damage(amount: float, attacker_node: Node):
	current_health -= maxf(0.1, amount - current_defense)
	damaged += amount
	attacker = attacker_node
	#if current_health <= 0:
	#	if attacker_node:
	#		get_parent().summon_cell(global_position,"born",attacker_node)
	#	#attacker_node.targets.erase
	#	queue_free()
	
func _move(delta: float):
	
	if damaged > 0 and attacker:
		var dir = attacker.global_position.direction_to(global_position)
		velocity = dir * (damaged * 3)
		damaged -= delta

	elif current_flee_threshold > 0 and current_health < current_max_health * current_flee_threshold and targets.size() > 0:
		var threat := get_closest_node(self, targets)
		var dir := threat.global_position.direction_to(global_position)
		velocity = dir * (current_movement_speed * 2)

	elif targets.size() < 1:
		if !current_x_movement:
			current_x_movement = rng.randf_range(-5,5)
			desired_x_movement = current_x_movement
		if !current_y_movement:
			current_y_movement = rng.randf_range(-5,5)
			desired_y_movement = current_y_movement
		
		if round(desired_x_movement) == round(current_x_movement):
			desired_x_movement = rng.randf_range(-5,5)
		if round(desired_y_movement) == round(current_y_movement):
			desired_y_movement = rng.randf_range(-5,5)
			
		if desired_x_movement > current_x_movement:
			current_x_movement += movement_change
		if desired_x_movement < current_x_movement:
			current_x_movement -= movement_change
		if desired_y_movement > current_y_movement:
			current_y_movement += movement_change
		if desired_y_movement < current_y_movement:
			current_y_movement -= movement_change
		velocity = Vector2(current_x_movement * current_movement_speed,current_y_movement * current_movement_speed)
	else:
		var closest_target = get_closest_node(self, targets)
		var dir = global_position.direction_to(closest_target.global_position)
		velocity = dir * (current_movement_speed * 2)
		
		
	move_and_slide()
			
	
func get_closest_node(origin: Node2D, nodes: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist := INF

	for n in nodes:
		if n == null or n == origin:
			continue

		var d := origin.global_position.distance_squared_to(n.global_position)
		if d < min_dist:
			min_dist = d
			closest = n

	return closest



func _should_target(entity: Node) -> bool:
	if entity == self:
		return false
	match diet_type:
		"herbivore":
			if entity.species_uuid == species_uuid:
				return false
			return entity.is_in_group("plant")
		"carnivore":
			if entity.species_uuid == species_uuid:
				return false
			if entity.species_uuid == parent_species_uuid:
				return false
			if entity.parent_species_uuid == species_uuid:
				return false
			if entity.parent_species_uuid == parent_species_uuid:
				return false
			if entity.is_in_group("meat") and entity.origin_species_uuid == species_uuid:
				return false
			return entity.is_in_group("cell") or entity.is_in_group("meat")
		"omnivore":
			if entity.species_uuid == species_uuid:
				return false
			if entity.species_uuid == parent_species_uuid:
				return false
			if entity.parent_species_uuid == species_uuid:
				return false
			if entity.parent_species_uuid == parent_species_uuid:
				return false
			if entity.is_in_group("meat") and entity.origin_species_uuid == species_uuid:
				return false
			return true
	return false

func _on_vision_range_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
		return
	var entity := area.get_parent()
	if _should_target(entity):
		targets.append(entity)

func _on_vision_range_area_exited(area: Area2D) -> void:
	targets.erase(area.get_parent())

func _on_hit_box_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
		return
	var entity := area.get_parent()
	if _should_target(entity):
		attackable_targets.append(entity)

func _on_hit_box_area_exited(area: Area2D) -> void:
	attackable_targets.erase(area.get_parent())
	
func _on_perf_changed(level):
	match level:
		PerformanceMonitor.Level.HIGH:
			can_move = true
			can_attack = true
			can_birth = true
			should_update_stat_panel = true
			should_check_hunger = true
			set_collision_layer_value(1, true)
		PerformanceMonitor.Level.MEDIUM:
			can_move = true
			can_attack = true
			can_birth = true
			should_update_stat_panel = false
			should_check_hunger = true
			set_collision_layer_value(1, false)
		PerformanceMonitor.Level.LOW:
			can_move = false
			can_attack = true
			can_birth = false
			should_update_stat_panel = false
			should_check_hunger = false
			set_collision_layer_value(1, false)
		PerformanceMonitor.Level.CRITICAL:
			can_move = false
			can_attack = false
			can_birth = false
			should_update_stat_panel = false
			should_check_hunger = false
			set_collision_layer_value(1, false)
			

func _exit_tree():
	WorldWrapper.unregister(self)
	if is_instance_valid(main):
		main.current_cells -= 1
	LineageTracker.on_cell_died(species_uuid)
