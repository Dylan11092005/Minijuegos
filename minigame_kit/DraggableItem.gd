extends Area2D
class_name DraggableItem


signal item_dropped(item)


@export var item_id: String = ""
@export var item_texture: Texture2D


var dragging := false
var locked := false
var start_position: Vector2
var start_rotation := 0.0
var start_scale := Vector2.ONE


@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready():
	_setup_item()
	_save_start_transform()
	_apply_texture()


func _input_event(_viewport, event, _shape_idx):
	if locked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag()


func _input(event):
	if locked:
		return

	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_stop_drag()


func _process(_delta):
	if locked:
		return

	if dragging:
		global_position = get_global_mouse_position()


func return_to_start():
	global_position = start_position
	rotation_degrees = start_rotation
	scale = start_scale
	z_index = 10


func remove_from_game():
	locked = true
	dragging = false
	visible = false


func _setup_item():
	input_pickable = true
	monitoring = true
	monitorable = true
	z_index = 10


func _save_start_transform():
	start_position = global_position
	start_rotation = rotation_degrees
	start_scale = scale


func _apply_texture():
	if sprite == null:
		print("No se encontró Sprite2D en: " + name)
		return

	if item_texture != null:
		sprite.texture = item_texture


func _start_drag():
	dragging = true
	z_index = 100


func _stop_drag():
	dragging = false
	z_index = 10
	item_dropped.emit(self)
