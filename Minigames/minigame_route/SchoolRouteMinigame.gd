
extends Node2D
class_name SchoolRouteMinigame


signal game_won
signal game_lost


enum ExternalDirection {
	LEFT,
	UP,
	RIGHT,
	DOWN
}


enum FixedPathType {
	STRAIGHT_HORIZONTAL,
	STRAIGHT_VERTICAL,
	CURVE_UP_RIGHT,
	CURVE_RIGHT_DOWN,
	CURVE_DOWN_LEFT,
	CURVE_LEFT_UP
}


const TIMER_UI_SCENE: PackedScene = preload(
	"res://Minigames/ui_global/TimerUi.tscn"
)

const GAME_RESULT_SCENE: PackedScene = preload(
	"res://Minigames/ui_global/GameResult.tscn"
)

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN
]


@export var path_piece_scene: PackedScene

@export_group("Tiempo")
@export var time_limit: float = 90.0
@export var timer_panel_width: float = 620.0
@export var timer_panel_height: float = 60.0

@export_group("Panel de caminos")
@export var panel_width: float = 190.0
@export var panel_height_margin: float = 30.0
@export var panel_right_margin: float = 20.0
@export var panel_inner_margin: float = 18.0
@export var palette_piece_size: Vector2 = Vector2(82.0, 82.0)

@export_group("Piezas del tablero")
@export var board_piece_percentage: float = 1.0
@export var board_piece_vertical_offset: float = 8.0

@export_group("Detección de casillas vecinas")
@export var neighbor_distance_multiplier: float = 1.70
@export var neighbor_axis_tolerance_multiplier: float = 0.35

@export_group("Entrada y salida")
@export_enum("Izquierda", "Arriba", "Derecha", "Abajo")
var start_external_direction: int = ExternalDirection.LEFT

@export_enum("Izquierda", "Arriba", "Derecha", "Abajo")
var goal_external_direction: int = ExternalDirection.RIGHT

@export_group("Piezas predeterminadas")
@export_enum(
	"Horizontal",
	"Vertical",
	"Curva arriba-derecha",
	"Curva derecha-abajo",
	"Curva abajo-izquierda",
	"Curva izquierda-arriba"
)
var start_fixed_path_type: int = FixedPathType.STRAIGHT_HORIZONTAL

@export_enum(
	"Horizontal",
	"Vertical",
	"Curva arriba-derecha",
	"Curva derecha-abajo",
	"Curva abajo-izquierda",
	"Curva izquierda-arriba"
)
var goal_fixed_path_type: int = FixedPathType.STRAIGHT_HORIZONTAL


var _active_piece: Node = null
var _board_piece_size: Vector2 = Vector2(100.0, 100.0)
var _slot_reference_size: Vector2 = Vector2(100.0, 100.0)

var _timer_ui: Node = null
var _game_result: Node = null
var _game_finished: bool = false


@onready var _slots_root: Node2D = $Slots
@onready var _placed_pieces: Node2D = $PlacedPieces
@onready var _piece_panel: Node2D = $PiecePanel

@onready var _panel_background: Sprite2D = (
	$PiecePanel/PanelBackground
)

@onready var _background_sound: AudioStreamPlayer = (
	get_node_or_null("BackgroundSound")
)

@onready var _piece_sound: AudioStreamPlayer = (
	get_node_or_null("PieceSound")
)


func _ready() -> void:
	if path_piece_scene == null:
		push_error(
			"No se asignó PathPiece.tscn en Path Piece Scene."
		)
		return

	var resize_callable: Callable = Callable(
		self,
		"_layout_interface"
	)

	if not get_viewport().size_changed.is_connected(
		resize_callable
	):
		get_viewport().size_changed.connect(
			resize_callable
		)

	_calculate_board_piece_size()
	_apply_slot_offsets()
	_configure_palette_pieces()
	_create_fixed_endpoint_pieces()
	_layout_interface()
	_create_global_ui()
	_configure_audio()
	_start_game()


func _create_global_ui() -> void:
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.call(
			"set_tamano_panel",
			timer_panel_width,
			timer_panel_height
		)

	var time_up_callable: Callable = Callable(
		self,
		"_on_time_up"
	)

	if _timer_ui.has_signal("time_up"):
		if not _timer_ui.is_connected(
			"time_up",
			time_up_callable
		):
			_timer_ui.connect(
				"time_up",
				time_up_callable
			)

	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)


func _configure_audio() -> void:
	if _background_sound == null:
		return

	var finished_callable: Callable = Callable(
		self,
		"_on_background_sound_finished"
	)

	if not _background_sound.finished.is_connected(
		finished_callable
	):
		_background_sound.finished.connect(
			finished_callable
		)


