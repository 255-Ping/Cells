extends CharacterBody2D
class_name Cell

var rng = RandomNumberGenerator.new()
var gcs = GenerateCellStats.new()

#Node Variables
@onready var collision_node = $CollisionPolygon2D
@onready var vision_node = $VisionRange
@onready var hit_box_node = $HitBox

#Identity Variables
var cell_uuid: String
var species_uuid: String
var diet_type: String
var birth_type: String
var parent: Node

#Targeting Variables
var targets: Array
var attackable_targets: Array

#Movement Variables
var current_x_movement: float
var desired_x_movement: float
var current_y_movement: float
var desired_y_movement: float
var movement_change: float
var damaged: float
var attacker: Node

#Growth Stats
var current_growth: float = 0.0
var growth_speed: float
var growth_hunger: float

#Birth Stats (Needed for Growth)
var birth_scale: float
var birth_damage: float
var birth_max_health: float
var birth_movement_speed: float
var birth_max_hunger: float
var birth_hunger: float

#Current Stats (with Growth Calculated)
var current_scale: float
var current_damage: float
var current_damage_cooldown: float
var current_max_health: float
var current_health: float
var current_movement_speed: float
var current_max_hunger: float
var current_hunger: float
var hunger_drain: float

#Static Stats
var color: Color
var damage_cooldown: float

var main

@onready var stats_panel = $Panel

func _ready() -> void:
	main = get_parent()
	cell_uuid = gcs.create_uuid() #Generate new cell uuid
	
#Cell is CREATED
	if birth_type == "miracle":
		var diet_selector = rng.randi_range(1,3)
		if diet_selector == 1:
			diet_type = "carnivore"
		if diet_selector == 2:
			diet_type = "omnivore"
		if diet_selector == 3:
			diet_type = "herbivore"
		species_uuid = gcs.create_uuid() #Generate new species uuid
		color = Color(rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),1.0)
		growth_speed = rng.randf_range(0.000025,0.001)
		movement_change = rng.randf_range(0.00001,0.01)
		birth_damage = rng.randf_range(0.5,3)
		damage_cooldown = rng.randf_range(0.5,3)
		birth_max_health = rng.randf_range(1,4)
		birth_movement_speed = rng.randf_range(0.5,5)
		birth_scale = rng.randf_range(0.5,1.25)
		birth_max_hunger = rng.randf_range(5,15)
		hunger_drain = rng.randf_range(0.5,0.05)
		growth_hunger = rng.randf_range(1,3)
		birth_hunger = rng.randf_range(1.5, birth_max_hunger * 0.75)
	
#Cell is BORN
	elif birth_type == "born":
		if !parent:
			queue_free()
		diet_type = parent.diet_type
		species_uuid = parent.species_uuid
		growth_speed = gcs.create_rand_stat_from_stat(parent.growth_speed, 0.000005 * main.cell_mutation_rate)
		movement_change = gcs.create_rand_stat_from_stat(parent.movement_change, 0.00005 * main.cell_mutation_rate)
		birth_damage = gcs.create_rand_stat_from_stat(parent.birth_damage, 0.05 * main.cell_mutation_rate)
		damage_cooldown = gcs.create_rand_stat_from_stat(parent.damage_cooldown, 0.05 * main.cell_mutation_rate)
		birth_max_health = gcs.create_rand_stat_from_stat(parent.birth_max_health, 0.05 * main.cell_mutation_rate)
		birth_movement_speed = gcs.create_rand_stat_from_stat(parent.birth_movement_speed, 0.05 * main.cell_mutation_rate)
		birth_scale = gcs.create_rand_stat_from_stat(parent.birth_scale, 0.01 * main.cell_mutation_rate)
		birth_max_hunger = gcs.create_rand_stat_from_stat(parent.birth_max_hunger, 0.005 * main.cell_mutation_rate)
		hunger_drain = gcs.create_rand_stat_from_stat(parent.hunger_drain, 0.00005 * main.cell_mutation_rate)
		growth_hunger = gcs.create_rand_stat_from_stat(parent.growth_hunger, 0.0005 * main.cell_mutation_rate)
		birth_hunger = gcs.create_rand_stat_from_stat(parent.birth_hunger, 0.0005 * main.cell_mutation_rate)
		color.r = gcs.create_rand_stat_from_stat(parent.color.r, 0.005 * main.cell_mutation_rate)
		color.g = gcs.create_rand_stat_from_stat(parent.color.g, 0.005 * main.cell_mutation_rate)
		color.b = gcs.create_rand_stat_from_stat(parent.color.b, 0.005 * main.cell_mutation_rate)
		
