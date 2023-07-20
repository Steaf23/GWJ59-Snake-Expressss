extends CanvasLayer


func _ready() -> void:
	$MarginContainer.visible = get_tree().paused


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
		
		$MarginContainer.visible = get_tree().paused