func _start_game() -> void:
	_game_finished = false

	if _background_sound != null:
		_background_sound.play()

	if (
		_timer_ui != null
		and _timer_ui.has_method("iniciar")
	):
		_timer_ui.call(
			"iniciar",
			time_limit,
			"Tiempo restante",
			"para llegar a la zona segura"
		)


func _on_background_sound_finished() -> void:
	if _game_finished:
		return

	if _background_sound == null:
		return

	_background_sound.play()


func _calculate_board_piece_size() -> void:
	var accumulated_size: Vector2 = Vector2.ZERO
	var valid_slot_count: int = 0

	for child: Node in _slots_root.get_children():
		if not child.has_method("can_receive_piece"):
			continue

		var collision: CollisionShape2D = (
			child.get_node_or_null("CollisionShape2D")
			as CollisionShape2D
		)

		if collision == null:
			continue

		if not collision.shape is RectangleShape2D:
			continue

		var rectangle: RectangleShape2D = (
			collision.shape as RectangleShape2D
		)

		var global_scale_size: Vector2 = Vector2(
			absf(collision.global_scale.x),
			absf(collision.global_scale.y)
		)

		var slot_size: Vector2 = (
			rectangle.size * global_scale_size
		)

		accumulated_size += slot_size
		valid_slot_count += 1

	if valid_slot_count <= 0:
		return

	_slot_reference_size = (
		accumulated_size / float(valid_slot_count)
	)

	_board_piece_size = (
		_slot_reference_size
		* board_piece_percentage
	)


func _apply_slot_offsets() -> void:
	for child: Node in _slots_root.get_children():
		if not child.has_method("get_snap_position"):
			continue

		child.set(
			"snap_offset",
			Vector2(
				0.0,
				board_piece_vertical_offset
			)
		)


func _configure_palette_pieces() -> void:
	for child: Node in _piece_panel.get_children():
		if not child.has_method("refresh_piece"):
			continue

		if not child.has_signal("drag_requested"):
			continue

		child.set(
			"is_palette_piece",
			true
		)

		child.set(
			"palette_visual_size",
			palette_piece_size
		)

		child.set(
			"board_visual_size",
			_board_piece_size
		)

		if child is Node2D:
			var piece_node: Node2D = (
				child as Node2D
			)

			piece_node.scale = Vector2.ONE

		child.call("refresh_piece")

		var drag_callable: Callable = Callable(
			self,
			"_on_palette_piece_drag_requested"
		)

		if not child.is_connected(
			"drag_requested",
			drag_callable
		):
			child.connect(
				"drag_requested",
				drag_callable
			)


func _layout_interface() -> void:
	var viewport_size: Vector2 = (
		get_viewport_rect().size
	)

	_position_piece_panel(viewport_size)
	_resize_panel_background(viewport_size)
	_position_palette_pieces(viewport_size)


func _position_piece_panel(
	viewport_size: Vector2
) -> void:
	var panel_x: float = (
		viewport_size.x
		- panel_right_margin
		- panel_width * 0.5
	)

	var panel_y: float = (
		viewport_size.y * 0.5
	)

	_piece_panel.position = Vector2(
		panel_x,
		panel_y
	)

	_piece_panel.scale = Vector2.ONE
	_piece_panel.z_index = 50


func _resize_panel_background(
	viewport_size: Vector2
) -> void:
	if _panel_background == null:
		return

	if _panel_background.texture == null:
		return

	var panel_height: float = (
		viewport_size.y
		- panel_height_margin * 2.0
	)

	var target_size: Vector2 = Vector2(
		panel_width,
		panel_height
	)

	var texture_size: Vector2 = (
		_panel_background.texture.get_size()
	)

	if texture_size.x <= 0.0:
		return

	if texture_size.y <= 0.0:
		return

	_panel_background.centered = true
	_panel_background.position = Vector2.ZERO

	_panel_background.scale = Vector2(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)

	_panel_background.z_index = -1


