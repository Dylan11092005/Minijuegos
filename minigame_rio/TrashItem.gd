extends Area2D

signal dropped(trash)

@export var trash_texture: Texture2D
@export var float_amplitude := 8.0
@export var float_speed := 2.0
@export var rotation_amplitude := 5.0

var dragging := false
var start_position: Vector2
var phase := 0.0

@onready var sprite = $Sprite2D


func _ready():
	start_position = global_position
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
	var float_y = sin(t * float_speed + phase) * float_amplitude
	var float_rotation = sin(t * float_speed + phase) * rotation_amplitude

	global_position = start_position + Vector2(0, float_y)
	rotation_degrees = float_rotation


func return_to_start():
	global_position = start_position
	rotation_degrees = 0
