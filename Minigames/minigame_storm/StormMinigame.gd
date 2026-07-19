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

const TIMER_UI_SCENE := preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE := preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE := preload("res://Minigames/ui_global/LivesUi.tscn")
const DEFAULT_LIGHTNING_SCENE := preload("res://Minigames/minigame_storm/Lightning.tscn")


# =========================================================
# CONSTANTS
# =========================================================

const GLOBAL_SOUND_VOLUME := -10.0
const BASE_TIME := 28.0
const LIGHTNING_SPAWN_MARGIN := 80

var TOTAL_TIME: float = BASE_TIME


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

var _last_player_lives := 3

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null


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
		_last_player_lives = _player.lives

	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()
	_setup_damage_effect()
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

	if _player:
		if _player.lives < _last_player_lives:
			_play_damage_effect()

		_last_player_lives = _player.lives

	if _player and _player.lives <= 0:
		_lose_game()


# =========================================================
# SETUP METHODS
# =========================================================

func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	if _timer_ui.has_signal("time_up"):
		_timer_ui.time_up.connect(_on_time_up)
	else:
		print("ERROR: El TimerUi no tiene la señal time_up")

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(500, 60)

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = BASE_TIME - _get_time_penalty(player_age)
	else:
		TOTAL_TIME = BASE_TIME

	TOTAL_TIME = max(TOTAL_TIME, 10.0)

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

	_game_result.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_game_result_sound_volume()


# =========================================================
# DAMAGE EFFECT
# =========================================================

func _setup_damage_effect():
	damage_layer = CanvasLayer.new()
	damage_layer.name = "DamageLayer"
	damage_layer.layer = 200
	add_child(damage_layer)
	
	damage_rect = ColorRect.new()
	damage_rect.name = "DamageRect"
	damage_rect.color = Color(1, 0, 0)
	damage_rect.modulate.a = 0.0
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	damage_layer.add_child(damage_rect)


func _play_damage_effect():
	if not damage_rect:
		return
	
	var original_position: Vector2 = position
	
	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)
	
	var shake_tween := create_tween()
	
	for i in range(6):
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)


# =========================================================
# AUDIO SETUP
# =========================================================

func _setup_audio():
	if _rain_audio:
		_rain_audio.volume_db = GLOBAL_SOUND_VOLUME
		_rain_audio.play()

		if not _rain_audio.finished.is_connected(_on_rain_audio_finished):
			_rain_audio.finished.connect(_on_rain_audio_finished)

	if _thunder_audio:
		_thunder_audio.volume_db = GLOBAL_SOUND_VOLUME

	_set_game_result_sound_volume()


func _set_game_result_sound_volume() -> void:
	if _game_result == null:
		return

	var result_sounds := [
		"WinSound",
		"win_sound",
		"AudioWin",
		"WinAudio",
		"LoseSound",
		"lose_sound",
		"AudioLose",
		"LoseAudio"
	]

	for sound_name in result_sounds:
		var sound = _game_result.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


# =========================================================
# CONNECTION METHODS
# =========================================================

func _connect_background_lightning():
	if _storm_background == null:
		print("ERROR: No se encontró StormBackground")
		return

	var callback := Callable(self, "_on_background_lightning_flashes")

	if _storm_background.has_signal("relampago_aparecio"):
		if not _storm_background.is_connected("relampago_aparecio", callback):
			_storm_background.connect("relampago_aparecio", callback)
	else:
		print("ERROR: StormBackground no tiene la señal relampago_aparecio")


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

	# Estos son los rayos que el jugador esquiva.
	# Aquí NO se reproduce sonido.
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

func _play_thunder_sound():
	if _game_finished:
		return

	if _thunder_audio == null:
		print("ERROR: No se encontró el nodo ThunderAudio")
		return

	if _thunder_audio.stream == null:
		print("ERROR: ThunderAudio no tiene sonido asignado en el Inspector")
		return

	_play_sound(_thunder_audio)


func _on_background_lightning_flashes():
	if _game_finished:
		return

	_play_thunder_sound()


func _on_rain_audio_finished():
	if not _game_finished and _rain_audio:
		_rain_audio.volume_db = GLOBAL_SOUND_VOLUME
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

	if _thunder_audio:
		_thunder_audio.stop()

	_set_game_result_sound_volume()

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

	if _thunder_audio:
		_thunder_audio.stop()

	_set_game_result_sound_volume()

	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

	emit_signal("puzzle_failed")


# =========================================================
# DIFICULTAD POR EDAD
# Entre menor edad, menos tiempo.
# =========================================================

func _get_time_penalty(age: int) -> float:
	match age:
		11:
			return 2.0
		10:
			return 3.0
		9:
			return 5.0
		8:
			return 7.0
		7:
			return 10.0
		_:
			return 10.0 if age < 7 else 0.0
