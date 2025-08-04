class_name Level
extends Node2D

@onready var grid_overlay: GridOverlay = $GridOverlay
@onready var foreground: TileMapLayer = $Foreground

@onready var stations: Node2D = $Stations
@onready var items: Node2D = $Items
@onready var train: Train = $Train


func _ready() -> void:
	grid_overlay.setup(foreground.get_used_rect())


func _on_train_move_timer_timeout() -> void:
	check_level_won()
	train.move(can_object_travel_to)
	#try_pickup_passenger()
	#try_pickup_item()
	#try_deliver_passenger()
	#update_train_head() # used for opening the mouth of the snake when its close to a pickup


func check_level_won() -> void:
	if train.get_passenger_count() != 0:
		return
	
	for station in stations.get_children():
		if not station.is_delivery and station.passenger_count != 0:
			return
	
	SceneSignalBus.next_level()


func can_object_travel_to(grid_object: Node2D, cell: Vector2i) -> bool:
	var tile_data = foreground.get_cell_tile_data(cell)
	
	for station in stations.get_children():
		if station.current_cell == cell:
			return false
	
	return tile_data == null || tile_data.get_custom_data("type") != 1
