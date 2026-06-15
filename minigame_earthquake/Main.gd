# Main.gd
# Controlador principal del juego.
#
# Árbol de escena esperado:
#   Main  (Node2D)
#   ├── Background    (Node2D  →  Background.gd)
#   ├── Player        (Node2D  →  Player.gd)
#   ├── Hud           (CanvasLayer → Hud.gd)
#   ├── AudioMusic    (AudioStreamPlayer)  ← música de fondo de todo el minijuego (en bucle)
#   ├── AudioWarning  (AudioStreamPlayer)  ← sonido de aviso, termina justo cuando empieza el terremoto
#   └── AudioEQ       (AudioStreamPlayer)  ← sonido al aparecer el letrero de terremoto
#
# LivesUi    se instancia automáticamente desde res://ui_global/LivesUi.tscn
# GameResult se instancia automáticamente desde res://ui_global/GameResult.tscn
#
# Flujo:
#   1. El juego empieza en WALKING: la chica corre desde el inicio.
#      Suena AudioMusic en bucle desde el inicio hasta WIN/LOSE (se reinicia
#      automáticamente cada vez que termina, mientras el juego siga activo).
#   2. El sonido de aviso (AudioWarning) se programa para que TERMINE justo
#      cuando empiece el terremoto: AudioWarning suena → termina → EARTHQUAKE.
#   3. Tras un intervalo aleatorio → EARTHQUAKE:
#      suena AudioEQ y aparece el letrero; el jugador debe MANTENER PRESIONADO
#      el botón para esconderse. Tiene hide_grace_period segundos de margen
#      al inicio y al soltar.
#   4. Al terminar el terremoto exitosamente → WALKING de nuevo.
#   5. Los terremotos se repiten hasta que:
#      - El progreso llega a 1.0 → WIN
#      - Las vidas llegan a 0   → LOSE
#
# VOLÚMENES:
#   - AudioMusic:   -15 dB respecto al volumen configurado en el nodo
#   - AudioWarning:  -5 dB respecto al volumen configurado en el nodo
#   - AudioEQ:       -5 dB respecto al volumen configurado en el nodo
#
# SISTEMA DE ALEATORIEDAD MEJORADO:
#   - _walk_timer separado del _eq_timer (evita bug de reutilización)
#   - Duración variable por terremoto (earthquake_duration_min/max)
#   - Ráfagas: tras un terremoto, probabilidad de que venga otro casi inmediato
#   - Velocidad de caminata varía ligeramente entre tramos
#
# AJUSTES DE DIFICULTAD (más accesible):
#   - Intervalos entre terremotos más largos
#   - Terremotos más cortos
#   - Mayor margen de gracia para reaccionar
#   - Ráfagas mucho menos frecuentes y con más tiempo de reacción
#   - Menor variación de velocidad de caminata

extends Node

# ---- Señales ---------------------------------------------------------------
signal earthquake_started
signal earthquake_ended

# ---- Parámetros exportables ------------------------------------------------
# Intervalo más amplio: terremotos menos seguidos, más tiempo para caminar tranquilo
@export var earthquake_interval_min: float = 3.0   # antes: 1.0
@export var earthquake_interval_max: float = 7.0   # antes: 4.0

# Duración más corta: terremotos más breves
@export var earthquake_duration_min: float = 1.5   # antes: 2.5
@export var earthquake_duration_max: float = 3.5   # antes: 5.5

@export var total_walk_distance: float = 3000.0
@export var walk_scroll_speed:   float = 140.0
@export var max_lives:           int   = 3

# Margen de gracia más generoso: más tiempo para reaccionar
@export var hide_grace_period: float = 1.0   # antes: 0.5

# Ráfagas mucho menos frecuentes
@export var aftershock_chance: float = 0.15        # antes: 0.50

# Intervalo de ráfaga más amplio: más tiempo de reacción entre terremotos encadenados
@export var aftershock_interval_min: float = 1.0   # antes: 0.3
@export var aftershock_interval_max: float = 2.0   # antes: 1.0

# Menor variación de velocidad: ritmo más predecible
@export var walk_speed_variance: float = 15.0      # antes: 30.0

