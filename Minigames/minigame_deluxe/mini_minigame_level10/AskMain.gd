extends Node2D


# =========================================================
# PATHS
# =========================================================
# Ajusta estas rutas a donde tengas guardados tus scripts globales.

const TIMER_UI_SCRIPT_PATH := "res://Minigames/ui_global/TimerUI.gd"
const LIVES_UI_SCRIPT_PATH := "res://Minigames/ui_global/LivesUi.gd"


# =========================================================
# GAME SETTINGS
# =========================================================

const GAME_TIME := 90.0
const MAX_WRONG_ANSWERS := 3

# Cuántas preguntas hay que responder bien para ganar.
const CORRECT_NEEDED_TO_WIN := 5

# Cuánto se muestra el color de acierto/error antes de pasar a la
# siguiente pregunta.
const FEEDBACK_DELAY := 0.9


# =========================================================
# BANCO DE PREGUNTAS
# =========================================================
# Preguntas relacionadas con los temas de TODOS los minijuegos
# (qué debe hacer un niño/a ante cada situación), no preguntas
# técnicas sobre cómo se juega. correct_index es el índice (0-3)
# de la opción correcta dentro de "options".

var question_bank: Array = [
	{
		"question": "Si tiemblas fuerte por un terremoto, ¿qué debes hacer primero?",
		"options": ["Meterte debajo de una mesa fuerte", "Correr afuera lo más rápido posible", "Subir al segundo piso", "Quedarte parado junto a una ventana"],
		"correct_index": 0,
	},
	{
		"question": "Si hueles humo o ves fuego en la escuela, ¿qué es lo correcto?",
		"options": ["Esconderte en el baño", "Avisar a un adulto y salir por la ruta de evacuación", "Apagarlo tú solo con agua", "Seguir jugando y ver qué pasa"],
		"correct_index": 1,
	},
	{
		"question": "¿Por qué es importante no botar basura al río?",
		"options": ["Porque contamina el agua y puede tapar el cauce, causando inundaciones", "Porque a los peces no les gusta el ruido", "Porque el río se pone más profundo", "No tiene ninguna importancia"],
		"correct_index": 0,
	},
	{
		"question": "¿Para qué sirve sembrar árboles en una ladera o montaña?",
		"options": ["Para que se vea más bonito nada más", "Para que sus raíces sostengan la tierra y eviten deslizamientos", "Para tener más sombra en verano", "Para que crezca más pasto"],
		"correct_index": 1,
	},
	{
		"question": "Si hay una alerta de maremoto (tsunami), ¿qué debes hacer?",
		"options": ["Ir a la playa a observar", "Evacuar de inmediato hacia un lugar alto y alejado de la costa", "Meterte al mar para nadar más rápido", "Esperar a ver si sube el agua"],
		"correct_index": 1,
	},
	{
		"question": "En un botiquín de primeros auxilios, ¿qué se debe hacer con cada utensilio médico?",
		"options": ["Guardarlos todos revueltos", "Colocar cada uno en su lugar correcto para encontrarlo rápido", "Dejarlos tirados en el piso", "Botar los que no se usan seguido"],
		"correct_index": 1,
	},
	{
		"question": "Si un alimento ya pasó su fecha de vencimiento, ¿qué se debe hacer?",
		"options": ["Cocinarlo igual, no pasa nada", "Descartarlo, no se debe comer", "Guardarlo para después", "Dárselo a otra persona"],
		"correct_index": 1,
	},
	{
		"question": "¿Cuál es el número de emergencia al que debes llamar si necesitas ayuda urgente?",
		"options": ["911", "123", "000", "555"],
		"correct_index": 0,
	},
	{
		"question": "¿Por qué las alarmas de emergencia deben tener también luces y no solo sonido?",
		"options": ["Porque se ven más bonitas", "Para que las personas con discapacidad auditiva también puedan darse cuenta", "Porque son más baratas", "No hay ninguna razón especial"],
		"correct_index": 1,
	},
	{
		"question": "Durante una evacuación, ¿cómo debes caminar?",
		"options": ["Corriendo y empujando a los demás", "Caminando rápido, en orden y sin correr", "Muy despacio, deteniéndote a cada rato", "Como cada quien quiera"],
		"correct_index": 1,
	},
	{
		"question": "Si te separas de tu familia durante una emergencia, ¿qué debes hacer?",
		"options": ["Quedarte donde estás sin decirle a nadie", "Ir al punto de encuentro acordado con tu familia", "Salir a buscarlos por toda la ciudad", "Esconderte hasta que anochezca"],
		"correct_index": 1,
	},
	{
		"question": "¿Por qué es importante participar en el Plan de Seguridad Escolar?",
		"options": ["Porque así sales antes de clases", "Porque ayuda a que todos sepan qué hacer y estén más seguros ante una emergencia", "Porque es un requisito sin importancia", "Porque solo participan los maestros"],
		"correct_index": 1,
	},
	{
		"question": "Si ves una fuga o grieta en una tubería de agua, ¿qué es lo correcto?",
		"options": ["Ignorarla, no es importante", "Avisar para que la reparen y evitar que se desperdicie el agua", "Abrir más la llave", "Taparla con tierra"],
		"correct_index": 1,
	},
	{
		"question": "¿Qué NIÑEZ tiene incluso durante un desastre?",
		"options": ["Ninguna, todo se suspende", "Derechos, como estar protegida y recibir ayuda", "Solamente obligaciones", "Nada distinto a los adultos"],
		"correct_index": 1,
	},
	{
		"question": "Antes de construir viviendas cerca de un volcán activo, ¿qué se debe considerar?",
		"options": ["Nada, se puede construir donde sea", "El riesgo que representa y buscar una zona más segura", "Solo el precio del terreno", "Que tenga buena vista"],
		"correct_index": 1,
	},
	{
		"question": "En un comité de emergencia escolar, ¿por qué es importante asignar roles (primeros auxilios, evacuación, comunicación)?",
		"options": ["Para que cada quien sepa qué hacer y la ayuda sea más rápida y ordenada", "Para tener más tareas sin sentido", "No es importante, cada quien hace lo que quiera", "Solo para que participen los mayores"],
		"correct_index": 0,
	},
	{
		"question": "Si tu comunidad deforestó un bosque, ¿qué puede pasar con más facilidad?",
		"options": ["Nada cambia", "Deslizamientos e inundaciones, porque el suelo pierde sostén", "El clima se vuelve más frío", "Crecen más árboles solos"],
		"correct_index": 1,
	},
	{
		"question": "Cuando termina el temblor de un terremoto, ¿qué debes hacer?",
		"options": ["Salir de inmediato con calma, por rutas seguras", "Quedarte debajo de la mesa por horas", "Ir corriendo a las escaleras eléctricas", "Volver a dormir"],
		"correct_index": 0,
	},
]


