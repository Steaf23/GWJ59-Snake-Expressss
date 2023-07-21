extends Node

signal new_scene_requested(scene_path: String)


func request_change_scene(scene_path: String) -> void:
	new_scene_requested.emit(scene_path)
