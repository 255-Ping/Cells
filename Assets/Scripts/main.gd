extends Node2D
class_name Main

var math = Math.new()
var rng = RandomNumberGenerator.new()

var max_cells: int = 50
var current_cells: int = 0
var perf_cell_cap: int = 50

var max_meat: int = 100
var current_meat: int = 0

var max_plant: int = 100
var current_plant: int = 0

#Node Variables
@onready var cell_node = preload("res://Assets/Scenes/cell.tscn")
@onready var plant_node = preload("res://Assets/Scenes/plant.tscn")
@onready var meat_node = preload("res://Assets/Scenes/meat.tscn")
@onready var plant_spawner_node = preload("res://Assets/Scenes/plant_spawner.tscn")

var plant_spawners: Array = []

#Cell Modifying Variables
var cell_mutation_chance: float = 0.03
var cell_mutation_rate: float = 1.0

func _ready() -> void:
	Engine.max_fps = 60
	PerformanceMonitor.performance_level_changed.connect(_on_perf_changed)
	add_plant_spawner(WorldWrapper.world_radius, max_plant, 0.5, Vector2.ZERO)

func add_plant_spawner(p_radius: float, p_density: int, p_nutrition: float, pos: Vector2) -> Node:
	var spawner = plant_spawner_node.instantiate()
	spawner.radius = p_radius
	spawner.plant_density = p_density
	spawner.plant_nutrition = p_nutrition
	spawner.position = pos
	add_child(spawner)
	plant_spawners.append(spawner)
	return spawner

func remove_plant_spawner(index: int):
	if index < 0 or index >= plant_spawners.size():
		return
	plant_spawners[index].queue_free()
	plant_spawners.remove_at(index)

func _on_perf_changed(level) -> void:
	match level:
		PerformanceMonitor.Level.HIGH:
			perf_cell_cap = max_cells
		PerformanceMonitor.Level.MEDIUM:
			perf_cell_cap = current_cells
		PerformanceMonitor.Level.LOW:
			perf_cell_cap = max(1, current_cells - 5)
		PerformanceMonitor.Level.CRITICAL:
			perf_cell_cap = max(1, current_cells - 10)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_check_summon_cell_at_mouse()
	_check_summon_plant_at_mouse()
	_check_summon_meat_at_mouse()

	_check_click_on_cells()
	
func _check_summon_cell_at_mouse():
	if !Input.is_action_just_pressed("spawn_random_cell"):
		return
	summon_cell(get_global_mouse_position(), "miracle")
	
func _check_summon_plant_at_mouse():
	if !Input.is_action_just_pressed("spawn_plant"):
		return
	summon_plant(get_global_mouse_position(), 1.0)
	
func _check_summon_meat_at_mouse():
	if !Input.is_action_just_pressed("spawn_meat"):
		return
	summon_meat(get_global_mouse_position(), 1.0)
	
func _check_click_on_cells():
	if !Input.is_action_just_pressed("left_click"):
		return
	for area in get_areas_at_global_pos(get_global_mouse_position()):
		if area.get_parent().is_in_group("cell") and area.is_in_group("hitbox"):
			area.get_parent().stats_panel.visible = !area.get_parent().stats_panel.visible
	
func summon_cell(pos: Vector2, birth_type: String, parent: Node = null) -> bool:
	if current_cells >= min(max_cells, perf_cell_cap):
		return false
	var instance = cell_node.instantiate()
	instance.global_position = pos
	if birth_type == "born" and rng.randf_range(0,1) > cell_mutation_chance:
		birth_type = birth_type + "-mutate"
	instance.birth_type = birth_type
	if parent:
		instance.parent = parent
	add_child(instance)
	current_cells += 1
	return true
	
func summon_plant(pos: Vector2, size: float, spawner: Node = null) -> bool:
	if current_plant >= max_plant:
		return false
	var instance = plant_node.instantiate()
	instance.global_position = pos
	instance.size = size
	if spawner:
		instance.spawner = spawner
	add_child(instance)
	current_plant += 1
	return true
	
func summon_meat(pos: Vector2, size: float, origin_species: String = "") -> bool:
	if current_meat >= max_meat:
		return false
	var instance = meat_node.instantiate()
	instance.global_position = pos
	instance.size = size
	instance.origin_species_uuid = origin_species
	add_child(instance)
	current_meat += 1
	return true
	
func get_areas_at_global_pos(pos: Vector2) -> Array[Area2D]:
	var space := get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results := space.intersect_point(query)

	var areas: Array[Area2D] = []
	for hit in results:
		if hit.collider is Area2D:
			areas.append(hit.collider)

	return areas
