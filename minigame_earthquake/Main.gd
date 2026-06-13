# Main.gd
# Controlador principal del juego.
#
# Árbol de escena esperado:
#   Main  (Node2D)
#   ├── Background  (Node2D  →  Background.gd)
#   ├── Player      (Node2D  →  Player.gd)
#   ├── Hud         (CanvasLayer → Hud.gd)
#   └── AudioEQ     (AudioStreamPlayer)   ← opcional
#
# LivesUi    se instancia automáticamente desde res://ui_global/LivesUi.tscn
# GameResult se instancia automáticamente desde res://ui_global/GameResult.tscn
#
# Flujo:
#   1. El juego empieza en WALKING: la chica corre desde el inicio.
#   2. Tras un intervalo aleatorio → EARTHQUAKE:
#      el jugador debe MANTENER PRESIONADO el botón para esconderse.
#      Tiene hide_grace_period segundos de margen al inicio y al soltar.
#   3. Al terminar el terremoto exitosamente → WALKING de nuevo.
#   4. Los terremotos se repiten hasta que:
#      - El progreso llega a 1.0 → WIN
#      - Las vidas llegan a 0   → LOSE
#
# SISTEMA DE ALEATORIEDAD MEJORADO:
#   - _walk_timer separado del _eq_timer (evita bug de reutilización)
#   - Duración variable por terremoto (earthquake_duration_min/max)
#   - Ráfagas: tras un terremoto, probabilidad de que venga otro casi inmediato
#   - Velocidad de caminata varía ligeramente entre tramos

extends Node

# ---- Señales ---------------------------------------------------------------
signal earthquake_started
signal earthquake_ended

# ---- Parámetros exportables ------------------------------------------------
# Intervalo reducido: terremotos más seguidos
@export var earthquake_interval_min: float = 1.0   # antes: 2.0
@export var earthquake_interval_max: float = 4.0   # antes: 8.0

# Duración ahora es un rango, no un valor fijo
@export var earthquake_duration_min: float = 2.5
@export var earthquake_duration_max: float = 5.5

@export var total_walk_distance: float = 3000.0
@export var walk_scroll_speed:   float = 140.0
@export var max_lives:           int   = 3

# Margen de gracia: segundos que tiene el jugador para presionar
# el botón (o para volver a presionarlo si lo soltó) sin perder vida.
@export var hide_grace_period: float = 0.5

# Probabilidad de ráfaga aumentada para más caos
@export var aftershock_chance: float = 0.50        # antes: 0.35

# Intervalo de ráfaga: cuánto tiempo "libre" hay entre terremotos encadenados
@export var aftershock_interval_min: float = 0.3   # antes: 0.4
@export var aftershock_interval_max: float = 1.0   # antes: 1.5

# Variación de velocidad: la velocidad de caminata cambia ±walk_speed_variance
# en cada tramo, rompiendo el ritmo predecible
@export var walk_speed_variance: float = 30.0

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

# ---- Nodos -----------------------------------------------------------------
@onready var _hud:        CanvasLayer       = $Hud
@onready var _background: Node2D            = $Background
@onready var _player:     Node2D            = $Player
@onready var _audio_eq:   AudioStreamPlayer = get_node_or_null("AudioEQ")

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
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.play()
			_hud.show_earthquake_banner()
			emit_signal("earthquake_started")

		State.WIN:
			_button_held   = false
			_current_speed = 0.0
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()
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
			_hud.hide_earthquake_banner()
			if _player and _player.has_method("set_idle"):
				_player.set_idle()
			if _game_result and _game_result.has_method("mostrar_perdiste"):
				_game_result.mostrar_perdiste()


func _schedule_next_earthquake() -> void:
	_walk_timer = 0.0

	if _next_is_aftershock:
		# Ráfaga: intervalo muy corto, el jugador apenas tiene tiempo de reaccionar
		_next_eq_in          = randf_range(aftershock_interval_min, aftershock_interval_max)
		_next_is_aftershock  = false
	else:
		# Intervalo normal aleatorio
		_next_eq_in = randf_range(earthquake_interval_min, earthquake_interval_max)
		# ¿El siguiente será una ráfaga?
		_next_is_aftershock = randf() < aftershock_chance


# ---------------------------------------------------------------------------
func on_player_reached_safe_zone() -> void:
	if _state != State.WIN and _state != State.LOSE:
		_set_state(State.WIN)
