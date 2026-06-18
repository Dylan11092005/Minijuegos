extends Area2D
class_name PathSlot


const STRAIGHT_HORIZONTAL: int = 0
const STRAIGHT_VERTICAL: int = 1
const CURVE_UP_RIGHT: int = 2
const CURVE_RIGHT_DOWN: int = 3
const CURVE_DOWN_LEFT: int = 4
const CURVE_LEFT_UP: int = 5


@export var slot_id: String = ""
@export var is_start_slot: bool = false
@export var is_goal_slot: bool = false
@export var snap_offset: Vector2 = Vector2(0.0, 8.0)


var occupied: bool = false
var placed_piece: Node = null


@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = true
	monitorable = true
	input_pickable = false

	if slot_id.is_empty():
		slot_id = name


func contains_global_point(point: Vector2) -> bool:
	if _collision_shape == null:
		return false

	if _collision_shape.disabled:
		return false

	if not _collision_shape.shape is RectangleShape2D:
		return false

	var rectangle: RectangleShape2D = _collision_shape.shape as RectangleShape2D
	var local_point: Vector2 = _collision_shape.to_local(point)
	var half_size: Vector2 = rectangle.size * 0.5

	return (
		absf(local_point.x) <= half_size.x
		and absf(local_point.y) <= half_size.y
	)


func can_receive_piece(piece_position: Vector2) -> bool:
	if occupied:
		return false

	return contains_global_point(piece_position)


func place_piece(piece: Node) -> bool:
	if occupied:
		return false

	if not piece.has_method("place_at"):
		return false

	occupied = true
	placed_piece = piece
	piece.call("place_at", get_snap_position())

	return true


func remove_piece() -> void:
	occupied = false
	placed_piece = null


func get_snap_position() -> Vector2:
	return global_position + snap_offset


func has_connection(direction: Vector2i) -> bool:
	if placed_piece == null:
		return false

	var current_path_type: int = int(placed_piece.get("path_type"))

	match current_path_type:
		STRAIGHT_HORIZONTAL:
			return (
				direction == Vector2i.LEFT
				or direction == Vector2i.RIGHT
			)

		STRAIGHT_VERTICAL:
			return (
				direction == Vector2i.UP
				or direction == Vector2i.DOWN
			)

		CURVE_UP_RIGHT:
			return (
				direction == Vector2i.UP
				or direction == Vector2i.RIGHT
			)

		CURVE_RIGHT_DOWN:
			return (
				direction == Vector2i.RIGHT
				or direction == Vector2i.DOWN
			)

		CURVE_DOWN_LEFT:
			return (
				direction == Vector2i.DOWN
				or direction == Vector2i.LEFT
			)

		CURVE_LEFT_UP:
			return (
				direction == Vector2i.LEFT
				or direction == Vector2i.UP
			)

	return false
