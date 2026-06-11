extends Area2D
class_name TrashItem


signal trash_dropped(trash)


@export var trash_texture: Texture2D
@export var float_y_amount := 14.0
@export var float_x_amount := 8.0
@export var float_speed := 1.8
@export var rotation_amount := 10.0
@export var drift_amount := 20.0
@export var drift_speed := 0.35


var dragging := false
var start_position: Vector2
var base_position: Vector2
var phase := 0.0


@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	input_pickable = true

	start_position = global_position
	base_position = global_position
	phase = randf() * TAU

	if trash_texture != null:
		sprite.texture = trash_texture


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag()


func _input(event):
	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_drag()


func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()
		return

	_float_on_water()


func return_to_start():
	global_position = start_position
	base_position = start_position
	rotation_degrees = 0


func _start_drag():
	dragging = true
	z_index = 50
	rotation_degrees = 0


func _stop_drag():
	dragging = false
	z_index = 0
	trash_dropped.emit(self)


func _float_on_water():
	var time = Time.get_ticks_msec() / 1000.0

	var float_x = sin(time * float_speed + phase) * float_x_amount
	var float_y = cos(time * float_speed * 1.2 + phase) * float_y_amount
	var drift_x = sin(time * drift_speed + phase) * drift_amount
	var current_rotation = sin(time * float_speed + phase) * rotation_amount

	global_position = base_position + Vector2(float_x + drift_x, float_y)
	rotation_degrees = current_rotation
