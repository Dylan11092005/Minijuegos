extends Control

# ── Señal que emites al padre cuando el usuario confirma la edad
signal age_selected(age: int)

# ── Referencias a los nodos (ajusta rutas si cambiaste los nombres)
@onready var panda_display: TextureRect = $PandaDisplay
@onready var age_label: Label = $AgeLabel
@onready var stone: TextureButton = $StoneSlider
@onready var bar: TextureRect = $Bar

# ── Las 5 etapas del panda (cárgalas desde tus assets)
var panda_textures: Array[Texture2D] = []

# ── Rangos: índice 0 = Etapa1, ..., 4 = Etapa5
# Formato: [edad_minima, edad_maxima]
const AGE_RANGES = [
	[0,  5],   # Etapa1 — bebé
	[6,  12],  # Etapa2 — niño
	[13, 17],  # Etapa3 — adolescente
	[18, 59],  # Etapa4 — adulto
	[60, 99],  # Etapa5 — adulto mayor
]
const MIN_AGE = 0
const MAX_AGE = 99

# ── Estado interno
var current_age: int = 0
var dragging: bool = false
var drag_offset: float = 0.0

func _ready() -> void:
	# Cargar texturas
	panda_textures = [
		load("res://selector_edad/assets/Etapa1.png"),
		load("res://selector_edad/assets/Etapa2.png"),
		load("res://selector_edad/assets/Etapa3.png"),
		load("res://selector_edad/assets/Etapa4.png"),
		load("res://selector_edad/assets/Etapa5.png"),
	]
	_update_display(MIN_AGE)
	
	# Conectar señales del botón Continuar
	$BtnContinuar.pressed.connect(_on_continuar_pressed)

func _on_continuar_pressed() -> void:
	emit_signal("age_selected", current_age)

# ────────────────────────────────────────────
#  LÓGICA DE ARRASTRE DE LA PIEDRA
# ────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_over_stone(event.position):
				dragging = true
				drag_offset = event.position.x - stone.global_position.x
			else:
				dragging = false

	if event is InputEventMouseMotion and dragging:
		_move_stone(event.position.x - drag_offset)

func _is_over_stone(pos: Vector2) -> bool:
	var rect = Rect2(stone.global_position, stone.size)
	return rect.has_point(pos)

func _move_stone(target_x: float) -> void:
	# Límites de la barra (en coordenadas globales)
	var bar_left: float  = bar.global_position.x
	var bar_right: float = bar.global_position.x + bar.size.x - stone.size.x
	
	# Clampear dentro de la barra
	var new_x = clamp(target_x, bar_left, bar_right)
	stone.global_position.x = new_x
	
	# Convertir posición a edad
	var t = (new_x - bar_left) / (bar_right - bar_left)  # 0.0 … 1.0
	var age = int(round(lerp(float(MIN_AGE), float(MAX_AGE), t)))
	_update_display(age)

# ────────────────────────────────────────────
#  ACTUALIZAR LABEL Y PANDA
# ────────────────────────────────────────────

func _update_display(age: int) -> void:
	current_age = age
	age_label.text = str(age)
	panda_display.texture = panda_textures[_get_stage(age)]

func _get_stage(age: int) -> int:
	for i in range(AGE_RANGES.size()):
		if age >= AGE_RANGES[i][0] and age <= AGE_RANGES[i][1]:
			return i
	return AGE_RANGES.size() - 1  # fallback: última etapa
