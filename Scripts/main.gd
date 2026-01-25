extends Node2D
class_name Main

#Cell node var
@onready var cell_node = preload("res://Scenes/cell.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_check_summon_cell_at_mouse()
	
func _check_summon_cell_at_mouse():
	if !Input.is_action_just_pressed("spawn_random_cell"):
		return
	summon_cell(get_global_mouse_position(), "miracle")
	
func summon_cell(pos: Vector2, birth_type: String, parent: Node = null):
	var instance = cell_node.instantiate()
	instance.global_position = pos
	instance.birth_type = birth_type
	if parent:
		instance.parent = parent
	add_child(instance)