func _position_palette_pieces(
	viewport_size: Vector2
) -> void:
	var palette_pieces: Array[Node2D] = []

	for child: Node in _piece_panel.get_children():
		if not child.has_method("refresh_piece"):
			continue

		if child is Node2D:
			palette_pieces.append(
				child as Node2D
			)

	if palette_pieces.is_empty():
		return

	var panel_height: float = (
		viewport_size.y
		- panel_height_margin * 2.0
	)

	var usable_height: float = (
		panel_height
		- panel_inner_margin * 2.0
	)

	var piece_count: int = (
		palette_pieces.size()
	)

	var distance_between_pieces: float = (
		usable_height / float(piece_count)
	)

	var first_y: float = (
		-usable_height * 0.5
		+ distance_between_pieces * 0.5
	)

	for index: int in range(piece_count):
		var piece: Node2D = (
			palette_pieces[index]
		)

		var piece_y: float = (
			first_y
			+ distance_between_pieces
			* float(index)
		)

		piece.position = Vector2(
			0.0,
			piece_y
		)

		piece.rotation = 0.0
		piece.scale = Vector2.ONE
		piece.z_index = 1

		piece.set(
			"palette_visual_size",
			palette_piece_size
		)

		piece.set(
			"board_visual_size",
			_board_piece_size
		)

		piece.call("refresh_piece")


func _create_fixed_endpoint_pieces() -> void:
	var start_slot: Node = _get_start_slot()
	var goal_slot: Node = _get_goal_slot()

	if start_slot == null:
		push_error(
			"No se encontró el SlotInicial."
		)
		return

	if goal_slot == null:
		push_error(
			"No se encontró el SlotFinal."
		)
		return

	_create_fixed_piece_in_slot(
		start_slot,
		start_fixed_path_type
	)

	if goal_slot != start_slot:
		_create_fixed_piece_in_slot(
			goal_slot,
			goal_fixed_path_type
		)


func _create_fixed_piece_in_slot(
	slot: Node,
	fixed_path_type: int
) -> void:
	if slot == null:
		return

	var occupied_value: Variant = slot.get(
		"occupied"
	)

	if occupied_value == true:
		return

	var fixed_texture: Texture2D = (
		_find_palette_texture(
			fixed_path_type
		)
	)

	if fixed_texture == null:
		push_error(
			"No se encontró la textura de la pieza fija tipo "
			+ str(fixed_path_type)
		)
		return

	var fixed_piece: Node = (
		path_piece_scene.instantiate()
	)

	if fixed_piece == null:
		push_error(
			"No se pudo crear una pieza fija."
		)
		return

	_placed_pieces.add_child(fixed_piece)

	fixed_piece.call(
		"configure",
		fixed_path_type,
		fixed_texture,
		palette_piece_size,
		_board_piece_size
	)

	if fixed_piece.has_method(
		"set_fixed_piece"
	):
		fixed_piece.call(
			"set_fixed_piece",
			true
		)
	else:
		fixed_piece.set(
			"is_fixed_piece",
			true
		)

	var placed_correctly: bool = bool(
		slot.call(
			"place_piece",
			fixed_piece
		)
	)

	if not placed_correctly:
		fixed_piece.queue_free()


func _find_palette_texture(
	requested_path_type: int
) -> Texture2D:
	for child: Node in _piece_panel.get_children():
		if not child.has_method("refresh_piece"):
			continue

		var type_value: Variant = child.get(
			"path_type"
		)

		if type_value == null:
			continue

		if int(type_value) != requested_path_type:
			continue

		var texture_value: Variant = child.get(
			"piece_texture"
		)

		if texture_value is Texture2D:
			return texture_value as Texture2D

	return null


func _on_palette_piece_drag_requested(
	source_piece: Node
) -> void:
	if _game_finished:
		return

	if path_piece_scene == null:
		return

	_cancel_active_piece()

	var new_piece: Node = (
		path_piece_scene.instantiate()
	)

	if new_piece == null:
		push_error(
			"No se pudo crear PathPiece."
		)
		return

	_placed_pieces.add_child(new_piece)

	var source_path_type: int = int(
		source_piece.get("path_type")
	)

	var source_texture: Texture2D = (
		source_piece.get("piece_texture")
		as Texture2D
	)

	new_piece.call(
		"configure",
		source_path_type,
		source_texture,
		palette_piece_size,
		_board_piece_size
	)

	_connect_board_piece_signals(
		new_piece
	)

	_active_piece = new_piece

	new_piece.call(
		"begin_dragging_from_mouse"
	)


func _connect_board_piece_signals(
	piece: Node
) -> void:
	if piece.has_signal("piece_dropped"):
		var dropped_callable: Callable = Callable(
			self,
			"_on_piece_dropped"
		)

		if not piece.is_connected(
			"piece_dropped",
			dropped_callable
		):
			piece.connect(
				"piece_dropped",
				dropped_callable
			)

	if piece.has_signal("placed_piece_clicked"):
		var clicked_callable: Callable = Callable(
			self,
			"_on_placed_piece_clicked"
		)

		if not piece.is_connected(
			"placed_piece_clicked",
			clicked_callable
		):
			piece.connect(
				"placed_piece_clicked",
				clicked_callable
			)


