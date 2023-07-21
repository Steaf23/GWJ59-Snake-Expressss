extends Node


func change_action_key(new_action: KeyActions.RebindableAction, new_keycode: Key):
	remove_action_events(new_action.action_id)
	
	var event = InputEventKey.new()
	event.keycode = new_keycode
	KeyActions.get_action(new_action.action_id).keycode = new_keycode
	InputMap.action_add_event(new_action.action_id, event)
	
	
func remove_action_events(action_id: StringName):
	for event in InputMap.action_get_events(action_id):
		InputMap.action_erase_event(action_id, event)
