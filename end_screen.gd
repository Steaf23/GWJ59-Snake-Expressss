extends Control


func _ready() -> void:
	SoundManager.stop_music()
	SoundManager.play_sfx("res://Assets/Audio/Victory_Jingle.wav")

func _on_main_menu_pressed() -> void:
	SoundManager.play_sfx(Sounds.MENU_CONFIRM)
	SceneSignalBus.request_change_scene("res://main_menu.tscn")
