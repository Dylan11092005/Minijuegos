extends Area2D


# =========================================================
# SEÑAL
# =========================================================

# Se emite cuando el objeto se soltó lo suficientemente cerca de su
# posición correcta (target_position).
signal placed_correctly(item)


# =========================================================
# CONFIGURACIÓN (la asigna ColdMain al armar el nivel)
# =========================================================

# Posición GLOBAL a la que hay que arrastrar este objeto.
var target_position: Vector2 = Vector2.ZERO

# Qué tan cerca del target hay que soltarlo para que cuente como acierto.
# ColdMain sobreescribe este valor por objeto para ajustar la tolerancia
# exacta que necesite cada uno; esto es solo un respaldo.
var snap_radius: float = 100.0


# =========================================================
# ESTADO INTERNO
# =========================================================

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _placed: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = true
	_original_position = position

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


# =========================================================
# INPUT
# =========================================================

# Detecta cuándo se empieza a arrastrar (el mouse tiene que estar
# efectivamente sobre el objeto para esto).
func _on_input_event(_viewport, event, _shape_idx):
	if _placed:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = true
		_drag_offset = global_position - get_global_mouse_position()
		z_index = 10


# Una vez que el arrastre empezó, seguimos el mouse y detectamos el
# "soltar" acá (con _input, no con input_event), porque el mouse puede
# terminar en cualquier parte de la pantalla, no necesariamente sobre
# la forma de colisión de este objeto.
func _input(event):
	if not _dragging:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + _drag_offset

	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = false
		_try_drop()


# =========================================================
# SOLTAR EL OBJETO
# =========================================================

func _try_drop():
	z_index = 0

	if global_position.distance_to(target_position) <= snap_radius:
		_placed = true
		visible = false
		placed_correctly.emit(self)
	else:
		# No cayó en el lugar correcto: vuelve a su posición original.
		position = _original_position


# =========================================================
# API PÚBLICA (reiniciar para una nueva partida)
# =========================================================

func reset_item():
	_placed = false
	_dragging = false
	position = _original_position
	visible = true
	z_index = 0
