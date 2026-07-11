extends Node2D
class_name MedicalKitMinigame


const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")


@export_category("Configuración del juego")
@export var TOTAL_TIME: float = 30.0
@export var max_errors := 3

@export_category("Animación de apertura")
@export var lid_open_distance := 320.0
@export var lid_open_duration := 0.85
@export var open_kit_reveal_offset := 55.0
@export var open_kit_reveal_delay := 0.15

@export_category("Posiciones aleatorias")
@export var randomize_item_positions := true


var _total_items := 0
var _placed_items := 0
var _errors := 0

var _game_active := false
var _kit_opened := false
var _opened_locks := 0

var _timer_hud
var _panel_resultado
var _lives_ui: LivesUi

var _closed_kit_start_position := Vector2.ZERO
var _closed_kit_start_scale := Vector2.ONE

var _kit_start_position := Vector2.ZERO
var _kit_start_scale := Vector2.ONE

var _open_lid_start_position := Vector2.ZERO
var _open_lid_start_scale := Vector2.ONE

var _random := RandomNumberGenerator.new()


@onready var _kit: Sprite2D = get_node_or_null("kit") as Sprite2D
@onready var _open_lid: Sprite2D = get_node_or_null("OpenLid") as Sprite2D

@onready var _targets: Node2D = get_node_or_null("Targets") as Node2D
@onready var _items: Node2D = get_node_or_null("Items") as Node2D
@onready var _placed_items_node: Node2D = get_node_or_null(
	"PlacedItems"
) as Node2D

@onready var _closed_kit: Node2D = get_node_or_null(
	"ClosedKit"
) as Node2D

@onready var _lock_left: KitLock = get_node_or_null(
	"ClosedKit/LockLeft"
) as KitLock

@onready var _lock_right: KitLock = get_node_or_null(
	"ClosedKit/LockRight"
) as KitLock

@onready var _errors_label: Label = get_node_or_null(
	"CanvasLayer/ErrorsLabel"
) as Label

@onready var _back_button: Button = get_node_or_null(
	"CanvasLayer/BackButton"
) as Button

@onready var _background_sound: AudioStreamPlayer = get_node_or_null(
	"BackgroundSound"
) as AudioStreamPlayer

@onready var _piece_placed_sound: AudioStreamPlayer = get_node_or_null(
	"PiecePlacedSound"
) as AudioStreamPlayer

@onready var _lock_sound: AudioStreamPlayer = get_node_or_null(
	"LockSound"
) as AudioStreamPlayer


func _ready():
	_random.randomize()

	_setup_game_state()
	_setup_timer_hud()
	_setup_result_panel()
	_setup_lives_ui()
	_setup_audio()

	if not _has_required_nodes():
		return

	if randomize_item_positions:
		_randomize_item_positions()

	_save_initial_transforms()
	_connect_items()
	_connect_locks()
	_connect_back_button()
	_prepare_closed_kit()


func _setup_game_state():
	_total_items = 0
	_placed_items = 0
	_errors = 0
	_opened_locks = 0

	_game_active = false
	_kit_opened = false


func _setup_timer_hud():
	_timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(_timer_hud)

	_timer_hud.time_up.connect(_on_time_finished)
	_timer_hud.set_tamano_panel(720, 60)

	if _timer_hud.has_method("ocultar"):
		_timer_hud.ocultar()


func _setup_result_panel():
	_panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(_panel_resultado)


func _setup_lives_ui():
	if _errors_label != null:
		_errors_label.visible = false

	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	_lives_ui.set_max_lives(max_errors)
	_lives_ui.set_panel_corner(LivesUi.PanelCorner.TOP_RIGHT)
	_lives_ui.set_panel_margin(Vector2(35, 20))
	_lives_ui.actualizar_vidas(max_errors)
	_lives_ui.visible = false


func _setup_audio():
	if _background_sound == null:
		print("No se encontró BackgroundSound")

	if _piece_placed_sound == null:
		print("No se encontró PiecePlacedSound")

	if _lock_sound == null:
		print("No se encontró LockSound")


func _has_required_nodes() -> bool:
	if _kit == null:
		print("No se encontró el nodo kit")
		return false

	if _open_lid == null:
		print("No se encontró el nodo OpenLid")
		return false

	if _targets == null:
		print("No se encontró el nodo Targets")
		return false

	if _items == null:
		print("No se encontró el nodo Items")
		return false

	if _closed_kit == null:
		print("No se encontró el nodo ClosedKit")
		return false

	if _lock_left == null:
		print("No se encontró ClosedKit/LockLeft")
		return false

	if _lock_right == null:
		print("No se encontró ClosedKit/LockRight")
		return false

	return true


