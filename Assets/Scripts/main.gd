extends Node2D
class_name Main

var math = Math.new()
var rng = RandomNumberGenerator.new()

var max_cells: int = 50
var current_cells: int = 0

var max_meat: int = 100
var current_meat: int = 0

var max_plant: int = 100
var current_plant: int = 0

#Node Variables
@onready var cell_node = preload("res://Assets/Scenes/cell.tscn")
@onready var plant_node = preload("res://Assets/Scenes/plant.tscn")
@onready var meat_node = preload("res://Assets/Scenes/meat.tscn")

#Cell Modifying Variables
var cell_mutation_chance: float = 0.1
var cell_mutation_rate: float = 1.0

#Plant Summon Variables 
var plant_summon_time: float = 2.5
var plant_summon_timer: float = 2.5

func _ready() -> void:
	Engine.max_fps = 60

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if plant_summon_timer > 0:
		plant_summon_timer -= delta
	else:
		plant_summon_timer = plant_summon_time
		for i in 5:
			if summon_plant(math.random_point_in_circle(250.0),rng.randf_range(0.25,0.75)):
				print("Randomly Summoned Plant!")
			#math.random_point_in_circle()
	_check_summon_cell_at_mouse()
	_check_summon_plant_at_mouse()
	_check_summon_meat_at_mouse()
	_check_click_on_cells()
	
func _check_summon_cell_at_mouse():
	if !Input.is_action_just_pressed("spawn_random_cell"):
		return
	if summon_cell(get_global_mouse_position(), "miracle"):
		print("Miracle Cell Summoned!")
	
func _check_summon_plant_at_mouse():
	if !Input.is_action_just_pressed("spawn_plant"):
		return
	if summon_plant(get_global_mouse_position(), 1.0):
		print("Plant Summoned!")
	
func _check_summon_meat_at_mouse():
	if !Input.is_action_just_pressed("spawn_meat"):
		return
	if summon_meat(get_global_mouse_position(), 1.0):
		print("Meat Summoned!")
	
func _check_click_on_cells():
	if !Input.is_action_just_pressed("left_click"):
		return
	for area in get_areas_at_global_pos(get_global_mouse_position()):
		if area.get_parent().is_in_group("cell") and area.is_in_group("hitbox"):
			area.get_parent().stats_panel.visible = !area.get_parent().stats_panel.visible
	
func summon_cell(pos: Vector2, birth_type: String, parent: Node = null) -> bool:
	if current_cells >= max_cells:
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
	
func summon_plant(pos: Vector2, size: float) -> bool:
	if current_plant >= max_plant:
		return false
	var instance = plant_node.instantiate()
	instance.global_position = pos
	instance.size = size
	add_child(instance)
	current_plant += 1
	return true
	
func summon_meat(pos: Vector2, size: float) -> bool:
	if current_meat >= max_meat:
		return false
	var instance = meat_node.instantiate()
	instance.global_position = pos
	instance.size = size
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
