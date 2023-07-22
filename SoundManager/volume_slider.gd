extends HBoxContainer

@export var bus: StringName = &""

@onready var label = $Label
@onready var slider = $HSlider
@onready var testSound = $TestSound


func _ready():
	update_slider(slider.value)
	testSound.bus = bus


func update_slider(value):
	label.text = "%s: %s%%" % [bus.capitalize(), value] 
	SoundManager.update_bus(bus, value)


func _on_h_slider_value_changed(value: float) -> void:
	update_slider(value)


func _on_h_slider_drag_ended(_value_changed: bool) -> void:
	testSound.play()
