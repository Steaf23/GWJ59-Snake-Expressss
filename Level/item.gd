@tool
class_name Item
extends Node2D

enum ITEM_TYPE {
	None,
	Grow,
	Boost,
	BigGrow,
	Shrink,
	Portal,
	Frog,
}

@export var type: ITEM_TYPE:
	set(value):
		type = value
		
		var texture: String
		match type:
			ITEM_TYPE.Grow:
				texture = "res://Assets/Art/GrowthFruit.png"
			ITEM_TYPE.Boost:
				texture = "res://Assets/Art/BoostFruit.png"
			ITEM_TYPE.BigGrow:
				texture = "res://Assets/Art/GrowthFruitBig.png"
			ITEM_TYPE.Shrink:
				texture = "res://Assets/Art/ShrinkFruit.png"
			ITEM_TYPE.Portal:
				texture = "res://Assets/Art/GhostFruit.png"
			ITEM_TYPE.Frog:
				texture = "res://Assets/Art/GoldenFrog.png"
		
		if $Sprite2D == null:
			await ready
		$Sprite2D.texture = load(texture)

var current_cell: Vector2i


func _ready() -> void:
	current_cell = (global_position + Vector2(2.0, 2.0)) / Global.TILE_SIZE
	$AnimationPlayer.advance(randf())
	
