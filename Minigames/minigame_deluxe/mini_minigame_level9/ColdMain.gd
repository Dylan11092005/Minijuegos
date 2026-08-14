extends Node2D


# =========================================================
# PATHS
# =========================================================

const TIMER_UI_SCRIPT_PATH := "res://Minigames/ui_global/TimerUI.gd"


# =========================================================
# GAME SETTINGS
# =========================================================

const GAME_TIME := 45.0

# Qué prenda arrastrable corresponde a qué overlay (ya puesto en el niño,
# pero invisible hasta que se coloque bien).
const PARES_OBJETOS := {
	"Jacket": "KidJacket",
	"Pants": "KidPants",
	"Shoe1": "KidShoe1",
	"Shoe2": "KidShoe2"
}

# Overlays EXTRA que hay que revelar además del overlay principal cuando
# se coloca correctamente cierto objeto. Caso puntual: la cabeza ("Head")
# está oculta al principio y recién aparece cuando se pone la campera,
# porque sin campera se ve raro tener la cabeza sola puesta.
const EXTRAS_POR_OBJETO := {
	"Jacket": ["Head"]
}

# Qué tan cerca (en píxeles) hay que soltar cada prenda de su posición
# correcta para que cuente como acierto. Más grande = más fácil/permisivo.
# OJO con los zapatos: KidShoe1 y KidShoe2 están a solo ~116px entre sí,
# así que su radio tiene que ser chico (bien por debajo de la mitad de esa
# distancia) para que no se solapen las zonas de acierto de ambos pies.
const SNAP_RADIUS_DEFAULT := 100.0
const SNAP_RADIUS_POR_OBJETO := {
	"Jacket": 110.0,
	"Pants": 100.0,
	"Shoe1": 45.0,
	"Shoe2": 45.0
}


# =========================================================
# COLORES DEL PANEL DE RESULTADO PROPIO
# =========================================================

const RC_BEIGE := Color("#E5C89E")
const RC_ORANGE := Color("#E0B080")
const RC_BLUE := Color("#3E5F8F")
const RC_CYAN := Color("#30C0F0")
const RC_LIGHT_BLUE := Color("#C0E0FF")
const RC_WHITE := Color("#F5F5F5")

const RESULT_PANEL_SIZE := Vector2(500, 260)
const RESULT_BUTTON_SIZE := Vector2(240, 56)

const WIN_MESSAGE := "¡Felicidades!\nAbrigaste al niño a tiempo"
const LOSE_MESSAGE := "¡Qué mal!\nSe acabó el tiempo"
const BACK_BUTTON_TEXT := "Volver al mapa"


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("BackgroundSound")
var _background_sound_active: bool = false

@onready var place_item_sound: AudioStreamPlayer = get_node_or_null("PlaceItemSound")

# --- Panel de resultado propio (creado por código) ---
var resultado_layer: CanvasLayer = null
var resultado_panel: Panel = null
var resultado_label: Label = null
var resultado_boton: Button = null


# =========================================================
# VARIABLES
# =========================================================

var game_over: bool = false
var game_started: bool = false

var _resultado_gano: bool = false

var meta_label: Label = null

var draggable_items: Array = []
var placed_count: int = 0
var target_count: int = 0


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	_setup_draggable_items()
	_setup_timer_ui()
	_setup_resultado_ui()
	_setup_resultado_sound()
	_setup_meta_label()

	call_deferred("_start_game")


func _setup_meta_label():
	var meta_layer := CanvasLayer.new()
	meta_layer.name = "MetaLayer"
	meta_layer.layer = 90
	add_child(meta_layer)

	meta_label = Label.new()
	meta_label.add_theme_color_override("font_color", RC_WHITE)
	meta_label.add_theme_font_size_override("font_size", 24)
	meta_label.add_theme_constant_override("outline_size", 7)
	meta_label.add_theme_color_override("font_outline_color", RC_BLUE)
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	meta_label.position = Vector2(-250, 90)
	meta_label.custom_minimum_size = Vector2(500, 36)

	meta_layer.add_child(meta_label)


func _update_meta_label():
	if not meta_label:
		return
	meta_label.text = "Ropa colocada: %d / %d" % [placed_count, target_count]


# =========================================================
# ARMADO DE LAS PRENDAS ARRASTRABLES
# =========================================================