# =========================================================
# COLORES DEL PANEL / UI
# =========================================================

const RC_BEIGE := Color("#E5C89E")
const RC_ORANGE := Color("#E0B080")
const RC_BLUE := Color("#3E5F8F")
const RC_CYAN := Color("#30C0F0")
const RC_LIGHT_BLUE := Color("#C0E0FF")
const RC_WHITE := Color("#F5F5F5")
const RC_GREEN := Color("#4CAF7D")
const RC_RED := Color("#E06060")

const RESULT_PANEL_SIZE := Vector2(500, 260)
const RESULT_BUTTON_SIZE := Vector2(240, 56)

const WIN_MESSAGE := "¡Felicidades!\nRespondiste bien las preguntas"
const LOSE_MESSAGE := "¡Qué mal!\nNo lograste responder suficientes preguntas"
const BACK_BUTTON_TEXT := "Volver al mapa"

const QUIZ_PANEL_SIZE := Vector2(950, 520)
const OPTION_BUTTON_SIZE := Vector2(860, 70)


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("Background")
var _background_sound_active: bool = false

@onready var correct_sound: AudioStreamPlayer = get_node_or_null("CorrectAnswer")
@onready var wrong_sound: AudioStreamPlayer = get_node_or_null("WrongAnswer")

var lives_layer: CanvasLayer = null
var lives_ui = null

# --- Panel de resultado propio (creado por código) ---
var resultado_layer: CanvasLayer = null
var resultado_panel: Panel = null
var resultado_label: Label = null
var resultado_boton: Button = null

