extends Node2D
class_name HillsideRollingRock


# =========================================================
# CONSTANTS
# =========================================================

const HIT_DISTANCE := 100.0

const BASE_ROTATION_SPEED := 7.5

const FRAME_COUNT := 3

# Ajusta estos valores si tu sprite sheet tiene otra medida.
const FRAME_WIDTH := 512
const FRAME_HEIGHT := 864

const BASE_ROCK_SCALE := Vector2(0.18, 0.18)
const BASE_ANIMATION_SPEED := 10.0


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

var _rock_scale := BASE_ROCK_SCALE
var _rotation_speed := BASE_ROTATION_SPEED
var _animation_speed := BASE_ANIMATION_SPEED
var _rotation_direction := 1.0
var _rock_color := Color.WHITE

var _previous_global_position := Vector2.ZERO

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
	_previous_global_position = global_position

	_distance = max(_start_position.distance_to(_end_position), 1.0)
	_progress = 0.0
	_active = true

	_randomize_rock_variant()
	_setup_sprite()


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	_randomize_rock_variant()
	_setup_sprite()


func _process(delta):
	if not _active:
		return

	_previous_global_position = global_position

	_progress += (_speed * delta) / _distance
	_progress = clamp(_progress, 0.0, 1.0)

	position = _start_position.lerp(_end_position, _progress)

	rotation += _rotation_speed * _rotation_direction * delta

	_update_animation(delta)
	_check_tree_collision()

	if _progress >= 1.0:
		_active = false

		if _minigame and _minigame.has_method("register_rock_reached_bottom"):
			_minigame.register_rock_reached_bottom(self)

		queue_free()


# =========================================================
# ROCK VARIANTS
# =========================================================

func _randomize_rock_variant() -> void:
	var random_scale := randf_range(0.85, 1.25)
	_rock_scale = BASE_ROCK_SCALE * random_scale

	_rotation_speed = randf_range(5.5, 10.5)
	_animation_speed = randf_range(7.0, 13.0)

	if randf() < 0.5:
		_rotation_direction = -1.0
	else:
		_rotation_direction = 1.0

	var color_variants := [
		Color(1.0, 1.0, 1.0),
		Color(0.85, 0.85, 0.85),
		Color(0.75, 0.72, 0.68),
		Color(0.65, 0.62, 0.58),
		Color(0.90, 0.82, 0.72)
	]

	_rock_color = color_variants.pick_random()


# =========================================================
# SPRITE METHODS
# =========================================================

func _setup_sprite():
	if _rock_sprite == null:
		return

	_rock_sprite.centered = true
	_rock_sprite.region_enabled = true
	_rock_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	_rock_sprite.scale = _rock_scale
	_rock_sprite.modulate = _rock_color
	_rock_sprite.z_index = 35


func _update_animation(delta):
	if _rock_sprite == null:
		return

	_animation_time += delta * _animation_speed

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

		var tree_hit_position: Vector2 = tree.global_position

		if tree.has_method("get_rock_hit_position"):
			tree_hit_position = tree.get_rock_hit_position()

		var hit_radius: float = HIT_DISTANCE

		if tree.has_method("get_rock_hit_radius"):
			hit_radius = tree.get_rock_hit_radius()

		var distance_to_tree: float = global_position.distance_to(tree_hit_position)

		if distance_to_tree <= hit_radius:
			_active = false

			if _minigame and _minigame.has_method("register_rock_blocked"):
				_minigame.register_rock_blocked(self, tree)

			queue_free()
			return


func _distance_point_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()

	if segment_length_squared <= 0.001:
		return point.distance_to(segment_start)

	var t := (point - segment_start).dot(segment) / segment_length_squared
	t = clamp(t, 0.0, 1.0)

	var closest_point := segment_start + segment * t

	return point.distance_to(closest_point)