func _setup_draggable_items():
	draggable_items.clear()
	target_count = PARES_OBJETOS.size()

	for nombre_objeto in PARES_OBJETOS.keys():
		var objeto = get_node_or_null(nombre_objeto)
		var nombre_overlay: String = PARES_OBJETOS[nombre_objeto]
		var overlay = get_node_or_null(nombre_overlay)

		if objeto == null:
			push_error("No se encontró el objeto arrastrable: " + nombre_objeto)
			continue
		if overlay == null:
			push_error("No se encontró el overlay del niño: " + nombre_overlay)
			continue
		if not objeto.has_signal("placed_correctly"):
			push_error("El nodo " + nombre_objeto + " no tiene el script DraggableItem.gd asignado.")
			continue

		# La prenda tiene que soltarse cerca de donde va su versión en el niño.
		objeto.target_position = overlay.global_position
		objeto.snap_radius = SNAP_RADIUS_POR_OBJETO.get(nombre_objeto, SNAP_RADIUS_DEFAULT)
		objeto.set_meta("overlay", overlay)

		# Overlays extra que se revelan junto con este (ej: la cabeza junto
		# con la campera). Resolvemos los nodos acá para no buscarlos cada
		# vez que se coloca la prenda.
		var extras: Array = []
		for nombre_extra in EXTRAS_POR_OBJETO.get(nombre_objeto, []):
			var extra_nodo = get_node_or_null(nombre_extra)
			if extra_nodo:
				extras.append(extra_nodo)
			else:
				push_error("No se encontró el overlay extra: " + nombre_extra)
		objeto.set_meta("extras", extras)

		if not objeto.placed_correctly.is_connected(_on_item_placed):
			objeto.placed_correctly.connect(_on_item_placed)

		draggable_items.append(objeto)


# =========================================================
# TIMER UI GLOBAL
# =========================================================

func _setup_timer_ui():
	if ResourceLoader.exists(TIMER_UI_SCRIPT_PATH):
		var timer_script = load(TIMER_UI_SCRIPT_PATH)
		timer_ui = timer_script.new()
		timer_ui.name = "TimerUI"
		add_child(timer_ui)
	else:
		push_error("No se encontró el script de TimerUI en: " + TIMER_UI_SCRIPT_PATH)
		return

	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)


func _start_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("set_tamano_panel"):
		timer_ui.set_tamano_panel(650, 60)

	if timer_ui.has_method("iniciar"):
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para abrigar al niño")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# PANEL DE RESULTADO PROPIO (100% por código, no usa GameResult.tscn)
# =========================================================

