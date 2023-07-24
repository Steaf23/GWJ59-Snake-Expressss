class_name Grid
extends TileMap

const GOLD_ROCK = 12

@export var infinite_level: bool = false

@onready var train: Train = $Train
@onready var stations: Node2D = $Stations
@onready var items: Node2D = $Items

enum OBJECT_TYPES {
	Ground = 0,
	Wall = 1,
	PASSENGER_PICKUP = 2,
}


func _ready() -> void:
	if train != null:
		train.move_timer_timeout.connect(_on_train_move_timer_timeout)
		
	train.frogged.connect(_on_train_frogged)


func _on_train_move_timer_timeout() -> void:
	check_level_won()
	train.move(can_traverse)
	try_pickup_passenger()
	try_pickup_item()
	try_deliver_passenger()
	update_train_head()
	
	
func can_traverse(grid_object: Node2D, cell: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(OBJECT_TYPES.Wall, cell)
	
	for station in stations.get_children():
		if station.current_cell == cell:
			return false
	
	return tile_data == null || tile_data.get_custom_data("type") != 1


func try_pickup_passenger():
	if not train.can_add_passenger():
		return
	
	for wagon in train.get_available_wagons():
		for station in stations.get_children():
			if wagon.current_cell in station.get_pickup_cells() and not station.is_delivery:
				station.pickup_passenger(wagon)
				train.add_passenger(wagon)
				return


func try_deliver_passenger():
	if train.get_passenger_count() == 0:
		return
		
	for wagon in train.wagons.get_children():
		if !wagon.can_have_passenger or !wagon.has_passenger:
			continue

		for station in stations.get_children():
			if wagon.current_cell in station.get_pickup_cells() and station.is_delivery:
				station.deliver_passenger(wagon)
				train.remove_passenger(wagon)
				return

	
func try_pickup_item() -> void:
	for item in items.get_children():
		if train.current_cell == item.current_cell:
			train.pickup_item(item)


func update_train_head() -> void:
	var close_to_item: bool = false
	
	for item in items.get_children():
		if abs(train.current_cell.x - item.current_cell.x) < 2 and abs(train.current_cell.y - item.current_cell.y) < 2:
			close_to_item = true
			break
	
	if close_to_item:
		train.start_bite()
	elif not close_to_item && train.is_biting:
		train.cancel_bite()



func check_level_won() -> void:
	if infinite_level:
		return
		
	if train.get_passenger_count() != 0:
		return
	
	for station in stations.get_children():
		if not station.is_delivery and station.passenger_count != 0:
			return
	
	SceneSignalBus.next_level()


func _on_train_frogged() -> void:
	for cell in get_used_cells_by_id(1, GOLD_ROCK):
		set_cell(1, cell)
