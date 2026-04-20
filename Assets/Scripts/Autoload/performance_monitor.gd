extends Node

# Downgrade thresholds (FPS falling) — scaled from target FPS
var FPS_DROP_TO_MEDIUM   = 52
var FPS_DROP_TO_LOW      = 38
var FPS_DROP_TO_CRITICAL = 23

# Upgrade thresholds (FPS recovering) — higher than drop thresholds to prevent thrashing
var FPS_RISE_TO_HIGH     = 57
var FPS_RISE_TO_MEDIUM   = 43
var FPS_RISE_TO_LOW      = 28

const UPGRADE_HOLD_TIME = 5.0  # Seconds before allowing an upgrade
const WARMUP_TIME = 3.0        # Seconds to ignore FPS after launch

enum Level { HIGH, MEDIUM, LOW, CRITICAL }
var current_level: Level = Level.HIGH
var hold_timer: float = 0.0
var warmup_timer: float = WARMUP_TIME

# Smoothed FPS to avoid flickering on/off
var smoothed_fps: float = 60.0
const SMOOTH_FACTOR = 0.05  # Lower = slower to react, more stable

signal performance_level_changed(new_level)

func set_target_fps(fps: float) -> void:
	FPS_DROP_TO_MEDIUM   = fps * 0.867
	FPS_DROP_TO_LOW      = fps * 0.633
	FPS_DROP_TO_CRITICAL = fps * 0.383
	FPS_RISE_TO_HIGH     = fps * 0.950
	FPS_RISE_TO_MEDIUM   = fps * 0.717
	FPS_RISE_TO_LOW      = fps * 0.467

func _process(delta):
	if warmup_timer > 0:
		warmup_timer -= delta
		smoothed_fps = 60.0
		return

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
