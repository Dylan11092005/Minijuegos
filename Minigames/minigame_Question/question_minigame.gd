extends Node2D

@export var time_limit := 60.0
@export var lives_limit := 3
@export var required_correct_answers := 5

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

var game_active := false
var already_finished := false

var lives := 3
var correct_answers := 0
var current_question_index := 0

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var lives_ui: Node
var lives_layer: CanvasLayer

var questions := [
	{
		"question": "¿Qué derecho tiene la niñez durante una emergencia?",
		"options": [
			"Recibir protección y ayuda",
			"Quedarse sola",
			"No recibir información",
			"Ser ignorada"
		],
		"correct": 0
	},
	{
		"question": "¿Qué necesita un niño o niña durante un desastre?",
		"options": [
			"Protección, alimento y atención",
			"Estar sin adultos",
			"No recibir apoyo",
			"Resolver todo solo"
		],
		"correct": 0
	},
	{
		"question": "¿Qué se debe hacer si un niño o niña se pierde en una emergencia?",
		"options": [
			"Dejarlo solo",
			"Buscar ayuda de adultos o autoridades",
			"No avisar a nadie",
			"Castigarlo"
		],
		"correct": 1
	},
	{
		"question": "¿Por qué se deben proteger los derechos de la niñez en desastres?",
		"options": [
			"Porque tienen derechos y necesitan seguridad",
			"Porque no son importantes",
			"Porque deben ayudar a todos",
			"Porque no necesitan cuidado"
		],
		"correct": 0
	},
	{
		"question": "¿Cuál acción respeta los derechos de los niños y niñas?",
		"options": [
			"Ignorar sus emociones",
			"Escuchar sus necesidades",
			"Separarlos sin explicación",
			"No darles información"
		],
		"correct": 1
	},
	{
		"question": "Después de un desastre, la niñez debe recibir:",
		"options": [
			"Apoyo emocional y seguridad",
			"Menos atención",
			"Castigos",
			"Abandono"
		],
		"correct": 0
	},
	{
		"question": "¿Qué significa proteger a la niñez durante una emergencia?",
		"options": [
			"Brindar seguridad, cuidado y apoyo",
			"No escuchar sus necesidades",
			"Separarlos de sus familias sin razón",
			"Dejarlos sin información"
		],
		"correct": 0
	},
	{
		"question": "¿Cuál es una forma correcta de ayudar a un niño o niña en un desastre?",
		"options": [
			"Escucharlo y llevarlo a un lugar seguro",
			"Ignorarlo",
			"Asustarlo más",
			"Decirle que no pregunte"
		],
		"correct": 0
	}
]

@onready var background: ColorRect = $Background
@onready var top_bar: ColorRect = $TopBar
@onready var title_label: Label = $TopBar/TitleLabel
@onready var question_panel: Panel = $QuestionPanel
@onready var question_label: Label = $QuestionPanel/QuestionLabel
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var score_label: Label = $ScoreLabel

@onready var option_buttons: Array[Button] = [
	$OptionsContainer/OptionButton1,
	$OptionsContainer/OptionButton2,
	$OptionsContainer/OptionButton3,
	$OptionsContainer/OptionButton4
]


func _ready() -> void:
	randomize()
	add_to_group("game_manager")

	create_timer()
	create_game_result_panel()
	create_lives_ui()
	setup_scene_style()
	connect_buttons()

	start_game()


func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		setup_scene_style()


func create_timer() -> void:
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true

	if timer_hud.has_signal("time_up"):
		timer_hud.time_up.connect(_on_time_up)

	if timer_hud.has_method("set_tamano_panel"):
		timer_hud.set_tamano_panel(520, 65)


func create_game_result_panel() -> void:
	game_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(game_result_panel)
	game_result_panel.layer = 60


func create_lives_ui() -> void:
	var new_lives_ui = LIVES_UI_SCENE.instantiate()

	if new_lives_ui is CanvasLayer:
		lives_ui = new_lives_ui
		add_child(lives_ui)
		lives_ui.layer = 55
	else:
		lives_layer = CanvasLayer.new()
		lives_layer.layer = 55
		add_child(lives_layer)

		lives_ui = new_lives_ui
		lives_layer.add_child(lives_ui)

	if lives_ui.has_method("set_panel_corner"):
		lives_ui.call("set_panel_corner", LivesUi.PanelCorner.TOP_RIGHT)

	if lives_ui.has_method("set_panel_margin"):
		lives_ui.call("set_panel_margin", Vector2(35, 20))

	setup_lives_ui()


func setup_lives_ui() -> void:
	if lives_ui == null:
		return

	if lives_ui.has_method("set_max_lives"):
		lives_ui.call("set_max_lives", lives_limit)
	elif lives_ui.has_method("set_total_lives"):
		lives_ui.call("set_total_lives", lives_limit)
	elif lives_ui.has_method("set_max_vidas"):
		lives_ui.call("set_max_vidas", lives_limit)

	update_lives_ui()


