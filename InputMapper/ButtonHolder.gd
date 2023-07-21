extends GridContainer


func add_button(action: KeyActions.RebindableAction):
	var button = Button.new()
	add_child(button)
	button.set_meta("action", action)
	update_button(button, action.keycode)
	return button


func update_button(button: Button, keycode: Key):
	var key_string = PackedByteArray([keycode]).get_string_from_utf8()
	match keycode:
		KEY_SPACE: key_string = "SPACE"
		KEY_LEFT: key_string = "LEFT"
		KEY_RIGHT: key_string = "RIGHT"
		KEY_DOWN: key_string = "DOWN"
		KEY_UP: key_string = "UP"
		
	if key_string == " ":
		key_string = "SPACE"
	button.text = "%s: [%s]" % [button.get_meta("action").display_name, key_string]
	var updated_meta: KeyActions.RebindableAction = button.get_meta("action")
	updated_meta.keycode = keycode
	button.set_meta("action", updated_meta)
