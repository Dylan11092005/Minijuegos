extends Area2D

var is_active = false
var start_position = Vector2.ZERO
var offset = Vector2.ZERO

func _ready():
	start_position = global_position

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_active:
			is_active = true
			offset = global_position - get_global_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	if is_active:
		global_position = get_global_mouse_position() + offset
		realizar_riego()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_active:
			desactivar_regadera()
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and is_active:
			desactivar_regadera()

func realizar_riego():
	var areas = get_overlapping_areas()
	
	for area in areas:
		if area.is_in_group("holes"):
			area.try_water()

func desactivar_regadera():
	is_active = false
	global_position = start_position
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
