extends RigidBody2D
class_name Plant

var health: float
		
func take_damage(amount: float, _attacker_node: Node):
	health -= amount
	if health <= 0:
		queue_free()
