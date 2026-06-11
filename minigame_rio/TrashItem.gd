extends Area2D

signal dropped(trash)

@export var trash_texture: Texture2D

# Movimiento de flotación
@export var float_y_amount := 14.0
@export var float_x_amount := 8.0
@export var float_speed := 1.8
@export var rotation_amount := 10.0

# Corriente del río
@export var drift_amount := 20.0
@export var drift_speed := 0.35

var dragging := false
var start_position: Vector2
var base_position: Vector2
var phase := 0.0

@onready var sprite = $Sprite2D


func _ready():
	start_position = global_position
	base_position = global_position
	input_pickable = true
	phase = randf() * TAU

	if trash_texture != null:
		sprite.texture = trash_texture


func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging = true
			z_index = 50
			rotation_degrees = 0


func _input(event):
	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
			z_index = 0
			dropped.emit(self)


func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()
		return

	var t = Time.get_ticks_msec() / 1000.0

	var float_x = sin(t * float_speed + phase) * float_x_amount
	var float_y = cos(t * float_speed * 1.2 + phase) * float_y_amount
	var drift_x = sin(t * drift_speed + phase) * drift_amount
	var rot = sin(t * float_speed + phase) * rotation_amount

	global_position = base_position + Vector2(float_x + drift_x, float_y)
	rotation_degrees = rot


func return_to_start():
	global_position = start_position
	base_position = start_position
	rotation_degrees = 0
