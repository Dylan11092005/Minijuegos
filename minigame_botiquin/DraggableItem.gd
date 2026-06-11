extends Area2D
class_name DraggableItem

signal dropped(item)

@export var item_id: String = ""
@export var item_texture: Texture2D

var dragging := false
var locked := false

var start_position: Vector2
var start_rotation := 0.0
var start_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	input_pickable = true
	monitoring = true
	monitorable = true

	start_position = global_position
	start_rotation = rotation_degrees
	start_scale = scale

	z_index = 10

	if item_texture != null:
		sprite.texture = item_texture


func _input_event(_viewport, event, _shape_idx):
	if locked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging = true
			z_index = 100


func _input(event):
	if locked:
		return

	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
			z_index = 10
			dropped.emit(self)


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
