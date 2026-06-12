extends Node2D
class_name MedicalKitMinigame


const TIMER_HUD_SCENE = preload("res://ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/GameResult.tscn")


@export var time_limit := 30.0
@export var max_errors := 3


var total_items := 0
var placed_items := 0
var errors := 0
var game_active := false
var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer
var errors_panel: PanelContainer


@onready var targets = get_node_or_null("Targets")
@onready var items = get_node_or_null("Items")
@onready var canvas_layer = get_node_or_null("CanvasLayer")
@onready var errors_label = get_node_or_null("CanvasLayer/ErrorsLabel")
@onready var back_button = get_node_or_null("CanvasLayer/BackButton")
@onready var background_sound = get_node_or_null("BackgroundSound")
@onready var piece_placed_sound = get_node_or_null("PiecePlacedSound")


func _ready():
	_setup_game_state()
	_setup_timer_hud()
	_setup_result_panel()
	_setup_errors_panel()
	_setup_audio()

	if not _has_required_nodes():
		return

	_connect_items()
	_connect_back_button()
	_update_errors_label()
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

	# Más ancho para que no se corte el texto.
	timer_hud.set_tamano_panel(720, 60)


func _setup_result_panel():
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)


func _setup_errors_panel():
	if canvas_layer == null:
		print("No se encontró CanvasLayer")
		return

	if errors_label == null:
		print("No se encontró CanvasLayer/ErrorsLabel")
		return

	errors_panel = PanelContainer.new()
	errors_panel.name = "ErrorsPanel"
	errors_panel.position = Vector2(20, 85)
	errors_panel.custom_minimum_size = Vector2(230, 52)
	canvas_layer.add_child(errors_panel)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.93, 0.78, 0.56, 0.95)
	panel_style.border_color = Color(0.90, 0.47, 0.20, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin(SIDE_LEFT, 16)
	panel_style.set_content_margin(SIDE_RIGHT, 16)
	panel_style.set_content_margin(SIDE_TOP, 8)
	panel_style.set_content_margin(SIDE_BOTTOM, 8)

	errors_panel.add_theme_stylebox_override("panel", panel_style)

	var old_parent = errors_label.get_parent()
	old_parent.remove_child(errors_label)
	errors_panel.add_child(errors_label)

	errors_label.text = "Errores: 0/3"
	errors_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	errors_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	errors_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	errors_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	errors_label.add_theme_font_size_override("font_size", 24)
	errors_label.add_theme_color_override("font_color", Color(0.12, 0.30, 0.52, 1.0))


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
	_update_errors_label()

	item.return_to_start()

	if errors >= max_errors:
		_lose_game()


func _update_errors_label():
	if errors_label != null:
		errors_label.text = "Errores: " + str(errors) + "/" + str(max_errors)


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
