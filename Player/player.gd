class_name Train
extends Node2D

signal move_timer_timeout()
signal item_picked_up()
signal frogged()

@export var base_movement_time: float = 0.22

@export var grow_amount: int = 1
@export var boost_multiplier: float = 0.5
@export var boost_size: int = 20
@export var big_grow_amount: int = 3
@export var shrink_amoumt: int = 1
var has_portal = false
var boost_left: int = 0
var old_boost_left: int = 0

@onready var TRAIN_WAGON_SCN = preload("res://player/train_wagon.tscn")
@onready var wagons = $Wagons
@onready var head: TrainWagon = %Head
@onready var tail: TrainWagon = %Tail
@onready var head_player: AnimationPlayer = $Wagons/Head/AnimationPlayer
@onready var boost_bar: TextureProgressBar = $HUDLayer/MarginContainer/BoostBar
@onready var input_manager: InputManager = $InputManager

var wagon_queue: int = 0
var insert_new_wagon: bool = false
var current_cell: Vector2i
var freeze_tail = false

var sound_time_max = 10
var sound_time_min = 7

var start_level = false
var first_move = true

var can_turn: bool = false

func _ready():
	boost_bar.max_value = boost_size
	current_cell = (head.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	
	head.current_cell = current_cell
	tail.current_cell = (tail.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	
	await get_tree().create_timer(0.5).timeout
	start_level = true
	can_turn = true


func _physics_process(delta: float) -> void:
	if not start_level:
		return
		
	boost_bar.visible = old_boost_left > 0
	boost_bar.value = old_boost_left
	
	if has_portal:
		head.modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		if head.modulate.a < 1.0:
			await get_tree().create_timer(base_movement_time).timeout
			head.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_movement_timer_timeout() -> void:
	move_timer_timeout.emit()


func move_force(precondition: Callable):	
	if can_turn:
		move_early()

	if not precondition.call(self, current_cell):
		SoundManager.play_random_sfx([Sounds.CRASH_1, Sounds.CRASH_2, Sounds.CRASH_3])
		SceneSignalBus.reload_level()
		return
		
	# current cell is already updated
	for wagon in wagons.get_children():
		if wagon is TrainWagon and wagon.current_cell == current_cell and wagon.current_cell != head.current_cell:
			if has_portal:
				has_portal = false
				SoundManager.play_sfx(Sounds.GHOST)
				SoundManager.play_sfx(Sounds.BOOST)
				continue
				
			SoundManager.play_random_sfx([Sounds.CRASH_1, Sounds.CRASH_2, Sounds.CRASH_3])
			SceneSignalBus.reload_level()
			return
		
	if boost_left > 0:
		old_boost_left = boost_left
		boost_left -= 1
	elif boost_left == 0 and old_boost_left > 0:
		old_boost_left = 0
		end_boost()
	
	queue_redraw()
	$MinMoveTime.start($MovementTimer.wait_time * 0.75)
	
	

func move_early() -> void:
	if not can_turn:
		return
		
	input_manager.update_current_direction()
	var direction = input_manager.current_direction
	current_cell += direction
	
	update_wagons($MovementTimer.wait_time)
	
	can_turn = false


func _draw() -> void:
	var current_direction =  input_manager.current_direction
	var queued_input = input_manager.queued_input
	var tile_size = Vector2i(Global.TILE_SIZE, Global.TILE_SIZE)
	var ahead = current_direction
	var left = Vector2(current_direction).rotated(-PI/2)
	var right = Vector2(current_direction).rotated(PI/2)

	var new_dir: Vector2
	match (current_direction):
		Vector2i.LEFT, Vector2i.RIGHT:
			if not is_equal_approx(queued_input.y, 0.0):
				new_dir = Vector2(0, sign(queued_input.y))
		Vector2i.DOWN, Vector2i.UP:
			if not is_equal_approx(queued_input.x, 0.0):
				new_dir = Vector2(sign(queued_input.x), 0)
				
#	print(left, " ", new_dir)
	
#	var color = Color(1.0, 1.0, 1.0, 0.3)
#	if is_equal_approx(left.x, new_dir.x) and is_equal_approx(left.y, new_dir.y):
#		color = Color(0.0, 1.0, 0.0, 0.3)
#	else:
#		color = Color(1.0, 1.0, 1.0, 0.3)
#	draw_rect(Rect2i(((Vector2(current_cell) + left) * Global.TILE_SIZE) - global_position, tile_size), color)
#
#	if is_equal_approx(ahead.x, new_dir.x) and is_equal_approx(ahead.y, new_dir.y):
#		color = Color(0.0, 1.0, 0.0, 0.3)
#	else:
#		color = Color(1.0, 1.0, 1.0, 0.3)
#	draw_rect(Rect2i(((current_cell + ahead) * Global.TILE_SIZE) - Vector2i(global_position), tile_size), color)
#
#	if is_equal_approx(right.x, new_dir.x) and is_equal_approx(right.y, new_dir.y):
#		color = Color(0.0, 1.0, 0.0, 0.3)
#	else:
#		color = Color(1.0, 1.0, 1.0, 0.3)
#	draw_rect(Rect2i(((Vector2(current_cell) + right) * Global.TILE_SIZE) - global_position, tile_size), color)

func add_wagon() -> void:
	wagon_queue += 1
	
	
func update_wagons(tween_speed: float) -> void:	
	# add wagon if queue is bigger than 0
	var wagon_created = false
	if wagon_queue > 0:
		wagon_created = true
		wagon_queue -= 1
		create_wagon()
		
	var target_cell = current_cell
	for wagon in wagons.get_children():
		var current_wagon_cell = wagon.current_cell
		wagon.tween_speed = tween_speed
		wagon.move(target_cell, wagon == head or not wagon_created)
		target_cell = current_wagon_cell


func create_wagon() -> void:
	var wagon = TRAIN_WAGON_SCN.instantiate()
	wagons.add_child(wagon)
	wagons.move_child(wagon, 1)
	var new_wagon_cell = head.current_cell
	wagon.global_position = new_wagon_cell * Global.TILE_SIZE
	wagon.current_cell = new_wagon_cell
	wagon.rotation = rotation
	wagon.target_angle = wagon.rotation
	
	var scale_tween = create_tween()
	var t1 = scale_tween.tween_property(wagon, ^"scale", Vector2(1.0, 1.0), wagon.tween_speed)
	t1.from(Vector2(0, 0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var opacity_tween = create_tween()
	var t3 = opacity_tween.tween_property(wagon, ^"modulate", Color.WHITE, wagon.tween_speed)
	t3.from(Color(1, 1, 1, 0)).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	
	
	freeze_tail = true
	await get_tree().create_timer(wagon.tween_speed).timeout
	freeze_tail = false


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


func remove_passenger(wagon: TrainWagon) -> void:
	if wagon.has_passenger:
		SoundManager.play_random_sfx([Sounds.DELIVERY_1, Sounds.DELIVERY_2, Sounds.DELIVERY_3])
		
	wagon.has_passenger = false


func pickup_item(item: Item) -> void:
	var powerup = true
	match item.type:
		Item.ITEM_TYPE.Grow:
			powerup = false
			for i in grow_amount:
				add_wagon()
		Item.ITEM_TYPE.BigGrow:
			for i in big_grow_amount:
				add_wagon()
		Item.ITEM_TYPE.Shrink:
			for i in shrink_amoumt:
				remove_wagon()
		Item.ITEM_TYPE.Portal:
			has_portal = true
			add_wagon()
		Item.ITEM_TYPE.Boost:
			add_wagon()
			boost_left = boost_size
			start_boost()
		Item.ITEM_TYPE.Frog:
			frogged.emit()
			
	if powerup:
		SoundManager.play_random_sfx([Sounds.POWERUP_1, Sounds.POWERUP_2])
	else:
		SoundManager.play_random_sfx([Sounds.FRUIT_1, Sounds.FRUIT_2, Sounds.FRUIT_3])
	
	end_bite()
	item_picked_up.emit()
	
	var head_tween2 = create_tween()
	head_tween2.tween_property(head.get_node("Sprite"), "scale", Vector2(1.2, 1.2), base_movement_time / 2.0)
	head_tween2.tween_property(head.get_node("Sprite"), "scale", Vector2(1.0, 1.0), base_movement_time / 2.0)
	
	
	await get_tree().create_timer(base_movement_time / 2.0).timeout
	item.queue_free()


func get_passenger_count() -> int:
	var count = 0
	for wagon in wagons.get_children():
		if wagon.has_passenger:
			count += 1
	return count


func get_available_wagons() -> Array[TrainWagon]:
	var available_wagons: Array[TrainWagon] = []
	for wagon in wagons.get_children():
		if wagon is TrainWagon:
			if not wagon.has_passenger and wagon.can_have_passenger:
				available_wagons.append(wagon)
	return available_wagons


func remove_wagon() -> void:
	if wagons.get_child_count() == 2:
		return
	
	var back_wagon = null
	var idx = wagons.get_child_count() - 3
	for i in range(0, wagons.get_child_count()):
		back_wagon = wagons.get_child(wagons.get_child_count() - i - 1)
		if not back_wagon.has_passenger and back_wagon.can_have_passenger:
			break
		
	if back_wagon.can_have_passenger:
		back_wagon.queue_free()


func _on_sound_timer_timeout() -> void:
	SoundManager.play_random_sfx(Sounds.HISSES)
	$SoundTimer.start(sound_time_min + randi() % (sound_time_max - sound_time_min))


func start_boost() -> void:
	SoundManager.play_sfx(Sounds.BOOST)
	boost_left = boost_size
	old_boost_left = boost_size
	$MovementTimer.stop()
	$MovementTimer.wait_time = boost_multiplier * base_movement_time
	$MovementTimer.start()
	
	
func end_boost() -> void:
	$MovementTimer.stop()
	$MovementTimer.wait_time = base_movement_time
	$MovementTimer.start()
	
	
var ending_bite := false
var is_biting: = false

func start_bite() -> void:
	if ending_bite:
		return
	if not is_biting:
		head_player.play("bite_start")
	is_biting = true
	
func cancel_bite() -> void:
	if ending_bite:
		return
		
	is_biting = false
	head_player.play_backwards("bite_start")
	
func end_bite() -> void:
	is_biting = false
	ending_bite = true
	head_player.stop()
	head_player.play("bite_end")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"bite_end":
			ending_bite = false


func _on_input_manager_input_direction_changed() -> void:
	if first_move:
		first_move = false
		$MovementTimer.start(base_movement_time)
		move_timer_timeout.emit()
	queue_redraw()
	
	move_early()
	

func _on_input_manager_output_direction_changed() -> void:
	SoundManager.play_random_sfx([Sounds.TURN_1, Sounds.TURN_2, Sounds.TURN_3])


func _on_min_move_time_timeout() -> void:
	can_turn = true
