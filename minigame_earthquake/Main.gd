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
# IMPORTANTE: Main debe ser de tipo Node2D (o el nodo raíz debe permitir
# z_index en sus hijos 2D). Si Main es un Node simple, los z_index de
# Background y Player igualmente funcionan porque Viewport los respeta,
# pero asegúrate de que el orden en el árbol sea:
#   Background primero, luego Player, luego Hud (CanvasLayer siempre va al frente)
#
# Flujo:
#   1. El juego empieza en WAITING.
#   2. Tras un intervalo aleatorio → EARTHQUAKE:
#      el jugador debe presionar el botón para esconderse.
#   3. Al terminar el terremoto → WALKING:
#      la chica avanza (Background mueve el mundo, no la chica).
#   4. Cuando el progreso llega a 1.0 → WIN.

extends Node

# ---- Señales ---------------------------------------------------------------
signal earthquake_started
signal earthquake_ended

# ---- Parámetros exportables ------------------------------------------------
@export var earthquake_interval_min: float = 3.0
@export var earthquake_interval_max: float = 7.0
@export var earthquake_duration:     float = 4.0

# Distancia total que debe recorrer el "mundo" (en píxeles a velocidad 1)
@export var total_walk_distance: float = 3000.0

# Velocidades del scroll (px/s)
@export var idle_scroll_speed:  float = 0.0    # sin moverse
@export var walk_scroll_speed:  float = 140.0

# ---- Estado interno --------------------------------------------------------
enum State { WAITING, EARTHQUAKE, WALKING, WIN }
var _state: State = State.WAITING

var _eq_timer:   float = 0.0   # tiempo acumulado en estado actual
var _next_eq_in: float = 0.0   # cuándo dispara el próximo terremoto

var _distance_traveled: float = 0.0
var _current_speed:     float = 0.0

# ---- Nodos -----------------------------------------------------------------
@onready var _hud:        CanvasLayer       = $Hud
@onready var _background: Node2D            = $Background
@onready var _player:     Node2D            = $Player
@onready var _audio_eq:   AudioStreamPlayer = get_node_or_null("AudioEQ")  # puede faltar


func _ready() -> void:
	_schedule_next_earthquake()
	_hud.hide_earthquake_banner()
	_set_state(State.WAITING)


func _process(delta: float) -> void:
	match _state:
		State.WAITING:
			_process_waiting(delta)
		State.EARTHQUAKE:
			_process_earthquake(delta)
		State.WALKING:
			_process_walking(delta)


# ---------------------------------------------------------------------------
func _process_waiting(delta: float) -> void:
	_eq_timer += delta
	if _eq_timer >= _next_eq_in:
		_set_state(State.EARTHQUAKE)


func _process_earthquake(delta: float) -> void:
	_eq_timer += delta
	if _eq_timer >= earthquake_duration:
		_set_state(State.WALKING)


func _process_walking(delta: float) -> void:
	_distance_traveled += _current_speed * delta
	var progress = clamp(_distance_traveled / total_walk_distance, 0.0, 1.0)

	_hud.update_progress(progress)
	_background.update_progress(progress)

	# Scroll del fondo
	_scroll_background(delta)

	if progress >= 1.0:
		_set_state(State.WIN)


func _scroll_background(delta: float) -> void:
	if _background.has_method("scroll_step"):
		_background.scroll_step(_current_speed, delta)


# ---------------------------------------------------------------------------
func _set_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.WAITING:
			_current_speed = idle_scroll_speed
			_schedule_next_earthquake()

		State.EARTHQUAKE:
			_eq_timer = 0.0
			_current_speed = 0.0
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.play()
			_hud.show_earthquake_banner()
			emit_signal("earthquake_started")

		State.WALKING:
			if _audio_eq and is_instance_valid(_audio_eq):
				_audio_eq.stop()
			_hud.hide_earthquake_banner()
			_current_speed = walk_scroll_speed
			emit_signal("earthquake_ended")

		State.WIN:
			_current_speed = 0.0
			_hud.show_win()


func _schedule_next_earthquake() -> void:
	_eq_timer    = 0.0
	_next_eq_in  = randf_range(earthquake_interval_min, earthquake_interval_max)


# ---------------------------------------------------------------------------
# Llamado por Player cuando llega a la zona segura
func on_player_reached_safe_zone() -> void:
	if _state != State.WIN:
		_set_state(State.WIN)
