extends Node
class_name Math

func random_point_in_circle(radius: float) -> Vector2:
	var theta := randf() * TAU
	var r := radius * sqrt(randf())
	return Vector2(cos(theta), sin(theta)) * r