#Apply stats
	$CollisionPolygon2D/Sprite2D.modulate = Color(color)
	current_damage = birth_damage
	current_damage_cooldown = damage_cooldown
	current_max_health = birth_max_health
	current_health = birth_max_health
	current_scale = birth_scale
	current_movement_speed = birth_movement_speed
	current_max_hunger = birth_max_hunger
	current_hunger = birth_hunger * 0.5
	_update_stats()
	
func _process(delta: float) -> void:
	_move(delta)
	_attack(delta)
	_grow(delta)
	_hunger_check(delta)
	_check_for_birth()
	_update_stats()
	_update_stats_panel()
	
	if current_health <= 0:
		if current_hunger <= 0:
			main.summon_meat(global_position, current_scale * 0.3)
		else:
			main.summon_meat(global_position, current_scale * 0.6)
		queue_free()
		
func _update_stats_panel():
	$Panel/Label.text = str("cell_uuid: ", cell_uuid, "\n",
	"species_uuid: ", species_uuid, "\n",
	"diet_type: ", diet_type, "\n",
	"birth_type: ", birth_type, "\n",
	"parent: ", parent, "\n",
	"\n",
	
	"current_health: ", current_health, "\n",
	"current_max_health: ", current_max_health, "\n",
	"birth_max_health: ", birth_max_health, "\n",
	"\n",
	
	"current_growth: ", current_growth, "\n",
	"growth_speed: ", growth_speed, "\n",
	"growth_hunger: ", growth_hunger, "\n",
	"\n",
	
	"current_hunger: ", current_hunger, "\n",
	"current_max_hunger: ", current_max_hunger, "\n",
	"birth_max_hunger: ", birth_max_hunger, "\n",
	"hunger_drain: ", hunger_drain, "\n",
	"\n",
	
	"birth_movement_speed: ", birth_movement_speed, "\n",
	"current_movement_speed: ", current_movement_speed, "\n",
	"current_x_movement: ", current_x_movement, "\n",
	"desired_x_movement: ", desired_x_movement, "\n",
	"current_y_movement: ", current_y_movement, "\n",
	"desired_y_movement: ", desired_y_movement, "\n",
	"velocity: ", velocity, "\n",
	"movement_change: ", movement_change, "\n",
	"\n",
	
	"damaged: ", damaged, "\n",
	"\n",
	
	"birth_scale: ", birth_scale, "\n",
	"current_scale: ", current_scale, "\n",
	"\n",
	
	"birth_damage: ", birth_damage, "\n",
	"current_damage: ", current_damage, "\n",
	"damage_cooldown: ", damage_cooldown, "\n",
	"current_damage_cooldown: ", current_damage_cooldown, "\n",
	"\n",
	
	"color: ", color, "\n")
		
func _check_for_birth():
	if current_hunger >= birth_hunger:
		main.summon_cell(global_position, "born", self)
		current_hunger -= birth_hunger
		
	
func _grow(delta: float):
	if current_growth >= 1:
		return
	if current_hunger > growth_hunger:
		current_growth += growth_speed * delta
		current_movement_speed = birth_movement_speed * (current_growth + 1)
		current_scale = birth_scale * (current_growth + 1)
		current_max_hunger = birth_max_hunger * (current_growth + 1)
		if current_hunger > 0:
			current_hunger -= hunger_drain * delta
		
func _hunger_check(delta: float):
	#print(current_hunger)
	#$Label.text = str(current_hunger)
	if current_hunger <= 0:
		current_health -= hunger_drain * delta
		return
	var velocity_average = (abs(velocity.x) + abs(velocity.y)) / 2
	#print(velocity_average)
	if velocity_average > 0:
		current_hunger -= (hunger_drain * delta) * (velocity_average * 0.1)
	
func _update_stats():
	scale = Vector2(current_scale,current_scale)
	
