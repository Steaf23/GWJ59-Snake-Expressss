@icon("res://Assets/Art/SnakeTrain_Head1.png")
class_name PlayerSnake
extends Node2D

signal move_timer_timeout()
signal item_picked_up()
signal frogged()

@export var base_movement_time: float = 0.5

@export var grow_amount: int = 1
@export var boost_multiplier: float = 0.5
@export var boost_size: int = 20
@export var big_grow_amount: int = 3
@export var shrink_amoumt: int = 1
var has_portal = false
var boost_left: int = 0
var old_boost_left: int = 0

@onready var wagons: Wagons = $Wagons
@onready var head: Wagon = wagons.head
@onready var tail: Wagon = wagons.tail
@onready var head_player: AnimationPlayer = $Wagons/Head/AnimationPlayer
@onready var boost_bar: TextureProgressBar = $HUDLayer/MarginContainer/BoostBar
@onready var movement_timer: Timer = $MovementTimer
@onready var level: Level

var current_direction : Vector2i = Vector2i.DOWN
var insert_new_wagon: bool = false
var current_cell: Vector2i

var queued_input = Vector2()

var sound_time_max = 10
var sound_time_min = 7

var start_level = false
var first_move = true

func _ready():
	boost_bar.max_value = boost_size
	current_cell = (head.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	
	head.current_cell = current_cell
	tail.current_cell = (tail.global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	
	await get_tree().create_timer(0.5).timeout
	start_level = true
	
	wagons.wagon_spawn_time = movement_timer.wait_time + 0.2
	for w in wagons.get_children():
		w.snake = self
		

func _physics_process(delta: float) -> void:
	if not start_level:
		return

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		if first_move:
			first_move = false
			movement_timer.start(base_movement_time)
			#move_timer_timeout.emit()
		queued_input = input_vector
		
	boost_bar.visible = old_boost_left > 0
	boost_bar.value = old_boost_left
	
	if has_portal:
		head.modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		if head.modulate.a < 1.0:
			await get_tree().create_timer(base_movement_time).timeout
			head.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _process(delta: float) -> void:
	queue_redraw()
	

func _on_movement_timer_timeout() -> void:
	move_timer_timeout.emit()


func take_turn(move_precondition: Callable) -> void:
	if not level:
		return
		
	move(move_precondition)
	
	# pickup item
	var item = level.item_at_cell(current_cell)
	if item:
		pickup_item(item)
	
	# pickup passengers after item to account for possible change in amount of wagons.
	try_pickup()
	try_deliver()
	
	
func try_pickup() -> void:
	for wagon: Wagon in wagons.get_available_wagons():
		for station: PickupStation in level.get_pickup_stations():
			if wagon.current_cell in station.get_pickup_cells():
				station.pickup_passenger(wagon)
				add_passenger(wagon)
				# only 1 passenger can be picked up per turn
				return


func try_deliver() -> void:
	for wagon: Wagon in wagons.get_occupied_wagons():
		for station: DeliveryStation in level.get_delivery_stations():
			if wagon.current_cell in station.get_delivery_cells():
				station.deliver_passenger(wagon)
				remove_passenger(wagon)
				return
	

func move(precondition: Callable):
	var prev_direction = current_direction
	
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
		SceneSignalBus.reload_level()
		return
		
	for wagon: Wagon in wagons.get_all_wagons():
		if wagon.current_cell == target_cell:
			if has_portal:
				has_portal = false
				SoundManager.play_sfx(Sounds.GHOST)
				SoundManager.play_sfx(Sounds.BOOST)
				continue
				
			SoundManager.play_random_sfx([Sounds.CRASH_1, Sounds.CRASH_2, Sounds.CRASH_3])
			SceneSignalBus.reload_level()
			return
	
	if prev_direction != current_direction:
		SoundManager.play_random_sfx([Sounds.TURN_1, Sounds.TURN_2, Sounds.TURN_3])
		
	current_cell = target_cell
	wagons.update(current_cell)
		
	if boost_left > 0:
		old_boost_left = boost_left
		boost_left -= 1
	elif boost_left == 0 and old_boost_left > 0:
		old_boost_left = 0
		end_boost()


func can_add_passenger() -> bool:
	for wagon: Wagon in wagons.get_all_wagons():
		if not wagon.has_passenger and wagon.can_have_passenger:
			return true
	return false
	
	
func add_passenger(wagon: Wagon) -> void:
	if not wagon.has_passenger and wagon.can_have_passenger:
		wagon.has_passenger = true
		SoundManager.play_random_sfx([Sounds.PICKUP_1, Sounds.PICKUP_2, Sounds.PICKUP_3])
		return


func remove_passenger(wagon: Wagon) -> void:
	if wagon.has_passenger:
		SoundManager.play_random_sfx([Sounds.DELIVERY_1, Sounds.DELIVERY_2, Sounds.DELIVERY_3])
		
	wagon.has_passenger = false

# Item cannot be null
func pickup_item(item: Item) -> void:
	var powerup = true
	match item.type:
		Item.ITEM_TYPE.Grow:
			powerup = false
			for i in grow_amount:
				wagons.add_wagon()
		Item.ITEM_TYPE.BigGrow:
			for i in big_grow_amount:
				wagons.add_wagon()
		Item.ITEM_TYPE.Shrink:
			for i in shrink_amoumt:
				wagons.remove_wagon()
		Item.ITEM_TYPE.Portal:
			has_portal = true
			wagons.add_wagon()
		Item.ITEM_TYPE.Boost:
			wagons.add_wagon()
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
	for wagon in wagons.get_all_wagons():
		if wagon.has_passenger:
			count += 1
	return count


func _on_sound_timer_timeout() -> void:
	SoundManager.play_random_sfx(Sounds.HISSES)
	$SoundTimer.start(sound_time_min + randi() % (sound_time_max - sound_time_min))


func start_boost() -> void:
	SoundManager.play_sfx(Sounds.BOOST)
	boost_left = boost_size
	old_boost_left = boost_size
	movement_timer.stop()
	movement_timer.wait_time = boost_multiplier * base_movement_time
	movement_timer.start()
	
	
func end_boost() -> void:
	movement_timer.stop()
	movement_timer.wait_time = base_movement_time
	movement_timer.start()
	
	
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


func _draw() -> void:
	#draw_rect(Rect2(to_local(current_cell * Global.TILE_SIZE), Vector2(Global.TILE_SIZE, Global.TILE_SIZE)), Color.DARK_RED)
#
	var c = Color.BLACK
	c.a = 0.25
	for w in wagons.get_children():
		var size = 24
		var start_offset = (Global.TILE_SIZE - size) / 2
		draw_rect(Rect2(to_local(w.current_cell * Global.TILE_SIZE) + Vector2(start_offset, start_offset), Vector2(size, size)), c)
