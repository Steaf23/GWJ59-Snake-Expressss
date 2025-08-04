@tool
class_name BoundCamera2D
extends Camera2D

@onready var c1: Node2D = $Corner1
@onready var c2: Node2D = $Corner2
@onready var ref_rect: ReferenceRect = $CanvasLayer/ReferenceRect


func _ready() -> void:
	limit_bottom = max(c1.global_position.y, c2.global_position.y)
	limit_top = min(c1.global_position.y, c2.global_position.y)
	limit_left = min(c1.global_position.x, c2.global_position.x)
	limit_right = max(c1.global_position.x, c2.global_position.x)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		var top_left = Vector2i(min(c1.global_position.x, c2.global_position.x), min(c1.global_position.y, c2.global_position.y))
		var bottom_right = Vector2i(max(c1.global_position.x, c2.global_position.x), max(c1.global_position.y, c2.global_position.y))
		ref_rect.position = top_left
		ref_rect.size = bottom_right - top_left
