extends Area2D

var is_active = false
var start_position = Vector2.ZERO
var offset = Vector2.ZERO

# Bigger value = easier to plant in good holes
@export var planting_distance := 90.0

# Bigger value = easier to detect a bad hole when releasing the seed
# It does not affect passing over the hole, only when releasing
@export var bad_hole_distance := 55.0


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


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_active:
			check_seed_release_position()
			deactivate_seed()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and is_active:
			deactivate_seed()


func check_seed_release_position():
	var areas = get_overlapping_areas()

	for area in areas:
		if area.is_in_group("holes"):
			if area.current_state == area.State.INVALID:
				print("Seed placed in a bad hole by contact")
				apply_bad_hole_damage()
				return

	var holes = get_tree().get_nodes_in_group("holes")

	var closest_bad_hole = null
	var shortest_bad_distance := 999999.0

	var closest_good_hole = null
	var shortest_good_distance := 999999.0

	for hole in holes:
		var distance = global_position.distance_to(hole.global_position)

		if hole.current_state == hole.State.INVALID:
			if distance < shortest_bad_distance:
				shortest_bad_distance = distance
				closest_bad_hole = hole

		elif hole.current_state == hole.State.EMPTY:
			if distance < shortest_good_distance:
				shortest_good_distance = distance
				closest_good_hole = hole

	if closest_bad_hole != null and shortest_bad_distance <= bad_hole_distance:
		print("Seed placed in a bad hole by distance")
		apply_bad_hole_damage()
		return

	if closest_good_hole != null and shortest_good_distance <= planting_distance:
		var planted = closest_good_hole.try_plant()

		if planted:
			print("Seed planted")
			return

	print("The seed was not released over a valid hole")


func apply_bad_hole_damage():
	get_tree().call_group("game_manager", "receive_bad_hole_damage")


func deactivate_seed():
	is_active = false
	global_position = start_position
	z_index = 50
