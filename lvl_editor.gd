extends Node

@onready var level = $Level


enum Tiles {
	STONE,
	GRASS,
	GROW,
	BIGGGROW,
	BOOST,
	SHRINK,
	PORTAL,
	PICKUP_STATION,
	DELIVERY_STATION,
}

@onready var container = $GameContainer/SubViewport

@onready var ITEM = preload("res://item.tscn")
@onready var PICKUP = preload("res://station.tscn")
@onready var DELIVERY = preload("res://delivery_station.tscn")
@onready var SNAKE = preload("res://train.tscn")

var selected_idx: int = 0

func _ready() -> void:
	var lvl_scn = load("res://world.tscn")
	place_level(lvl_scn)
	get_tree().paused = true
	

func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	selected_idx = index


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed:
		# TODO THIS


func _on_save_pressed() -> void:
	var level: int = $CanvasLayer/HBoxContainer/LineEdit.value
	
	var lvl_scn: Node2D = container.get_child(0)
	var packed_lvl = PackedScene.new()
	packed_lvl.pack(lvl_scn)
	ResourceSaver.save(packed_lvl, "res://Levels/level_" + str(level) + ".tscn")
	
	

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
		
	var level = scene.instantiate()
	container.add_child(level)
	

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
	var train = SNAKE.instantiate()
	train.global_position = cell * Global.TILE_SIZE
	container.get_child(0).get_node("Grid").add_child(train)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() && event is InputEventMouseButton:
		var cell = Vector2i((get_viewport().global_canvas_transform.origin + get_viewport().get_mouse_position()) / Global.TILE_SIZE / 2.0)
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_item(Item.ITEM_TYPE.Portal, cell)
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
		if c is Train and c.current_cell == cell:
			c.queue_free()
			return
