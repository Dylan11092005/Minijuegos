extends Area2D

var is_dragging = false
var start_position = Vector2.ZERO

func _ready():
	start_position = global_position

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			is_dragging = false
			attempt_plant()

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position()

func attempt_plant():
	var areas = get_overlapping_areas()
	var planted = false
	
	for area in areas:
		if area.is_in_group("holes"):
			if area.try_plant():
				planted = true
				break
				
	if planted:
		get_tree().call_group("game_manager", "spawn_new_seed")
		queue_free()
	else:
		global_position = start_position
