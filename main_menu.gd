extends Control


func _ready() -> void:
	SoundManager.play_music("res://Assets/Audio/background ambience.wav")


func _on_button_pressed() -> void:
	SceneSignalBus.request_change_scene("res://level_4.tscn")
