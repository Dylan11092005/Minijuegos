extends Node2D


# =========================================================
# PATHS
# =========================================================

const BACKGROUND_BROKEN_PATH := "res://Minigames/minigame_bridge/assets/background.png"
const BACKGROUND_FIXED_PATH := "res://Minigames/minigame_bridge/assets/background_fixed.png"
const HAMMER_PATH := "res://Minigames/minigame_bridge/assets/hammer.png"

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
const TOTAL_BOARDS := 6

const DROP_DISTANCE := 115.0

const BOARD_SCALE := Vector2(0.38, 0.38)
const SLOT_SCALE := Vector2(0.38, 0.38)

const HAMMER_SCALE := Vector2(0.23, 0.23)
const HAMMER_PICK_RADIUS := 95.0
const HAMMER_HIT_RADIUS := 85.0


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
@onready var hammer: Sprite2D = get_node_or_null("Hammer")

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

var placed_boards: int = 0
var game_started: bool = false
var game_over: bool = false

var hammer_phase: bool = false
var hammer_dragging: bool = false
var hammer_hit_busy: bool = false

var hammer_offset: Vector2 = Vector2.ZERO
var hammer_hits: Array = []
var hammer_hit_positions: Array = []
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	rng.randomize()
	randomize()
	
	_remove_old_bridge_layers()
	_setup_background()
	_setup_hammer()
	_setup_fade_overlay()
	_setup_timer_ui()
	_setup_game_result()
	_setup_ui()
	
	call_deferred("_start_game")


func _process(_delta):
	if not game_started:
		return
	
	if game_over:
		return
	
	if hammer_phase and hammer_dragging and not hammer_hit_busy:
		_check_hammer_hits()
	
	_update_hud()


func _input(event):
	if game_over:
		return
	
	if not hammer_phase:
		return
	
	if not hammer:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_start_hammer_drag()
			else:
				_stop_hammer_drag()
	
	if event is InputEventMouseMotion:
		if hammer_dragging:
			hammer.global_position = get_global_mouse_position() + hammer_offset
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_try_start_hammer_drag()
		else:
			_stop_hammer_drag()
	
	if event is InputEventScreenDrag:
		if hammer_dragging:
			hammer.global_position = event.position + hammer_offset


# =========================================================
# CLEANUP
# =========================================================

func _remove_old_bridge_layers():
	var old_nodes := [
		"RepairLayer",
		"BridgeLayer",
		"BridgeFixed",
		"BridgeBroken",
		"BridgeSprite"
	]
	
	for node_name in old_nodes:
		var old_node = get_node_or_null(node_name)
		
		if old_node:
			old_node.queue_free()


# =========================================================
# BACKGROUND
# =========================================================

func _setup_background():
	if not background:
		return
	
	background.position = get_viewport_rect().size / 2
	background.z_index = -20
	
	_set_background(BACKGROUND_BROKEN_PATH)


func _set_background(path: String):
	if not background:
		return
	
	if not ResourceLoader.exists(path):
		push_error("No se encontró el fondo: " + path)
		return
	
	background.texture = load(path)
	
	var screen_size: Vector2 = get_viewport_rect().size
	
	if background.texture:
		var texture_size: Vector2 = background.texture.get_size()
		var scale_x: float = screen_size.x / texture_size.x
		var scale_y: float = screen_size.y / texture_size.y
		var final_scale: float = max(scale_x, scale_y)
		
		background.scale = Vector2(final_scale, final_scale)
		background.position = screen_size / 2


# =========================================================
# HAMMER
# =========================================================

func _setup_hammer():
	hammer = get_node_or_null("Hammer")
	
	if not hammer:
		hammer = Sprite2D.new()
		hammer.name = "Hammer"
		add_child(hammer)
	
	if ResourceLoader.exists(HAMMER_PATH):
		hammer.texture = load(HAMMER_PATH)
	else:
		push_error("No se encontró hammer.png en: " + HAMMER_PATH)
	
	hammer.visible = false
	hammer.z_index = 150
	hammer.scale = HAMMER_SCALE
	hammer.rotation_degrees = -35


