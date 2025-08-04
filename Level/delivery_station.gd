@tool
class_name DeliveryStation
extends Node2D

enum STATION_TYPE {
	Square,
	Triangle,
	Star,
	Circle,
	Dusk,
	Dawn,
}

@export var entry: StationEntry: 
	set(value):
		entry = value
		if entry != null:
			if not is_node_ready():
				await ready
			$Icon.modulate = entry.color


@export var is_delivery: bool
@export var starting_count: int = 2:
	set(value):
		starting_count = value
		set_count(value)
		
@export var number_gradient: Gradient

@onready var capacity: int = starting_count

var current_cell: Vector2i


func _ready() -> void:
	self.entry = entry
	current_cell = (global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	set_count(starting_count)


func get_pickup_cells() -> Array[Vector2i]:
	if capacity <= 0:
		return []
		
	var cells: Array[Vector2i] = []
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]:
		cells.append(current_cell + dir)
	return cells
	
	
func deliver_passenger(wagon: TrainWagon) -> void:
	capacity -= 1
	set_count(capacity)
	
		
func set_count(count: int) -> void:
	if count == 0:
		$Count.label_settings.font_color = number_gradient.sample(0.0)
		
	$Count.label_settings.font_color = number_gradient.sample(float(count) / starting_count)
	$Count.text = str(count)
