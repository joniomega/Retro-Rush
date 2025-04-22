extends Node

var selected_level: int = 1
var unlocked_levels: Array = [1]  # Start with only level 1 unlocked

func _ready() -> void:
	load_progress()

func save_progress():
	var save_data = {"unlocked_levels": unlocked_levels}
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_var(save_data)

func load_progress():
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		var save_data = file.get_var()
		unlocked_levels = save_data["unlocked_levels"]

func unlock_next_level(current_level: int):
	if !unlocked_levels.has(current_level + 1):
		unlocked_levels.append(current_level + 1)
		save_progress()
