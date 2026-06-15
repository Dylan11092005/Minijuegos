extends Node2D

@export var time_limit := 30.0
@export var chances_limit := 3

const TIMER_HUD_SCENE = preload("res://ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://ui_global/GameResult.tscn")

var game_active := false
var already_finished := false

var current_round := 1
var max_rounds := 3
var chances := 3

var river_options: Array[RiverOption] = []

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var ui_layer: CanvasLayer
var round_label: Label
var chances_label: Label
var feedback_label: Label
var back_button: Button


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

	get_river_options()
	create_timer()
	create_game_result_panel()
	create_simple_ui()
	connect_river_options()

	start_game()


func get_river_options() -> void:
	river_options.clear()

	for child in get_children():
		if child is RiverOption:
			river_options.append(child)

	if river_options.size() == 0:
		print("ERROR: No se encontraron RiverOption dentro de Main.")


func create_timer() -> void:
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true
	timer_hud.time_up.connect(_on_time_up)
	timer_hud.set_tamano_panel(500, 60)


func create_game_result_panel() -> void:
	game_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(game_result_panel)
	game_result_panel.layer = 60


func create_simple_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	add_child(ui_layer)

	round_label = Label.new()
	round_label.position = Vector2(40, 95)
	round_label.add_theme_font_size_override("font_size", 28)
	ui_layer.add_child(round_label)

	chances_label = Label.new()
	chances_label.position = Vector2(40, 135)
	chances_label.add_theme_font_size_override("font_size", 28)
	ui_layer.add_child(chances_label)

	feedback_label = Label.new()
	feedback_label.position = Vector2(420, 95)
	feedback_label.add_theme_font_size_override("font_size", 32)
	ui_layer.add_child(feedback_label)

	back_button = Button.new()
	back_button.text = "Volver"
	back_button.position = Vector2(40, 650)
	back_button.size = Vector2(140, 45)
	back_button.pressed.connect(_on_back_pressed)
	ui_layer.add_child(back_button)


func connect_river_options() -> void:
	for river_option in river_options:
		if not river_option.river_selected.is_connected(_on_river_selected):
			river_option.river_selected.connect(_on_river_selected)


func start_game() -> void:
	game_active = true
	already_finished = false

	current_round = 1
	chances = chances_limit

	feedback_label.text = ""
	update_ui()

	start_round()


func start_round() -> void:
	if river_options.size() == 0:
		print("ERROR: No hay ríos para jugar.")
		return

	game_active = true
	feedback_label.text = ""

	reset_all_rivers()
	update_ui()

	timer_hud.detener()
	timer_hud.iniciar(time_limit, "Tiempo", "para identificar el río diferente")

	var different_index := randi() % river_options.size()

	for i in range(river_options.size()):
		var river_option := river_options[i]

		if i == different_index:
			river_option.setup(get_different_river_state(), true)
		else:
			river_option.setup(RiverOption.State.NORMAL, false)


func reset_all_rivers() -> void:
	for river_option in river_options:
		river_option.reset_river()


func get_different_river_state() -> RiverOption.State:
	if current_round == 1:
		return RiverOption.State.HIGH
	elif current_round == 2:
		return RiverOption.State.DARK
	else:
		return RiverOption.State.FOAM


func update_ui() -> void:
	round_label.text = "Ronda: " + str(current_round) + " / " + str(max_rounds)
	chances_label.text = "Oportunidades: " + str(chances)


func _on_river_selected(is_different: bool) -> void:
	if not game_active or already_finished:
		return

	if is_different:
		feedback_label.text = "¡Correcto!"
		timer_hud.detener()
		disable_all_rivers()

		if current_round >= max_rounds:
			win_game()
		else:
			game_active = false
			current_round += 1
			await get_tree().create_timer(1.0).timeout
			start_round()
	else:
		chances -= 1
		feedback_label.text = "Incorrecto, intenta de nuevo."
		update_ui()

		if chances <= 0:
			lose_game()


func disable_all_rivers() -> void:
	for river_option in river_options:
		river_option.disable_selection()


func _on_time_up() -> void:
	if game_active and not already_finished:
		lose_game()


func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()
	disable_all_rivers()

	feedback_label.text = "¡Ganaste!"

	if game_result_panel != null:
		game_result_panel.mostrar_ganaste()


func lose_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()
	disable_all_rivers()

	feedback_label.text = "Perdiste."

	if game_result_panel != null:
		game_result_panel.mostrar_perdiste()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
