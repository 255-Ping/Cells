extends Control

const FONT     = preload("res://Assets/Fonts/VCR_OSD_MONO_1.001.ttf")
const CELL_TEX = preload("res://Assets/Textures/cell.png")
const NODE_W:    float = 150.0
const NODE_H:    float = 64.0
const ICON_S:    float = 44.0
const LEVEL_GAP: float = 130.0
const NODE_GAP:  float = 170.0
const BAR_H:     float = 44.0

var _pan_offset:   Vector2 = Vector2.ZERO
var _zoom:         float   = 1.0
var _is_panning:   bool    = false
var _positions:    Dictionary = {}
var _layout_dirty: bool = true
var _refresh_timer: float = 0.0
var _title_label:  Label

func _ready() -> void:
	LineageTracker.lineage_updated.connect(_on_lineage_updated)

	var bar = HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = BAR_H
	bar.add_theme_constant_override("separation", 4)
	add_child(bar)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", FONT)
	_title_label.add_theme_font_size_override("font_size", 14)
	bar.add_child(_title_label)

	var prune_btn = Button.new()
	prune_btn.text = "Prune"
	prune_btn.custom_minimum_size = Vector2(70, 0)
	prune_btn.pressed.connect(func():
		LineageTracker.prune_extinct()
		_layout_dirty = true
		queue_redraw()
	)
	bar.add_child(prune_btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(70, 0)
	close_btn.pressed.connect(func(): visible = false)
	bar.add_child(close_btn)

	visible = false

func _on_lineage_updated() -> void:
	_layout_dirty = true
	if visible:
		queue_redraw()

func open() -> void:
	visible = true
	_layout_dirty = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= 1.5:
		_refresh_timer = 0.0
		_update_title()
		queue_redraw()
	if _layout_dirty:
		_rebuild_layout()
		_layout_dirty = false
		_update_title()
		queue_redraw()

func _update_title() -> void:
	if _title_label:
		_title_label.text = "  LINEAGE TREE   —   " + str(LineageTracker.species.size()) + " species"

func _rebuild_layout() -> void:
	_positions.clear()
	var sp := LineageTracker.species
	if sp.is_empty():
		return

	var roots: Array = []
	for uuid in sp:
		if not sp.has(sp[uuid]["parent_uuid"]):
			roots.append(uuid)

	var depths: Dictionary = {}
	var bfs: Array = []
	for r in roots:
		bfs.append([r, 0])
	var head := 0
	while head < bfs.size():
		var uuid: String = bfs[head][0]
		var d: int       = bfs[head][1]
		head += 1
		if depths.has(uuid):
			continue
		depths[uuid] = d
		for child in sp[uuid]["children"]:
			if not depths.has(child):
				bfs.append([child, d + 1])

	var by_level: Dictionary = {}
	for uuid in depths:
		var d: int = depths[uuid]
		if not by_level.has(d):
			by_level[d] = []
		by_level[d].append(uuid)

	var sorted_depths: Array = by_level.keys()
	sorted_depths.sort()

	for depth in sorted_depths:
		var nodes: Array = by_level[depth]
		nodes.sort_custom(func(a: String, b: String) -> bool:
			var pa: String = sp[a]["parent_uuid"]
			var pb: String = sp[b]["parent_uuid"]
			var xa: float = _positions[pa].x if _positions.has(pa) else 0.0
			var xb: float = _positions[pb].x if _positions.has(pb) else 0.0
			return xa < xb
		)
		var count := nodes.size()
		for i in range(count):
			_positions[nodes[i]] = Vector2(
				(i - (count - 1) * 0.5) * NODE_GAP,
				depth * LEVEL_GAP
			)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.07, 0.96))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, BAR_H)), Color(0.08, 0.08, 0.12, 1.0))

	var sp     := LineageTracker.species
	var origin := Vector2(size.x * 0.5, size.y * 0.5 + BAR_H * 0.5) + _pan_offset
	var nw:     float = NODE_W * _zoom
	var nh:     float = NODE_H * _zoom
	var icon_s: float = ICON_S * _zoom

	for uuid in _positions:
		if not sp.has(uuid):
			continue
		var puuid: String = sp[uuid]["parent_uuid"]
		if _positions.has(puuid) and sp.has(puuid):
			draw_line(
				_positions[puuid] * _zoom + origin + Vector2(0, nh),
				_positions[uuid]  * _zoom + origin,
				Color(0.35, 0.35, 0.45, 0.8), 1.5, true
			)

	for uuid in _positions:
		if not sp.has(uuid):
			continue
		var pos: Vector2 = _positions[uuid] * _zoom + origin - Vector2(nw * 0.5, 0.0)
		var col: Color   = sp[uuid]["color"]
		var pop: int     = sp[uuid]["population"]

		var dim := pop == 0
		draw_rect(Rect2(pos, Vector2(nw, nh)), Color(0.10, 0.10, 0.14))
		draw_rect(Rect2(pos, Vector2(nw, nh)),
			col if not dim else col.darkened(0.55), false, 2.5 if not dim else 1.0)

		var icon_rect := Rect2(pos + Vector2(4.0 * _zoom, (nh - icon_s) * 0.5), Vector2(icon_s, icon_s))
		draw_texture_rect(CELL_TEX, icon_rect, false, col if not dim else col.darkened(0.4))

		if _zoom >= 0.4:
			var fs  := maxi(6, roundi(10.0 * _zoom))
			var fs2 := maxi(5, roundi(9.0  * _zoom))
			var lh:     float   = 16.0 * _zoom
			var text_w: float   = nw - (ICON_S + 10.0) * _zoom
			var tx:     Vector2 = pos + Vector2((ICON_S + 8.0) * _zoom, lh)
			var tc  := Color.WHITE if not dim else Color(0.5, 0.5, 0.5)
			var sname: String = sp[uuid].get("name", uuid.substr(0, 6))
			draw_string(FONT, tx, sname, HORIZONTAL_ALIGNMENT_LEFT, text_w, fs, tc)
			var diet: String = sp[uuid].get("diet", "")
			var dc := Color(0.4, 0.8, 1.0) if diet == "herbivore" else \
					  Color(1.0, 0.5, 0.3) if diet == "carnivore" else \
					  Color(0.8, 0.7, 0.3)
			if dim: dc = dc.darkened(0.4)
			draw_string(FONT, tx + Vector2(0, lh),       diet,               HORIZONTAL_ALIGNMENT_LEFT, text_w, fs2, dc)
			var pc := Color(0.3, 1.0, 0.4) if not dim else Color(0.7, 0.3, 0.3)
			draw_string(FONT, tx + Vector2(0, lh * 2.0), "pop: " + str(pop), HORIZONTAL_ALIGNMENT_LEFT, text_w, fs2, pc)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_is_panning = event.pressed
				accept_event()
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(event.position, 1.12)
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(event.position, 1.0 / 1.12)
				accept_event()
	elif event is InputEventMouseMotion and _is_panning:
		_pan_offset += event.relative
		queue_redraw()
		accept_event()

func _zoom_at(mouse_pos: Vector2, factor: float) -> void:
	var old_zoom := _zoom
	_zoom = clampf(_zoom * factor, 0.1, 5.0)
	var base   := Vector2(size.x * 0.5, size.y * 0.5 + BAR_H * 0.5)
	var origin := base + _pan_offset
	_pan_offset = mouse_pos - base - (mouse_pos - origin) * (_zoom / old_zoom)
	queue_redraw()
