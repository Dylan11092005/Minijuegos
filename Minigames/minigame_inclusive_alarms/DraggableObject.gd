extends Area2D

@export var correct_category := ""

var is_dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO

func _ready() -> void:
	start_position = global_position

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
			else:
				is_dragging = false
				global_position = start_position
