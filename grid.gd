class_name Grid
extends TileMap

@onready var train: Train = $Train
@onready var stations: Node2D = $Stations
@onready var items: Node2D = $Items


enum OBJECT_TYPES {
	Ground = 0,
	Wall = 1,
	PASSENGER_PICKUP = 2,
}


func _on_train_move_timer_timeout() -> void:
	train.move(can_traverse)
	try_pickup_passenger()
	try_pickup_item()
	update_train_head()
	
	
func can_traverse(grid_object: Node2D, cell: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(OBJECT_TYPES.Wall, cell)
	
	return tile_data == null || tile_data.get_custom_data("type") != 1


func try_pickup_passenger():
	if not train.can_add_passenger():
		return
	
	for station in stations.get_children():
		if train.current_cell in station.get_pickup_cells():
			station.pickup_passenger(train.head)
			train.add_passenger()
	
	
func try_pickup_item() -> void:
	for item in items.get_children():
		if train.current_cell == item.current_cell:
			train.pickup_item(item)


func update_train_head() -> void:
	var close_to_item: bool = false
	
	for item in items.get_children():
		if abs(train.current_cell.x - item.current_cell.x) < 2 and abs(train.current_cell.y - item.current_cell.y) < 2:
			print("CLOSE: " + str(train.current_cell) + " " + str(item.current_cell))
			close_to_item = true
			break
	
	if close_to_item && not train.is_biting:
		train.start_bite()
	elif train.is_biting:
		train.cancel_bite()
