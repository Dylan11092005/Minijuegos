extends Node2D
class_name HillsideRollingRock


# =========================================================
# CONSTANTS
# =========================================================

const HIT_DISTANCE := 105.0
const ROTATION_SPEED := 7.5

const COLOR_ROCK := Color("#8A8A82")
const COLOR_ROCK_DARK := Color("#4F4F49")
const COLOR_ROCK_LIGHT := Color("#B8B8AA")


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _start_position := Vector2.ZERO
var _end_position := Vector2.ZERO
var _speed := 120.0
var _distance := 1.0
var _progress := 0.0
var _active := false

var _minigame: Node = null


# =========================================================
# PUBLIC METHODS
# =========================================================

func setup(p_start: Vector2, p_end: Vector2, p_speed: float, p_minigame: Node):
	_start_position = p_start
	_end_position = p_end
	_speed = p_speed
	_minigame = p_minigame

	position = _start_position
	_distance = max(_start_position.distance_to(_end_position), 1.0)
	_progress = 0.0
	_active = true

	queue_redraw()


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _process(delta):
	if not _active:
		return

	_progress += (_speed * delta) / _distance
	_progress = clamp(_progress, 0.0, 1.0)

	position = _start_position.lerp(_end_position, _progress)
	rotation += ROTATION_SPEED * delta

	_check_tree_collision()

	if _progress >= 1.0:
		_active = false

		if _minigame and _minigame.has_method("register_rock_reached_bottom"):
			_minigame.register_rock_reached_bottom(self)

		queue_free()


func _draw():
	# Sombra
	draw_circle(Vector2(8, 10), 34, Color(0, 0, 0, 0.22))

	# Roca principal
	draw_circle(Vector2.ZERO, 34, COLOR_ROCK)

	# Borde
	draw_arc(Vector2.ZERO, 34, 0, TAU, 64, COLOR_ROCK_DARK, 4.0, true)

	# Detalles
	draw_circle(Vector2(-10, -10), 9, COLOR_ROCK_LIGHT)
	draw_circle(Vector2(12, 9), 7, COLOR_ROCK_DARK)
	draw_line(Vector2(-18, 6), Vector2(15, -14), COLOR_ROCK_DARK, 3.0)
	draw_line(Vector2(-5, 22), Vector2(20, 8), COLOR_ROCK_DARK, 2.5)


# =========================================================
# PRIVATE METHODS
# =========================================================

func _check_tree_collision():
	for tree in get_tree().get_nodes_in_group("planted_trees"):
		if tree == null:
			continue

		if not is_instance_valid(tree):
			continue

		if global_position.distance_to(tree.global_position) <= HIT_DISTANCE:
			_active = false

			if _minigame and _minigame.has_method("register_rock_blocked"):
				_minigame.register_rock_blocked(self, tree)

			queue_free()
			return
