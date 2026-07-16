# Main.gd

extends Node

# ---- Señales ---------------------------------------------------------------
signal earthquake_started
signal earthquake_ended

# ---- Parámetros exportables ------------------------------------------------

@export var earthquake_interval_min: float = 3.0
@export var earthquake_interval_max: float = 7.0

@export var earthquake_duration_min: float = 1.5
@export var earthquake_duration_max: float = 3.5

@export var total_walk_distance: float = 3000.0
@export var walk_scroll_speed: float = 140.0
@export var max_lives: int = 3

@export var hide_grace_period: float = 1.0

@export var aftershock_chance: float = 0.15
@export var aftershock_interval_min: float = 1.0
@export var aftershock_interval_max: float = 2.0

@export var walk_speed_variance: float = 15.0

# Tiempo mínimo antes del terremoto donde ya se permite presionar el botón.
@export var button_warning_window: float = 1.5

# Movimiento de pantalla durante terremoto.
@export var screen_shake_strength: float = 10.0
@export var screen_shake_speed: float = 45.0

const GLOBAL_SOUND_VOLUME := -10.0


# ---- Estado interno --------------------------------------------------------

enum State { WALKING, EARTHQUAKE, WIN, LOSE }
var _state: State = State.WALKING

var _walk_timer: float = 0.0
var _next_eq_in: float = 0.0

var _eq_timer: float = 0.0
var _current_eq_duration: float = 0.0

var _grace_timer: float = 0.0

var _distance_traveled: float = 0.0
var _current_speed: float = 0.0
var _current_lives: int = 3

var _progress_age_multiplier: float = 1.0

var _button_held: bool = false
var _button_allowed: bool = false

var _next_is_aftershock: bool = false
var _warning_played: bool = false
var _warning_start_time: float = 0.0

var _shake_time: float = 0.0
var _background_base_position := Vector2.ZERO
var _player_base_position := Vector2.ZERO


# ---- Nodos -----------------------------------------------------------------

@onready var _hud: CanvasLayer = $Hud
@onready var _background: Node2D = $Background
@onready var _player: Node2D = $Player

@onready var _audio_music: AudioStreamPlayer = get_node_or_null("AudioMusic")
@onready var _audio_warning: AudioStreamPlayer = get_node_or_null("AudioWarning")
@onready var _audio_eq: AudioStreamPlayer = get_node_or_null("AudioEQ")

var _lives_ui: Node2D = null
var _game_result: Node = null


func _ready() -> void:
	randomize()

	_current_lives = max_lives

	var player_age: int = MinigameData.player_age
	_progress_age_multiplier = _get_progress_multiplier(player_age)

	if _background:
		_background_base_position = _background.position

	if _player:
		_player_base_position = _player.position

	var lives_scene = load("res://Minigames/ui_global/LivesUi.tscn")
	if lives_scene:
		_lives_ui = lives_scene.instantiate()
		add_child(_lives_ui)
		_lives_ui.set_max_lives(max_lives)
		_lives_ui.actualizar_vidas(_current_lives)
	else:
		push_error("Main.gd: No se encontró res://Minigames/ui_global/LivesUi.tscn")

	var result_scene = load("res://Minigames/ui_global/GameResult.tscn")
	if result_scene:
		_game_result = result_scene.instantiate()
		add_child(_game_result)
		_game_result.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_result_sound_volume()
	else:
		push_error("Main.gd: No se encontró res://Minigames/ui_global/GameResult.tscn")

	_hud.hide_earthquake_banner()

	if _hud.has_method("set_hide_button_mode"):
		_hud.set_hide_button_mode("normal")

	_setup_sound_volumes()

	if _audio_music and is_instance_valid(_audio_music):
		_audio_music.finished.connect(_on_music_finished)
		_audio_music.play()

	_set_state(State.WALKING)


func _process(delta: float) -> void:
	match _state:
		State.WALKING:
			_process_walking(delta)

		State.EARTHQUAKE:
			_process_earthquake(delta)