func update_lives_ui() -> void:
	if lives_ui == null:
		return

	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.call("actualizar_vidas", lives)
	elif lives_ui.has_method("update_lives"):
		lives_ui.call("update_lives", lives)
	elif lives_ui.has_method("set_lives"):
		lives_ui.call("set_lives", lives)
	elif lives_ui.has_method("set_current_lives"):
		lives_ui.call("set_current_lives", lives)
	else:
		print("ERROR: LivesUi no tiene método para actualizar vidas.")


func connect_buttons() -> void:
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(func(): _on_option_selected(i))


func start_game() -> void:
	game_active = true
	already_finished = false

	lives = lives_limit
	correct_answers = 0
	current_question_index = 0

	questions.shuffle()

	update_lives_ui()
	update_score_ui()
	show_question()

	if timer_hud.has_method("detener"):
		timer_hud.detener()

	if timer_hud.has_method("iniciar"):
		timer_hud.iniciar(time_limit, "Tiempo", "responde las preguntas")


func show_question() -> void:
	if already_finished:
		return

	if current_question_index >= questions.size():
		questions.shuffle()
		current_question_index = 0

	var current_question = questions[current_question_index]

	question_label.text = current_question["question"]

	for i in range(option_buttons.size()):
		option_buttons[i].text = current_question["options"][i]
		option_buttons[i].disabled = false


func _on_option_selected(selected_index: int) -> void:
	if not game_active or already_finished:
		return

	var current_question = questions[current_question_index]

	disable_buttons()

	if selected_index == current_question["correct"]:
		correct_answers += 1
		update_score_ui()

		if correct_answers >= required_correct_answers:
			await get_tree().create_timer(0.6).timeout
			win_game()
			return
	else:
		lives -= 1

		if lives < 0:
			lives = 0

		update_lives_ui()

		if lives <= 0:
			await get_tree().create_timer(0.6).timeout
			lose_game()
			return

	await get_tree().create_timer(0.7).timeout

	current_question_index += 1
	show_question()


func disable_buttons() -> void:
	for button in option_buttons:
		button.disabled = true


func update_score_ui() -> void:
	score_label.text = "Correctas: " + str(correct_answers) + " / " + str(required_correct_answers)


func _on_time_up() -> void:
	if game_active and not already_finished:
		lose_game()


func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	if timer_hud != null and timer_hud.has_method("detener"):
		timer_hud.detener()

	disable_buttons()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_ganaste"):
			game_result_panel.mostrar_ganaste()
		elif game_result_panel.has_method("show_win"):
			game_result_panel.show_win()


func lose_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	if timer_hud != null and timer_hud.has_method("detener"):
		timer_hud.detener()

	disable_buttons()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_perdiste"):
			game_result_panel.mostrar_perdiste()
		elif game_result_panel.has_method("show_lose"):
			game_result_panel.show_lose()


func setup_scene_style() -> void:
	var screen_size := get_viewport_rect().size
	var screen_width := screen_size.x
	var screen_height := screen_size.y

	background.position = Vector2.ZERO
	background.size = screen_size
	background.color = Color("#4B535C")

	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(screen_width, screen_height * 0.12)
	top_bar.color = Color("#2FA85A")

	title_label.position = Vector2.ZERO
	title_label.size = top_bar.size
	title_label.text = "DERECHOS DE LA NIÑEZ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", int(screen_height * 0.045))
	title_label.add_theme_color_override("font_color", Color.WHITE)

	var question_width := screen_width * 0.74
	var question_height := screen_height * 0.22
	var question_x := (screen_width - question_width) / 2.0
	var question_y := screen_height * 0.18

	question_panel.position = Vector2(question_x, question_y)
	question_panel.size = Vector2(question_width, question_height)

	question_label.position = Vector2(35, 20)
	question_label.size = Vector2(question_width - 70, question_height - 40)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", int(screen_height * 0.04))
	question_label.add_theme_color_override("font_color", Color("#333333"))

	var options_width := screen_width * 0.68
	var options_height := screen_height * 0.36
	var options_x := (screen_width - options_width) / 2.0
	var options_y := question_y + question_height + screen_height * 0.055

	options_container.position = Vector2(options_x, options_y)
	options_container.size = Vector2(options_width, options_height)
	options_container.add_theme_constant_override("separation", int(screen_height * 0.025))

	var button_height := screen_height * 0.075

	for button in option_buttons:
		button.custom_minimum_size = Vector2(options_width, button_height)
		button.add_theme_font_size_override("font_size", int(screen_height * 0.032))

	score_label.position = Vector2(0, screen_height - screen_height * 0.105)
	score_label.size = Vector2(screen_width, screen_height * 0.07)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", int(screen_height * 0.035))
	score_label.add_theme_color_override("font_color", Color.WHITE)