func _randomize_item_positions():
	var draggable_items: Array[DraggableItem] = []
	var available_positions: Array[Vector2] = []

	for child in _items.get_children():
		if child is DraggableItem:
			var item := child as DraggableItem
			draggable_items.append(item)
			available_positions.append(item.position)

	_shuffle_positions(available_positions)

	for index in range(draggable_items.size()):
		var item := draggable_items[index]
		item.position = available_positions[index]
		_update_item_start_position(item)


func _shuffle_positions(positions: Array[Vector2]):
	for index in range(positions.size() - 1, 0, -1):
		var random_index := _random.randi_range(0, index)
		var temporary_position := positions[index]
		positions[index] = positions[random_index]
		positions[random_index] = temporary_position


func _update_item_start_position(item: DraggableItem):
	# Compatibilidad con diferentes versiones de DraggableItem.
	# Esto garantiza que return_to_start() regrese a la nueva posición aleatoria.
	var method_names := [
		"set_start_position",
		"set_initial_position",
		"save_start_position",
		"guardar_posicion_inicial"
	]

	for method_name in method_names:
		if item.has_method(method_name):
			if method_name == "save_start_position" or method_name == "guardar_posicion_inicial":
				item.call(method_name)
			else:
				item.call(method_name, item.position)
			return

	var possible_property_names := [
		"start_position",
		"_start_position",
		"initial_position",
		"_initial_position",
		"original_position",
		"_original_position"
	]

	var available_properties := {}
	for property_data in item.get_property_list():
		available_properties[String(property_data.name)] = true

	for property_name in possible_property_names:
		if available_properties.has(property_name):
			item.set(property_name, item.position)
			return


func _save_initial_transforms():
	_closed_kit_start_position = _closed_kit.position
	_closed_kit_start_scale = _closed_kit.scale

	_kit_start_position = _kit.position
	_kit_start_scale = _kit.scale

	_open_lid_start_position = _open_lid.position
	_open_lid_start_scale = _open_lid.scale


func _connect_items():
	for item in _items.get_children():
		if item is DraggableItem:
			_total_items += 1
			item.item_dropped.connect(_on_item_dropped)

	if _total_items == 0:
		print("No hay DraggableItem dentro del nodo Items")


func _connect_locks():
	_lock_left.lock_opened.connect(_on_lock_opened)
	_lock_right.lock_opened.connect(_on_lock_opened)


func _connect_back_button():
	if _back_button != null:
		_back_button.pressed.connect(_on_back_button_pressed)
	else:
		print(
			"No se encontró CanvasLayer/BackButton, " +
			"pero el juego puede continuar."
		)


func _prepare_closed_kit():
	_game_active = false
	_kit_opened = false
	_opened_locks = 0

	_kit.visible = false
	_kit.position = _kit_start_position
	_kit.scale = _kit_start_scale
	_kit.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_open_lid.visible = false
	_open_lid.position = _open_lid_start_position
	_open_lid.scale = _open_lid_start_scale
	_open_lid.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_items.visible = false

	if _placed_items_node != null:
		_placed_items_node.visible = false

	_closed_kit.visible = true
	_closed_kit.position = _closed_kit_start_position
	_closed_kit.scale = _closed_kit_start_scale
	_closed_kit.modulate = Color.WHITE

	_play_background_sound()


func _on_lock_opened(_lock_node: KitLock):
	if _kit_opened:
		return

	_play_lock_sound()

	_opened_locks += 1

	if _opened_locks >= 2:
		_open_kit()


func _open_kit():
	if _kit_opened:
		return

	_kit_opened = true

	await get_tree().create_timer(0.35).timeout

	if _closed_kit == null:
		_finish_opening_kit()
		return

	_kit.visible = true
	_kit.position = _kit_start_position + Vector2(
		0.0,
		open_kit_reveal_offset
	)
	_kit.scale = _kit_start_scale * 0.96
	_kit.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_open_lid.visible = true
	_open_lid.position = _open_lid_start_position + Vector2(
		0.0,
		open_kit_reveal_offset
	)
	_open_lid.scale = _open_lid_start_scale * 0.96
	_open_lid.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		_closed_kit,
		"position",
		_closed_kit_start_position + Vector2(
			0.0,
			-lid_open_distance
		),
		lid_open_duration
	)

	tween.parallel().tween_property(
		_closed_kit,
		"scale",
		Vector2(
			_closed_kit_start_scale.x * 1.02,
			_closed_kit_start_scale.y * 0.82
		),
		lid_open_duration
	)

	tween.parallel().tween_property(
		_closed_kit,
		"modulate:a",
		0.0,
		lid_open_duration * 0.75
	).set_delay(lid_open_duration * 0.25)

	tween.parallel().tween_property(
		_kit,
		"position",
		_kit_start_position,
		lid_open_duration * 0.70
	).set_delay(open_kit_reveal_delay)

	tween.parallel().tween_property(
		_kit,
		"scale",
		_kit_start_scale,
		lid_open_duration * 0.70
	).set_delay(open_kit_reveal_delay)

	tween.parallel().tween_property(
		_kit,
		"modulate:a",
		1.0,
		lid_open_duration * 0.65
	).set_delay(open_kit_reveal_delay)

	tween.parallel().tween_property(
		_open_lid,
		"position",
		_open_lid_start_position,
		lid_open_duration * 0.70
	).set_delay(open_kit_reveal_delay)

	tween.parallel().tween_property(
		_open_lid,
		"scale",
		_open_lid_start_scale,
		lid_open_duration * 0.70
	).set_delay(open_kit_reveal_delay)

	tween.parallel().tween_property(
		_open_lid,
		"modulate:a",
		1.0,
		lid_open_duration * 0.65
	).set_delay(open_kit_reveal_delay)

	await tween.finished

	_finish_opening_kit()


