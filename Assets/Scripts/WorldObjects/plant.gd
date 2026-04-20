extends RigidBody2D
class_name Plant

var size: float
var health: float
var species_uuid: String = "plant"
var parent_species_uuid: String = "0"
var spawner: Node = null

var main

func _ready() -> void:
	await get_tree().process_frame
	WorldWrapper.register(self)
	PerformanceMonitor.performance_level_changed.connect(_on_perf_changed)
	main = get_tree().current_scene
	health = 5 * size
	$CollisionPolygon2D.scale = Vector2(size,size)
	$HitBox.scale = Vector2(size,size)
		
func take_damage(amount: float, _attacker_node: Node):
	health -= amount
	if health <= 0:
		main.current_plant -= 1
		if spawner:
			spawner.plant_died()
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
