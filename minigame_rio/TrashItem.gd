extends Area2D

signal dropped(trash)

@export var trash_texture: Texture2D

var dragging := false
var start_position: Vector2

@onready var sprite = $Sprite2D


func _ready():
	start_position = global_position
	input_pickable = true

	if trash_texture != null:
		sprite.texture = trash_texture


func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				z_index = 10
			else:
				dragging = false
				z_index = 0
				dropped.emit(self)


func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()


func return_to_start():
	global_position = start_position
