extends Node2D
class_name StormMinigame


# =========================================================
# SIGNALS
# =========================================================

signal puzzle_completed
signal puzzle_failed


# =========================================================
# SCENES
# =========================================================

const TIMER_UI_SCENE := preload("res://ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE := preload("res://ui_global/GameResult.tscn")
const LIVES_UI_SCENE := preload("res://ui_global/LivesUi.tscn")
const DEFAULT_LIGHTNING_SCENE := preload("res://minigame_storm/Lightning.tscn")


# =========================================================
# CONSTANTS
# =========================================================

const TOTAL_TIME := 20.0
const LIGHTNING_SPAWN_MARGIN := 80


# =========================================================
# EXPORTED VARIABLES
# =========================================================

@export var lightning_scene: PackedScene


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _game_finished := false

var _timer_ui: Node
var _game_result: Node
var _lives_ui: Node


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var _player = $StormPlayer
@onready var _lightning_spawn_timer: Timer = $LightningSpawnTimer
@onready var _storm_background: Node2D = $StormBackground
@onready var _rain_audio: AudioStreamPlayer = $RainAudio
@onready var _thunder_audio: AudioStreamPlayer = $ThunderAudio


# =========================================================
# LIFECYCLE METHODS
# =========================================================

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
	_connect_lightning_spawn_timer()
	_update_lives_ui()

	if _lightning_spawn_timer:
		_lightning_spawn_timer.start()


func _process(_delta):
	if _game_finished:
		return

	_update_lives_ui()

	if _player and _player.lives <= 0:
		_lose_game()


# =========================================================
# SETUP METHODS
# =========================================================

func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	# Tu TimerUi global emite la señal "time_up"
	if _timer_ui.has_signal("time_up"):
		_timer_ui.connect("time_up", Callable(self, "_on_time_up"))
	else:
		print("ERROR: El TimerUi no tiene la señal time_up")

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(500, 60)

	if _timer_ui.has_method("iniciar"):
		_timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para sobrevivir")
	else:
		print("ERROR: El TimerUi no tiene el método iniciar()")


func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(3)
	else:
		print("ERROR: LivesUi no tiene el método actualizar_vidas()")


func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)

	if _game_result is CanvasLayer:
		_game_result.layer = 50


func _setup_audio():
	if _rain_audio:
		_rain_audio.volume_db = -12
		_rain_audio.play()

		if not _rain_audio.finished.is_connected(_on_rain_audio_finished):
			_rain_audio.finished.connect(_on_rain_audio_finished)

	if _thunder_audio:
		_thunder_audio.volume_db = -3


func _connect_background_lightning():
	if _storm_background == null:
		return

	if _storm_background.has_signal("lightning_flashes"):
		_storm_background.connect(
			"lightning_flashes",
			Callable(self, "_on_background_lightning_flashes")
		)


func _connect_lightning_spawn_timer():
	if _lightning_spawn_timer == null:
		print("ERROR: No se encontró LightningSpawnTimer")
		return

	if not _lightning_spawn_timer.timeout.is_connected(_on_lightning_spawn_timer_timeout):
		_lightning_spawn_timer.timeout.connect(_on_lightning_spawn_timer_timeout)


# =========================================================
# TIMER METHODS
# =========================================================

func _on_time_up():
	if _game_finished:
		return

	_win_game()


func _stop_timer_ui():
	if _timer_ui == null:
		return

	if _timer_ui.has_method("detener"):
		_timer_ui.detener()


# =========================================================
# LIVES METHODS
# =========================================================

func _update_lives_ui():
	if _lives_ui == null or _player == null:
		return

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_player.lives)


# =========================================================
# LIGHTNING METHODS
# =========================================================

func _on_lightning_spawn_timer_timeout():
	if _game_finished:
		return

	var scene_to_spawn: PackedScene = lightning_scene

	if scene_to_spawn == null:
		scene_to_spawn = DEFAULT_LIGHTNING_SCENE

	var screen_width: float = get_viewport_rect().size.x

	# Caen más rayos.
	# A veces cae 1 y a veces caen 2.
	var lightning_amount := randi_range(1, 2)

	for index in range(lightning_amount):
		var lightning = scene_to_spawn.instantiate()

		lightning.position.x = randi_range(
			LIGHTNING_SPAWN_MARGIN,
			int(screen_width - LIGHTNING_SPAWN_MARGIN)
		)

		lightning.position.y = -80 - (index * 90)

		add_child(lightning)


# =========================================================
# AUDIO METHODS
# =========================================================

func _on_background_lightning_flashes():
	if _game_finished:
		return

	if _thunder_audio:
		_thunder_audio.stop()
		_thunder_audio.play()


func _on_rain_audio_finished():
	if not _game_finished and _rain_audio:
		_rain_audio.play()


# =========================================================
# RESULT METHODS
# =========================================================

func _win_game():
	if _game_finished:
		return

	_game_finished = true

	if _lightning_spawn_timer:
		_lightning_spawn_timer.stop()

	_stop_timer_ui()

	if _rain_audio:
		_rain_audio.stop()

	if _game_result:
		if _game_result.has_method("show_win"):
			_game_result.show_win()
		elif _game_result.has_method("mostrar_ganaste"):
			_game_result.mostrar_ganaste()

	emit_signal("puzzle_completed")


func _lose_game():
	if _game_finished:
		return

	_game_finished = true

	if _lightning_spawn_timer:
		_lightning_spawn_timer.stop()

	_stop_timer_ui()

	if _rain_audio:
		_rain_audio.stop()

	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

	emit_signal("puzzle_failed")
