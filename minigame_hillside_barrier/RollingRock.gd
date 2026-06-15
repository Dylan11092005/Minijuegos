extends Node2D
class_name HillsideRollingRock


# =========================================================
# CONSTANTS
# =========================================================

const HIT_DISTANCE := 105.0
const ROTATION_SPEED := 7.5

const FRAME_COUNT := 3

# La imagen mide 1536 x 864, entonces cada frame mide 512 de ancho.
const FRAME_WIDTH := 512
const FRAME_HEIGHT := 864

# Tamaño visual de la piedra en el juego.
const ROCK_SCALE := Vector2(0.18, 0.18)

# Velocidad de la animación de los 3 frames.
const ANIMATION_SPEED := 10.0


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _start_position := Vector2.ZERO
var _end_position := Vector2.ZERO
var _speed := 120.0
var _distance := 1.0
var _progress := 0.0
var _active := false

var _animation_time := 0.0
var _current_frame := 0

var _minigame: Node = null


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var _rock_sprite: Sprite2D = get_node_or_null("RockSprite") as Sprite2D


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

	_setup_sprite()


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	_setup_sprite()


func _process(delta):
	if not _active:
		return

	_progress += (_speed * delta) / _distance
	_progress = clamp(_progress, 0.0, 1.0)

	position = _start_position.lerp(_end_position, _progress)

	# Giro general de la piedra.
	rotation += ROTATION_SPEED * delta

	# Cambio entre las 3 imágenes.
	_update_animation(delta)

	_check_tree_collision()

	if _progress >= 1.0:
		_active = false

		if _minigame and _minigame.has_method("register_rock_reached_bottom"):
			_minigame.register_rock_reached_bottom(self)

		queue_free()


# =========================================================
# SPRITE METHODS
# =========================================================

func _setup_sprite():
	if _rock_sprite == null:
		return

	_rock_sprite.centered = true
	_rock_sprite.region_enabled = true
	_rock_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	_rock_sprite.scale = ROCK_SCALE
	_rock_sprite.z_index = 35


func _update_animation(delta):
	if _rock_sprite == null:
		return

	_animation_time += delta * ANIMATION_SPEED

	var new_frame: int = int(_animation_time) % FRAME_COUNT

	if new_frame == _current_frame:
		return

	_current_frame = new_frame

	_rock_sprite.region_rect = Rect2(
		_current_frame * FRAME_WIDTH,
		0,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)


# =========================================================
# COLLISION METHODS
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