func _attack(delta: float):
	if current_damage_cooldown > 0:
		current_damage_cooldown -= delta
		return
	if attackable_targets.size() > 0:
		current_damage_cooldown = damage_cooldown
		for target in attackable_targets:
			target.take_damage(current_damage, self)
			if target.is_in_group("cell"):
				current_hunger -= hunger_drain * delta
			elif current_hunger < current_max_hunger and target.is_in_group("plant"):
				current_hunger += current_damage * 0.25
			elif current_hunger < current_max_hunger and target.is_in_group("meat"):
				current_hunger += current_damage * 0.75

	
func take_damage(amount: float, attacker_node: Node):
	print("damaged: ", amount)
	current_health -= amount
	damaged += amount
	attacker = attacker_node
	#if current_health <= 0:
	#	if attacker_node:
	#		get_parent().summon_cell(global_position,"born",attacker_node)
	#	#attacker_node.targets.erase
	#	queue_free()
	
func _move(delta: float):
	
	if damaged > 0 and attacker:
		var dir = attacker.global_position.direction_to(global_position)
		velocity = dir * (damaged * 3)
		damaged -= delta
		
	elif targets.size() < 1:
		if !current_x_movement:
			current_x_movement = randf_range(-5,5)
			desired_x_movement = current_x_movement
		if !current_y_movement:
			current_y_movement = randf_range(-5,5)
			desired_y_movement = current_y_movement
		
		if round(desired_x_movement) == round(current_x_movement):
			desired_x_movement = randf_range(-5,5)
		if round(desired_y_movement) == round(current_y_movement):
			desired_y_movement = randf_range(-5,5)
			
		if desired_x_movement > current_x_movement:
			current_x_movement += movement_change
		if desired_x_movement < current_x_movement:
			current_x_movement -= movement_change
		if desired_y_movement > current_y_movement:
			current_y_movement += movement_change
		if desired_y_movement < current_y_movement:
			current_y_movement -= movement_change
		velocity = Vector2(current_x_movement * current_movement_speed,current_y_movement * current_movement_speed)
	else:
		var closest_target = get_closest_node(self, targets)
		var dir = global_position.direction_to(closest_target.global_position)
		velocity = dir * (current_movement_speed * 2)
		
		
	move_and_slide()
			
	
func get_closest_node(origin: Node2D, nodes: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist := INF

	for n in nodes:
		if n == null or n == origin:
			continue

		var d := origin.global_position.distance_squared_to(n.global_position)
		if d < min_dist:
			min_dist = d
			closest = n

	return closest



func _on_vision_range_area_entered(area: Area2D) -> void:
	if diet_type == "carnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("cell") or !area.get_parent().is_in_group("meat"):
			return
		targets.append(area.get_parent())
	if diet_type == "omnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		targets.append(area.get_parent())
	if diet_type == "herbivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("plant"):
			return
		targets.append(area.get_parent())
	#print(area.get_parent())


func _on_vision_range_area_exited(area: Area2D) -> void:
	if diet_type == "carnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("cell") or !area.get_parent().is_in_group("meat"):
			return
		targets.erase(area.get_parent())
	if diet_type == "omnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		targets.erase(area.get_parent())
	if diet_type == "herbivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("plant"):
			return
		targets.erase(area.get_parent())
	#print(area.get_parent())


func _on_hit_box_area_entered(area: Area2D) -> void:
	if diet_type == "carnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("cell") or !area.get_parent().is_in_group("meat"):
			return
		attackable_targets.append(area.get_parent())
	if diet_type == "omnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		attackable_targets.append(area.get_parent())
	if diet_type == "herbivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("plant"):
			return
		attackable_targets.append(area.get_parent())
	#print(area.get_parent())


func _on_hit_box_area_exited(area: Area2D) -> void:
	if diet_type == "carnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("cell") or !area.get_parent().is_in_group("meat"):
			return
		attackable_targets.erase(area.get_parent())
	if diet_type == "omnivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		attackable_targets.erase(area.get_parent())
	if diet_type == "herbivore":
		if area.get_parent() == self:
			return
		if area.get_parent().species_uuid == species_uuid:
			return
		if !area.is_in_group("hitbox"):
			return
		if !area.get_parent().is_in_group("plant"):
			return
		attackable_targets.erase(area.get_parent())
	#print(area.get_parent())
