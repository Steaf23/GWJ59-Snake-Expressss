class_name Wagons
extends Node2D

@onready var TRAIN_WAGON = preload("res://Level/Player/wagon.tscn")

@onready var head: Wagon = %Head
@onready var tail: Wagon = %Tail
@onready var snake: PlayerSnake = owner

@onready var wagon_spawn_time: float = 1.0

var wagon_queue: int = 0

func get_all_wagons() -> Array[Wagon]:
	var result: Array[Wagon] = []
	result.assign(get_children().filter(func(w): return w is Wagon))
	return result

func get_available_wagons() -> Array[Wagon]:
	var available_wagons: Array[Wagon] = []
	for wagon in get_children():
		if wagon is Wagon:
			if wagon.can_have_passenger and not wagon.has_passenger: 
				available_wagons.append(wagon)
	return available_wagons


func get_occupied_wagons() -> Array[Wagon]:
	var result: Array[Wagon] = []
	for wagon in get_children():
		if wagon is Wagon:
			if wagon.can_have_passenger and wagon.has_passenger:
				result.append(wagon)
	return result


func add_wagon() -> void:
	wagon_queue += 1
	

func update(head_cell: Vector2i) -> void:	
	# add wagon if queue is bigger than 0
	var wagon_created = false
	if wagon_queue > 0:
		wagon_created = true
		wagon_queue -= 1
		create_wagon()
		
	var target_cell = head_cell
	for wagon in get_children():
		var current_wagon_cell = wagon.current_cell
		wagon.move(target_cell, wagon == head or not wagon_created)
		target_cell = current_wagon_cell


func create_wagon() -> void:
	var wagon = TRAIN_WAGON.instantiate()
	wagon.snake = snake
	add_child(wagon)
	move_child(wagon, 1)
	var new_wagon_cell = head.current_cell
	wagon.global_position = new_wagon_cell * Global.TILE_SIZE
	wagon.current_cell = new_wagon_cell
	wagon.rotation = rotation
	wagon.target_angle = wagon.rotation
	
	var scale_tween = create_tween()
	var t1 = scale_tween.tween_property(wagon, ^"scale", Vector2(1.0, 1.0), wagon_spawn_time)
	t1.from(Vector2(0, 0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var opacity_tween = create_tween()
	var t3 = opacity_tween.tween_property(wagon, ^"modulate", Color.WHITE, wagon_spawn_time)
	t3.from(Color(1, 1, 1, 0)).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	


func remove_wagon() -> void:
	if get_child_count() == 2:
		return
	
	var back_wagon = null
	var idx = get_child_count() - 3
	for i in range(0, get_child_count()):
		back_wagon = get_child(get_child_count() - i - 1)
		if not back_wagon.has_passenger and back_wagon.can_have_passenger:
			break
		
	if back_wagon.can_have_passenger:
		back_wagon.queue_free()