# --- Panel del quiz (creado por código) ---
var quiz_layer: CanvasLayer = null
var quiz_panel: Panel = null
var progress_label: RichTextLabel = null
var question_label: Label = null
var option_buttons: Array = []
var option_styles_normal: Array = []


# =========================================================
# VARIABLES
# =========================================================

var current_wrong: int = 0
var correct_count: int = 0
var game_over: bool = false
var game_started: bool = false
var _answer_locked: bool = false

var _resultado_gano: bool = false

var _remaining_questions: Array = []
var _current_question: Dictionary = {}


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()

	_setup_timer_ui()
	_setup_resultado_ui()
	_setup_resultado_sound()
	_setup_lives_ui()
	_setup_quiz_ui()

	call_deferred("_start_game")


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
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para responder las preguntas")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# VIDAS GLOBAL (una "vida" = un intento equivocado permitido)
# =========================================================

func _setup_lives_ui():
	if lives_layer:
		return

	lives_layer = CanvasLayer.new()
	lives_layer.name = "LivesLayer"
	lives_layer.layer = 120
	add_child(lives_layer)

	if ResourceLoader.exists(LIVES_UI_SCRIPT_PATH):
		var lives_script = load(LIVES_UI_SCRIPT_PATH)
		lives_ui = Node2D.new()
		lives_ui.name = "LivesUI"
		lives_ui.set_script(lives_script)
		lives_layer.add_child(lives_ui)
	else:
		push_error("No se encontró LivesUi.gd en: " + LIVES_UI_SCRIPT_PATH)
		return

	if lives_ui.has_method("set_max_lives"):
		lives_ui.set_max_lives(MAX_WRONG_ANSWERS)
	else:
		lives_ui.set("max_lives", MAX_WRONG_ANSWERS)

	_update_lives_ui()


func _update_lives_ui():
	if not lives_ui:
		return

	var lives_left: int = MAX_WRONG_ANSWERS - current_wrong

	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.actualizar_vidas(lives_left)
	else:
		lives_ui.set("current_lives", lives_left)

	if lives_ui.has_method("queue_redraw"):
		lives_ui.queue_redraw()


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

	if quiz_panel:
		quiz_panel.visible = false

	var screen := get_viewport().get_visible_rect().size
	resultado_panel.position = (screen - RESULT_PANEL_SIZE) / 2.0
	resultado_panel.visible = true


func _on_volver_al_mapa_pressed():
	GameState.volver_al_mapa_con_resultado(_resultado_gano)


# =========================================================
# PANEL DEL QUIZ (100% por código)
# =========================================================

func _setup_quiz_ui():
	quiz_layer = CanvasLayer.new()
	quiz_layer.name = "QuizLayer"
	quiz_layer.layer = 100
	add_child(quiz_layer)

	quiz_panel = Panel.new()
	quiz_panel.custom_minimum_size = QUIZ_PANEL_SIZE
	quiz_layer.add_child(quiz_panel)

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = RC_BEIGE
	estilo_panel.border_color = RC_ORANGE
	estilo_panel.set_border_width_all(6)
	estilo_panel.set_corner_radius_all(28)
	estilo_panel.shadow_color = Color(0, 0, 0, 0.28)
	estilo_panel.shadow_size = 16
	estilo_panel.content_margin_left = 32
	estilo_panel.content_margin_right = 32
	estilo_panel.content_margin_top = 24
	estilo_panel.content_margin_bottom = 24
	quiz_panel.add_theme_stylebox_override("panel", estilo_panel)

	var screen := get_viewport().get_visible_rect().size
	quiz_panel.position = (screen - QUIZ_PANEL_SIZE) / 2.0

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	quiz_panel.add_child(vbox)

	progress_label = RichTextLabel.new()
	progress_label.bbcode_enabled = true
	progress_label.fit_content = true
	progress_label.scroll_active = false
	progress_label.custom_minimum_size = Vector2(QUIZ_PANEL_SIZE.x - 64, 30)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("normal_font_size", 20)
	vbox.add_child(progress_label)

	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.custom_minimum_size = Vector2(QUIZ_PANEL_SIZE.x - 64, 0)
	question_label.add_theme_color_override("font_color", RC_BLUE)
	question_label.add_theme_font_size_override("font_size", 30)
	vbox.add_child(question_label)

	option_buttons.clear()
	option_styles_normal.clear()

	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = OPTION_BUTTON_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var estilo_normal := StyleBoxFlat.new()
		estilo_normal.bg_color = RC_CYAN
		estilo_normal.border_color = RC_BLUE
		estilo_normal.set_border_width_all(4)
		estilo_normal.set_corner_radius_all(16)

		var estilo_hover := estilo_normal.duplicate()
		estilo_hover.bg_color = RC_LIGHT_BLUE

		var estilo_pressed := estilo_normal.duplicate()
		estilo_pressed.bg_color = RC_BLUE
		estilo_pressed.border_color = RC_CYAN

		button.add_theme_stylebox_override("normal", estilo_normal)
		button.add_theme_stylebox_override("hover", estilo_hover)
		button.add_theme_stylebox_override("pressed", estilo_pressed)
		button.add_theme_color_override("font_color", RC_WHITE)
		button.add_theme_font_size_override("font_size", 22)

		button.pressed.connect(_on_option_pressed.bind(i))

		vbox.add_child(button)
		option_buttons.append(button)
		option_styles_normal.append(estilo_normal)

	quiz_panel.visible = false


