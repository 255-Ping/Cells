extends Camera2D

@export var zoom_speed := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 3.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(-1)

func zoom_camera(direction: int) -> void:
	var new_zoom = zoom.x + direction * zoom_speed
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