func _on_piece_dropped(
	piece: Node
) -> void:
	if _game_finished:
		return

	if not piece is Node2D:
		return

	var piece_node: Node2D = (
		piece as Node2D
	)

	var selected_slot: Node = (
		_find_available_slot(
			piece_node.global_position
		)
	)

	if selected_slot == null:
		piece.call("cancel_piece")
		_active_piece = null
		return

	var piece_was_placed: bool = bool(
		selected_slot.call(
			"place_piece",
			piece
		)
	)

	if not piece_was_placed:
		piece.call("cancel_piece")
		_active_piece = null
		return

	_play_piece_sound()
	_active_piece = null

	_check_win_condition()


func _on_placed_piece_clicked(
	piece: Node
) -> void:
	if _game_finished:
		return

	if piece == null:
		return

	var fixed_value: Variant = piece.get(
		"is_fixed_piece"
	)

	if fixed_value == true:
		return

	var slot: Node = _find_slot_by_piece(
		piece
	)

	if slot == null:
		return

	var removed: bool = bool(
		slot.call("remove_piece")
	)

	if not removed:
		return

	_play_piece_sound()

	if is_instance_valid(piece):
		piece.queue_free()


func _find_available_slot(
	piece_position: Vector2
) -> Node:
	for child: Node in _slots_root.get_children():
		if not child.has_method(
			"can_receive_piece"
		):
			continue

		var can_receive: bool = bool(
			child.call(
				"can_receive_piece",
				piece_position
			)
		)

		if can_receive:
			return child

	return null


func _find_slot_by_piece(
	piece: Node
) -> Node:
	for child: Node in _slots_root.get_children():
		var placed_piece_value: Variant = child.get(
			"placed_piece"
		)

		if placed_piece_value == piece:
			return child

	return null


func _check_win_condition() -> void:
	if _game_finished:
		return

	var start_slot: Node = _get_start_slot()
	var goal_slot: Node = _get_goal_slot()

	if start_slot == null:
		return

	if goal_slot == null:
		return

	var start_direction: Vector2i = (
		_get_external_direction(
			start_external_direction
		)
	)

	var goal_direction: Vector2i = (
		_get_external_direction(
			goal_external_direction
		)
	)

	if not _slot_has_connection(
		start_slot,
		start_direction
	):
		return

	if not _slot_has_connection(
		goal_slot,
		goal_direction
	):
		return

	var pending_slots: Array[Node] = []
	var visited_slots: Dictionary = {}

	pending_slots.append(start_slot)

	var current_index: int = 0

	while current_index < pending_slots.size():
		var current_slot: Node = (
			pending_slots[current_index]
		)

		current_index += 1

		var current_id: int = (
			current_slot.get_instance_id()
		)

		if visited_slots.has(current_id):
			continue

		visited_slots[current_id] = true

		if current_slot == goal_slot:
			_finish_game(true)
			return

		for direction: Vector2i in CARDINAL_DIRECTIONS:
			if not _slot_has_connection(
				current_slot,
				direction
			):
				continue

			var neighbor_slot: Node = (
				_find_neighbor(
					current_slot,
					direction
				)
			)

			if neighbor_slot == null:
				continue

			var opposite_direction: Vector2i = (
				_get_opposite_direction(
					direction
				)
			)

			if not _slot_has_connection(
				neighbor_slot,
				opposite_direction
			):
				continue

			var neighbor_id: int = (
				neighbor_slot.get_instance_id()
			)

			if not visited_slots.has(neighbor_id):
				pending_slots.append(
					neighbor_slot
				)


