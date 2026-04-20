extends Node

const SAVE_DIR = "user://saves/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save(file_name: String, data: Dictionary) -> void:
	var path = SAVE_DIR + file_name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_file(file_name: String) -> Dictionary:
	var path = SAVE_DIR + file_name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	return result if result is Dictionary else {}
