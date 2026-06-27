extends Node2D

# =========================================================
# SCENES
# =========================================================
const TIMER_UI_SCENE := preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE := preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE := preload("res://Minigames/ui_global/LivesUi.tscn")

# =========================================================
# CONSTANTS
# =========================================================
const TOTAL_TIME := 40.0

# =========================================================
# NODE REFERENCES
# =========================================================
@onready var boy = $CharacterBody2D/BoyAnimated
@onready var wave = $WaveAnimated
@onready var obstacles_node = $Obstacles

# =========================================================
# VARIABLES
# =========================================================
var score = 0
var score_timer = 0.0
var game_over = false
var speed = 300.0
var speed_increase = 20.0
var hits = 0
var wave_x := 0.0

var _timer_ui: Node
var _game_result: Node
var _lives_ui: Node

# =========================================================
# LIFECYCLE
# =========================================================
func _ready():
	wave.play("wave")
	wave_x = wave.position.x
	for obs in obstacles_node.get_children():
		obs.visible = false
	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()

func _process(delta):
	if game_over:
		return
	
	score_timer += delta
	if score_timer >= 0.5:
		score_timer = 0
		score += 1
	
	speed = 300.0 + (score / 10) * speed_increase

# =========================================================
# SETUP
# =========================================================
func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)
	
	if _timer_ui.has_signal("time_up"):
		_timer_ui.connect("time_up", Callable(self, "_on_time_up"))
	
	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(500, 60)
	
	if _timer_ui.has_method("iniciar"):
		_timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para sobrevivir")

func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)
	_update_lives_ui()

func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)
	if _game_result is CanvasLayer:
		_game_result.layer = 50

# =========================================================
# LIVES
# =========================================================
func _update_lives_ui():
	if _lives_ui == null:
		return
	var lives_remaining = 3 - hits
	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(lives_remaining)

# =========================================================
# HITS Y OLA
# =========================================================
func register_hit():
	if game_over:
		return
	hits += 1
	wave_x += 160.0
	wave.position.x = wave_x
	_update_lives_ui()
	if hits >= 3:
		wave_x += 400.0
		wave.position.x = wave_x
		await get_tree().create_timer(0.5).timeout
		_lose_game()

# =========================================================
# TIMER
# =========================================================
func _on_time_up():
	if game_over:
		return
	_win_game()

func _stop_timer_ui():
	if _timer_ui and _timer_ui.has_method("detener"):
		_timer_ui.detener()

# =========================================================
# RESULTADO
# =========================================================
func _win_game():
	if game_over:
		return
	game_over = true
	_stop_timer_ui()
	if _game_result:
		if _game_result.has_method("show_win"):
			_game_result.show_win()
		elif _game_result.has_method("mostrar_ganaste"):
			_game_result.mostrar_ganaste()

func _lose_game():
	if game_over:
		return
	game_over = true
	_stop_timer_ui()
	boy.play("fail")
	boy.scale = Vector2(1.09, 1.072)
	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

func trigger_game_over():
	hits = 3
	wave_x += 400.0
	wave.position.x = wave_x
	await get_tree().create_timer(0.5).timeout
	_lose_game()
