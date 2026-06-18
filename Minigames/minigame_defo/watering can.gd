extends Area2D

var is_active = false
var start_position = Vector2.ZERO
var offset = Vector2.ZERO


func _ready():
	start_position = global_position
	z_index = 50
	monitoring = true
	monitorable = true


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_active:
			is_active = true
			offset = global_position - get_global_mouse_position()
			z_index = 80


func _process(_delta):
	if is_active:
		global_position = get_global_mouse_position() + offset
		water_hole()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_active:
			deactivate_watering_can()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and is_active:
			deactivate_watering_can()


func water_hole():
	var areas = get_overlapping_areas()

	for area in areas:
		if area.is_in_group("holes"):
			var watered = area.try_water()

			if watered:
				print("Hole watered")
				break


func deactivate_watering_can():
	is_active = false
	global_position = start_position
	z_index = 50
