extends Node2D


# =========================================================
# PATHS
# =========================================================

const BACKGROUND_PATH := "res://Minigames/minigame_bridge/assets/background.png"

const BRIDGE_BOARD_SCENE_PATH := "res://Minigames/minigame_bridge/BridgeBoard.tscn"
const BRIDGE_SLOT_SCENE_PATH := "res://Minigames/minigame_bridge/BridgeSlot.tscn"

const TIMER_UI_SCENE_PATH := "res://Minigames/ui_global/TimerUI.tscn"
const GAME_RESULT_SCENE_PATH := "res://Minigames/ui_global/GameResult.tscn"

const BOARD_TEXTURES := {
	1: "res://Minigames/minigame_bridge/assets/boards/board_1.png",
	2: "res://Minigames/minigame_bridge/assets/boards/board_2.png",
	3: "res://Minigames/minigame_bridge/assets/boards/board_3.png",
	4: "res://Minigames/minigame_bridge/assets/boards/board_4.png",
}


# =========================================================
# GAME SETTINGS
# =========================================================

const TOTAL_TIME := 40.0
const TOTAL_BOARDS := 4

const DROP_DISTANCE := 80.0

const BOARD_SCALE := Vector2(0.42, 0.42)
const SLOT_SCALE := Vector2(0.42, 0.42)


# =========================================================
# COLORS
# =========================================================

const C_BEIGE := Color("#E5C89E")
const C_ORANGE := Color("#E0B080")
const C_BLUE := Color("#3E5F8F")
const C_PHASE_BLUE := Color("#3E5F8F")
const C_PHASE_ORANGE := Color("#E07820")
const C_PHASE_RED := Color("#D63A3A")


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var background: Sprite2D = $Background
@onready var river_water: Node2D = $RiverWater
@onready var slots_parent: Node2D = $Slots
@onready var boards_parent: Node2D = $Boards

@onready var hud: CanvasLayer = $HUD
@onready var board_label: Label = $HUD/BoardLabel


# =========================================================
# VARIABLES
# =========================================================

var timer_ui = null
var game_result = null

var rng := RandomNumberGenerator.new()

var slots: Array = []
var boards: Array = []

var placed_boards := 0
var game_started := false
var game_over := false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	rng.randomize()
	randomize()
	
	_setup_background()
	_setup_timer_ui()
	_setup_game_result()
	_setup_ui()
	
	call_deferred("_start_game")


func _process(_delta):
	if not game_started:
		return
	
	if game_over:
		return
	
	_update_hud()


# =========================================================
# BACKGROUND
# =========================================================

func _setup_background():
	if not background:
		return
	
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH)
	
	background.position = get_viewport_rect().size / 2
	background.z_index = -20
	
	var screen_size := get_viewport_rect().size
	
	if background.texture:
		var texture_size := background.texture.get_size()
		var scale_x := screen_size.x / texture_size.x
		var scale_y := screen_size.y / texture_size.y
		var final_scale = max(scale_x, scale_y)
		
		background.scale = Vector2(final_scale, final_scale)


# =========================================================
# TIMER UI GLOBAL
# =========================================================

func _setup_timer_ui():
	if ResourceLoader.exists(TIMER_UI_SCENE_PATH):
		var timer_scene = load(TIMER_UI_SCENE_PATH)
		timer_ui = timer_scene.instantiate()
		timer_ui.name = "TimerUI"
		add_child(timer_ui)
	else:
		push_error("No se encontró TimerUI en: " + TIMER_UI_SCENE_PATH)
		return
	
	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)
	
	if timer_ui.has_method("ocultar"):
		timer_ui.ocultar()


func _start_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("set_tamano_panel"):
		timer_ui.set_tamano_panel(650, 60)
	
	if timer_ui.has_method("iniciar"):
		timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para reparar el puente")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# GAME RESULT GLOBAL
# =========================================================

func _setup_game_result():
	if ResourceLoader.exists(GAME_RESULT_SCENE_PATH):
		var result_scene = load(GAME_RESULT_SCENE_PATH)
		game_result = result_scene.instantiate()
		game_result.name = "GameResult"
		add_child(game_result)
	else:
		push_error("No se encontró GameResult.tscn en: " + GAME_RESULT_SCENE_PATH)


# =========================================================
# UI
# =========================================================

func _setup_ui():
	if not hud or not board_label:
		return
	
	if hud.has_node("BoardCounterPanel"):
		return
	
	var counter_panel := Panel.new()
	counter_panel.name = "BoardCounterPanel"
	counter_panel.position = Vector2(30, 95)
	counter_panel.size = Vector2(330, 46)
	counter_panel.z_index = 100
	counter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = C_BEIGE
	style.border_color = C_ORANGE
	
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	
	counter_panel.add_theme_stylebox_override("panel", style)
	hud.add_child(counter_panel)
	
	if board_label.get_parent():
		board_label.get_parent().remove_child(board_label)
	
	counter_panel.add_child(board_label)
	
	board_label.position = Vector2.ZERO
	board_label.size = counter_panel.size
	board_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	board_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	board_label.add_theme_font_size_override("font_size", 22)
	board_label.add_theme_color_override("font_color", C_BLUE)
	
	_update_hud()


func _update_hud():
	if board_label:
		board_label.text = "Tablas colocadas: " + str(placed_boards) + "/" + str(TOTAL_BOARDS)
		board_label.add_theme_color_override("font_color", _get_counter_color())


