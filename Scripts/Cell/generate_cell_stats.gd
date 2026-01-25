extends Node
class_name GenerateCellStats

var rng = RandomNumberGenerator.new()

func create_uuid() -> String:
	return str(Time.get_unix_time_from_system(), "_", randi())

func create_rand_stat_from_stat(initial_stat: float, stat_range: float = 0.01) -> float:
	return rng.randf_range(initial_stat - (stat_range * -1),initial_stat + stat_range)
