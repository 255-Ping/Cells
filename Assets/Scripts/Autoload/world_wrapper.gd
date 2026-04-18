extends Node

var world_radius := 300.0
var tracked_nodes: Array[Node2D] = []

func register(node: Node2D):
	tracked_nodes.append(node)

func unregister(node: Node2D):
	tracked_nodes.erase(node)

func _physics_process(_delta):
	for node in tracked_nodes:
		if not is_instance_valid(node):
			tracked_nodes.erase(node)
			continue
		var dist = node.global_position.length()
		if dist > world_radius:
			var overshoot = dist - world_radius
			node.global_position = node.global_position.normalized() * -(world_radius - overshoot)
