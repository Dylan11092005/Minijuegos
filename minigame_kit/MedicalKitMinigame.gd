extends Node2D
class_name MedicalKitMinigame


const TIMER_HUD_SCENE = preload("res://ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://ui_global/LivesUi.tscn")


@export var time_limit := 30.0
@export var max_errors := 3


var total_items := 0
var placed_items := 0
var errors := 0
var game_active := false
var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer
var lives_ui: LivesUi


@onready var targets = get_node_or_null("Targets")
@onready var items = get_node_or_null("Items")
@onready var errors_label = get_node_or_null("CanvasLayer/ErrorsLabel")
@onready var back_button = get_node_or_null("CanvasLayer/BackButton")
@onready var background_sound = get_node_or_null("BackgroundSound")
@onready var piece_placed_sound = get_node_or_null("PiecePlacedSound")


func _ready():
	_setup_game_state()
	_setup_timer_hud()
	_setup_result_panel()
	_setup_lives_ui()
	_setup_audio()

	if not _has_required_nodes():
		return

	_connect_items()
	_connect_back_button()
	_update_lives_ui()
	_play_background_sound()
	_start_game()


func _setup_game_state():
	game_active = false
	errors = 0
	placed_items = 0
	total_items = 0


func _setup_timer_hud():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	timer_hud.time_up.connect(_on_time_finished)
	timer_hud.set_tamano_panel(720, 60)


func _setup_result_panel():
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)


func _setup_lives_ui():
	if errors_label != null:
		errors_label.visible = false

	lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(lives_ui)

	lives_ui.set_max_lives(max_errors)
	lives_ui.set_panel_corner(LivesUi.PanelCorner.TOP_RIGHT)
	lives_ui.set_panel_margin(Vector2(35, 20))
	lives_ui.actualizar_vidas(max_errors)


func _setup_audio():
	if background_sound == null:
		print("No se encontró BackgroundSound")

	if piece_placed_sound == null:
		print("No se encontró PiecePlacedSound")


func _has_required_nodes() -> bool:
	if targets == null:
		print("No se encontró el nodo Targets")
		return false

	if items == null:
		print("No se encontró el nodo Items")
		return false

	return true


func _connect_items():
	for item in items.get_children():
		if item is DraggableItem:
			total_items += 1
			item.item_dropped.connect(_on_item_dropped)

	if total_items == 0:
		print("No hay DraggableItem dentro del nodo Items")


func _connect_back_button():
	if back_button != null:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton")


func _start_game():
	game_active = true

	if timer_hud != null:
		timer_hud.iniciar(time_limit, "Tiempo restante", "para ordenar el botiquín")


func _on_item_dropped(item: DraggableItem):
	if not game_active:
		return

	var correct_target = _get_correct_target(item)

	if correct_target != null:
		_place_item(item, correct_target)
	else:
		_register_error(item)


func _get_correct_target(item: DraggableItem) -> TargetSlot:
	var overlapping_areas = item.get_overlapping_areas()

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

	placed_items += 1

	if placed_items >= total_items:
		_win_game()


func _register_error(item: DraggableItem):
	errors += 1
	_update_lives_ui()

	item.return_to_start()

	if errors >= max_errors:
		_lose_game()


func _update_lives_ui():
	if lives_ui == null:
		return

	var remaining_lives = max_errors - errors
	lives_ui.actualizar_vidas(remaining_lives)


func _play_background_sound():
	if background_sound != null:
		background_sound.play()


func _stop_background_sound():
	if background_sound != null:
		background_sound.stop()


func _play_piece_placed_sound():
	if piece_placed_sound != null:
		piece_placed_sound.stop()
		piece_placed_sound.play()


func _on_time_finished():
	if game_active:
		_lose_game()


func _win_game():
	game_active = false
	_lock_all_items()
	_stop_background_sound()

	if timer_hud != null:
		timer_hud.detener()

	if panel_resultado != null:
		panel_resultado.mostrar_ganaste()


func _lose_game():
	game_active = false
	_lock_all_items()
	_stop_background_sound()

	if timer_hud != null:
		timer_hud.detener()

	if panel_resultado != null:
		panel_resultado.mostrar_perdiste()


func _lock_all_items():
	if items == null:
		return

	for item in items.get_children():
		if item is DraggableItem:
			item.locked = true


func _on_back_button_pressed():
	_stop_background_sound()

	if timer_hud != null:
		timer_hud.detener()

	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
