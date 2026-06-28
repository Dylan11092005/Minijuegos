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
@onready var safe_zone = $SafeZone
@onready var background = $Background

@onready var background_sound = $BackgroundSound
@onready var collision_sound = $CollisionSound
@onready var jump_sound = $JumpSound

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

var wave_frame := 0
var wave_direction := 1
var wave_timer := 0.0
var wave_fps := 0.2

var safe_zones_spawned = false

var _timer_ui: Node
var _game_result: Node
var _lives_ui: Node

# =========================================================
# LIFECYCLE
# =========================================================
func _ready():
	wave.sprite_frames.set_animation_loop("wave", false)
	wave.animation = "wave"
	wave.frame = 0
	wave_x = wave.position.x
	for obs in obstacles_node.get_children():
		obs.visible = false
	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()
	_setup_background_sound()
	
	if jump_sound:
		jump_sound.volume_db = -5.0   # ✅ bajamos el volumen del salto

func _process(delta):
	if game_over:
		return
	
	wave_timer += delta
	if wave_timer >= wave_fps:
		wave_timer = 0.0
		wave_frame += wave_direction
		if wave_frame >= wave.sprite_frames.get_frame_count("wave") - 1:
			wave_direction = -1
		elif wave_frame <= 0:
			wave_direction = 1
		wave.frame = wave_frame
	
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
# SONIDO DE FONDO (LOOP MANUAL)
# =========================================================
func _setup_background_sound():
	if background_sound == null:
		return
	background_sound.volume_db = -15.0   # ✅ bajamos el volumen del fondo
	background_sound.play()
	if not background_sound.finished.is_connected(_on_background_sound_finished):
		background_sound.finished.connect(_on_background_sound_finished)

func _on_background_sound_finished():
	# ✅ Lo vuelve a reproducir mientras el juego no haya terminado
	if not game_over and background_sound:
		background_sound.play()

func _stop_background_sound():
	if background_sound and background_sound.playing:
		background_sound.stop()

# =========================================================
# SONIDOS PUNTUALES
# =========================================================
func play_collision_sound():
	if collision_sound:
		collision_sound.play()

func play_jump_sound():
	if jump_sound:
		jump_sound.play()

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
	
	# ✅ Sonido de choque
	play_collision_sound()
	
	# ✅ Parpadeo de daño en el niño
	var boy_body = get_node("CharacterBody2D")
	if boy_body.has_method("take_damage_feedback"):
		boy_body.take_damage_feedback()
	
	if hits >= 3:
		wave_x += 400.0
		wave.position.x = wave_x
		await get_tree().create_timer(0.5).timeout
		_lose_game()

# =========================================================
# SAFE ZONES
# =========================================================
func _on_time_up():
	if game_over:
		return
	spawn_safe_zones()
	# ✅ 3 segundos después empieza secuencia de victoria
	await get_tree().create_timer(3.0).timeout
	if not game_over:
		_start_win_sequence()

func spawn_safe_zones():
	if safe_zones_spawned:
		return
	safe_zones_spawned = true
	
	# ✅ Desaparecen todos los obstáculos
	for obs in obstacles_node.get_children():
		obs.visible = false
		if obs.has_method("set_process"):
			obs.set_process(false)
	
	var y_positions = [150.0, 502.0, 874.0]
	
	safe_zone.position = Vector2(2500.0, y_positions[0])
	safe_zone.activate(speed)
	
	for i in range(1, 3):
		var copy = safe_zone.duplicate()
		copy.position = Vector2(2500.0, y_positions[i])
		add_child(copy)
		call_deferred("_activate_copy", copy)

func _activate_copy(copy: Node):
	copy.activate(speed)

# =========================================================
# TIMER
# =========================================================
func _stop_timer_ui():
	if _timer_ui and _timer_ui.has_method("detener"):
		_timer_ui.detener()

# =========================================================
# SECUENCIA DE VICTORIA
# =========================================================
func _start_win_sequence():
	if game_over:
		return
	game_over = true
	_stop_timer_ui()
	_stop_background_sound()
	
	# ✅ Detener obstáculos restantes
	for obs in obstacles_node.get_children():
		obs.visible = false
	
	# ✅ Detener niño completamente
	var boy_body = get_node("CharacterBody2D")
	boy_body.velocity = Vector2.ZERO
	boy_body.set_process(false)
	boy_body.set_physics_process(false)
	boy.stop()
	
	# ✅ Detener background
	background.stop_scroll()
	
	# ✅ Ola se va hacia la izquierda con animación
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(wave, "position:x", -600.0, 2.0)
	
	# ✅ 3 segundos después mostrar ganaste
	await get_tree().create_timer(3.0).timeout
	if _game_result:
		if _game_result.has_method("show_win"):
			_game_result.show_win()
		elif _game_result.has_method("mostrar_ganaste"):
			_game_result.mostrar_ganaste()

# =========================================================
# RESULTADO
# =========================================================
func _lose_game():
	if game_over:
		return
	game_over = true
	_stop_timer_ui()
	_stop_background_sound()
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
