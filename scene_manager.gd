extends Node

@onready var game_layer = $GameLayer

@onready var GAME_CONTAINER = preload("res://game_container.tscn")

var current_level = 0


func _ready() -> void:
	SceneSignalBus.new_scene_requested.connect(_on_new_scene_requested)
	SceneSignalBus.reload_level_requested.connect(_on_reload_level_requested)
	SceneSignalBus.next_level_requested.connect(_on_next_level_requested)
	SceneSignalBus.load_level_requested.connect(_on_load_level_requested)
	switch("res://main_menu.tscn")
	
	
func switch(scene_path: String, use_viewport: bool = false) -> void:
	for child in game_layer.get_children():
		child.queue_free()
		
	if !use_viewport:
		game_layer.add_child(load(scene_path).instantiate())
		return
	
	var vp = GAME_CONTAINER.instantiate()
	game_layer.add_child(vp)
	vp.get_node("SubViewport").add_child(load(scene_path).instantiate())


func _on_new_scene_requested(scene_path: String) -> void:
	switch(scene_path, true)
	
	
func _on_reload_level_requested() -> void:
	reload_current_level()


func _on_next_level_requested() -> void:
	next_level()


func _on_load_level_requested(level: int) -> void:
	load_level(level)

	
func next_level() -> void:
	current_level += 1
	load_level(current_level)
	
	
func reload_current_level() -> void:
	load_level(current_level)


func load_level(level: int) -> void:
	current_level = level
	if not "level_" + str(level + 1) + ".tscn" in DirAccess.get_files_at("res://Levels"):
		print("No Level " + str(level + 1) + " exists in res://Levels!")
		switch("res://main_menu.tscn", false)
		return
	switch("res://Levels/level_" + str(level + 1) + ".tscn", true)
		
		
	
