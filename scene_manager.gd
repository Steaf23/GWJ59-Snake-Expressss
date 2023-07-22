extends Node

@onready var game_layer = $GameLayer

@onready var GAME_CONTAINER = preload("res://game_container.tscn")


func _ready() -> void:
	SceneSignalBus.new_scene_requested.connect(_on_new_scene_requested)
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
