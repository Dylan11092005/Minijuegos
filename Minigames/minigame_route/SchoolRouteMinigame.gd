extends Node2D
class_name SchoolRouteMinigame


const TIMER_UI_SCENE: PackedScene = preload(
	"res://Minigames/ui_global/TimerUi.tscn"
)

const GAME_RESULT_SCENE: PackedScene = preload(
	"res://Minigames/ui_global/GameResult.tscn"
)


@export var path_piece_scene: PackedScene

@export_group("Tiempo")
@export var time_limit: float = 60.0
@export var timer_panel_width: float = 650.0

@export_group("Panel de caminos")
@export var panel_width: float = 190.0
@export var panel_height_margin: float = 30.0
@export var panel_right_margin: float = 20.0
@export var panel_inner_margin: float = 18.0
@export var palette_piece_size: Vector2 = Vector2(82.0, 82.0)

@export_group("Piezas del tablero")
@export var board_piece_percentage: float = 1.0
@export var board_piece_vertical_offset: float = 8.0

@export_group("Detección de vecinos")
@export var neighbor_alignment_tolerance: float = 40.0


var _active_piece: Node = null
var _board_piece_size: Vector2 = Vector2(100.0, 100.0)
var _timer_ui: CanvasLayer = null
var _result_panel: CanvasLayer = null
var _game_finished: bool = false


@onready var _slots_root: Node2D = $Slots
@onready var _placed_pieces: Node2D = $PlacedPieces
@onready var _piece_panel: Node2D = $PiecePanel
@onready var _panel_background: Sprite2D = $PiecePanel/PanelBackground

@onready var _background_sound: AudioStreamPlayer = get_node_or_null("BackgroundSound")
@onready var _place_sound: AudioStreamPlayer = get_node_or_null("PlaceSound")
@onready var _error_sound: AudioStreamPlayer = get_node_or_null("ErrorSound")
@onready var _time_sound: AudioStreamPlayer = get_node_or_null("TimeSound")


func _ready() -> void:
	if path_piece_scene == null:
		push_error("No se asignó PathPiece.tscn en path_piece_scene.")
		return

	var resize_callable: Callable = Callable(self, "_layout_interface")

	if not get_viewport().size_changed.is_connected(resize_callable):
		get_viewport().size_changed.connect(resize_callable)

	_setup_timer_ui()
	_setup_result_panel()
	_calculate_board_piece_size()
	_apply_slot_offsets()
	_configure_palette_pieces()
	_layout_interface()
	_start_game()


func _setup_timer_ui() -> void:
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.call("set_tamano_panel", timer_panel_width, 60.0)

	if _timer_ui.has_signal("time_up"):
		var time_up_callable: Callable = Callable(self, "_on_time_up")

		if not _timer_ui.is_connected("time_up", time_up_callable):
			_timer_ui.connect("time_up", time_up_callable)


func _setup_result_panel() -> void:
	_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(_result_panel)


func _start_game() -> void:
	_game_finished = false

	if _background_sound != null:
		_background_sound.play()

	if _timer_ui != null and _timer_ui.has_method("iniciar"):
		_timer_ui.call(
			"iniciar",
			time_limit,
			"Tiempo restante",
			"para llegar a la zona segura"
		)


func _on_time_up() -> void:
	if _game_finished:
		return

	_lose_game()


func _lose_game() -> void:
	if _game_finished:
		return

	_game_finished = true
	_cancel_active_piece()

	if _background_sound != null:
		_background_sound.stop()

	if _timer_ui != null and _timer_ui.has_method("detener"):
		_timer_ui.call("detener")

	if _result_panel != null and _result_panel.has_method("mostrar_perdiste"):
		_result_panel.call("mostrar_perdiste")


func _win_game() -> void:
	if _game_finished:
		return

	_game_finished = true
	_cancel_active_piece()

	if _background_sound != null:
		_background_sound.stop()

	if _timer_ui != null and _timer_ui.has_method("detener"):
		_timer_ui.call("detener")

	if _result_panel != null and _result_panel.has_method("mostrar_ganaste"):
		_result_panel.call("mostrar_ganaste")


func _cancel_active_piece() -> void:
	if _active_piece == null:
		return

	if is_instance_valid(_active_piece):
		if _active_piece.has_method("cancel_piece"):
			_active_piece.call("cancel_piece")

	_active_piece = null


func _calculate_board_piece_size() -> void:
	for child: Node in _slots_root.get_children():
		if not child.has_method("can_receive_piece"):
			continue

		var collision: CollisionShape2D = child.get_node_or_null("CollisionShape2D") as CollisionShape2D

		if collision == null:
			continue

		if not collision.shape is RectangleShape2D:
			continue

		var rectangle: RectangleShape2D = collision.shape as RectangleShape2D

		var scale_size: Vector2 = Vector2(
			absf(collision.global_scale.x),
			absf(collision.global_scale.y)
		)

		var slot_size: Vector2 = rectangle.size * scale_size
		_board_piece_size = slot_size * board_piece_percentage
		return


