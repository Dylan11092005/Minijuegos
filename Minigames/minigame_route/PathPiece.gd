
extends Area2D
class_name PathPiece


signal drag_requested(source_piece: Node)
signal piece_dropped(piece: Node)
signal placed_piece_clicked(piece: Node)


enum PathType {
	STRAIGHT_HORIZONTAL,
	STRAIGHT_VERTICAL,
	CURVE_UP_RIGHT,
	CURVE_RIGHT_DOWN,
	CURVE_DOWN_LEFT,
	CURVE_LEFT_UP
}


@export var path_type: int = PathType.STRAIGHT_HORIZONTAL
@export var piece_texture: Texture2D
@export var is_palette_piece: bool = false
@export var is_fixed_piece: bool = false


var dragging: bool = false
var placed: bool = false

var palette_visual_size: Vector2 = Vector2(82.0, 82.0)
var board_visual_size: Vector2 = Vector2(105.0, 105.0)

var _mouse_offset: Vector2 = Vector2.ZERO


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = true
	monitorable = true
	input_pickable = not is_fixed_piece

	_make_collision_unique()
	refresh_piece()


func _process(_delta: float) -> void:
	if dragging:
		global_position = (
			get_global_mouse_position()
			+ _mouse_offset
		)


func _input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	if is_fixed_piece:
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_event.pressed:
		return

	if is_palette_piece:
		drag_requested.emit(self)
		return

	if placed:
		placed_piece_clicked.emit(self)
		return

	_start_dragging()


func _input(event: InputEvent) -> void:
	if is_palette_piece:
		return

	if is_fixed_piece:
		return

	if placed:
		return

	if not dragging:
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_event.pressed:
		return

	_stop_dragging()


func configure(
	new_path_type: int,
	new_texture: Texture2D,
	new_palette_size: Vector2,
	new_board_size: Vector2
) -> void:
	path_type = new_path_type
	piece_texture = new_texture
	palette_visual_size = new_palette_size
	board_visual_size = new_board_size

	is_palette_piece = false
	is_fixed_piece = false

	refresh_piece()


func set_fixed_piece(fixed_value: bool) -> void:
	is_fixed_piece = fixed_value

	if is_node_ready():
		input_pickable = not is_fixed_piece


func begin_dragging_from_mouse() -> void:
	if is_fixed_piece:
		return

	dragging = true
	placed = false
	_mouse_offset = Vector2.ZERO

	global_position = get_global_mouse_position()
	z_index = 100
	input_pickable = true

	refresh_piece()


func place_at(target_position: Vector2) -> void:
	dragging = false
	placed = true

	global_position = target_position
	z_index = 10
	input_pickable = not is_fixed_piece

	refresh_piece()


func cancel_piece() -> void:
	if is_fixed_piece:
		return

	dragging = false
	queue_free()


func refresh_piece() -> void:
	if not is_node_ready():
		return

	if _sprite == null:
		return

	_sprite.texture = piece_texture
	_sprite.position = Vector2.ZERO
	_sprite.rotation = 0.0
	_sprite.centered = true

	if piece_texture == null:
		return

	var target_size: Vector2 = board_visual_size

	if is_palette_piece:
		target_size = palette_visual_size

	_fit_sprite_to_size(target_size)
	_update_collision(target_size)


func _start_dragging() -> void:
	if is_fixed_piece:
		return

	dragging = true

	_mouse_offset = (
		global_position
		- get_global_mouse_position()
	)

	z_index = 100


func _stop_dragging() -> void:
	dragging = false
	z_index = 10

	piece_dropped.emit(self)


func _fit_sprite_to_size(target_size: Vector2) -> void:
	if piece_texture == null:
		return

	var texture_size: Vector2 = piece_texture.get_size()

	if texture_size.x <= 0.0:
		return

	if texture_size.y <= 0.0:
		return

	var scale_x: float = (
		target_size.x / texture_size.x
	)

	var scale_y: float = (
		target_size.y / texture_size.y
	)

	var final_scale: float = minf(
		scale_x,
		scale_y
	)

	_sprite.scale = Vector2(
		final_scale,
		final_scale
	)


func _update_collision(target_size: Vector2) -> void:
	if _collision_shape == null:
		return

	if not _collision_shape.shape is RectangleShape2D:
		return

	var rectangle: RectangleShape2D = (
		_collision_shape.shape as RectangleShape2D
	)

	rectangle.size = target_size * 0.85
	_collision_shape.position = Vector2.ZERO


func _make_collision_unique() -> void:
	if _collision_shape == null:
		return

	if _collision_shape.shape == null:
		return

	var duplicated_shape: Shape2D = (
		_collision_shape.shape.duplicate()
		as Shape2D
	)

	if duplicated_shape != null:
		_collision_shape.shape = duplicated_shape