func _start_hammer_phase():
	hammer_phase = true
	hammer_dragging = false
	hammer_hit_busy = false
	hammer_hits = [false, false, false, false, false, false]
	
	_stop_global_timer()
	
	for board in boards:
		board.locked = true
	
	for slot in slots:
		slot.visible = false
	
	var screen_size: Vector2 = get_viewport_rect().size
	
	hammer_hit_positions = [
		Vector2(screen_size.x * 0.32, screen_size.y * 0.46),
		Vector2(screen_size.x * 0.395, screen_size.y * 0.46),
		Vector2(screen_size.x * 0.46, screen_size.y * 0.46),
		Vector2(screen_size.x * 0.525, screen_size.y * 0.46),
		Vector2(screen_size.x * 0.59, screen_size.y * 0.46),
		Vector2(screen_size.x * 0.655, screen_size.y * 0.46),
	]
	
	if hammer:
		hammer.visible = true
	hammer.global_position = Vector2(screen_size.x * 0.50, screen_size.y * 0.92)
	hammer.rotation_degrees = -35
	hammer.scale = Vector2.ZERO
	hammer.z_index = 150

	var hammer_intro := create_tween()
	hammer_intro.set_ease(Tween.EASE_OUT)
	hammer_intro.set_trans(Tween.TRANS_BACK)
	hammer_intro.tween_property(hammer, "global_position", Vector2(screen_size.x * 0.50, screen_size.y * 0.86), 0.35)
	hammer_intro.parallel().tween_property(hammer, "scale", HAMMER_SCALE, 0.35)
	
	_update_hud()


func _try_start_hammer_drag():
	if not hammer:
		return
	
	var mouse_position: Vector2 = get_global_mouse_position()
	var distance: float = mouse_position.distance_to(hammer.global_position)
	
	if distance <= HAMMER_PICK_RADIUS:
		hammer_dragging = true
		hammer_offset = hammer.global_position - mouse_position
		hammer.z_index = 180


func _stop_hammer_drag():
	hammer_dragging = false
	
	if hammer:
		hammer.z_index = 150


func _check_hammer_hits():
	if not hammer:
		return
	
	for i in range(hammer_hit_positions.size()):
		if hammer_hits[i]:
			continue
		
		var hit_position: Vector2 = hammer_hit_positions[i]
		var distance: float = hammer.global_position.distance_to(hit_position)
		
		if distance <= HAMMER_HIT_RADIUS:
			hammer_hits[i] = true
			await _hammer_hit_effect(hit_position)
			_check_all_hammer_hits()
			return


func _hammer_hit_effect(hit_position: Vector2):
	if not hammer:
		return
	
	hammer_hit_busy = true
	
	var start_position := hit_position + Vector2(-45, -95)
	var hit_down_position := hit_position + Vector2(-8, -45)
	var back_position := hit_position + Vector2(-42, -88)
	
	var tween := create_tween()
	
	# Se acerca al punto lentamente.
	tween.tween_property(hammer, "global_position", start_position, 0.12)
	tween.parallel().tween_property(hammer, "rotation_degrees", -42.0, 0.12)
	
	# Golpe más lento y visible.
	tween.tween_property(hammer, "global_position", hit_down_position, 0.22)
	tween.parallel().tween_property(hammer, "rotation_degrees", 18.0, 0.22)
	tween.parallel().tween_property(hammer, "scale", HAMMER_SCALE * 1.12, 0.22)
	
	# Pequeña pausa para que se sienta el golpe.
	tween.tween_interval(0.08)
	
	# Regresa.
	tween.tween_property(hammer, "global_position", back_position, 0.20)
	tween.parallel().tween_property(hammer, "rotation_degrees", -35.0, 0.20)
	tween.parallel().tween_property(hammer, "scale", HAMMER_SCALE, 0.20)
	
	await tween.finished
	
	hammer_hit_busy = false


func _check_all_hammer_hits():
	for hit in hammer_hits:
		if not hit:
			return
	
	await _finish_repair_with_hammer()


func _finish_repair_with_hammer():
	if game_over:
		return
	
	hammer_phase = false
	hammer_dragging = false
	hammer_hit_busy = false
	
	await get_tree().create_timer(0.35).timeout
	
	# Fundido suave antes de cambiar al puente reparado.
	if fade_rect:
		var fade_out := create_tween()
		fade_out.tween_property(fade_rect, "modulate:a", 0.45, 0.45)
		await fade_out.finished
	
	if hammer:
		hammer.visible = false
	
	for board in boards:
		board.visible = false
	
	_set_background(BACKGROUND_FIXED_PATH)
	
	await get_tree().create_timer(0.15).timeout
	
	# Fundido suave de regreso.
	if fade_rect:
		var fade_in := create_tween()
		fade_in.tween_property(fade_rect, "modulate:a", 0.0, 0.55)
		await fade_in.finished
	
	await get_tree().create_timer(0.25).timeout
	
	_win_game()

