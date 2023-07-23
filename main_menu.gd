extends Control

@onready var BUTTON = preload("res://level_button.tscn")

func _ready() -> void:
	%Play.grab_focus()
	SoundManager.play_music("res://Assets/Audio/background ambience.wav")
	
	var lvl_counter = 0
	for file in DirAccess.get_files_at("res://Levels"):
		if not "level_" in file or not ".tscn" in file:
			return
		
		lvl_counter += 1
		var btn = BUTTON.instantiate()
		btn.text = str(lvl_counter)
		btn.pressed.connect(_on_lvl_button_pressed.bind(lvl_counter))
		%Levels.add_child(btn)


func _on_button_pressed() -> void:
	SceneSignalBus.reload_level()


func _on_lvl_button_pressed(level: int) -> void:
	SceneSignalBus.load_level(level - 1)
