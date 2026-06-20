extends Node2D


# =========================================================
# CONSTANTS
# =========================================================

const BACKGROUND_PATH := "res://Minigames/minigame_fire/assets/background.png"

const TIMER_UI_SCENE_PATH := "res://Minigames/ui_global/TimerUI.tscn"
const GAME_RESULT_SCENE_PATH := "res://Minigames/ui_global/GameResult.tscn"

const TOTAL_TIME := 20.0

const TOTAL_FLAMES_TO_APPEAR := 10
const INITIAL_FIRE_TREES := 2
const MAX_ACTIVE_FLAMES := 3
const SPAWN_FLAME_EVERY := 2.2

const MAX_LIVES := 3

const TREE_REPOSITION_DELAY := 0.45
const MIN_TREE_DISTANCE := 180.0

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
@onready var trees_parent: Node2D = $Trees

@onready var hud: CanvasLayer = $HUD
@onready var fire_label: Label = $HUD/FireLabel
@onready var lives_ui = $HUD/LivesUi


# =========================================================
# VARIABLES
# =========================================================

var timer_ui = null
var game_result = null

var trees: Array = []
var rng := RandomNumberGenerator.new()

var spawn_timer := 0.0
var current_lives := MAX_LIVES

var total_flames_spawned := 0
var total_flames_resolved := 0

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
	_collect_trees()
	_setup_ui()
	
	call_deferred("_start_game")


func _process(delta):
	if not game_started:
		return
	
	if game_over:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= SPAWN_FLAME_EVERY:
		spawn_timer = 0.0
		
		if total_flames_spawned < TOTAL_FLAMES_TO_APPEAR:
			if _get_burning_count() < MAX_ACTIVE_FLAMES:
				_spawn_one_flame()
	
	_update_hud()


# =========================================================
# SETUP BACKGROUND
# =========================================================

func _setup_background():
	if not background:
		return
	
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH)
	
	background.position = get_viewport_rect().size / 2
	background.z_index = -10
	
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
		timer_ui.set_tamano_panel(570, 60)
	
	if timer_ui.has_method("iniciar"):
		timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para apagar incendios")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("detener"):
		timer_ui.detener()


func _hide_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("ocultar"):
		timer_ui.ocultar()


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
# SETUP TREES
# =========================================================

func _collect_trees():
	trees.clear()
	
	for child in trees_parent.get_children():
		if child.has_method("reset_tree") and child.has_method("set_burning"):
			trees.append(child)
			
			child.reset_tree()
			child.set_disabled(true)
			
			if child.has_signal("extinguished"):
				if not child.extinguished.is_connected(_on_tree_extinguished):
					child.extinguished.connect(_on_tree_extinguished)
			
			if child.has_signal("wrong_pressed"):
				if not child.wrong_pressed.is_connected(_on_wrong_tree_pressed):
					child.wrong_pressed.connect(_on_wrong_tree_pressed)
			
			if child.has_signal("burned_out"):
				if not child.burned_out.is_connected(_on_tree_burned_out):
					child.burned_out.connect(_on_tree_burned_out)


# =========================================================
# SETUP UI
# =========================================================

func _setup_ui():
	current_lives = MAX_LIVES
	spawn_timer = 0.0
	
	if lives_ui:
		if lives_ui.has_method("set_max_lives"):
			lives_ui.set_max_lives(MAX_LIVES)
		
		if lives_ui.has_method("actualizar_vidas"):
			lives_ui.actualizar_vidas(current_lives)
	
	_setup_fire_label()
	_update_hud()


func _setup_fire_label():
	if not hud or not fire_label:
		return
	
	if hud.has_node("FireCounterPanel"):
		return
	
	var counter_panel := Panel.new()
	counter_panel.name = "FireCounterPanel"
	
	# Contador debajo del TimerUI, con estilo parecido al timer global.
	counter_panel.position = Vector2(30, 95)
	counter_panel.size = Vector2(300, 46)
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
	
	if fire_label.get_parent():
		fire_label.get_parent().remove_child(fire_label)
	
	counter_panel.add_child(fire_label)
	
	fire_label.position = Vector2.ZERO
	fire_label.size = counter_panel.size
	fire_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	fire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	fire_label.add_theme_font_size_override("font_size", 22)
	fire_label.add_theme_color_override("font_color", C_BLUE)


# =========================================================
# RANDOM TREE POSITIONS
# =========================================================

func _randomize_tree_positions():
	rng.seed = Time.get_ticks_usec()
	
	var used_positions: Array = []
	
	for tree in trees:
		var selected_position := _get_random_safe_tree_position(used_positions)
		
		tree.position = selected_position
		tree.z_index = int(selected_position.y)
		
		used_positions.append(selected_position)


func _move_tree_after_extinguish(tree):
	if not tree:
		return
	
	if tree.has_method("set_disabled"):
		tree.set_disabled(true)
	
	await get_tree().create_timer(TREE_REPOSITION_DELAY).timeout
	
	if game_over:
		return
	
	var used_positions: Array = []
	
	for other_tree in trees:
		if other_tree != tree:
			used_positions.append(other_tree.position)
	
	var new_position := _get_random_safe_tree_position(used_positions)
	
	tree.position = new_position
	tree.z_index = int(new_position.y)
	
	if tree.has_method("reset_tree"):
		tree.reset_tree()


