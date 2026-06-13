class_name StormMinigame
extends Node2D

const TIMER_UI_SCENE := preload("res://ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE := preload("res://ui_global/GameResult.tscn")
const LIVES_UI_SCENE := preload("res://ui_global/LivesUi.tscn")

const TOTAL_TIME := 15.0
const LIGHTNING_SPAWN_MARGIN := 80

@export var lightning_scene: PackedScene

var _game_finished := false

@onready var _player = $StormPlayer
@onready var _lightning_spawn_timer: Timer = $LightningSpawnTimer
@onready var _storm_background: Node2D = $StormBackground
@onready var _rain_audio: AudioStreamPlayer = $RainAudio
@onready var _thunder_audio: AudioStreamPlayer = $ThunderAudio

var _timer_ui: Node
var _game_result: Node
var _lives_ui: Node


func _ready():
	randomize()

	_game_finished = false

	if _player:
		_player.lives = 3

	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()
	_setup_audio()
	_connect_background_lightning()
	_update_lives_ui()


func _process(_delta):
	_update_lives_ui()

	if _player.lives <= 0 and not _game_finished:
		_lose_game()


func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	if _timer_ui.has_signal("time_expired"):
		_timer_ui.time_expired.connect(_on_time_expired)
	elif _timer_ui.has_signal("tiempo_agotado"):
		_timer_ui.tiempo_agotado.connect(_on_time_expired)

	if _timer_ui.has_method("set_panel_size"):
		_timer_ui.set_panel_size(500, 60)
	elif _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(500, 60)

	if _timer_ui.has_method("start_timer"):
		_timer_ui.start_timer(TOTAL_TIME, "Time remaining", "to survive")
	elif _timer_ui.has_method("iniciar"):
		_timer_ui.iniciar(TOTAL_TIME, "Time remaining", "to survive")


func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	if _lives_ui.has_method("set_max_lives"):
		_lives_ui.set_max_lives(3)


func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)


func _setup_audio():
	if _rain_audio:
		_rain_audio.volume_db = -12
		_rain_audio.play()
		_rain_audio.finished.connect(_on_rain_audio_finished)

	if _thunder_audio:
		_thunder_audio.volume_db = -3


func _connect_background_lightning():
	if _storm_background and _storm_background.has_signal("lightning_flashes"):
		_storm_background.lightning_flashes.connect(_on_background_lightning_flashes)


func _on_lightning_spawn_timer_timeout():
	if _game_finished:
		return

	if lightning_scene == null:
		print("ERROR: Lightning.tscn was not assigned in StormMinigame.")
		return

	var screen_width := get_viewport_rect().size.x

	var lightning = lightning_scene.instantiate()
	lightning.position.x = randi_range(
		LIGHTNING_SPAWN_MARGIN,
		int(screen_width - LIGHTNING_SPAWN_MARGIN)
	)
	lightning.position.y = -80

	add_child(lightning)


func _on_background_lightning_flashes():
	if _game_finished:
		return

	if _thunder_audio:
		_thunder_audio.stop()
		_thunder_audio.play()


func _on_rain_audio_finished():
	if not _game_finished:
		_rain_audio.play()


func _on_time_expired():
	if not _game_finished:
		_win_game()


func _update_lives_ui():
	if _lives_ui == null or _player == null:
		return

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_player.lives)


func _stop_timer_ui():
	if _timer_ui == null:
		return

	if _timer_ui.has_method("stop_timer"):
		_timer_ui.stop_timer()
	elif _timer_ui.has_method("detener"):
		_timer_ui.detener()


func _show_win_result():
	if _game_result == null:
		return

	if _game_result.has_method("show_win"):
		_game_result.show_win()
	elif _game_result.has_method("mostrar_ganaste"):
		_game_result.mostrar_ganaste()


func _show_lose_result():
	if _game_result == null:
		return

	if _game_result.has_method("show_lose"):
		_game_result.show_lose()
	elif _game_result.has_method("mostrar_perdiste"):
		_game_result.mostrar_perdiste()


func _win_game():
	_game_finished = true

	_lightning_spawn_timer.stop()
	_stop_timer_ui()

	if _rain_audio:
		_rain_audio.stop()

	_show_win_result()


func _lose_game():
	_game_finished = true

	_lightning_spawn_timer.stop()
	_stop_timer_ui()

	if _rain_audio:
		_rain_audio.stop()

	_show_lose_result()
