class_name Station
extends Node2D

@export var starting_count: int = 2

@onready var passenger_count: int = starting_count

var current_cell: Vector2i


func _ready() -> void:
	current_cell = (global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	$Count.text = str(passenger_count)
	$Sprite2D.frame = 0 if passenger_count > 0 else 1


func get_pickup_cells() -> Array[Vector2i]:
	if passenger_count <= 0:
		return []
		
	var cells: Array[Vector2i] = []
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]:
		cells.append(current_cell + dir)
	return cells


func pickup_passenger(wagon: TrainWagon) -> void:
	passenger_count -= 1
	$Count.text = str(passenger_count)
	$Sprite2D.frame = 0 if passenger_count > 0 else 1
	$Newt.visible = passenger_count > 0
		
