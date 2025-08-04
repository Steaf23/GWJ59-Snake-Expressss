extends Node

signal new_scene_requested(scene_path: String)
signal reload_level_requested()
signal next_level_requested()
signal load_level_requested(level: int)


func request_change_scene(scene_path: String) -> void:
	new_scene_requested.emit(scene_path)


func next_level() -> void:
	next_level_requested.emit()
	
	
func reload_level() -> void:
	reload_level_requested.emit()

func load_level(level: int) -> void:
	load_level_requested.emit(level)
