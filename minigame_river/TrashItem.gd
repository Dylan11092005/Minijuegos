extends Area2D
class_name TrashItem


signal trash_dropped(trash)


@export var trash_texture: Texture2D

@export_category("Flotación")
@export var float_y_amount := 10.0
@export var float_x_amount := 5.0
@export var float_speed := 1.8
@export var rotation_amount := 8.0

@export_category("Corriente")
@export var current_speed := 55.0


var dragging := false

var start_position: Vector2
var base_position: Vector2
var phase := 0.0
var sprite_half_width := 50.0


@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	input_pickable = true
	monitoring = true
	monitorable = true

	start_position = global_position
	base_position = global_position
	phase = randf() * TAU

	if trash_texture != null:
		sprite.texture = trash_texture

	_calculate_sprite_width()


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag()


func _input(event):
	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_drag()


func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()
		return

	_move_with_current(delta)


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

	base_position = global_position

	trash_dropped.emit(self)


func _calculate_sprite_width():
	if sprite == null or sprite.texture == null:
		sprite_half_width = 50.0
		return

	var sprite_width = sprite.get_rect().size.x
	var final_scale = abs(sprite.global_scale.x)

	sprite_half_width = sprite_width * final_scale / 2.0


func _move_with_current(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	var viewport_width = get_viewport_rect().size.x

	base_position.x += current_speed * delta

	var float_x = sin(
		current_time * float_speed + phase
	) * float_x_amount

	var float_y = cos(
		current_time * float_speed * 1.2 + phase
	) * float_y_amount

	var current_rotation = sin(
		current_time * float_speed + phase
	) * rotation_amount

	var next_position = base_position + Vector2(float_x, float_y)

	# Cuando la basura desaparece completamente por la derecha,
	# reaparece inmediatamente por la izquierda.
	if next_position.x - sprite_half_width > viewport_width:
		next_position.x = -sprite_half_width
		base_position.x = next_position.x - float_x

	global_position = next_position
	rotation_degrees = current_rotation
