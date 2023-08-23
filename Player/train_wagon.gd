class_name TrainWagon
extends Area2D

@export var tween_speed = 0.5
@export var can_have_passenger = true

@onready var passenger: Node2D = $Passenger

var current_cell: Vector2i = Vector2i()
var pos_tween: Tween

var target_angle: float = 0.0
var rotation_time: float = 0.0

var has_passenger: bool = false: 
	set(value):
		has_passenger = value and can_have_passenger

		if value:
			await get_tree().create_timer(tween_speed).timeout
		passenger.visible = has_passenger
		

func _ready() -> void:
	self.has_passenger = false
	

func _process(delta: float) -> void:
	rotation_time += delta * 0.8
	$Sprite.rotation = lerp_angle($Sprite.rotation, target_angle, rotation_time)
	$Passenger.rotation = lerp_angle($Passenger.rotation, target_angle, rotation_time)


func move(target_cell: Vector2i, reposition: bool) -> void:
	var new_direction = Vector2(current_cell).direction_to(target_cell)
	rotation_time = 0.0
	target_angle = Vector2.DOWN.angle_to(new_direction)
	
	if not reposition:
		return
		
	if pos_tween != null and pos_tween.is_running():
		pos_tween.stop()
	
	pos_tween = create_tween()
	var tweener = pos_tween.tween_property(self, ^"global_position", Vector2(target_cell * Global.TILE_SIZE) + (new_direction * (Global.TILE_SIZE/3.0)), tween_speed * 1.2)
	tweener.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)
	current_cell = target_cell
