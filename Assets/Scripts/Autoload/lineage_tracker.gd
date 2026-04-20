extends Node

signal lineage_updated

var species: Dictionary = {}
# species[uuid] = { parent_uuid, color, population, children }

func _ready() -> void:
	_load_lineage()

func register_birth(uuid: String, parent_uuid: String, col: Color, diet: String = "", sname: String = "") -> void:
	if not species.has(uuid):
		species[uuid] = {
			"parent_uuid": parent_uuid,
			"color": col,
			"diet": diet,
			"name": sname,
			"population": 0,
			"children": []
		}
		if species.has(parent_uuid) and not species[parent_uuid]["children"].has(uuid):
			species[parent_uuid]["children"].append(uuid)
		_save_lineage()
		lineage_updated.emit()
	species[uuid]["population"] += 1

func on_cell_died(uuid: String) -> void:
	if species.has(uuid):
		species[uuid]["population"] = maxi(0, species[uuid]["population"] - 1)

func prune_extinct() -> void:
	var removed = true
	while removed:
		removed = false
		for uuid in species.keys():
			if species[uuid]["population"] > 0:
				continue
			if _has_living_descendants(uuid):
				continue
			var puuid: String = species[uuid]["parent_uuid"]
			if species.has(puuid):
				species[puuid]["children"].erase(uuid)
			species.erase(uuid)
			removed = true
			break
	_save_lineage()
	lineage_updated.emit()

func _has_living_descendants(uuid: String) -> bool:
	for child in species[uuid]["children"]:
		if not species.has(child):
			continue
		if species[child]["population"] > 0:
			return true
		if _has_living_descendants(child):
			return true
	return false

func _save_lineage() -> void:
	var data: Dictionary = {}
	for uuid in species:
		var s = species[uuid]
		data[uuid] = {
			"parent_uuid": s["parent_uuid"],
			"color": [s["color"].r, s["color"].g, s["color"].b],
			"diet": s.get("diet", ""),
			"name": s.get("name", ""),
			"children": s["children"]
		}
	SaveManager.save("lineage", data)

func _load_lineage() -> void:
	var data = SaveManager.load_file("lineage")
	if data.is_empty():
		return
	for uuid in data:
		var s = data[uuid]
		var c = s["color"]
		species[uuid] = {
			"parent_uuid": s["parent_uuid"],
			"color": Color(c[0], c[1], c[2]),
			"diet": s.get("diet", ""),
			"name": s.get("name", ""),
			"population": 0,
			"children": s["children"]
		}
	lineage_updated.emit()
