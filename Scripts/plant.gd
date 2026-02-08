extends RigidBody2D
class_name Plant

var size: float
var health: float
var species_uuid: String = "plant"

func _ready() -> void:
	await get_tree().process_frame
	health = 5 * size
	$CollisionPolygon2D.scale = Vector2(size,size)
	$HitBox.scale = Vector2(size,size)
		
func take_damage(amount: float, _attacker_node: Node):
	health -= amount
	if health <= 0:
		queue_free()
