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
	var instance = cell_node.instantiate()
	instance.global_position = get_global_mouse_position()
	add_child(instance)
