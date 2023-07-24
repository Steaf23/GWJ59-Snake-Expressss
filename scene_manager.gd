extends Node

@onready var game_layer = $GameLayer
@onready var pause_layer = $PauseLayer

@onready var GAME_CONTAINER = preload("res://game_container.tscn")

var current_level = 0


func _ready() -> void:
	SceneSignalBus.new_scene_requested.connect(_on_new_scene_requested)
	SceneSignalBus.reload_level_requested.connect(_on_reload_level_requested)
	SceneSignalBus.next_level_requested.connect(_on_next_level_requested)
	SceneSignalBus.load_level_requested.connect(_on_load_level_requested)
	switch("res://main_menu.tscn")
	
	
func switch(scene_path: String, use_viewport: bool = false) -> void:
	current_level = 0
	for child in game_layer.get_children():
		child.queue_free()
		
	game_layer.add_child(load(scene_path).instantiate())
	return


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
	if not "level_" + str(level + 1) + ".tscn" in DirAccess.get_files_at("res://Levels") \
	and not "level_" + str(level + 1) + ".tscn.remap" in DirAccess.get_files_at("res://Levels") :
		print("No Level " + str(level + 1) + " exists in res://Levels!")
		switch("res://end_screen.tscn", false)
		return
	var scene_path = "res://Levels/level_" + str(level + 1) + ".tscn"
	
	for child in game_layer.get_children():
		child.queue_free()
	
	var vp = GAME_CONTAINER.instantiate()
	game_layer.add_child(vp)
	vp.get_node("SubViewport").add_child(load(scene_path).instantiate())
		
		
func _on_main_menu_pressed() -> void:
	SoundManager.play_sfx(Sounds.MENU_CONFIRM)
	switch("res://main_menu.tscn")
	pause_layer.unpause()


func _on_pause_layer_paused(is_paused) -> void:
	if is_paused:
		$CanvasLayer/Label.text = "Unpause: ESC or P"
	else:
		$CanvasLayer/Label.text = "Pause: ESC or P"
