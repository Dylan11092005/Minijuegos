extends Control

# ── Señal que emites al padre cuando el usuario confirma la edad
signal age_selected(age: int)

# ── Referencias a los nodos (ajusta rutas si cambiaste los nombres)
@onready var panda_display: TextureRect = $PandaDisplay
@onready var age_label: Label = $AgeLabel
@onready var stone: TextureButton = $StoneSlider
@onready var bar: TextureRect = $Bar

# ── Solo 5 imágenes de panda disponibles
var panda_textures: Array[Texture2D] = []

# ── Rangos de edad (6 tramos, pero comparten solo 5 texturas)
# Formato: [edad_minima, edad_maxima]
const AGE_RANGES = [
	[0,  7],    # Tramo1 — <= 7   -> Etapa1
	[8,  8],    # Tramo2 — 8      -> Etapa2
	[9,  9],    # Tramo3 — 9      -> Etapa3
	[10, 10],   # Tramo4 — 10     -> Etapa4
	[11, 11],   # Tramo5 — 11     -> Etapa5
	[12, 99],   # Tramo6 — >= 12  -> Etapa5 (comparte con el tramo anterior)
]

# ── Mapeo de cada tramo a su índice de textura (0..4, solo 5 imágenes)
const STAGE_TO_TEXTURE = [0, 1, 2, 3, 4, 4]

const MIN_AGE = 7    # La barra empieza en 7
const MAX_AGE = 12   # 12 = "12 o más"

# ── Estado interno
var current_age: int = MIN_AGE
var dragging: bool = false
var drag_offset: float = 0.0

func _ready() -> void:
	# Cargar las 5 texturas
	panda_textures = [
		load("res://age_selector/assets/Etapa1.png"),
		load("res://age_selector/assets/Etapa2.png"),
		load("res://age_selector/assets/Etapa3.png"),
		load("res://age_selector/assets/Etapa4.png"),
		load("res://age_selector/assets/Etapa5.png"),
	]
	_update_display(MIN_AGE)
	
	# Conectar señales del botón Continuar
	$BtnContinuar.pressed.connect(_on_continuar_pressed)

func _on_continuar_pressed() -> void:
	# Guardar la edad seleccionada en el Autoload MinigameData
	MinigameData.player_age = current_age
	emit_signal("age_selected", current_age)
	# Abrir el menú principal
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

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
	
	# Convertir posición a edad (rango 7 a 12)
	var t = (new_x - bar_left) / (bar_right - bar_left)  # 0.0 … 1.0
	var age = int(round(lerp(float(MIN_AGE), float(MAX_AGE), t)))
	_update_display(age)

# ────────────────────────────────────────────
#  ACTUALIZAR LABEL Y PANDA
# ────────────────────────────────────────────
func _update_display(age: int) -> void:
	current_age = age
	if age >= MAX_AGE:
		age_label.text = str(MAX_AGE) + "+"
	elif age <= MIN_AGE:
		age_label.text = str(MIN_AGE) + "-"
	else:
		age_label.text = str(age)
	
	var stage := _get_stage(age)
	panda_display.texture = panda_textures[STAGE_TO_TEXTURE[stage]]

func _get_stage(age: int) -> int:
	for i in range(AGE_RANGES.size()):
		if age >= AGE_RANGES[i][0] and age <= AGE_RANGES[i][1]:
			return i
	return AGE_RANGES.size() - 1  # fallback: último tramo