func _find_neighbor(
	current_slot: Node,
	direction: Vector2i
) -> Node:
	var current_position: Vector2 = (
		_get_slot_position(current_slot)
	)

	var maximum_distance: float = (
		maxf(
			_slot_reference_size.x,
			_slot_reference_size.y
		)
		* neighbor_distance_multiplier
	)

	var axis_tolerance: float = (
		minf(
			_slot_reference_size.x,
			_slot_reference_size.y
		)
		* neighbor_axis_tolerance_multiplier
	)

	var nearest_slot: Node = null
	var nearest_distance: float = INF

	for candidate: Node in _slots_root.get_children():
		if candidate == current_slot:
			continue

		if not candidate.has_method(
			"has_connection"
		):
			continue

		var candidate_position: Vector2 = (
			_get_slot_position(candidate)
		)

		var difference: Vector2 = (
			candidate_position
			- current_position
		)

		var forward_distance: float = -1.0

		if direction == Vector2i.LEFT:
			if difference.x >= 0.0:
				continue

			if absf(difference.y) > axis_tolerance:
				continue

			forward_distance = -difference.x

		elif direction == Vector2i.RIGHT:
			if difference.x <= 0.0:
				continue

			if absf(difference.y) > axis_tolerance:
				continue

			forward_distance = difference.x

		elif direction == Vector2i.UP:
			if difference.y >= 0.0:
				continue

			if absf(difference.x) > axis_tolerance:
				continue

			forward_distance = -difference.y

		elif direction == Vector2i.DOWN:
			if difference.y <= 0.0:
				continue

			if absf(difference.x) > axis_tolerance:
				continue

			forward_distance = difference.y

		if forward_distance < 0.0:
			continue

		if forward_distance > maximum_distance:
			continue

		if forward_distance < nearest_distance:
			nearest_distance = forward_distance
			nearest_slot = candidate

	return nearest_slot


func _get_slot_position(
	slot: Node
) -> Vector2:
	if slot.has_method("get_snap_position"):
		var position_value: Variant = slot.call(
			"get_snap_position"
		)

		if position_value is Vector2:
			return position_value

	if slot is Node2D:
		var slot_node: Node2D = (
			slot as Node2D
		)

		return slot_node.global_position

	return Vector2.ZERO


func _slot_has_connection(
	slot: Node,
	direction: Vector2i
) -> bool:
	if slot == null:
		return false

	if not slot.has_method("has_connection"):
		return false

	return bool(
		slot.call(
			"has_connection",
			direction
		)
	)


func _get_start_slot() -> Node:
	for child: Node in _slots_root.get_children():
		var start_value: Variant = child.get(
			"is_start_slot"
		)

		if start_value == true:
			return child

	return null


func _get_goal_slot() -> Node:
	for child: Node in _slots_root.get_children():
		var goal_value: Variant = child.get(
			"is_goal_slot"
		)

		if goal_value == true:
			return child

	return null


func _get_external_direction(
	direction_value: int
) -> Vector2i:
	match direction_value:
		ExternalDirection.LEFT:
			return Vector2i.LEFT

		ExternalDirection.UP:
			return Vector2i.UP

		ExternalDirection.RIGHT:
			return Vector2i.RIGHT

		ExternalDirection.DOWN:
			return Vector2i.DOWN

	return Vector2i.ZERO


func _get_opposite_direction(
	direction: Vector2i
) -> Vector2i:
	if direction == Vector2i.LEFT:
		return Vector2i.RIGHT

	if direction == Vector2i.RIGHT:
		return Vector2i.LEFT

	if direction == Vector2i.UP:
		return Vector2i.DOWN

	if direction == Vector2i.DOWN:
		return Vector2i.UP

	return Vector2i.ZERO


func _on_time_up() -> void:
	if _game_finished:
		return

	_finish_game(false)


func _finish_game(
	did_win: bool
) -> void:
	if _game_finished:
		return

	_game_finished = true

	_cancel_active_piece()
	_stop_timer()
	_disable_piece_interaction()

	if _background_sound != null:
		_background_sound.stop()

	if did_win:
		game_won.emit()

		if (
			_game_result != null
			and _game_result.has_method(
				"mostrar_ganaste"
			)
		):
			_game_result.call(
				"mostrar_ganaste"
			)
	else:
		game_lost.emit()

		if (
			_game_result != null
			and _game_result.has_method(
				"mostrar_perdiste"
			)
		):
			_game_result.call(
				"mostrar_perdiste"
			)


func _stop_timer() -> void:
	if _timer_ui == null:
		return

	if _timer_ui.has_method("detener"):
		_timer_ui.call("detener")


func _cancel_active_piece() -> void:
	if _active_piece == null:
		return

	if is_instance_valid(_active_piece):
		if _active_piece.has_method(
			"cancel_piece"
		):
			_active_piece.call(
				"cancel_piece"
			)
		else:
			_active_piece.queue_free()

	_active_piece = null


func _disable_piece_interaction() -> void:
	for child: Node in _piece_panel.get_children():
		if child is Area2D:
			var palette_piece: Area2D = (
				child as Area2D
			)

			palette_piece.input_pickable = false

	for child: Node in _placed_pieces.get_children():
		if child is Area2D:
			var board_piece: Area2D = (
				child as Area2D
			)

			board_piece.input_pickable = false


func _play_piece_sound() -> void:
	if _piece_sound == null:
		return

	_piece_sound.stop()
	_piece_sound.play()
