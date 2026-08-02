extends Node2D
class_name Faucet

# Multiplica cuánto recorre la gota (y por lo tanto, qué tan lejos
# del grifo aparece el charco final).
const DROP_TRAVEL_MULTIPLIER := 4.5


# =========================================================
# SEÑALES
# =========================================================

signal clicked(faucet)


# =========================================================
# ESTADO
# =========================================================

var is_open: bool = false


# =========================================================
# NODOS
# =========================================================
# Estructura esperada dentro de esta escena (Faucet.tscn):
#   Faucet (Node2D, este script)
#     - FaucetSprite (Sprite2D)   -> la textura de la llave (color A/B/C)
#     - WaterDrop (Node2D)
#         - Sprite2D              -> la gota de agua
#     - Waterfall (Sprite2D)      -> tu sprite de "agua ya caída"
#     - Area2D
#         - CollisionShape2D      -> cubre la llave, para detectar el clic

@onready var area: Area2D = $Area2D
@onready var water_drop: Node2D = $WaterDrop
@onready var waterfall: Sprite2D = $Waterfall

var _drop_tween: Tween = null
var _drop_start_y: float = 0.0
var _drop_end_y: float = 0.0


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	area.input_event.connect(_on_area_input_event)

	# Guardamos la posición Y de inicio (llave) tal como la dejaste en el editor,
	# y calculamos el punto final triplicando la distancia original hasta
	# donde habías puesto el Waterfall. Luego movemos el Waterfall a ese
	# nuevo punto para que el charco aparezca justo donde cae la gota.
	_drop_start_y = water_drop.position.y

	var original_end_y: float = waterfall.position.y
	var original_distance: float = original_end_y - _drop_start_y
	_drop_end_y = _drop_start_y + (original_distance * DROP_TRAVEL_MULTIPLIER)

	waterfall.position.y = _drop_end_y

	water_drop.visible = false
	waterfall.visible = false


# =========================================================
# INPUT
# =========================================================

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


# =========================================================
# ABRIR / CERRAR
# =========================================================

func open():
	if is_open:
		return

	is_open = true
	water_drop.visible = true
	waterfall.visible = true
	_start_drop_loop()


func close():
	if not is_open:
		return

	is_open = false
	water_drop.visible = false
	waterfall.visible = false
	_stop_drop_loop()


# =========================================================
# ANIMACIÓN DE LA GOTA
# =========================================================

func _start_drop_loop():
	_stop_drop_loop()

	water_drop.position.y = _drop_start_y

	_drop_tween = create_tween()
	_drop_tween.set_loops()
	_drop_tween.tween_property(water_drop, "position:y", _drop_end_y, 0.6)
	_drop_tween.tween_callback(func(): water_drop.position.y = _drop_start_y)


func _stop_drop_loop():
	if _drop_tween:
		_drop_tween.kill()
		_drop_tween = null
