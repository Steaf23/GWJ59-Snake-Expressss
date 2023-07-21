extends Node

var actions: Array[RebindableAction] = [
	RebindableAction.new(&"move_left", KEY_A, &"Steer Left"),
	RebindableAction.new(&"move_right", KEY_D, &"Steer Right"),
	RebindableAction.new(&"move_up", KEY_W, &"Steer Up"),
	RebindableAction.new(&"move_down", KEY_S, &"Steer Down"),
	]


func get_action(action_name: StringName) -> RebindableAction:
	for action in actions:
		if action.action_id == action_name:
			return action
	return null


class RebindableAction:
	var action_id: StringName
	var keycode: Key
	var display_name: StringName
	
	
	func _init(_action_id: String, _keycode: Key, _display_name: String) -> void:
		self.action_id = _action_id
		self.keycode = _keycode
		self.display_name = _display_name
