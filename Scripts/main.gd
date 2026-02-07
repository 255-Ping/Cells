extends Node2D
class_name Main

#Node Variables
@onready var cell_node = preload("res://Scenes/cell.tscn")
@onready var plant_node = preload("res://Scenes/plant.tscn")
@onready var meat_node = preload("res://Scenes/meat.tscn")

#Cell Modifying Variables
var cell_mutation_rate: float = 1.0

func _ready() -> void:
	Engine.max_fps = 60.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_check_summon_cell_at_mouse()
	_check_summon_plant_at_mouse()
	_check_summon_meat_at_mouse()
	
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
	
func summon_cell(pos: Vector2, birth_type: String, parent: Node = null):
	var instance = cell_node.instantiate()
	instance.global_position = pos
	instance.birth_type = birth_type
	if parent:
		instance.parent = parent
	add_child(instance)
	
func summon_plant(pos: Vector2, size: float):
	var instance = plant_node.instantiate()
	instance.global_position = pos
	instance.size = size
	add_child(instance)
	
func summon_meat(pos: Vector2, size: float):
	var instance = meat_node.instantiate()
	instance.global_position = pos
	instance.size = size
	add_child(instance)
