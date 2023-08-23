extends Node

const TILE_SIZE: int = 32

var input_method: InputManager.InputMethod = InputManager.InputMethod.DIRECTIONAL

func _enter_tree() -> void:
	randomize()