func _setup_fade_overlay():
	fade_layer = CanvasLayer.new()
	fade_layer.name = "FadeLayer"
	fade_layer.layer = 90
	add_child(fade_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	fade_layer.add_child(fade_rect)
	
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
	counter_panel.size = Vector2(420, 46)
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
	if not board_label:
		return
	
	if hammer_phase:
		var hits_done: int = 0
		
		for hit in hammer_hits:
			if hit:
				hits_done += 1
		
		board_label.text = "Usa el martillo: " + str(hits_done) + "/" + str(TOTAL_BOARDS)
		board_label.add_theme_color_override("font_color", C_ORANGE)
		return
	
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
	
	hammer_phase = false
	hammer_dragging = false
	hammer_hit_busy = false
	
	placed_boards = 0
	
	_set_background(BACKGROUND_BROKEN_PATH)
	
	if hammer:
		hammer.visible = false
	
	_clear_round()
	_create_slots()
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

func _create_slots():
	if not ResourceLoader.exists(BRIDGE_SLOT_SCENE_PATH):
		push_error("No se encontró BridgeSlot.tscn")
		return
	
	var slot_scene = load(BRIDGE_SLOT_SCENE_PATH)
	var screen_size: Vector2 = get_viewport_rect().size
	
	var slot_positions := [
		Vector2(screen_size.x * 0.32, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.395, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.46, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.525, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.59, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.655, screen_size.y * 0.50),
	]
	
	# Se repiten dos tablas usando las imágenes que ya tienes.
	var board_ids: Array = [1, 2, 3, 4, 1, 2]
	board_ids.shuffle()
	
	for i in range(TOTAL_BOARDS):
		var board_id: int = board_ids[i]
		var slot_position: Vector2 = slot_positions[i]
		
		var slot = slot_scene.instantiate()
		slots_parent.add_child(slot)
		
		slot.setup(board_id, BOARD_TEXTURES[board_id], slot_position, SLOT_SCALE)
		slots.append(slot)


func _create_boards():
	if not ResourceLoader.exists(BRIDGE_BOARD_SCENE_PATH):
		push_error("No se encontró BridgeBoard.tscn")
		return
	
	var board_scene = load(BRIDGE_BOARD_SCENE_PATH)
	var screen_size: Vector2 = get_viewport_rect().size
	
	var board_ids: Array = []
	
	for slot in slots:
		board_ids.append(slot.board_id)
	
	board_ids.shuffle()
	
	var spacing: float = screen_size.x * 0.105
	var total_width: float = spacing * float(board_ids.size() - 1)
	var start_x: float = screen_size.x * 0.5 - total_width * 0.5
	var start_y: float = screen_size.y * 0.86
	
	for i in range(board_ids.size()):
		var board_id: int = board_ids[i]
		var board_position := Vector2(start_x + spacing * float(i), start_y)
		
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
	
	if hammer_phase:
		return
	
	var target_slot = _get_matching_slot_for_board(board)
	
	if target_slot:
		target_slot.place_board()
		board.lock_to_position(target_slot.get_center_position())
		
		placed_boards += 1
		_update_hud()
		
		if placed_boards >= TOTAL_BOARDS:
			await get_tree().create_timer(0.30).timeout
			_start_hammer_phase()
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
		
		var distance: float = board.global_position.distance_to(slot.get_center_position())
		
		if distance <= DROP_DISTANCE:
			return slot
	
	return null


func _get_nearest_slot(position_to_check: Vector2):
	var nearest_slot = null
	var nearest_distance: float = 999999.0
	
	for slot in slots:
		if slot.occupied:
			continue
		
		var distance: float = position_to_check.distance_to(slot.get_center_position())
		
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
	
	if hammer:
		hammer.visible = false
	
	if game_result:
		if game_result.has_method("show_lose"):
			game_result.show_lose()
		elif game_result.has_method("mostrar_perdiste"):
			game_result.mostrar_perdiste()


func _disable_boards():
	for board in boards:
		board.locked = true
