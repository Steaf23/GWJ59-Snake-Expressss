extends Panel

signal key_selected(keycode)

func _ready():
	set_process_input(false)
	
func _input(event):
	if !event.is_pressed() || !(event is InputEventKey):
		return
	get_viewport().set_input_as_handled()
	emit_signal("key_selected", event.keycode)
	close()

func close():
	hide()
	set_process_input(false)
	
func open():
	show()
	set_process_input(true)
