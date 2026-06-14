extends Area2D
class_name HillsideTreeSapling


# =========================================================
# CONSTANTS
# =========================================================

const TREE_RADIUS := 55.0
const RETURN_SPEED := 18.0

const COLOR_TRUNK := Color("#8B4F24")
const COLOR_TRUNK_DARK := Color("#4A2B16")
const COLOR_TRUNK_LIGHT := Color("#B06A35")

const COLOR_LEAVES := Color("#5EAD3A")
const COLOR_LEAVES_LIGHT := Color("#8BD84A")
const COLOR_LEAVES_DARK := Color("#2F6B25")
const COLOR_OUTLINE := Color("#24551F")


# =========================================================
# PUBLIC VARIABLES
# =========================================================

var minigame: Node = null


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _start_position := Vector2.ZERO
var _dragging := false
var _placed := false
var _drag_offset := Vector2.ZERO
var _returning := false


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	_start_position = position

	z_index = 30
	monitoring = true
	monitorable = true
	input_pickable = true

	collision_layer = 2
	collision_mask = 4

	_ensure_collision_shape()

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

	queue_redraw()


func _process(delta):
	if _placed:
		return

	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset
	elif _returning:
		position = position.lerp(_start_position, delta * RETURN_SPEED)

		if position.distance_to(_start_position) < 2.0:
			position = _start_position
			_returning = false


func _input(event):
	if _placed:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _dragging:
			_drop_tree()


func _draw():
# Sombra suave debajo del árbol
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.8, 0.45))
	draw_circle(Vector2(0, 0), 18, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Tronco principal
	draw_rect(Rect2(Vector2(-8, -58), Vector2(16, 58)), COLOR_TRUNK)
	draw_line(Vector2(-8, -58), Vector2(-8, 0), COLOR_TRUNK_DARK, 2.5)
	draw_line(Vector2(8, -58), Vector2(8, 0), COLOR_TRUNK_DARK, 2.5)
	draw_line(Vector2(-2, -52), Vector2(-2, -6), COLOR_TRUNK_LIGHT, 2.0)
	# Raíces pequeñas
	draw_line(Vector2(-4, -5), Vector2(-24, 10), COLOR_TRUNK_DARK, 3.0)
	draw_line(Vector2(4, -5), Vector2(24, 10), COLOR_TRUNK_DARK, 3.0)
	draw_line(Vector2(0, -4), Vector2(0, 12), COLOR_TRUNK_DARK, 3.0)

	# Copa del árbol con borde oscuro
	draw_circle(Vector2(0, -100), 34, COLOR_OUTLINE)
	draw_circle(Vector2(-28, -78), 29, COLOR_OUTLINE)
	draw_circle(Vector2(28, -78), 29, COLOR_OUTLINE)
	draw_circle(Vector2(0, -65), 31, COLOR_OUTLINE)

	# Copa del árbol interior
	draw_circle(Vector2(0, -100), 30, COLOR_LEAVES)
	draw_circle(Vector2(-28, -78), 25, COLOR_LEAVES_DARK)
	draw_circle(Vector2(28, -78), 25, COLOR_LEAVES)
	draw_circle(Vector2(0, -65), 27, COLOR_LEAVES_LIGHT)

	# Brillos de hojas
	draw_circle(Vector2(-8, -108), 8, Color("#A7EE63"))
	draw_circle(Vector2(15, -86), 7, Color("#9BE75A"))
	draw_circle(Vector2(-13, -67), 6, Color("#A7EE63"))


# =========================================================
# DRAG METHODS
# =========================================================

func _on_input_event(_viewport, event, _shape_idx):
	if _placed:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_dragging = true
			_returning = false
			_drag_offset = global_position - get_global_mouse_position()
			z_index = 50
			get_viewport().set_input_as_handled()


func _drop_tree():
	_dragging = false
	z_index = 30

	var target_spot: Area2D = _get_target_spot()

	if target_spot != null:
		_place_on_spot(target_spot)
	else:
		_return_to_start()

		if minigame and minigame.has_method("register_failed_drop"):
			minigame.register_failed_drop(self)


func _get_target_spot() -> Area2D:
	for area in get_overlapping_areas():
		if area.has_method("can_place_tree") and area.can_place_tree():
			return area

	return null


func _place_on_spot(spot: Area2D):
	_placed = true
	_returning = false

	global_position = spot.global_position
	spot.place_tree()

	monitoring = false
	monitorable = false

	if minigame and minigame.has_method("register_successful_tree"):
		minigame.register_successful_tree(self, spot)

	queue_redraw()


func _return_to_start():
	_returning = true


# =========================================================
# PRIVATE METHODS
# =========================================================

func _ensure_collision_shape():
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = TREE_RADIUS

	collision_shape.position = Vector2(0, -60)
	collision_shape.shape = circle_shape
