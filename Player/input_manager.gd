class_name InputManager
extends Node

enum InputMethod { DIRECTIONAL, STEERING }

signal input_direction_changed()
signal output_direction_changed()

@onready var current_direction: Vector2i = Vector2i.DOWN
var queued_input: Vector2i:
	set(value):
		queued_input = value
	get:
		return queued_input

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var new_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Vector2(queued_input) != new_input:
			if new_input != Vector2.ZERO:
				queued_input = Vector2i(new_input)
			input_direction_changed.emit()


func update_current_direction() -> void:
	var prev_direction = current_direction
	
	var input = queued_input
	
	if Global.input_method == InputMethod.DIRECTIONAL:
		match (prev_direction):
			Vector2i.LEFT, Vector2i.RIGHT:
				if not is_equal_approx(input.y, 0.0):
					current_direction = Vector2(0, sign(input.y))
			Vector2i.DOWN, Vector2i.UP:
				if not is_equal_approx(input.x, 0.0):
					current_direction = Vector2(sign(input.x), 0)
					
	elif Global.input_method == InputMethod.STEERING:
		current_direction = Vector2(prev_direction).rotated(input.x * (PI/2))
	
	queued_input = Vector2.ZERO
	
	if prev_direction != current_direction:
		output_direction_changed.emit()
