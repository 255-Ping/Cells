extends Node

# Thresholds
const FPS_HIGH    = 55  # All features on
const FPS_MEDIUM  = 30  # Start cutting
const FPS_LOW     = 20  # Cut aggressively

enum Level { HIGH, MEDIUM, LOW, CRITICAL }
var current_level: Level = Level.HIGH

# Smoothed FPS to avoid flickering on/off
var smoothed_fps: float = 60.0
const SMOOTH_FACTOR = 0.05  # Lower = slower to react, more stable

signal performance_level_changed(new_level)

func _process(_delta):
	smoothed_fps = lerp(smoothed_fps, Performance.get_monitor(Performance.TIME_FPS), SMOOTH_FACTOR)
	
	var new_level: Level
	if smoothed_fps >= FPS_HIGH:
		new_level = Level.HIGH
	elif smoothed_fps >= FPS_MEDIUM:
		new_level = Level.MEDIUM
	elif smoothed_fps >= FPS_LOW:
		new_level = Level.LOW
	else:
		new_level = Level.CRITICAL
	
	if new_level != current_level:
		current_level = new_level
		emit_signal("performance_level_changed", current_level)