func _apply_slot_offsets() -> void:
	for child: Node in _slots_root.get_children():
		if child == null:
			continue

		child.set("snap_offset", Vector2(0.0, board_piece_vertical_offset))


func _configure_palette_pieces() -> void:
	for child: Node in _piece_panel.get_children():
		if not child.has_method("refresh_piece"):
			continue

		if not child.has_signal("drag_requested"):
			continue

		child.set("is_palette_piece", true)
		child.set("palette_visual_size", palette_piece_size)
		child.set("board_visual_size", _board_piece_size)

		if child is Node2D:
			var piece_node: Node2D = child as Node2D
			piece_node.scale = Vector2.ONE

		child.call("refresh_piece")

		var drag_callable: Callable = Callable(
			self,
			"_on_palette_piece_drag_requested"
		)

		if not child.is_connected("drag_requested", drag_callable):
			child.connect("drag_requested", drag_callable)


func _layout_interface() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	_position_piece_panel(viewport_size)
	_resize_panel_background(viewport_size)
	_position_palette_pieces(viewport_size)


func _position_piece_panel(viewport_size: Vector2) -> void:
	var panel_x: float = viewport_size.x - panel_right_margin - panel_width * 0.5
	var panel_y: float = viewport_size.y * 0.5

	_piece_panel.position = Vector2(panel_x, panel_y)
	_piece_panel.scale = Vector2.ONE
	_piece_panel.z_index = 50


func _resize_panel_background(viewport_size: Vector2) -> void:
	if _panel_background == null:
		return

	if _panel_background.texture == null:
		return

	var panel_height: float = viewport_size.y - panel_height_margin * 2.0
	var target_size: Vector2 = Vector2(panel_width, panel_height)
	var texture_size: Vector2 = _panel_background.texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	_panel_background.centered = true
	_panel_background.position = Vector2.ZERO
	_panel_background.scale = Vector2(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)
	_panel_background.z_index = -1


func _position_palette_pieces(viewport_size: Vector2) -> void:
	var palette_pieces: Array[Node2D] = []

	for child: Node in _piece_panel.get_children():
		if child.has_method("refresh_piece") and child is Node2D:
			palette_pieces.append(child as Node2D)

	if palette_pieces.is_empty():
		return

	var panel_height: float = viewport_size.y - panel_height_margin * 2.0
	var usable_height: float = panel_height - panel_inner_margin * 2.0
	var piece_count: int = palette_pieces.size()

	var distance: float = usable_height / float(piece_count)
	var first_y: float = -usable_height * 0.5 + distance * 0.5

	for index: int in range(piece_count):
		var piece: Node2D = palette_pieces[index]
		var piece_y: float = first_y + distance * float(index)

		piece.position = Vector2(0.0, piece_y)
		piece.rotation = 0.0
		piece.scale = Vector2.ONE
		piece.z_index = 1

		piece.set("palette_visual_size", palette_piece_size)
		piece.set("board_visual_size", _board_piece_size)
		piece.call("refresh_piece")


func _on_palette_piece_drag_requested(source_piece: Node) -> void:
	if _game_finished:
		return

	if path_piece_scene == null:
		return

	_cancel_active_piece()

	var new_piece: Node = path_piece_scene.instantiate()

	if new_piece == null:
		push_error("No se pudo crear PathPiece.")
		return

	_placed_pieces.add_child(new_piece)

	var source_path_type: int = int(source_piece.get("path_type"))
	var source_texture: Texture2D = source_piece.get("piece_texture") as Texture2D

	new_piece.call(
		"configure",
		source_path_type,
		source_texture,
		palette_piece_size,
		_board_piece_size
	)

	var dropped_callable: Callable = Callable(self, "_on_piece_dropped")
	var clicked_callable: Callable = Callable(self, "_on_placed_piece_clicked")

	if not new_piece.is_connected("piece_dropped", dropped_callable):
		new_piece.connect("piece_dropped", dropped_callable)

	if not new_piece.is_connected("placed_piece_clicked", clicked_callable):
		new_piece.connect("placed_piece_clicked", clicked_callable)

	_active_piece = new_piece
	new_piece.call("begin_dragging_from_mouse")


func _on_piece_dropped(piece: Node) -> void:
	if _game_finished:
		return

	if not piece is Node2D:
		return

	var piece_node: Node2D = piece as Node2D
	var selected_slot: Node = _find_available_slot(piece_node.global_position)

	if selected_slot == null:
		if _error_sound != null:
			_error_sound.stop()
			_error_sound.play()

		piece.call("cancel_piece")
		_active_piece = null
		return

	var piece_was_placed: bool = bool(selected_slot.call("place_piece", piece))

	if piece_was_placed:
		if _place_sound != null:
			_place_sound.stop()
			_place_sound.play()

		_check_win_condition()
	else:
		if _error_sound != null:
			_error_sound.stop()
			_error_sound.play()

		piece.call("cancel_piece")

	_active_piece = null


