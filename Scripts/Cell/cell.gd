extends CharacterBody2D
class_name Cell

var rng = RandomNumberGenerator.new()
var gcs = GenerateCellStats.new()

#Identity Variables
var cell_uuid: String
var species_uuid: String
var birth_type: String
var parent: Node

#Growth Stats
var current_growth: float = 0.0
var growth_speed: float

#Birth Stats (Needed for Growth)

#Current Stats (with Growth Calculated)

#Static Stats
var color: Color

func _ready() -> void:
	cell_uuid = gcs.create_uuid() #Generate new cell uuid
	
#Cell is CREATED
	if !birth_type:
		species_uuid = gcs.create_uuid() #Generate new species uuid
		color = Color(rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),rng.randf_range(0.1,0.9),1.0)
	
#Cell is BORN
	elif birth_type == "born":
		if !parent:
			queue_free()
		species_uuid = parent.species_uuid
		color.r = gcs.create_rand_stat_from_stat(parent.color.r, 0.05)
		color.g = gcs.create_rand_stat_from_stat(parent.color.g, 0.05)
		color.b = gcs.create_rand_stat_from_stat(parent.color.b, 0.05)
		
#Apply stats
	$Sprite2D.modulate = Color(color)
	
