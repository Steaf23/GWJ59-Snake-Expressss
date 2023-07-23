extends Node

@export var pool_size: int = 5

@onready var music_player = $MusicPlayer
@onready var sfx_pool = $SFXPool

var player_counter = 0

@export var time_between_drums_min = 12
@export var time_between_drums_max = 25


func _enter_tree():
	AudioServer.set_bus_layout(load("res://SoundManager/bus_layout.tres"))
	randomize()


func update_bus(bus_name, value) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), true if value == 0 else false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value / 100))


func play_music(path: String) -> void:
	if music_player.playing:
		if path == music_player.stream.resource_path:
			return
		else:
			music_player.stop()
		
	if !ResourceLoader.exists(path):
		print("Cannot find " + path + "!")
		
	music_player.stream = load(path)
	music_player.play()	
	_on_drum_timer_timeout()
	


func stop_music() -> void:
	music_player.stop()
	$DrumTimer.stop()
	$Drums.stop()
	
	
func muffle_music(muffle: bool) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, muffle)

# Play new sounds, while removing the oldest currently playing if the pool is full.
# this results in the most satisfying outcome.
func play_sfx(path: String, volume_percent = 1.0) -> void:
	if !ResourceLoader.exists(path):
		print("Cannot find " + path + "!")
	
	if sfx_pool.get_children().size() >= pool_size:
		_stop_player(_get_oldest_player())
	
	var player = AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.set_meta("path", path)
	player.set_meta("id", player_counter)
	player.stream = load(path)
	player.finished.connect(_on_player_finished.bind(player))
	player_counter += 1
	sfx_pool.add_child(player)
	player.play()
	player.volume_db = linear_to_db(volume_percent)


func play_random_sfx(sounds: Array[StringName]) -> void:
	var idx = randi() % sounds.size()
	play_sfx(sounds[idx])
	

func stop_sfx(path: String) -> void:
	for player in sfx_pool.get_children():
		if player.get_meta("path") == path:
			player.stop()
			player.queue_free()
			return
			
			
func _stop_player(player: AudioStreamPlayer) -> void:
	player.stop()
	player.queue_free()


func _get_oldest_player() -> AudioStreamPlayer:
	if sfx_pool.get_child_count() == 0:
		return null
		
	var oldest_record = 0
	var oldest_player = sfx_pool.get_children()[0]
	for player in sfx_pool.get_children():
		if player.get_meta("id") < oldest_record:
			oldest_player = player
			oldest_record = player.get_meta("id")
	
	return oldest_player


func _on_player_finished(player: AudioStreamPlayer) -> void:
	player.queue_free()


func _on_drum_timer_timeout() -> void:
	$Drums.play()
	$DrumTimer.wait_time = (randf() * (time_between_drums_max - time_between_drums_min)) + time_between_drums_min + $Drums.stream.get_length()
	$DrumTimer.start()
