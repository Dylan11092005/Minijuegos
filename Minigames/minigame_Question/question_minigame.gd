extends Node2D

@export var TOTAL_TIME: float = 60.0
@export var lives_limit := 3
@export var max_rounds := 8
@export var required_correct_answers := 8

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

const BACKGROUND_MUSIC = preload("res://Minigames/minigame_Question/Music/Music1.mp3")
const CORRECT_SOUND = preload("res://Minigames/minigame_Question/Music/Correct.mp3")
const INCORRECT_SOUND = preload("res://Minigames/minigame_Question/Music/Incorrect.mp3")

const GLOBAL_SOUND_VOLUME := -10.0

var game_active := false
var already_finished := false

var lives := 3
var correct_answers := 0
var current_round := 1
var current_question_index := 0
var current_correct_index := 0

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var lives_ui: Node
var lives_layer: CanvasLayer

var score_panel: Panel

var background_music_player: AudioStreamPlayer
var correct_sound_player: AudioStreamPlayer
var incorrect_sound_player: AudioStreamPlayer

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var questions := [
	{
		"question": "¿Qué debes hacer si empieza una emergencia?",
		"options": [
			"Buscar a un adulto de confianza",
			"Correr solo",
			"Esconderte sin avisar",
			"Salir a jugar"
		],
		"correct": 0
	},
	{
		"question": "Si hay una emergencia, ¿qué número se puede llamar?",
		"options": [
			"911",
			"123",
			"555",
			"000"
		],
		"correct": 0
	},
	{
		"question": "¿Qué necesita un niño o niña durante un desastre?",
		"options": [
			"Protección y ayuda",
			"Estar solo",
			"No comer",
			"No hablar"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer si tienes miedo?",
		"options": [
			"Contarle a un adulto",
			"Guardar silencio",
			"Salir corriendo",
			"Esconderte solo"
		],
		"correct": 0
	},
	{
		"question": "¿Qué lugar es mejor durante una emergencia?",
		"options": [
			"Un lugar seguro",
			"Un río crecido",
			"Una calle peligrosa",
			"Un árbol quemándose"
		],
		"correct": 0
	},
	{
		"question": "Si ves a un niño perdido, ¿qué debes hacer?",
		"options": [
			"Avisar a un adulto",
			"Dejarlo solo",
			"Reírte",
			"Ignorarlo"
		],
		"correct": 0
	},
	{
		"question": "¿Quiénes deben cuidar a los niños en una emergencia?",
		"options": [
			"Adultos responsables",
			"Nadie",
			"Solo otros niños",
			"Personas desconocidas"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer si alguien está herido?",
		"options": [
			"Pedir ayuda",
			"No decir nada",
			"Seguir jugando",
			"Irte lejos"
		],
		"correct": 0
	},
	{
		"question": "¿Qué derecho tienen los niños y niñas?",
		"options": [
			"Ser protegidos",
			"Ser ignorados",
			"Estar en peligro",
			"No recibir ayuda"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer durante una evacuación?",
		"options": [
			"Seguir las instrucciones",
			"Empujar a todos",
			"Correr sin mirar",
			"Separarte del grupo"
		],
		"correct": 0
	},
	{
		"question": "Si estás en un refugio, ¿qué debes hacer?",
		"options": [
			"Permanecer con tu familia o encargado",
			"Salir solo",
			"Pelear",
			"Esconderte"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debe recibir un niño después de un desastre?",
		"options": [
			"Apoyo y cariño",
			"Castigos",
			"Burla",
			"Abandono"
		],
		"correct": 0
	},
	{
		"question": "¿Qué es importante llevar en una emergencia?",
		"options": [
			"Agua y alimentos",
			"Juguetes peligrosos",
			"Piedras",
			"Basura"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer si escuchas una alarma?",
		"options": [
			"Prestar atención y obedecer",
			"Ignorarla",
			"Taparte los oídos",
			"Seguir jugando"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer si no entiendes algo en una emergencia?",
		"options": [
			"Preguntar a un adulto",
			"Quedarte con la duda",
			"Inventar qué hacer",
			"Irte solo"
		],
		"correct": 0
	},
	{
		"question": "¿Cómo deben tratar a los niños y niñas?",
		"options": [
			"Con respeto",
			"Con gritos",
			"Con burlas",
			"Con golpes"
		],
		"correct": 0
	},
	{
		"question": "Si hay fuego cerca, ¿qué debes hacer?",
		"options": [
			"Alejarte y avisar",
			"Acercarte",
			"Tocarlo",
			"Jugar con él"
		],
		"correct": 0
	},
	{
		"question": "Si hay una inundación, ¿qué debes hacer?",
		"options": [
			"Pedir ayuda",
			"Caminar por el agua",
			"Jugar en la lluvia",
			"Alejarte de los adultos"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debes hacer si estás triste después de un desastre?",
		"options": [
			"Hablar con alguien de confianza",
			"No decir nada nunca",
			"Alejarte de todos",
			"Gritar a los demás"
		],
		"correct": 0
	},
	{
		"question": "¿Qué deben hacer los adultos con los niños en una emergencia?",
		"options": [
			"Cuidarlos y protegerlos",
			"Ignorarlos",
			"Dejarlos solos",
			"Asustarlos"
		],
		"correct": 0
	},
	{
		"question": "¿Qué debe hacer un adulto si un niño está asustado durante un desastre?",
		"options": [
			"Consolarlo y explicarle con calma",
			"Regañarlo por tener miedo",
			"Dejarlo solo para que se calme",
			"Ignorar sus sentimientos"
		],
		"correct": 0
	},
	{
		"question": "¿Qué es importante para la salud de los niños después de una emergencia?",
		"options": [
			"Recibir atención médica si la necesitan",
			"No decir nada de sus heridas",
			"Evitar a los médicos",
			"Curarse solos"
		],
		"correct": 0
	},
	{
		"question": "¿Qué deben hacer los niños si se separan de su familia?",
		"options": [
			"Buscar a un adulto de uniforme o autoridad",
			"Esconderse y no hablar con nadie",
			"Salir a buscarlos solos por la calle",
			"Quedarse llorando sin pedir ayuda"
		],
		"correct": 0
	},
	{
		"question": "¿Por qué es importante que los niños participen en simulacros?",
		"options": [
			"Para saber cómo actuar en una emergencia real",
			"Porque es obligatorio y sin motivo",
			"Para perder clases",
			"Porque es un juego sin importancia"
		],
		"correct": 0
	},
	{
		"question": "¿Qué derecho tienen los niños a la educación durante un desastre?",
		"options": [
			"Seguir aprendiendo aunque cambien las condiciones",
			"Dejar de estudiar para siempre",
			"Perder el año sin ayuda",
			"No tener acceso a maestros"
		],
		"correct": 0
	},
	{
		"question": "¿Qué deben hacer los adultos si un niño no entiende las instrucciones de evacuación?",
		"options": [
			"Explicarle de forma clara y sencilla",
			"Gritarle para que corra más rápido",
			"Dejarlo atrás",
			"No explicarle nada"
		],
		"correct": 0
	},
	{
		"question": "¿Qué es un derecho básico de todo niño o niña en cualquier situación?",
		"options": [
			"Tener un nombre y una identidad protegida",
			"Perder su identidad",
			"No tener documentos",
			"Ser tratado como adulto"
		],
		"correct": 0
	},
	{
		"question": "¿Qué deben hacer los niños si ven que un adulto está en peligro?",
		"options": [
			"Pedir ayuda a otro adulto de confianza",
			"Intentar rescatarlo solos",
			"Ignorarlo",
			"Salir corriendo sin avisar a nadie"
		],
		"correct": 0
	},
	{
		"question": "¿Qué es importante mantener durante una emergencia para sentirse seguro?",
		"options": [
			"La calma y la comunicación con la familia",
			"El silencio total sin hablar",
			"La distancia de todos los adultos",
			"El desorden"
		],
		"correct": 0
	},
	{
		"question": "¿Qué deben recibir los niños que perdieron su hogar en un desastre?",
		"options": [
			"Refugio y cuidado seguro",
			"Ninguna ayuda",
			"Solo comida sin refugio",
			"Indiferencia"
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

var button_colors := [
	Color("#B9273A"),
	Color("#6E3FC7"),
	Color("#F39A0A"),
	Color("#14B735")
]

const CORRECT_COLOR := Color("#16C653")
const WRONG_COLOR := Color("#D63A3A")


func _ready() -> void:
	randomize()
	add_to_group("game_manager")

	create_score_panel()
	create_timer()
	create_game_result_panel()
	create_lives_ui()
	create_audio()
	_setup_damage_effect()
	setup_scene_style()
	connect_buttons()

	start_game()


func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		if is_inside_tree():
			setup_scene_style()


# =========================================================
# AUDIO
# =========================================================

func create_audio() -> void:
	background_music_player = AudioStreamPlayer.new()
	background_music_player.stream = BACKGROUND_MUSIC
	background_music_player.volume_db = GLOBAL_SOUND_VOLUME
	add_child(background_music_player)

	correct_sound_player = AudioStreamPlayer.new()
	correct_sound_player.stream = CORRECT_SOUND
	correct_sound_player.volume_db = GLOBAL_SOUND_VOLUME
	add_child(correct_sound_player)

	incorrect_sound_player = AudioStreamPlayer.new()
	incorrect_sound_player.stream = INCORRECT_SOUND
	incorrect_sound_player.volume_db = GLOBAL_SOUND_VOLUME
	add_child(incorrect_sound_player)


func _set_game_result_sound_volume() -> void:
	if game_result_panel == null:
		return

	var result_sounds := [
		"WinSound",
		"win_sound",
		"AudioWin",
		"WinAudio",
		"LoseSound",
		"lose_sound",
		"AudioLose",
		"LoseAudio"
	]

	for sound_name in result_sounds:
		var sound = game_result_panel.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


func play_background_music() -> void:
	if background_music_player != null:
		background_music_player.volume_db = GLOBAL_SOUND_VOLUME

		if not background_music_player.playing:
			background_music_player.play()


func stop_background_music() -> void:
	if background_music_player != null:
		background_music_player.stop()


func play_correct_sound() -> void:
	_play_sound(correct_sound_player)


func play_incorrect_sound() -> void:
	_play_sound(incorrect_sound_player)


# =========================================================
# DAMAGE EFFECT
# =========================================================

func _setup_damage_effect():
	damage_layer = CanvasLayer.new()
	damage_layer.name = "DamageLayer"
	damage_layer.layer = 200
	add_child(damage_layer)
	
	damage_rect = ColorRect.new()
	damage_rect.name = "DamageRect"
	damage_rect.color = Color(1, 0, 0)
	damage_rect.modulate.a = 0.0
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	damage_layer.add_child(damage_rect)


func _play_damage_effect():
	if not damage_rect:
		return
	
	var original_position: Vector2 = position
	
	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)
	
	var shake_tween := create_tween()
	
	for i in range(6):
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)


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
	game_result_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	_set_game_result_sound_volume()


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


func create_score_panel() -> void:
	score_panel = Panel.new()
	add_child(score_panel)

	if score_label != null:
		move_child(score_panel, score_label.get_index())


func connect_buttons() -> void:
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(func(): _on_option_selected(i))


func start_game() -> void:
	game_active = true
	already_finished = false

	lives = lives_limit
	correct_answers = 0
	current_round = 1
	current_question_index = 0

	questions.shuffle()

	update_lives_ui()
	update_score_ui()
	show_question()
	play_background_music()

	if timer_hud.has_method("detener"):
		timer_hud.detener()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 60.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 60.0

	if timer_hud.has_method("iniciar"):
		timer_hud.iniciar(TOTAL_TIME, "Tiempo", "responde las preguntas")


func show_question() -> void:
	if already_finished:
		return

	if current_question_index >= questions.size():
		questions.shuffle()
		current_question_index = 0

	var current_question = questions[current_question_index]

	question_label.text = current_question["question"]

	var options: Array = current_question["options"].duplicate()
	var correct_text: String = options[current_question["correct"]]

	options.shuffle()

	current_correct_index = options.find(correct_text)

	for i in range(option_buttons.size()):
		option_buttons[i].text = options[i]
		option_buttons[i].disabled = false
		option_buttons[i].modulate = Color.WHITE
		apply_button_style(option_buttons[i], button_colors[i], 1.0)

	update_score_ui()


func _on_option_selected(selected_index: int) -> void:
	if not game_active or already_finished:
		return

	disable_buttons()

	if selected_index == current_correct_index:
		play_correct_sound()
		correct_answers += 1
		show_correct_answer(current_correct_index)
	else:
		play_incorrect_sound()
		lives -= 1

		if lives < 0:
			lives = 0

		update_lives_ui()
		_play_damage_effect()
		show_wrong_answer(selected_index, current_correct_index)

		if lives <= 0:
			await get_tree().create_timer(1.0).timeout
			lose_game()
			return

	update_score_ui()

	await get_tree().create_timer(1.1).timeout

	if current_round >= max_rounds:
		if correct_answers >= required_correct_answers:
			win_game()
		else:
			_play_damage_effect()
			lose_game()
		return

	current_round += 1
	current_question_index += 1
	show_question()


func show_correct_answer(correct_index: int) -> void:
	for i in range(option_buttons.size()):
		if i == correct_index:
			apply_button_style(option_buttons[i], CORRECT_COLOR, 1.0)
			option_buttons[i].modulate = Color.WHITE
		else:
			apply_button_style(option_buttons[i], button_colors[i], 0.22)
			option_buttons[i].modulate = Color(1, 1, 1, 0.35)


func show_wrong_answer(selected_index: int, correct_index: int) -> void:
	for i in range(option_buttons.size()):
		if i == selected_index:
			apply_button_style(option_buttons[i], WRONG_COLOR, 1.0)
			option_buttons[i].modulate = Color.WHITE
		elif i == correct_index:
			apply_button_style(option_buttons[i], CORRECT_COLOR, 1.0)
			option_buttons[i].modulate = Color.WHITE
		else:
			apply_button_style(option_buttons[i], button_colors[i], 0.22)
			option_buttons[i].modulate = Color(1, 1, 1, 0.35)


func disable_buttons() -> void:
	for button in option_buttons:
		button.disabled = true


func update_score_ui() -> void:
	score_label.text = "Ronda: " + str(current_round) + " / " + str(max_rounds) + "     Correctas: " + str(correct_answers) + " / " + str(required_correct_answers)


func _on_time_up() -> void:
	if game_active and not already_finished:
		play_incorrect_sound()
		_play_damage_effect()
		lose_game()


func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	if timer_hud != null and timer_hud.has_method("detener"):
		timer_hud.detener()

	stop_background_music()
	disable_buttons()
	_set_game_result_sound_volume()

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

	stop_background_music()
	disable_buttons()
	_set_game_result_sound_volume()

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
	background.color = Color("#39C8C2")

	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(screen_width, screen_height * 0.115)
	top_bar.color = Color("#249995")

	title_label.position = Vector2.ZERO
	title_label.size = top_bar.size
	title_label.text = "DERECHOS DE LA NIÑEZ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", int(screen_height * 0.043))
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color("#1A5D62"))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)

	var question_width := screen_width * 0.75
	var question_height := screen_height * 0.22
	var question_x := (screen_width - question_width) / 2.0
	var question_y := screen_height * 0.175

	question_panel.position = Vector2(question_x, question_y)
	question_panel.size = Vector2(question_width, question_height)
	question_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(Color("#1888C9"), Color("#166DA0"), 14, 0)
	)

	question_label.position = Vector2(40, 20)
	question_label.size = Vector2(question_width - 80, question_height - 40)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", int(screen_height * 0.038))
	question_label.add_theme_color_override("font_color", Color.WHITE)
	question_label.add_theme_color_override("font_shadow_color", Color("#0F425D"))
	question_label.add_theme_constant_override("shadow_offset_x", 3)
	question_label.add_theme_constant_override("shadow_offset_y", 3)

	var options_width := screen_width * 0.69
	var options_x := (screen_width - options_width) / 2.0
	var options_y := question_y + question_height + screen_height * 0.06

	options_container.position = Vector2(options_x, options_y)
	options_container.size = Vector2(options_width, screen_height * 0.36)
	options_container.add_theme_constant_override("separation", int(screen_height * 0.025))

	var button_height := screen_height * 0.073

	for i in range(option_buttons.size()):
		var button := option_buttons[i]
		button.custom_minimum_size = Vector2(options_width, button_height)
		button.add_theme_font_size_override("font_size", int(screen_height * 0.028))
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_shadow_color", Color("#333333"))
		button.add_theme_constant_override("shadow_offset_x", 2)
		button.add_theme_constant_override("shadow_offset_y", 2)
		apply_button_style(button, button_colors[i], 1.0)

	var score_width := screen_width * 0.69
	var score_height := screen_height * 0.075
	var score_x := (screen_width - score_width) / 2.0
	var score_y := screen_height * 0.895

	score_panel.position = Vector2(score_x, score_y)
	score_panel.size = Vector2(score_width, score_height)
	score_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(Color.WHITE, Color("#D9D9D9"), 10, 0)
	)

	score_label.position = score_panel.position
	score_label.size = score_panel.size
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", int(screen_height * 0.032))
	score_label.add_theme_color_override("font_color", Color("#214A51"))


func apply_button_style(button: Button, base_color: Color, alpha := 1.0) -> void:
	var normal_color := Color(base_color.r, base_color.g, base_color.b, alpha)
	var border_base := base_color.darkened(0.25)
	var border_color := Color(border_base.r, border_base.g, border_base.b, alpha)

	button.add_theme_stylebox_override(
		"normal",
		create_panel_style(normal_color, border_color, 10, 4)
	)

	button.add_theme_stylebox_override(
		"hover",
		create_panel_style(normal_color.lightened(0.12), border_color, 10, 4)
	)

	button.add_theme_stylebox_override(
		"pressed",
		create_panel_style(normal_color.darkened(0.18), border_color.darkened(0.15), 10, 4)
	)

	button.add_theme_stylebox_override(
		"disabled",
		create_panel_style(normal_color, border_color, 10, 4)
	)


func create_panel_style(bg_color: Color, border_color: Color, radius: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_bottom = 3
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

	if shadow_size > 0:
		style.shadow_color = Color(0, 0, 0, 0.35)
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 4)

	return style


# =========================================================
# TIME BONUS POR EDAD
# =========================================================

func _get_time_bonus(age: int) -> float:
	match age:
		11:
			return 2.0
		10:
			return 3.0
		9:
			return 5.0
		8:
			return 7.0
		7:
			return 10.0
		_:
			return 10.0 if age < 7 else 0.0