func _set_option_color(index: int, color: Color) -> void:
	var button: Button = option_buttons[index]

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = RC_BLUE
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(16)

	button.add_theme_stylebox_override("normal", estilo)
	button.add_theme_stylebox_override("hover", estilo)
	button.add_theme_stylebox_override("pressed", estilo)


func _reset_option_colors() -> void:
	for i in range(option_buttons.size()):
		option_buttons[i].add_theme_stylebox_override("normal", option_styles_normal[i])
		var base_style: StyleBoxFlat = option_styles_normal[i]
		var hover: StyleBoxFlat = base_style.duplicate()
		hover.bg_color = RC_LIGHT_BLUE
		option_buttons[i].add_theme_stylebox_override("hover", hover)
		option_buttons[i].disabled = false


# =========================================================
# LÓGICA DE PREGUNTAS
# =========================================================

func _update_progress_label() -> void:
	if not progress_label:
		return

	var correct_hex: String = RC_GREEN.to_html(false)
	var wrong_hex: String = RC_RED.to_html(false)

	progress_label.text = "[color=#%s]Correctas: %d / %d[/color]      [color=#%s]Errores: %d / %d[/color]" % [
		correct_hex, correct_count, CORRECT_NEEDED_TO_WIN,
		wrong_hex, current_wrong, MAX_WRONG_ANSWERS,
	]


func _prepare_question_pool():
	_remaining_questions = question_bank.duplicate()
	_remaining_questions.shuffle()


func _load_next_question():
	if _remaining_questions.is_empty():
		_prepare_question_pool()

	_current_question = _remaining_questions.pop_front()
	_answer_locked = false

	_update_progress_label()
	question_label.text = _current_question["question"]

	var options: Array = _current_question["options"]
	for i in range(option_buttons.size()):
		option_buttons[i].text = options[i]

	_reset_option_colors()


func _on_option_pressed(index: int):
	if game_over or _answer_locked:
		return

	_answer_locked = true

	for button in option_buttons:
		button.disabled = true

	var correct_index: int = _current_question["correct_index"]

	if index == correct_index:
		_set_option_color(index, RC_GREEN)
		_play_correct_sound()
		correct_count += 1
	else:
		_set_option_color(index, RC_RED)
		_set_option_color(correct_index, RC_GREEN)
		_play_wrong_sound()
		current_wrong += 1
		_update_lives_ui()

	_update_progress_label()

	await get_tree().create_timer(FEEDBACK_DELAY).timeout

	if game_over:
		return

	if correct_count >= CORRECT_NEEDED_TO_WIN:
		_win_game()
	elif current_wrong >= MAX_WRONG_ANSWERS:
		_lose_game()
	else:
		_load_next_question()


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


func _play_correct_sound() -> void:
	if correct_sound:
		correct_sound.play()


func _play_wrong_sound() -> void:
	if wrong_sound:
		wrong_sound.play()


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	correct_count = 0
	current_wrong = 0

	_prepare_question_pool()
	_update_lives_ui()

	quiz_panel.visible = true
	resultado_panel.visible = false

	_load_next_question()
	_start_global_timer()
	_start_background_sound()


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
