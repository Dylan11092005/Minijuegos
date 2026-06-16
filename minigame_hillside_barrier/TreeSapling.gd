extends Area2D
class_name HillsideTreeSapling


# =========================================================
# CONSTANTS
# =========================================================

const RETURN_SPEED := 18.0

# Tamaño cuando ya está plantado para detener la roca.
const PLANTED_SCALE := Vector2(1.45, 1.45)

# Baja el árbol para que la raíz quede sobre el punto.
const PLANTED_POSITION_OFFSET := Vector2(0, 105)

const ROCK_HIT_OFFSET := Vector2(0, -95)
const ROCK_HIT_RADIUS := 100.0

const IDLE_ANIMATION_SPEED := 3.0
const IDLE_BOUNCE_AMOUNT := 4.0
const IDLE_SCALE_AMOUNT := 0.04


# =========================================================
# PUBLIC VARIABLES
# =========================================================

var minigame: Node = null


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _start_position := Vector2.ZERO
var _start_scale := Vector2.ONE

var _dragging := false
var _placed := false
var _drag_offset := Vector2.ZERO
var _returning := false

var _time_elapsed := 0.0
var _base_sprite_position := Vector2.ZERO
var _base_sprite_scale := Vector2.ONE


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	_start_position = position
	_start_scale = scale

	z_index = 30

	monitoring = true
	monitorable = true
	input_pickable = true

	collision_layer = 2
	collision_mask = 4

	if _sprite:
		_base_sprite_position = _sprite.position
		_base_sprite_scale = _sprite.scale

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


func _process(delta):
	if _placed:
		return

	_time_elapsed += delta
	_animate_idle()

	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset
	elif _returning:
		position = position.lerp(_start_position, delta * RETURN_SPEED)

		if position.distance_to(_start_position) < 2.0:
			position = _start_position
			scale = _start_scale
			_returning = false


func _input(event):
	if _placed:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _dragging:
			_drop_tree()


# =========================================================
# ANIMATION METHODS
# =========================================================

func _animate_idle():
	if _sprite == null:
		return

	var bounce := sin(_time_elapsed * IDLE_ANIMATION_SPEED) * IDLE_BOUNCE_AMOUNT
	var pulse := 1.0 + sin(_time_elapsed * IDLE_ANIMATION_SPEED) * IDLE_SCALE_AMOUNT

	_sprite.position = _base_sprite_position + Vector2(0, bounce)
	_sprite.scale = _base_sprite_scale * pulse


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
			z_index = 80

			if minigame and minigame.has_method("register_tree_grabbed"):
				minigame.register_tree_grabbed(self)

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
	add_to_group("planted_trees")
	_returning = false

	global_position = spot.global_position + PLANTED_POSITION_OFFSET
	scale = PLANTED_SCALE
	z_index = 45

	spot.place_tree()

	monitoring = false
	monitorable = false
	input_pickable = false

	if _sprite:
		_sprite.position = _base_sprite_position
		_sprite.scale = _base_sprite_scale

	if minigame and minigame.has_method("register_successful_tree"):
		minigame.register_successful_tree(self, spot, _start_position)


func _return_to_start():
	_returning = true


func get_rock_hit_position() -> Vector2:
	return global_position + ROCK_HIT_OFFSET


func get_rock_hit_radius() -> float:
	return ROCK_HIT_RADIUS
