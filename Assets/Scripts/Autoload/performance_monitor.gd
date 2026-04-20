extends Node

# Downgrade thresholds (FPS falling)
const FPS_DROP_TO_MEDIUM   = 52
const FPS_DROP_TO_LOW      = 38
const FPS_DROP_TO_CRITICAL = 23

# Upgrade thresholds (FPS recovering) — higher than drop thresholds to prevent thrashing
const FPS_RISE_TO_HIGH     = 57
const FPS_RISE_TO_MEDIUM   = 43
const FPS_RISE_TO_LOW      = 28

const UPGRADE_HOLD_TIME = 5.0  # Seconds before allowing an upgrade

enum Level { HIGH, MEDIUM, LOW, CRITICAL }
var current_level: Level = Level.HIGH
var hold_timer: float = 0.0

# Smoothed FPS to avoid flickering on/off
var smoothed_fps: float = 60.0
const SMOOTH_FACTOR = 0.05  # Lower = slower to react, more stable

signal performance_level_changed(new_level)

func _process(delta):
	smoothed_fps = lerp(smoothed_fps, Performance.get_monitor(Performance.TIME_FPS), SMOOTH_FACTOR)

	if hold_timer > 0:
		hold_timer -= delta

	var new_level: Level = current_level

	match current_level:
		Level.HIGH:
			if smoothed_fps < FPS_DROP_TO_MEDIUM:
				new_level = Level.MEDIUM
		Level.MEDIUM:
			if hold_timer <= 0 and smoothed_fps >= FPS_RISE_TO_HIGH:
				new_level = Level.HIGH
			elif smoothed_fps < FPS_DROP_TO_LOW:
				new_level = Level.LOW
		Level.LOW:
			if hold_timer <= 0 and smoothed_fps >= FPS_RISE_TO_MEDIUM:
				new_level = Level.MEDIUM
			elif smoothed_fps < FPS_DROP_TO_CRITICAL:
				new_level = Level.CRITICAL
		Level.CRITICAL:
			if hold_timer <= 0 and smoothed_fps >= FPS_RISE_TO_LOW:
				new_level = Level.LOW

	if new_level != current_level:
		var upgrading = new_level < current_level
		current_level = new_level
		if upgrading:
			hold_timer = UPGRADE_HOLD_TIME
		print("[PerformanceMonitor] Level -> ", Level.keys()[current_level], " | FPS: ", snappedf(smoothed_fps, 0.1))
		emit_signal("performance_level_changed", current_level)
