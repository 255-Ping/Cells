extends RigidBody2D
class_name Meat

var size: float
var health: float
var species_uuid: String = "meat"
var parent_species_uuid: String = "0"

var main

func _ready() -> void:
	await get_tree().process_frame
	WorldWrapper.register(self)
	main = get_tree().current_scene
	health = 5 * size
	$CollisionPolygon2D.scale = Vector2(size,size)
	$HitBox.scale = Vector2(size,size)
		
func take_damage(amount: float, _attacker_node: Node):
	health -= amount
	if health <= 0:
		main.current_meat -= 1
		queue_free()

func _exit_tree():
	WorldWrapper.unregister(self)
