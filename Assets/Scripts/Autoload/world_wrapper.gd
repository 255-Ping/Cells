extends Node

signal world_radius_changed(radius: float)

var world_radius := 300.0
var tracked_nodes: Array[Node2D] = []

func set_world_radius(value: float) -> void:
	world_radius = value
	emit_signal("world_radius_changed", value)

func register(node: Node2D):
	tracked_nodes.append(node)

func unregister(node: Node2D):
	tracked_nodes.erase(node)

func _physics_process(_delta):
	var to_remove: Array[Node2D] = []
	for node in tracked_nodes:
		if not is_instance_valid(node):
			to_remove.append(node)
			continue
		var dist = node.global_position.length()
		if dist > world_radius:
			node.global_position = -node.global_position.normalized() * (world_radius * 0.9)
	for node in to_remove:
		tracked_nodes.erase(node)