# ---- Ajustes de volumen (dB relativos al valor configurado en cada nodo) ----
@export var music_volume_offset_db:   float = -30.0
@export var warning_volume_offset_db: float = -17.0
@export var eq_volume_offset_db:      float = -17.0

# ---- Estado interno --------------------------------------------------------
enum State { WALKING, EARTHQUAKE, WIN, LOSE }
var _state: State = State.WALKING

# _walk_timer cuenta el tiempo caminando (separado del timer de terremoto)
var _walk_timer:       float = 0.0
var _next_eq_in:       float = 0.0

# _eq_timer cuenta la duración del terremoto actual
var _eq_timer:         float = 0.0
var _current_eq_duration: float = 0.0

var _grace_timer:      float = 0.0

var _distance_traveled: float = 0.0
var _current_speed:     float = 0.0
var _current_lives:     int   = 3

# _button_held se actualiza desde el Hud vía on_hide_button_pressed/released
var _button_held: bool = false

# Indica si el próximo intervalo es una ráfaga (tiempo muy corto)
var _next_is_aftershock: bool = false

# Indica si ya se reprodujo el sonido de aviso para el próximo terremoto
var _warning_played: bool = false

# Momento (dentro de _walk_timer) en que debe EMPEZAR el sonido de aviso,
# calculado para que TERMINE justo cuando arranca el terremoto
var _warning_start_time: float = 0.0

# ---- Nodos -----------------------------------------------------------------
@onready var _hud:        CanvasLayer       = $Hud
@onready var _background: Node2D            = $Background
@onready var _player:     Node2D            = $Player
@onready var _audio_music:   AudioStreamPlayer = get_node_or_null("AudioMusic")
@onready var _audio_warning: AudioStreamPlayer = get_node_or_null("AudioWarning")
@onready var _audio_eq:      AudioStreamPlayer = get_node_or_null("AudioEQ")

var _lives_ui:    Node2D = null
var _game_result: Node   = null


func _ready() -> void:
	_current_lives = max_lives

	# --- LivesUi ---
	var lives_scene = load("res://ui_global/LivesUi.tscn")
	if lives_scene:
		_lives_ui = lives_scene.instantiate()
		add_child(_lives_ui)
		_lives_ui.set_max_lives(max_lives)
		_lives_ui.actualizar_vidas(_current_lives)
	else:
		push_error("Main.gd: No se encontró res://ui_global/LivesUi.tscn")

	# --- GameResult ---
	var result_scene = load("res://ui_global/GameResult.tscn")
	if result_scene:
		_game_result = result_scene.instantiate()
		add_child(_game_result)
	else:
		push_error("Main.gd: No se encontró res://ui_global/GameResult.tscn")

	_hud.hide_earthquake_banner()

	# Ajuste de volúmenes relativos a lo configurado en cada nodo
	if _audio_music and is_instance_valid(_audio_music):
		_audio_music.volume_db += music_volume_offset_db
	if _audio_warning and is_instance_valid(_audio_warning):
		_audio_warning.volume_db += warning_volume_offset_db
	if _audio_eq and is_instance_valid(_audio_eq):
		_audio_eq.volume_db += eq_volume_offset_db

	# Música de fondo: arranca con el minijuego y se repite mientras
	# el juego no haya terminado (WIN/LOSE), aunque el stream no tenga loop activado
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
	_distance_traveled += _current_speed * delta
	var progress = clamp(_distance_traveled / total_walk_distance, 0.0, 1.0)

	_hud.update_progress(progress)
	_background.update_progress(progress)
	_scroll_background(delta)

	# Usamos _walk_timer (independiente de _eq_timer)
	_walk_timer += delta

	# ── Sonido de aviso: empieza en _warning_start_time, calculado para que
	# TERMINE justo cuando el terremoto comienza (_next_eq_in).
	if not _warning_played and _walk_timer >= _warning_start_time:
		_play_warning()
		_warning_played = true

	if _walk_timer >= _next_eq_in:
		_set_state(State.EARTHQUAKE)
		return

	if progress >= 1.0:
		_set_state(State.WIN)