func _finish_opening_kit():
	_closed_kit.visible = false
	_closed_kit.position = _closed_kit_start_position
	_closed_kit.scale = _closed_kit_start_scale
	_closed_kit.modulate = Color.WHITE

	_kit.visible = true
	_kit.position = _kit_start_position
	_kit.scale = _kit_start_scale
	_kit.modulate = Color.WHITE

	_open_lid.visible = true
	_open_lid.position = _open_lid_start_position
	_open_lid.scale = _open_lid_start_scale
	_open_lid.modulate = Color.WHITE

	_items.visible = true

	if _placed_items_node != null:
		_placed_items_node.visible = true

	if _lives_ui != null:
		_lives_ui.visible = true

	_start_game()



func _start_game():
	_game_active = true

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 30.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 30.0

	if _timer_hud != null:
		_timer_hud.iniciar(
			TOTAL_TIME,
			"Tiempo restante",
			"para ordenar el botiquín"
		)




func _on_item_dropped(item: DraggableItem):
	if not _game_active:
		return

	var correct_target := _get_correct_target(item)

	if correct_target != null:
		_place_item(item, correct_target)
	else:
		_register_error(item)


func _get_correct_target(item: DraggableItem) -> TargetSlot:
	var overlapping_areas := item.get_overlapping_areas()

	for area in overlapping_areas:
		if area is TargetSlot:
			var target := area as TargetSlot

			if target.occupied:
				continue

			if target.slot_id == item.item_id:
				return target

	return null


func _place_item(item: DraggableItem, target: TargetSlot):
	target.occupied = true
	target.show_placed_item()

	_play_piece_placed_sound()

	item.remove_from_game()
	_placed_items += 1

	if _placed_items >= _total_items:
		_win_game()


func _register_error(item: DraggableItem):
	_errors += 1
	_update_lives_ui()

	item.return_to_start()

	if _errors >= max_errors:
		_lose_game()


func _update_lives_ui():
	if _lives_ui == null:
		return

	var remaining_lives := max_errors - _errors
	_lives_ui.actualizar_vidas(remaining_lives)


func _play_background_sound():
	if _background_sound == null:
		return

	if not _background_sound.playing:
		_background_sound.play()


func _stop_background_sound():
	if _background_sound != null:
		_background_sound.stop()


func _play_piece_placed_sound():
	if _piece_placed_sound != null:
		_piece_placed_sound.stop()
		_piece_placed_sound.play()


func _play_lock_sound():
	if _lock_sound != null:
		_lock_sound.stop()
		_lock_sound.play()


func _on_time_finished():
	if _game_active:
		_lose_game()


func _win_game():
	if not _game_active:
		return

	_game_active = false

	_lock_all_items()
	_stop_background_sound()

	if _timer_hud != null:
		_timer_hud.detener()

	if _panel_resultado != null:
		_panel_resultado.mostrar_ganaste()


func _lose_game():
	if not _game_active:
		return

	_game_active = false

	_lock_all_items()
	_stop_background_sound()

	if _timer_hud != null:
		_timer_hud.detener()

	if _panel_resultado != null:
		_panel_resultado.mostrar_perdiste()


func _lock_all_items():
	if _items == null:
		return

	for item in _items.get_children():
		if item is DraggableItem:
			item.locked = true


func _on_back_button_pressed():
	_game_active = false

	_stop_background_sound()

	if _lock_sound != null:
		_lock_sound.stop()

	if _timer_hud != null:
		_timer_hud.detener()

	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")


# =========================================================
# TIME BONUS POR EDAD
# =========================================================
func _get_time_bonus(age: int) -> float:
	match age:
		11:
			return 2.0
		10:
			return 3.0
		9:
			return 5.0
		8:
			return 7.0
		7:
			return 10.0
		_:
			return 10.0 if age < 7 else 0.0
