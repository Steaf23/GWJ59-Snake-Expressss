extends Control


func _ready() -> void:
	$Button.grab_focus()
	SoundManager.play_music("res://Assets/Audio/background ambience.wav")
	
	var lvl_counter = 0
	for file in DirAccess.get_files_at("res://Levels"):
		if not "level_" in file or not ".tscn" in file:
			return
		
		lvl_counter += 1
		$ItemList.add_item(str(lvl_counter))


func _on_button_pressed() -> void:
	SceneSignalBus.reload_level()


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	SceneSignalBus.load_level(index)
