extends Node2D

# ─── Signals ───────────────────────────────────────────────────────────────────
signal earthquake_started
signal earthquake_ended
signal life_lost
signal game_over
signal player_won

# ─── State machine ────────────────────────────────────────────────────────────
enum State { WAITING, EARTHQUAKE, HIDING, WALKING, WIN, LOSE }
var current_state: State = State.WAITING

# ─── Config ───────────────────────────────────────────────────────────────────
@export var earthquake_interval_min: float = 3.0
@export var earthquake_interval_max: float = 7.0
@export var earthquake_duration:     float = 4.0
@export var shake_strength:          float = 8.0
@export var max_lives:               int   = 3

# ─── State ────────────────────────────────────────────────────────────────────
var lives: int = 3
var earthquake_timer: float = 0.0
var next_earthquake_in: float = 0.0
var shake_timer: float = 0.0
var original_camera_pos: Vector2

# ─── Node references ──────────────────────────────────────────────────────────
@onready var player:     Node2D    = $Player
@onready var hud:        CanvasLayer = $HUD
@onready var bg:         Node2D    = $Background
@onready var camera:     Camera2D  = $Camera2D
@onready var eq_sound:   AudioStreamPlayer = $AudioEQ
@onready var win_sound:  AudioStreamPlayer = $AudioWin
@onready var lose_sound: AudioStreamPlayer = $AudioLose

func _ready() -> void:
	lives = max_lives
	original_camera_pos = camera.position
	_schedule_next_earthquake()
	hud.update_lives(lives)
	hud.hide_earthquake_label()

func _process(delta: float) -> void:
	match current_state:
		State.WAITING:
			_process_waiting(delta)
		State.EARTHQUAKE:
			_process_earthquake(delta)
		State.WALKING:
			pass  # player.gd maneja el movimiento

# ─── State logic ──────────────────────────────────────────────────────────────
func _process_waiting(delta: float) -> void:
	earthquake_timer += delta
	if earthquake_timer >= next_earthquake_in:
		_start_earthquake()

func _process_earthquake(delta: float) -> void:
	shake_timer += delta
	# Shake de cámara
	camera.position = original_camera_pos + Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
	# El terremoto dura earthquake_duration segundos
	if shake_timer >= earthquake_duration:
		_end_earthquake()

func _start_earthquake() -> void:
	current_state = State.EARTHQUAKE
	shake_timer = 0.0
	earthquake_timer = 0.0
	eq_sound.play()
	hud.show_earthquake_label()
	emit_signal("earthquake_started")

func _end_earthquake() -> void:
	# Si el jugador estaba escondido → entra a WALKING
	camera.position = original_camera_pos
	eq_sound.stop()
	hud.hide_earthquake_label()
	emit_signal("earthquake_ended")
	# El player se encarga de cambiar a WALKING cuando reciba la señal

func _schedule_next_earthquake() -> void:
	earthquake_timer = 0.0
	next_earthquake_in = randf_range(earthquake_interval_min, earthquake_interval_max)

# ─── Called by player.gd ──────────────────────────────────────────────────────
func on_button_released_during_earthquake() -> void:
	if current_state != State.EARTHQUAKE:
		return
	lives -= 1
	emit_signal("life_lost")
	hud.update_lives(lives)
	if lives <= 0:
		current_state = State.LOSE
		lose_sound.play()
		emit_signal("game_over")
		hud.show_game_over()

func on_player_reached_safe_zone() -> void:
	current_state = State.WIN
	win_sound.play()
	emit_signal("player_won")
	hud.show_win()