# ---------------------------------------------------------------------------

func _process_walking(delta: float) -> void:
	_distance_traveled += _current_speed * _progress_age_multiplier * delta

	var progress = clamp(_distance_traveled / total_walk_distance, 0.0, 1.0)

	_hud.update_progress(progress)
	_background.update_progress(progress)
	_scroll_background(delta)

	_walk_timer += delta

	if not _warning_played and _walk_timer >= _warning_start_time:
		_play_warning()
		_warning_played = true
		_button_allowed = true

		if _hud.has_method("set_hide_button_mode"):
			_hud.set_hide_button_mode("warning")

	if _walk_timer >= _next_eq_in:
		_set_state(State.EARTHQUAKE)
		return

	if progress >= 1.0:
		_set_state(State.WIN)


func _process_earthquake(delta: float) -> void:
	_eq_timer += delta

	_update_screen_shake(delta)

	if _button_held:
		_grace_timer = 0.0
	else:
		_grace_timer += delta

		if _grace_timer >= hide_grace_period:
			_lose_life()
			return

	if _eq_timer >= _current_eq_duration:
		_set_state(State.WALKING)


func _scroll_background(delta: float) -> void:
	if _background.has_method("scroll_step"):
		_background.scroll_step(_current_speed, delta)


# ---------------------------------------------------------------------------
# AUDIO
# ---------------------------------------------------------------------------

func _setup_sound_volumes() -> void:
	if _audio_music and is_instance_valid(_audio_music):
		_audio_music.volume_db = GLOBAL_SOUND_VOLUME

	if _audio_warning and is_instance_valid(_audio_warning):
		_audio_warning.volume_db = GLOBAL_SOUND_VOLUME

	if _audio_eq and is_instance_valid(_audio_eq):
		_audio_eq.volume_db = GLOBAL_SOUND_VOLUME

	_set_result_sound_volume()


func _set_result_sound_volume() -> void:
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


func _play_warning() -> void:
	if _audio_warning and is_instance_valid(_audio_warning):
		_audio_warning.volume_db = GLOBAL_SOUND_VOLUME
		_audio_warning.stop()
		_audio_warning.play()


func _play_earthquake_sound() -> void:
	if _audio_eq and is_instance_valid(_audio_eq):
		_audio_eq.volume_db = GLOBAL_SOUND_VOLUME
		_audio_eq.stop()
		_audio_eq.play()


func _on_music_finished() -> void:
	if _state != State.WIN and _state != State.LOSE:
		if _audio_music and is_instance_valid(_audio_music):
			_audio_music.volume_db = GLOBAL_SOUND_VOLUME
			_audio_music.play()


# ---------------------------------------------------------------------------
# BOTÓN DE ESCONDERSE
# ---------------------------------------------------------------------------

func on_hide_button_pressed() -> void:
	_button_held = true

	if _state == State.WALKING:
		if not _button_allowed:
			_lose_life()
			return


func on_hide_button_released() -> void:
	_button_held = false


# ---------------------------------------------------------------------------
# SCREEN SHAKE
# ---------------------------------------------------------------------------

func _update_screen_shake(delta: float) -> void:
	_shake_time += delta

	var shake_x := sin(_shake_time * screen_shake_speed) * screen_shake_strength
	var shake_y := cos(_shake_time * screen_shake_speed * 1.25) * screen_shake_strength

	shake_x += randf_range(-screen_shake_strength * 0.35, screen_shake_strength * 0.35)
	shake_y += randf_range(-screen_shake_strength * 0.35, screen_shake_strength * 0.35)

	var shake_offset := Vector2(shake_x, shake_y)

	if _background and is_instance_valid(_background):
		_background.position = _background_base_position + shake_offset

	if _player and is_instance_valid(_player):
		_player.position = _player_base_position + shake_offset


func _reset_screen_shake() -> void:
	_shake_time = 0.0

	if _background and is_instance_valid(_background):
		_background.position = _background_base_position

	if _player and is_instance_valid(_player):
		_player.position = _player_base_position


