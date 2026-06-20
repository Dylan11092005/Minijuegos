extends Node2D


# =========================================================
# CONSTANTS
# =========================================================

const BACKGROUND_PATH := "res://Minigames/minigame_fire/assets/background.png"

const TOTAL_TIME := 35.0
const INITIAL_FIRE_TREES := 3
const PROPAGATE_EVERY := 5.0
const MAX_LIVES := 3


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var background: Sprite2D = $Background
@onready var trees_parent: Node2D = $Trees

@onready var fire_label: Label = $HUD/FireLabel
@onready var lives_ui = $HUD/LivesUi

@onready var timer_ui = $TimerUI
@onready var game_result = $GameResult


# =========================================================
# VARIABLES
# =========================================================

var trees: Array = []

var propagation_timer := 0.0
var current_lives := MAX_LIVES

var game_started := false
var game_over := false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()
	
	_setup_background()
	_collect_trees()
	_setup_ui()
	_setup_global_timer()
	
	call_deferred("_start_game")


func _process(delta):
	if not game_started:
		return
	
	if game_over:
		return
	
	propagation_timer += delta
	
	if propagation_timer >= PROPAGATE_EVERY:
		propagation_timer = 0.0
		_spread_fire()
	
	_update_hud()


# =========================================================
# SETUP
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


func _setup_ui():
	current_lives = MAX_LIVES
	propagation_timer = 0.0
	
	if lives_ui:
		lives_ui.set_max_lives(MAX_LIVES)
		lives_ui.actualizar_vidas(current_lives)
	
	_update_hud()


func _setup_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)
	
	if timer_ui.has_method("stop_timer"):
		timer_ui.stop_timer()
	elif timer_ui.has_method("detener_timer"):
		timer_ui.detener_timer()
	elif timer_ui.has_method("stop"):
		timer_ui.stop()


# =========================================================
# GAME FLOW
# =========================================================

func _start_game():
	game_started = true
	game_over = false
	
	propagation_timer = 0.0
	current_lives = MAX_LIVES
	
	if lives_ui:
		lives_ui.actualizar_vidas(current_lives)
	
	for tree in trees:
		tree.reset_tree()
	
	_start_global_timer()
	_start_fire()
	_update_hud()


func _start_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("start_timer"):
		timer_ui.start_timer(TOTAL_TIME)
	elif timer_ui.has_method("iniciar_timer"):
		timer_ui.iniciar_timer(TOTAL_TIME)
	elif timer_ui.has_method("start"):
		timer_ui.start(TOTAL_TIME)


func _stop_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("stop_timer"):
		timer_ui.stop_timer()
	elif timer_ui.has_method("detener_timer"):
		timer_ui.detener_timer()
	elif timer_ui.has_method("stop"):
		timer_ui.stop()


func _start_fire():
	if trees.is_empty():
		_lose_game()
		return
	
	var shuffled_trees := trees.duplicate()
	shuffled_trees.shuffle()
	
	var amount = min(INITIAL_FIRE_TREES, shuffled_trees.size())
	
	for i in range(amount):
		shuffled_trees[i].set_burning(true)


func _spread_fire():
	if game_over:
		return
	
	if _get_burning_count() == 0:
		return
	
	var available_trees: Array = []
	
	for tree in trees:
		if tree.has_method("can_catch_fire"):
			if tree.can_catch_fire():
				available_trees.append(tree)
	
	if available_trees.is_empty():
		_lose_game()
		return
	
	var new_tree = available_trees.pick_random()
	new_tree.set_burning(true)
	_update_hud()


func _on_tree_extinguished(tree):
	if game_over:
		return
	
	if _get_burning_count() == 0:
		_win_game()
		return
	
	_update_hud()


func _on_wrong_tree_pressed():
	if game_over:
		return
	
	_lose_life()


func _lose_life():
	current_lives -= 1
	current_lives = max(current_lives, 0)
	
	if lives_ui:
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
		game_result.show_win()


func _lose_game():
	if game_over:
		return
	
	game_over = true
	game_started = false
	
	_stop_global_timer()
	_disable_trees()
	
	if game_result:
		game_result.show_lose()


func _disable_trees():
	for tree in trees:
		tree.set_disabled(true)


# =========================================================
# HUD
# =========================================================

func _update_hud():
	if fire_label:
		fire_label.text = "Llamas: " + str(_get_burning_count())


func _get_burning_count() -> int:
	var count := 0
	
	for tree in trees:
		if tree.has_method("is_burning"):
			if tree.is_burning():
				count += 1
	
	return count
