extends Node2D


# =========================================================
# CONSTANTS
# =========================================================

const BACKGROUND_PATH := "res://Minigames/minigame_fire/assets/background.png"

const TIMER_UI_SCENE_PATH := "res://Minigames/ui_global/TimerUI.tscn"
const GAME_RESULT_SCENE_PATH := "res://Minigames/ui_global/GameResult.tscn"

const TOTAL_TIME := 35.0

const TOTAL_FLAMES_TO_APPEAR := 10
const INITIAL_FIRE_TREES := 2
const MAX_ACTIVE_FLAMES := 3
const SPAWN_FLAME_EVERY := 2.2

const MAX_LIVES := 3

const TREE_JITTER := 10.0


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
# SETUP TIMER UI GLOBAL BY CODE
# =========================================================

func _setup_timer_ui():
	if ResourceLoader.exists(TIMER_UI_SCENE_PATH):
		var timer_scene = load(TIMER_UI_SCENE_PATH)
		timer_ui = timer_scene.instantiate()
		timer_ui.name = "TimerUI"
		
		# Se agrega tal cual viene en el global.
		# No se cambia posición, escala, color, fuente ni nada.
		add_child(timer_ui)
	else:
		push_error("No se encontró TimerUI en: " + TIMER_UI_SCENE_PATH)
		return
	
	_connect_timer_signals()
	_stop_global_timer()


func _connect_timer_signals():
	if not timer_ui:
		return
	
	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)
	
	if timer_ui.has_signal("tiempo_agotado"):
		if not timer_ui.tiempo_agotado.is_connected(_on_time_up):
			timer_ui.tiempo_agotado.connect(_on_time_up)


func _start_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("start_timer"):
		timer_ui.start_timer(TOTAL_TIME)
	elif timer_ui.has_method("iniciar_timer"):
		timer_ui.iniciar_timer(TOTAL_TIME)
	elif timer_ui.has_method("iniciar"):
		timer_ui.iniciar(TOTAL_TIME)
	elif timer_ui.has_method("start"):
		timer_ui.start(TOTAL_TIME)
	else:
		push_error("TimerUI no tiene método para iniciar. Revisa el nombre exacto del método en TimerUI.gd.")


func _stop_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("stop_timer"):
		timer_ui.stop_timer()
	elif timer_ui.has_method("detener_timer"):
		timer_ui.detener_timer()
	elif timer_ui.has_method("detener"):
		timer_ui.detener()
	elif timer_ui.has_method("stop"):
		timer_ui.stop()


# =========================================================
# SETUP GAME RESULT GLOBAL BY CODE
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
	
	# Debajo del TimerUI global.
	# Si queda muy arriba o muy abajo, solo cambia este Y.
	counter_panel.position = Vector2(30, 120)
	counter_panel.size = Vector2(390, 62)
	counter_panel.z_index = 100
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#E5C89E")
	style.border_color = Color("#E08040")
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5
	
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(3, 4)
	
	counter_panel.add_theme_stylebox_override("panel", style)
	hud.add_child(counter_panel)
	
	if fire_label.get_parent():
		fire_label.get_parent().remove_child(fire_label)
	
	counter_panel.add_child(fire_label)
	
	fire_label.position = Vector2.ZERO
	fire_label.size = counter_panel.size
	fire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	fire_label.add_theme_font_size_override("font_size", 24)
	fire_label.add_theme_color_override("font_color", Color("#3E5F8F"))
	fire_label.add_theme_color_override("font_outline_color", Color.WHITE)
	fire_label.add_theme_constant_override("outline_size", 2)


# =========================================================
# RANDOM TREE POSITIONS
# =========================================================

func _randomize_tree_positions():
	var screen_size := get_viewport_rect().size
	
	var slots := [
		Vector2(screen_size.x * 0.17, screen_size.y * 0.56),
		Vector2(screen_size.x * 0.32, screen_size.y * 0.62),
		Vector2(screen_size.x * 0.48, screen_size.y * 0.72),
		Vector2(screen_size.x * 0.62, screen_size.y * 0.60),
		Vector2(screen_size.x * 0.77, screen_size.y * 0.55),
		Vector2(screen_size.x * 0.28, screen_size.y * 0.79),
		Vector2(screen_size.x * 0.66, screen_size.y * 0.79),
		Vector2(screen_size.x * 0.52, screen_size.y * 0.52)
	]
	
	slots.shuffle()
	
	for i in range(trees.size()):
		var base_position: Vector2 = slots[i % slots.size()]
		
		var random_offset := Vector2(
			rng.randf_range(-TREE_JITTER, TREE_JITTER),
			rng.randf_range(-TREE_JITTER, TREE_JITTER)
		)
		
		trees[i].position = base_position + random_offset
		trees[i].z_index = int(trees[i].position.y)


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


func _on_tree_extinguished(_tree):
	if game_over:
		return
	
	total_flames_resolved += 1
	
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
		fire_label.text = "🔥 Activas: " + str(_get_burning_count()) + "   Progreso: " + str(total_flames_resolved) + "/" + str(TOTAL_FLAMES_TO_APPEAR)


func _get_burning_count() -> int:
	var count := 0
	
	for tree in trees:
		if tree.has_method("is_burning"):
			if tree.is_burning():
				count += 1
	
	return count
