extends Node2D
class_name PlantSpawner

var radius: float = 300.0
var plant_density: int = 100
var plant_nutrition: float = 0.5

var current_plants: int = 0
var spawn_timer: float = 0.0

var spawn_interval: float = 2.5
const SPAWN_BATCH: int = 5
const DRAW_SEGMENTS: int = 64

var rng = RandomNumberGenerator.new()
var main
var _spawn_enabled: bool = true
var _perf_interval_scale: float = 1.0

func _ready():
	main = get_tree().current_scene
	PerformanceMonitor.performance_level_changed.connect(_on_perf_changed)

func _process(delta: float):
	if not _spawn_enabled:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval * _perf_interval_scale
		_spawn_batch()

func _on_perf_changed(level) -> void:
	match level:
		PerformanceMonitor.Level.HIGH:
			_spawn_enabled = true
			_perf_interval_scale = 1.0
		PerformanceMonitor.Level.MEDIUM:
			_spawn_enabled = true
			_perf_interval_scale = 2.0
		PerformanceMonitor.Level.LOW:
			_spawn_enabled = true
			_perf_interval_scale = 5.0
		PerformanceMonitor.Level.CRITICAL:
			_spawn_enabled = false

func _spawn_batch():
	for i in SPAWN_BATCH:
		if current_plants >= plant_density:
			return
		var angle = rng.randf() * TAU
		var dist = sqrt(rng.randf()) * radius
		var pos = global_position + Vector2(cos(angle), sin(angle)) * dist
		if main.summon_plant(pos, plant_nutrition, self):
			current_plants += 1

func plant_died():
	current_plants -= 1

func set_radius(value: float):
	radius = value
	queue_redraw()

func _draw():
	var inner = Color(0.3, 0.85, 0.3, 0.25)
	var outer = Color(0.3, 0.85, 0.3, 0.0)
	for i in DRAW_SEGMENTS:
		var a1 = TAU * i / DRAW_SEGMENTS
		var a2 = TAU * (i + 1) / DRAW_SEGMENTS
		draw_polygon(
			PackedVector2Array([
				Vector2.ZERO,
				Vector2(cos(a1), sin(a1)) * radius,
				Vector2(cos(a2), sin(a2)) * radius
			]),
			PackedColorArray([inner, outer, outer])
		)