# ---------------------------------------------------------------------------
# VIDAS
# ---------------------------------------------------------------------------

func _lose_life() -> void:
	_current_lives -= 1

	if _lives_ui:
		_lives_ui.actualizar_vidas(_current_lives)

	if _current_lives <= 0:
		_set_state(State.LOSE)
	else:
		_set_state(State.WALKING)


# ---------------------------------------------------------------------------
# ESTADOS
# ---------------------------------------------------------------------------

func _set_state(new_state: State) -> void:
	_state = new_state

	match new_state:

		State.WALKING:
			_button_held = false
			_button_allowed = false
			_grace_timer = 0.0

			_reset_screen_shake()

			_current_speed = walk_scroll_speed + randf_range(-walk_speed_variance, walk_speed_variance)

			_schedule_next_earthquake()

			_hud.hide_earthquake_banner()

			if _hud.has_method("set_hide_button_mode"):
				_hud.set_hide_button_mode("normal")

			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()

			emit_signal("earthquake_ended")

		State.EARTHQUAKE:
			_eq_timer = 0.0
			_grace_timer = 0.0
			_current_speed = 0.0
			_button_allowed = true

			_current_eq_duration = randf_range(earthquake_duration_min, earthquake_duration_max)

			_play_earthquake_sound()

			_hud.show_earthquake_banner()

			if _hud.has_method("set_hide_button_mode"):
				_hud.set_hide_button_mode("earthquake")

			emit_signal("earthquake_started")

		State.WIN:
			_button_held = false
			_button_allowed = false
			_current_speed = 0.0

			_reset_screen_shake()

			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()

			if _audio_music and is_instance_valid(_audio_music):
				_audio_music.stop()

			if _hud.has_method("set_hide_button_mode"):
				_hud.set_hide_button_mode("disabled")

			_hud.show_win()

			if _player and _player.has_method("set_win"):
				_player.set_win()

			_set_result_sound_volume()

			if _game_result and _game_result.has_method("mostrar_ganaste"):
				_game_result.mostrar_ganaste()

		State.LOSE:
			_button_held = false
			_button_allowed = false
			_current_speed = 0.0

			_reset_screen_shake()

			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()

			if _audio_music and is_instance_valid(_audio_music):
				_audio_music.stop()

			_hud.hide_earthquake_banner()

			if _hud.has_method("set_hide_button_mode"):
				_hud.set_hide_button_mode("disabled")

			if _player and _player.has_method("set_idle"):
				_player.set_idle()

			_set_result_sound_volume()

			if _game_result and _game_result.has_method("mostrar_perdiste"):
				_game_result.mostrar_perdiste()


func _schedule_next_earthquake() -> void:
	_walk_timer = 0.0
	_warning_played = false
	_button_allowed = false

	if _next_is_aftershock:
		_next_eq_in = randf_range(aftershock_interval_min, aftershock_interval_max)
		_next_is_aftershock = false
	else:
		_next_eq_in = randf_range(earthquake_interval_min, earthquake_interval_max)
		_next_is_aftershock = randf() < aftershock_chance

	var warning_duration := 0.0

	if _audio_warning and is_instance_valid(_audio_warning) and _audio_warning.stream:
		warning_duration = _audio_warning.stream.get_length()

	var real_warning_window: float = max(warning_duration, button_warning_window)

	_warning_start_time = max(0.0, _next_eq_in - real_warning_window)


# ---------------------------------------------------------------------------

func on_player_reached_safe_zone() -> void:
	if _state != State.WIN and _state != State.LOSE:
		_set_state(State.WIN)


# =========================================================
# PROGRESS BONUS POR EDAD
# =========================================================

func _get_progress_multiplier(age: int) -> float:
	match age:
		11:
			return 1.10
		10:
			return 1.20
		9:
			return 1.35
		8:
			return 1.50
		7:
			return 1.70
		_:
			return 1.80 if age < 7 else 1.0
