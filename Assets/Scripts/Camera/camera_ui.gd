extends Control

func _ready() -> void:
	pivot_offset = size / 2

func _process(delta):
	var cam = get_viewport().get_camera_2d()
	var target_scale = Vector2.ONE / cam.zoom
	scale = scale.lerp(target_scale, 10 * delta)
