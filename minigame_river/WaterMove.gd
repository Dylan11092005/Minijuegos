extends Sprite2D
class_name WaterMove


@export var move_amount_x := 35.0
@export var move_amount_y := 12.0
@export var move_speed := 1.6
@export var scale_amount := 0.02
@export var rotation_amount := 1.0


var base_position: Vector2
var base_scale: Vector2


func _ready():
	base_position = position
	base_scale = scale


func _process(_delta):
	_update_water_movement()


func _update_water_movement():
	var current_time = Time.get_ticks_msec() / 1000.0

	position.x = base_position.x + sin(current_time * move_speed) * move_amount_x
	position.y = base_position.y + cos(current_time * move_speed * 0.7) * move_amount_y

	var pulse_scale = 1.0 + sin(current_time * move_speed * 1.4) * scale_amount
	scale = base_scale * pulse_scale

	rotation_degrees = sin(current_time * move_speed * 0.5) * rotation_amount