func _on_placed_piece_clicked(piece: Node) -> void:
	if _game_finished:
		return

	var slot: Node = _find_slot_by_piece(piece)

	if slot != null:
		slot.call("remove_piece")

	if is_instance_valid(piece):
		piece.queue_free()


func _find_available_slot(piece_position: Vector2) -> Node:
	for child: Node in _slots_root.get_children():
		if not child.has_method("can_receive_piece"):
			continue

		var can_receive: bool = bool(child.call("can_receive_piece", piece_position))

		if can_receive:
			return child

	return null


func _find_slot_by_piece(piece: Node) -> Node:
	for child: Node in _slots_root.get_children():
		var placed_piece: Variant = child.get("placed_piece")

		if placed_piece == piece:
			return child

	return null


func _check_win_condition() -> void:
	var start_slot: Node = _get_start_slot()
	var goal_slot: Node = _get_goal_slot()

	if start_slot == null:
		return

	if goal_slot == null:
		return

	if not bool(start_slot.get("occupied")):
		return

	if not bool(goal_slot.get("occupied")):
		return

	var visited: Dictionary = {}
	var route_complete: bool = _follow_path_from_start(
		start_slot,
		goal_slot,
		visited
	)

	if route_complete:
		_win_game()


func _follow_path_from_start(
	start_slot: Node,
	goal_slot: Node,
	visited: Dictionary
) -> bool:
	var start_entry_direction: Vector2i = Vector2i.LEFT

	if not _slot_has_connection(start_slot, start_entry_direction):
		return false

	return _follow_path_recursive(
		start_slot,
		goal_slot,
		start_entry_direction,
		visited
	)


func _follow_path_recursive(
	current_slot: Node,
	goal_slot: Node,
	entry_direction: Vector2i,
	visited: Dictionary
) -> bool:
	var slot_id: int = current_slot.get_instance_id()

	if visited.has(slot_id):
		return false

	visited[slot_id] = true

	if not _slot_has_connection(current_slot, entry_direction):
		return false

	if current_slot == goal_slot:
		return _slot_has_connection(goal_slot, Vector2i.RIGHT)

	var directions: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	for direction: Vector2i in directions:
		if direction == entry_direction:
			continue

		if not _slot_has_connection(current_slot, direction):
			continue

		var neighbor_slot: Node = _find_neighbor_slot(current_slot, direction)

		if neighbor_slot == null:
			continue

		var needed_connection: Vector2i = _get_opposite_direction(direction)

		if not _slot_has_connection(neighbor_slot, needed_connection):
			continue

		if _follow_path_recursive(
			neighbor_slot,
			goal_slot,
			needed_connection,
			visited.duplicate()
		):
			return true

	return false


func _slot_has_connection(slot: Node, direction: Vector2i) -> bool:
	if slot == null:
		return false

	if not slot.has_method("has_connection"):
		return false

	return bool(slot.call("has_connection", direction))


func _find_neighbor_slot(current_slot: Node, direction: Vector2i) -> Node:
	var current_position: Vector2 = current_slot.global_position
	var best_slot: Node = null
	var best_distance: float = INF

	for child: Node in _slots_root.get_children():
		if child == current_slot:
			continue

		var other_position: Vector2 = child.global_position
		var delta: Vector2 = other_position - current_position
		var distance: float = INF

		match direction:
			Vector2i.LEFT:
				if delta.x >= 0.0:
					continue
				if absf(delta.y) > neighbor_alignment_tolerance:
					continue
				distance = absf(delta.x)

			Vector2i.RIGHT:
				if delta.x <= 0.0:
					continue
				if absf(delta.y) > neighbor_alignment_tolerance:
					continue
				distance = absf(delta.x)

			Vector2i.UP:
				if delta.y >= 0.0:
					continue
				if absf(delta.x) > neighbor_alignment_tolerance:
					continue
				distance = absf(delta.y)

			Vector2i.DOWN:
				if delta.y <= 0.0:
					continue
				if absf(delta.x) > neighbor_alignment_tolerance:
					continue
				distance = absf(delta.y)

		if distance < best_distance:
			best_distance = distance
			best_slot = child

	return best_slot


func _get_opposite_direction(direction: Vector2i) -> Vector2i:
	match direction:
		Vector2i.LEFT:
			return Vector2i.RIGHT
		Vector2i.RIGHT:
			return Vector2i.LEFT
		Vector2i.UP:
			return Vector2i.DOWN
		Vector2i.DOWN:
			return Vector2i.UP

	return Vector2i.ZERO


func _get_start_slot() -> Node:
	for child: Node in _slots_root.get_children():
		if bool(child.get("is_start_slot")):
			return child

	return null


func _get_goal_slot() -> Node:
	for child: Node in _slots_root.get_children():
		if bool(child.get("is_goal_slot")):
			return child

	return null
