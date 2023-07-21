class_name Train
extends Node2D

signal move_timer_timeout()
signal item_picked_up()

@onready var TRAIN_WAGON = preload("res://train_wagon.tscn")
@onready var wagons = $Wagons
@onready var head: TrainWagon = %Head
@onready var tail: TrainWagon = %Tail
@onready var head_player: AnimationPlayer = $Wagons/Head/AnimationPlayer

var current_direction : Vector2i = Vector2i.DOWN
var insert_new_wagon: bool = false
var current_cell: Vector2i
var freeze_tail = false

var queued_input = Vector2()

var sound_time_max = 10
var sound_time_min = 7

var is_biting: bool = false


func _ready():
	$MovementTimer.start(head.tween_speed)
	current_cell = (head.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	
	head.current_cell = current_cell
	tail.current_cell = (tail.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		add_wagon()


func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		queued_input = input_vector


func _on_movement_timer_timeout() -> void:
	move_timer_timeout.emit()


func move(precondition: Callable):
	var input = queued_input
	match (current_direction):
		Vector2i.LEFT, Vector2i.RIGHT:
			if not is_equal_approx(input.y, 0.0):
				current_direction = Vector2(0, sign(input.y))
		Vector2i.DOWN, Vector2i.UP:
			if not is_equal_approx(input.x, 0.0):
				current_direction = Vector2(sign(input.x), 0)
	
	var target_cell = current_cell + current_direction
	queued_input = Vector2.ZERO
	
	if not precondition.call(self, target_cell):
		SoundManager.play_random_sfx([Sounds.CRASH_1, Sounds.CRASH_2, Sounds.CRASH_3])
		SceneSignalBus.request_change_scene("res://world.tscn")
		return
		
	for wagon in wagons.get_children():
		if wagon is TrainWagon and wagon.current_cell == target_cell:
			SoundManager.play_random_sfx([Sounds.CRASH_1, Sounds.CRASH_2, Sounds.CRASH_3])
			SceneSignalBus.request_change_scene("res://world.tscn")
			return
		
	current_cell = target_cell
	update_wagons()


func add_wagon() -> void:
	if insert_new_wagon:
		# TODO: create wagon queue
		print("Cannot insert 2 new wagons at once!")
		return
		
	var wagon = TRAIN_WAGON.instantiate()
	wagons.add_child(wagon)
	wagons.move_child(wagon, 1)
	var new_wagon_cell = head.current_cell
	wagon.global_position = new_wagon_cell * Global.TILE_SIZE
	wagon.current_cell = new_wagon_cell
	wagon.rotation = rotation
	wagon.target_angle = wagon.rotation
	insert_new_wagon = true
	
	var scale_tween = create_tween()
	var t1 = scale_tween.tween_property(wagon, ^"scale", Vector2(1.0, 1.0), wagon.tween_speed)
	t1.from(Vector2(0, 0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var opacity_tween = create_tween()
	var t3 = opacity_tween.tween_property(wagon, ^"modulate", Color.WHITE, wagon.tween_speed)
	t3.from(Color(1, 1, 1, 0)).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	
	freeze_tail = true
	await get_tree().create_timer(wagon.tween_speed).timeout
	freeze_tail = false
	
	
func update_wagons() -> void:
	
	var target_cell = current_cell
	for wagon in wagons.get_children():
		var current_wagon_cell = wagon.current_cell
		wagon.move(target_cell, wagon == head or not insert_new_wagon)
		target_cell = current_wagon_cell
		
	insert_new_wagon = false


func can_add_passenger() -> bool:
	for wagon in wagons.get_children():
		if wagon is TrainWagon:
			if not wagon.has_passenger && wagon.can_have_passenger:
				return true
				
	return false
	
	
func add_passenger(wagon: TrainWagon) -> void:
	if not can_add_passenger():
		return
	
	if not wagon.has_passenger && wagon.can_have_passenger:
		wagon.has_passenger = true
		SoundManager.play_random_sfx([Sounds.PICKUP_1, Sounds.PICKUP_2, Sounds.PICKUP_3])
		return


func pickup_item(item: Item) -> void:
	item.queue_free()
	add_wagon()
	end_bite()
	item_picked_up.emit()


func get_passenger_count() -> int:
	# Head and Tail can not have passengers
	return wagons.get_child_count() - get_available_wagons().size() - 2


func get_available_wagons() -> Array[TrainWagon]:
	var available_wagons: Array[TrainWagon] = []
	for wagon in wagons.get_children():
		if wagon is TrainWagon:
			if not wagon.has_passenger and wagon.can_have_passenger:
				available_wagons.append(wagon)
	return available_wagons


func _on_sound_timer_timeout() -> void:
	SoundManager.play_random_sfx(Sounds.HISSES)
	$SoundTimer.start(sound_time_min + randi() % (sound_time_max - sound_time_min))


func start_bite() -> void:
	is_biting = true
	head_player.play("bite_start")
	
	
func cancel_bite() -> void:
	is_biting = false
	head_player.play_backwards("bite_start")
	
	
func end_bite() -> void:
	is_biting = true
	head_player.play("bite_end")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"bite_end":
			is_biting = false