func _process_earthquake(delta: float) -> void:
	_eq_timer += delta

	if _button_held:
		# Jugador escondido: resetea el margen de gracia
		_grace_timer = 0.0
	else:
		# Botón suelto: acumula tiempo de gracia
		_grace_timer += delta
		if _grace_timer >= hide_grace_period:
			_lose_life()
			return

	# Duración variable: cada terremoto tiene su propia duración
	if _eq_timer >= _current_eq_duration:
		_set_state(State.WALKING)


func _scroll_background(delta: float) -> void:
	if _background.has_method("scroll_step"):
		_background.scroll_step(_current_speed, delta)


func _play_warning() -> void:
	if _audio_warning and is_instance_valid(_audio_warning):
		_audio_warning.play()


func _on_music_finished() -> void:
	# Si el juego sigue en curso, vuelve a reproducir la música de fondo
	if _state != State.WIN and _state != State.LOSE:
		if _audio_music and is_instance_valid(_audio_music):
			_audio_music.play()


# ---------------------------------------------------------------------------
# Llamado por Hud._on_hold_down / _on_hold_up
func on_hide_button_pressed() -> void:
	_button_held = true
	# Si presiona fuera del terremoto → pierde vida
	if _state == State.WALKING:
		_lose_life()

func on_hide_button_released() -> void:
	_button_held = false


func _lose_life() -> void:
	_current_lives -= 1
	if _lives_ui:
		_lives_ui.actualizar_vidas(_current_lives)

	if _current_lives <= 0:
		_set_state(State.LOSE)
	else:
		_set_state(State.WALKING)


# ---------------------------------------------------------------------------
func _set_state(new_state: State) -> void:
	_state = new_state
	match new_state:

		State.WALKING:
			_button_held  = false
			_grace_timer  = 0.0
			# Velocidad ligeramente aleatoria para romper el ritmo
			_current_speed = walk_scroll_speed + randf_range(-walk_speed_variance, walk_speed_variance)
			_schedule_next_earthquake()
			_hud.hide_earthquake_banner()
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()
			emit_signal("earthquake_ended")

		State.EARTHQUAKE:
			_eq_timer             = 0.0
			_grace_timer          = 0.0
			_current_speed        = 0.0
			# Cada terremoto tiene su propia duración aleatoria
			_current_eq_duration  = randf_range(earthquake_duration_min, earthquake_duration_max)
			# Sonido + letrero de terremoto, sincronizados
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.play()
			_hud.show_earthquake_banner()
			emit_signal("earthquake_started")

		State.WIN:
			_button_held   = false
			_current_speed = 0.0
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()
			if _audio_music and is_instance_valid(_audio_music):
				_audio_music.stop()
			_hud.show_win()
			if _player and _player.has_method("set_win"):
				_player.set_win()
			if _game_result and _game_result.has_method("mostrar_ganaste"):
				_game_result.mostrar_ganaste()

		State.LOSE:
			_button_held   = false
			_current_speed = 0.0
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()
			if _audio_music and is_instance_valid(_audio_music):
				_audio_music.stop()
			_hud.hide_earthquake_banner()
			if _player and _player.has_method("set_idle"):
				_player.set_idle()
			if _game_result and _game_result.has_method("mostrar_perdiste"):
				_game_result.mostrar_perdiste()


func _schedule_next_earthquake() -> void:
	_walk_timer      = 0.0
	_warning_played  = false

	if _next_is_aftershock:
		# Ráfaga: intervalo corto, pero con margen razonable de reacción
		_next_eq_in          = randf_range(aftershock_interval_min, aftershock_interval_max)
		_next_is_aftershock  = false
	else:
		# Intervalo normal aleatorio
		_next_eq_in = randf_range(earthquake_interval_min, earthquake_interval_max)
		# ¿El siguiente será una ráfaga?
		_next_is_aftershock = randf() < aftershock_chance

	# Calcular cuándo debe EMPEZAR el sonido de aviso para que TERMINE
	# justo cuando arranca el terremoto (_next_eq_in)
	var warning_duration = 0.0
	if _audio_warning and is_instance_valid(_audio_warning) and _audio_warning.stream:
		warning_duration = _audio_warning.stream.get_length()

	_warning_start_time = max(0.0, _next_eq_in - warning_duration)


# ---------------------------------------------------------------------------
func on_player_reached_safe_zone() -> void:
	if _state != State.WIN and _state != State.LOSE:
		_set_state(State.WIN)
