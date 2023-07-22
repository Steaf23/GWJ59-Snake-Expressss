extends Node

@onready var container = $GameContainer/SubViewport

@onready var ITEM = preload("res://item.tscn")
@onready var PICKUP = preload("res://station.tscn")
@onready var DELIVERY = preload("res://delivery_station.tscn")
@onready var SNAKE = preload("res://train.tscn")
@onready var SNAKE_FAKE = preload("res://editor_snake.tscn")

var selected_idx: int = 0

func _ready() -> void:
	var lvl_scn = load("res://world.tscn")
	place_level(lvl_scn)
	get_tree().paused = true
	

func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	selected_idx = index
	print(index)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed:
		var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		container.global_canvas_transform.origin += (-input * Global.TILE_SIZE)


func _on_save_pressed() -> void:
	var level: int = $CanvasLayer/HBoxContainer/LineEdit.value
	
	var lvl_scn: Node2D = container.get_child(0).duplicate()
	var packed_lvl = PackedScene.new()
	
	for i in lvl_scn.get_node("Grid/Items").get_children():
		i.owner = lvl_scn
	
	for i in lvl_scn.get_node("Grid/Stations").get_children():
		i.owner = lvl_scn
	
	var train_found = false
	for c in lvl_scn.get_node("Grid").get_children():
		if c.has_meta("cell"):
			train_found = true
			c.queue_free()
			
			var train = SNAKE.instantiate()
			train.global_position = c.get_meta("cell") * Global.TILE_SIZE
			lvl_scn.get_node("Grid").add_child(train)
			train.owner = lvl_scn
			break
	
	if not train_found:
		print("Scene must have Snake!")
	
	packed_lvl.pack(lvl_scn)
	print(ResourceSaver.save(packed_lvl, "res://Levels/level_" + str(level) + ".tscn"))
	
	

func _on_load_pressed() -> void:
	var level: int = $CanvasLayer/HBoxContainer/LineEdit.value
	
	var lvl_scn = load("res://Levels/level_" + str(level) + ".tscn")
	place_level(lvl_scn)
	
	
func _on_new_pressed() -> void:
	var lvl_scn = load("res://world.tscn")
	place_level(lvl_scn)
		
	
func place_level(scene: PackedScene) -> void:
	for c in container.get_children():
		c.queue_free()
	
	if scene == null:
		print("Scene " + str($CanvasLayer/HBoxContainer/LineEdit.value) + " does not exist!")
		return
		
	var train_cell = Vector2i() 
	var level = scene.instantiate()
	for t in level.get_node("Grid").get_children():
		if t is Train:
			train_cell = t.current_cell
			t.queue_free()
	container.add_child(level)
	place_train(train_cell)
	

func place_item(item_type: Item.ITEM_TYPE, cell: Vector2i) -> void:
	var item = ITEM.instantiate()
	item.type = item_type
	item.global_position = cell * Global.TILE_SIZE
	container.get_child(0).get_node("Grid/Items").add_child(item)
	
	
func place_station(cell: Vector2i, is_delivery: bool, type: Station.STATION_TYPE) -> void:
	var station
	if is_delivery:
		station = DELIVERY.instantiate()
	else:
		station = PICKUP.instantiate()
		
	station.global_position = cell * Global.TILE_SIZE
	container.get_child(0).get_node("Grid/Stations").add_child(station)


func place_train(cell: Vector2i) -> void:
	var train = SNAKE_FAKE.instantiate()
	train.global_position = cell * Global.TILE_SIZE
	train.set_meta("cell", cell)
	container.get_child(0).get_node("Grid").add_child(train)


func place_terrain(cell: Vector2i, terrain_id: int, big: bool) -> void:
	var grid: TileMap = container.get_child(0).get_node("Grid") as TileMap
	var cells = []
	if not big:
		grid.set_cells_terrain_connect(1, [cell], 0, terrain_id)
		return
		
	for i in range(-1, 2):
		for j in range(-1, 2):
			cells.append(cell + Vector2i(i, j))
	grid.set_cells_terrain_connect(1, cells, 0, terrain_id)
	

func place_tile(cell: Vector2i, tile_id: int) -> void:
	var grid: TileMap = container.get_child(0).get_node("Grid") as TileMap
	var cells = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			cells.append(cell + Vector2i(i, j))
	grid.set_cells_terrain_connect(1, cells, 0, tile_id)
	


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() && event is InputEventMouseButton:
		var cell = Vector2i((get_viewport().get_mouse_position() + container.global_canvas_transform.origin) / Global.TILE_SIZE / 2.0)
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_object(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_object(cell)
			
			
func remove_object(cell: Vector2i) -> void:
	for item in container.get_child(0).get_node("Grid/Items").get_children():
		if item.current_cell == cell:
			item.queue_free()
			return
	
	for station in container.get_child(0).get_node("Grid/Stations").get_children():
		if station.current_cell == cell:
			station.queue_free()
			return
	
	for c in container.get_child(0).get_node("Grid").get_children():
		if c.has_meta("cell") and c.get_meta("cell") == cell:
			c.queue_free()
			return
			
	var grid: TileMap = container.get_child(0).get_node("Grid") as TileMap
	grid.set_cell(1, cell)
	

func place_object(cell: Vector2i) -> void:
	match selected_idx:
		0: place_train(cell)
		1: place_station(cell, false, Station.STATION_TYPE.Square)
		2: place_station(cell, true, Station.STATION_TYPE.Square)
		3: place_terrain(cell, 1, false)
		4: place_terrain(cell, 3, false)
		5: place_terrain(cell, 0, true)
		6: place_terrain(cell, 2, true)
		7: place_item(Item.ITEM_TYPE.Grow, cell)
		8: place_item(Item.ITEM_TYPE.BigGrow, cell)
		9: place_item(Item.ITEM_TYPE.Boost, cell)
		10: place_item(Item.ITEM_TYPE.Shrink, cell)
		11: place_item(Item.ITEM_TYPE.Portal, cell)