func _get_random_safe_tree_position(used_positions: Array) -> Vector2:
	var screen_size := get_viewport_rect().size
	
	var safe_slots := [
		Vector2(screen_size.x * 0.16, screen_size.y * 0.58),
		Vector2(screen_size.x * 0.30, screen_size.y * 0.60),
		Vector2(screen_size.x * 0.45, screen_size.y * 0.66),
		Vector2(screen_size.x * 0.60, screen_size.y * 0.58),
		Vector2(screen_size.x * 0.76, screen_size.y * 0.56),
		Vector2(screen_size.x * 0.23, screen_size.y * 0.76),
		Vector2(screen_size.x * 0.38, screen_size.y * 0.79),
		Vector2(screen_size.x * 0.55, screen_size.y * 0.77),
		Vector2(screen_size.x * 0.72, screen_size.y * 0.78),
		Vector2(screen_size.x * 0.84, screen_size.y * 0.68)
	]
	
	for attempt in range(40):
		var base_position: Vector2 = safe_slots[rng.randi_range(0, safe_slots.size() - 1)]
		
		var random_offset := Vector2(
			rng.randf_range(-55.0, 55.0),
			rng.randf_range(-35.0, 35.0)
		)
		
		var selected_position := base_position + random_offset
		
		if _is_tree_position_valid(selected_position, used_positions):
			return selected_position
	
	return safe_slots[rng.randi_range(0, safe_slots.size() - 1)]


func _is_tree_position_valid(new_position: Vector2, used_positions: Array) -> bool:
	for used_position in used_positions:
		if new_position.distance_to(used_position) < MIN_TREE_DISTANCE:
			return false
	
	return true


# =========================================================
# GAME FLOW
# =========================================================

func _start_game():
	game_started = true
	game_over = false
	
	spawn_timer = 0.0
	current_lives = MAX_LIVES
	
	total_flames_spawned = 0
	total_flames_resolved = 0
	
	if lives_ui:
		if lives_ui.has_method("actualizar_vidas"):
			lives_ui.actualizar_vidas(current_lives)
	
	_randomize_tree_positions()
	
	for tree in trees:
		tree.reset_tree()
	
	_start_global_timer()
	_start_initial_fires()
	_update_hud()


func _start_initial_fires():
	var amount = min(INITIAL_FIRE_TREES, TOTAL_FLAMES_TO_APPEAR)
	
	for i in range(amount):
		_spawn_one_flame()


func _spawn_one_flame():
	if total_flames_spawned >= TOTAL_FLAMES_TO_APPEAR:
		return
	
	var available_trees := []
	
	for tree in trees:
		if tree.has_method("can_catch_fire"):
			if tree.can_catch_fire():
				available_trees.append(tree)
	
	if available_trees.is_empty():
		if _get_burning_count() == 0:
			_lose_game()
		return
	
	var selected_tree = available_trees.pick_random()
	selected_tree.set_burning(true)
	
	total_flames_spawned += 1
	_update_hud()


func _on_tree_extinguished(tree):
	if game_over:
		return
	
	total_flames_resolved += 1
	
	_move_tree_after_extinguish(tree)
	_check_progress()
	_update_hud()


func _on_tree_burned_out(_tree):
	if game_over:
		return
	
	total_flames_resolved += 1
	_lose_life()
	
	if game_over:
		return
	
	_check_progress()
	_update_hud()


func _check_progress():
	if game_over:
		return
	
	if total_flames_spawned >= TOTAL_FLAMES_TO_APPEAR and _get_burning_count() == 0:
		_win_game()
		return
	
	if _get_burning_count() == 0 and total_flames_spawned < TOTAL_FLAMES_TO_APPEAR:
		_spawn_one_flame()


func _on_wrong_tree_pressed():
	if game_over:
		return
	
	_lose_life()


func _lose_life():
	current_lives -= 1
	current_lives = max(current_lives, 0)
	
	if lives_ui:
		if lives_ui.has_method("actualizar_vidas"):
			lives_ui.actualizar_vidas(current_lives)
	
	if current_lives <= 0:
		_lose_game()


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
	_disable_trees()
	
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
	_disable_trees()
	
	if game_result:
		if game_result.has_method("show_lose"):
			game_result.show_lose()
		elif game_result.has_method("mostrar_perdiste"):
			game_result.mostrar_perdiste()


func _disable_trees():
	for tree in trees:
		tree.set_disabled(true)


# =========================================================
# HUD
# =========================================================

func _update_hud():
	if fire_label:
		fire_label.text = "Llamas: " + str(_get_burning_count()) + "   " + str(total_flames_resolved) + "/" + str(TOTAL_FLAMES_TO_APPEAR)
		fire_label.add_theme_color_override("font_color", _get_counter_color())


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


func _get_burning_count() -> int:
	var count := 0
	
	for tree in trees:
		if tree.has_method("is_burning"):
			if tree.is_burning():
				count += 1
	
	return count