func _setup_resultado_ui():
	resultado_layer = CanvasLayer.new()
	resultado_layer.name = "ResultadoLayer"
	resultado_layer.layer = 150
	add_child(resultado_layer)

	resultado_panel = Panel.new()
	resultado_panel.custom_minimum_size = RESULT_PANEL_SIZE
	resultado_panel.visible = false
	resultado_layer.add_child(resultado_panel)

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = RC_BEIGE
	estilo_panel.border_color = RC_ORANGE
	estilo_panel.set_border_width_all(6)
	estilo_panel.set_corner_radius_all(28)
	estilo_panel.shadow_color = Color(0, 0, 0, 0.28)
	estilo_panel.shadow_size = 16
	estilo_panel.content_margin_left = 24
	estilo_panel.content_margin_right = 24
	estilo_panel.content_margin_top = 24
	estilo_panel.content_margin_bottom = 24
	resultado_panel.add_theme_stylebox_override("panel", estilo_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	resultado_panel.add_child(vbox)

	resultado_label = Label.new()
	resultado_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado_label.add_theme_color_override("font_color", RC_BLUE)
	resultado_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(resultado_label)

	resultado_boton = Button.new()
	resultado_boton.text = BACK_BUTTON_TEXT
	resultado_boton.custom_minimum_size = RESULT_BUTTON_SIZE
	resultado_boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var estilo_normal := StyleBoxFlat.new()
	estilo_normal.bg_color = RC_CYAN
	estilo_normal.border_color = RC_BLUE
	estilo_normal.set_border_width_all(4)
	estilo_normal.set_corner_radius_all(18)

	var estilo_hover := estilo_normal.duplicate()
	estilo_hover.bg_color = RC_LIGHT_BLUE

	var estilo_pressed := estilo_normal.duplicate()
	estilo_pressed.bg_color = RC_BLUE
	estilo_pressed.border_color = RC_CYAN

	resultado_boton.add_theme_stylebox_override("normal", estilo_normal)
	resultado_boton.add_theme_stylebox_override("hover", estilo_hover)
	resultado_boton.add_theme_stylebox_override("pressed", estilo_pressed)
	resultado_boton.add_theme_color_override("font_color", RC_WHITE)
	resultado_boton.add_theme_font_size_override("font_size", 22)

	resultado_boton.pressed.connect(_on_volver_al_mapa_pressed)
	vbox.add_child(resultado_boton)


# =========================================================
# SONIDO DE GANAR / PERDER (compartido por todos los minijuegos)
# =========================================================

const WIN_SOUND_PATH := "res://Minigames/ui_global/music/MusicaVictoria.mp3"
const LOSE_SOUND_PATH := "res://Minigames/ui_global/music/JuegoPerdido.mp3"

var resultado_sound_player: AudioStreamPlayer = null


func _setup_resultado_sound():
	resultado_sound_player = AudioStreamPlayer.new()
	resultado_sound_player.name = "ResultadoSoundPlayer"
	add_child(resultado_sound_player)


func _play_resultado_sound(gano: bool):
	if not resultado_sound_player:
		return

	var path: String = WIN_SOUND_PATH if gano else LOSE_SOUND_PATH
	if not ResourceLoader.exists(path):
		push_error("No se encontró el sonido de resultado en: " + path)
		return

	resultado_sound_player.stream = load(path)
	resultado_sound_player.play()


func _mostrar_resultado(gano: bool):
	_resultado_gano = gano
	resultado_label.text = WIN_MESSAGE if gano else LOSE_MESSAGE
	_play_resultado_sound(gano)

	var screen := get_viewport().get_visible_rect().size
	resultado_panel.position = (screen - RESULT_PANEL_SIZE) / 2.0
	resultado_panel.visible = true


func _on_volver_al_mapa_pressed():
	GameState.volver_al_mapa_con_resultado(_resultado_gano)


# =========================================================
# SONIDO DE FONDO
# =========================================================

func _start_background_sound() -> void:
	_background_sound_active = true

	if not background_sound:
		return

	if background_sound.stream:
		if background_sound.stream is AudioStreamWAV:
			background_sound.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif background_sound.stream is AudioStreamOggVorbis:
			background_sound.stream.loop = true

	if not background_sound.finished.is_connected(_on_background_sound_finished):
		background_sound.finished.connect(_on_background_sound_finished)

	background_sound.play()


func _on_background_sound_finished() -> void:
	if _background_sound_active and background_sound:
		background_sound.play()


func _stop_background_sound() -> void:
	_background_sound_active = false

	if background_sound:
		background_sound.stop()


func _play_place_item_sound() -> void:
	if place_item_sound:
		place_item_sound.play()


# =========================================================
# PRENDAS
# =========================================================

func _reset_items():
	placed_count = 0

	for item in draggable_items:
		if item.has_method("reset_item"):
			item.reset_item()

	for nombre_overlay in PARES_OBJETOS.values():
		var overlay = get_node_or_null(nombre_overlay)
		if overlay:
			overlay.visible = false

	for lista_extras in EXTRAS_POR_OBJETO.values():
		for nombre_extra in lista_extras:
			var extra_nodo = get_node_or_null(nombre_extra)
			if extra_nodo:
				extra_nodo.visible = false


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	_reset_items()
	_update_meta_label()
	_start_global_timer()
	_start_background_sound()


# =========================================================
# RESULTADO DE COLOCAR UNA PRENDA
# =========================================================

func _on_item_placed(item: Node):
	if game_over:
		return

	var overlay = item.get_meta("overlay", null)
	if overlay:
		overlay.visible = true

	# Revela los overlays extra asociados (ej: la cabeza al poner la campera).
	var extras: Array = item.get_meta("extras", [])
	for extra_nodo in extras:
		extra_nodo.visible = true

	_play_place_item_sound()

	placed_count += 1
	_update_meta_label()
	if placed_count >= target_count:
		_win_game()


# =========================================================
# WIN / LOSE
# =========================================================

func _on_time_up():
	if game_over:
		return

	_lose_game()


func _win_game():
	if game_over:
		return

	game_over = true
	game_started = false

	_stop_global_timer()
	_stop_background_sound()

	_mostrar_resultado(true)


func _lose_game():
	if game_over:
		return

	game_over = true
	game_started = false

	_stop_global_timer()
	_stop_background_sound()

	_mostrar_resultado(false)
