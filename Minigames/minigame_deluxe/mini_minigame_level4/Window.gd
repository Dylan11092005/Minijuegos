extends StaticBody2D


# =========================================================
# SEÑALES
# =========================================================

signal closed_in_time(window)
signal expired(window)
signal clicked_while_closed(window)


# =========================================================
# NODOS
# =========================================================

@onready var closed_sprite: Sprite2D = $Closed
@onready var opened_sprite: Sprite2D = $Opened
@onready var wind_sprite: Sprite2D = get_node_or_null("Wind")

var maturity_timer: Timer = null
var wind_tween: Tween = null
var _wind_base_position: Vector2 = Vector2.ZERO


# =========================================================
# ESTADO
# =========================================================

var is_open: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = true

	maturity_timer = Timer.new()
	maturity_timer.one_shot = true
	add_child(maturity_timer)
	maturity_timer.timeout.connect(_on_maturity_timeout)

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

	# Aseguramos el estado visual inicial: cerrada.
	closed_sprite.visible = true
	opened_sprite.visible = false
	is_open = false

	if wind_sprite:
		_wind_base_position = wind_sprite.position
		wind_sprite.visible = false
		wind_sprite.modulate.a = 0.0
		# Orientación al azar para que no todas las ventanas soplen igual.
		wind_sprite.flip_h = (randi() % 2 == 0)


# =========================================================
# API PÚBLICA (llamada desde WindowsMain)
# =========================================================

# Abre la ventana. "duration" es cuánto tiempo tiene el jugador
# para cerrarla antes de que se considere "expirada" (madura).
func open_window(duration: float):
	if is_open:
		return

	is_open = true
	closed_sprite.visible = false
	opened_sprite.visible = true

	_start_wind_animation()

	maturity_timer.start(duration)


# Deja la ventana lista para volver a usarse (cerrada, sin timers activos).
func reset_window():
	is_open = false
	maturity_timer.stop()
	closed_sprite.visible = true
	opened_sprite.visible = false

	_stop_wind_animation()


# =========================================================
# ANIMACIÓN DEL VIENTO (entra mientras la ventana está abierta)
# =========================================================

func _start_wind_animation():
	if not wind_sprite:
		return

	wind_sprite.visible = true
	wind_sprite.modulate.a = 0.0
	wind_sprite.position = _wind_base_position

	if wind_tween and wind_tween.is_valid():
		wind_tween.kill()

	wind_tween = create_tween()
	wind_tween.set_loops()

	# Sopla hacia adentro (aparece y se desplaza), se desvanece, y vuelve a empezar.
	wind_tween.tween_property(wind_sprite, "modulate:a", 0.85, 0.35)
	wind_tween.parallel().tween_property(
		wind_sprite, "position:x", _wind_base_position.x + 14.0, 0.35
	)
	wind_tween.tween_property(wind_sprite, "modulate:a", 0.2, 0.45)
	wind_tween.parallel().tween_property(
		wind_sprite, "position:x", _wind_base_position.x - 6.0, 0.45
	)
	wind_tween.tween_property(wind_sprite, "position:x", _wind_base_position.x, 0.2)


func _stop_wind_animation():
	if wind_tween and wind_tween.is_valid():
		wind_tween.kill()

	if wind_sprite:
		wind_sprite.visible = false
		wind_sprite.modulate.a = 0.0
		wind_sprite.position = _wind_base_position


# =========================================================
# INPUT (click del jugador)
# =========================================================

func _on_input_event(_viewport, event, _shape_idx):
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if is_open:
		_close_now(true)
	else:
		clicked_while_closed.emit(self)


# =========================================================
# MADURACIÓN (se le acabó el tiempo a la ventana)
# =========================================================

func _on_maturity_timeout():
	if not is_open:
		return

	_close_now(false)


# =========================================================
# CIERRE INTERNO
# =========================================================

func _close_now(success: bool):
	is_open = false
	maturity_timer.stop()

	opened_sprite.visible = false
	closed_sprite.visible = true

	_stop_wind_animation()

	if success:
		closed_in_time.emit(self)
	else:
		expired.emit(self)