func _get_counter_color() -> Color:
	if not timer_ui:
		return C_PHASE_BLUE
	
	if not timer_ui.has_method("get_remaining_time"):
		return C_PHASE_BLUE
	
	var remaining_time: float = timer_ui.get_remaining_time()
	var fraction: float = remaining_time / TOTAL_TIME
	
	if fraction > 0.5:
		return C_PHASE_BLUE
	elif fraction > 0.25:
		return C_PHASE_ORANGE
	else:
		return C_PHASE_RED


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false
	placed_boards = 0
	
	_clear_round()
	_create_random_slots()
	_create_boards()
	
	_start_global_timer()
	_update_hud()


func _clear_round():
	for child in slots_parent.get_children():
		child.queue_free()
	
	for child in boards_parent.get_children():
		child.queue_free()
	
	slots.clear()
	boards.clear()


# =========================================================
# CREATE SLOTS AND BOARDS
# =========================================================

func _create_random_slots():
	if not ResourceLoader.exists(BRIDGE_SLOT_SCENE_PATH):
		push_error("No se encontró BridgeSlot.tscn")
		return
	
	var slot_scene = load(BRIDGE_SLOT_SCENE_PATH)
	var screen_size := get_viewport_rect().size
	
	# Estas son posiciones posibles en el puente.
	# Cada partida se escogen 4 aleatorias.
	var possible_positions := [
		Vector2(screen_size.x * 0.31, screen_size.y * 0.48),
		Vector2(screen_size.x * 0.40, screen_size.y * 0.51),
		Vector2(screen_size.x * 0.49, screen_size.y * 0.47),
		Vector2(screen_size.x * 0.58, screen_size.y * 0.51),
		Vector2(screen_size.x * 0.45, screen_size.y * 0.61),
		Vector2(screen_size.x * 0.55, screen_size.y * 0.61),
		Vector2(screen_size.x * 0.36, screen_size.y * 0.59),
		Vector2(screen_size.x * 0.64, screen_size.y * 0.59)
	]
	
	possible_positions.shuffle()
	
	var board_ids := [1, 2, 3, 4]
	board_ids.shuffle()
	
	for i in range(TOTAL_BOARDS):
		var board_id: int = board_ids[i]
		var slot_position: Vector2 = possible_positions[i]
		
		var slot = slot_scene.instantiate()
		slots_parent.add_child(slot)
		
		slot.setup(board_id, BOARD_TEXTURES[board_id], slot_position, SLOT_SCALE)
		slots.append(slot)


func _create_boards():
	if not ResourceLoader.exists(BRIDGE_BOARD_SCENE_PATH):
		push_error("No se encontró BridgeBoard.tscn")
		return
	
	var board_scene = load(BRIDGE_BOARD_SCENE_PATH)
	var screen_size := get_viewport_rect().size
	
	var board_ids := []
	
	for slot in slots:
		board_ids.append(slot.board_id)
	
	board_ids.shuffle()
	
	var spacing := 145.0
	var total_width := spacing * float(board_ids.size() - 1)
	var start_x := screen_size.x * 0.5 - total_width * 0.5
	var start_y := screen_size.y - 95.0
	
	for i in range(board_ids.size()):
		var board_id: int = board_ids[i]
		var board_position := Vector2(start_x + spacing * i, start_y)
		
		var board = board_scene.instantiate()
		boards_parent.add_child(board)
		
		board.setup(board_id, BOARD_TEXTURES[board_id], board_position, BOARD_SCALE)
		
		if board.has_signal("dropped"):
			if not board.dropped.is_connected(_on_board_dropped):
				board.dropped.connect(_on_board_dropped)
		
		boards.append(board)


# =========================================================
# DROP LOGIC
# =========================================================

func _on_board_dropped(board):
	if game_over:
		return
	
	var target_slot = _get_matching_slot_for_board(board)
	
	if target_slot:
		target_slot.place_board()
		board.lock_to_position(target_slot.global_position)
		board.set_correct_feedback()
		
		placed_boards += 1
		_update_hud()
		
		if placed_boards >= TOTAL_BOARDS:
			_win_game()
	else:
		var wrong_slot = _get_nearest_slot(board.global_position)
		
		if wrong_slot:
			wrong_slot.highlight_wrong()
			await get_tree().create_timer(0.20).timeout
			wrong_slot.clear_highlight()
		
		board.set_wrong_feedback()
		board.return_to_start()


func _get_matching_slot_for_board(board):
	for slot in slots:
		if not slot.can_accept(board.board_id):
			continue
		
		var distance: float = board.global_position.distance_to(slot.global_position)
		
		if distance <= DROP_DISTANCE:
			return slot
	
	return null


func _get_nearest_slot(position_to_check: Vector2):
	var nearest_slot = null
	var nearest_distance: float = 999999.0
	
	for slot in slots:
		if slot.occupied:
			continue
		
		var distance: float = position_to_check.distance_to(slot.global_position)
		
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_slot = slot
	
	if nearest_distance <= DROP_DISTANCE:
		return nearest_slot
	
	return null


# =========================================================
# WIN / LOSE
# =========================================================

func _on_time_up():
	if game_over:
		return
	
	_lose_game()


func _win_game():
	if game_over:
		return
	
	game_over = true
	game_started = false
	
	_stop_global_timer()
	_disable_boards()
	
	if game_result:
		if game_result.has_method("show_win"):
			game_result.show_win()
		elif game_result.has_method("mostrar_ganaste"):
			game_result.mostrar_ganaste()


func _lose_game():
	if game_over:
		return
	
	game_over = true
	game_started = false
	
	_stop_global_timer()
	_disable_boards()
	
	if game_result:
		if game_result.has_method("show_lose"):
			game_result.show_lose()
		elif game_result.has_method("mostrar_perdiste"):
			game_result.mostrar_perdiste()


func _disable_boards():
	for board in boards:
		board.locked = true
