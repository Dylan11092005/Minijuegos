extends Node2D

@export var TOTAL_TIME: float = 30.0
@export var lives_limit := 3

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

const BASS_MUSIC = preload("res://Minigames/minigame_identify_river/assets/bass.mp3")
const FOREST_MUSIC = preload("res://Minigames/minigame_identify_river/assets/forest.mp3")
const CORRECT_SOUND = preload("res://Minigames/minigame_identify_river/assets/Correct.mp3")
const LOSER_SOUND = preload("res://Minigames/minigame_identify_river/assets/Loser.mp3")

var game_active := false
var already_finished := false

var current_round := 1
var max_rounds := 3
var lives := 3

var river_options: Array[RiverOption] = []
var river_positions: Array[Vector2] = []

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var lives_ui: Node
var lives_layer: CanvasLayer

var round_ui: RoundUi
var round_layer: CanvasLayer

var ui_layer: CanvasLayer
var feedback_label: Label

var bass_music_player: AudioStreamPlayer
var forest_music_player: AudioStreamPlayer
var correct_sound_player: AudioStreamPlayer
var loser_sound_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

	get_river_options()
	save_river_positions()
	create_timer()
	create_game_result_panel()
	create_lives_ui()
	create_round_ui()
	create_simple_ui()
	create_audio()
	connect_river_options()

	start_game()


func get_river_options() -> void:
	river_options.clear()

	for child in get_children():
		if child is RiverOption:
			river_options.append(child)

	if river_options.size() == 0:
		print("ERROR: No se encontraron RiverOption dentro de Main.")


func save_river_positions() -> void:
	river_positions.clear()

	for river_option in river_options:
		river_positions.append(river_option.position)


func shuffle_river_positions() -> void:
	if river_options.size() == 0:
		return

	if river_positions.size() != river_options.size():
		save_river_positions()

	var shuffled_positions := river_positions.duplicate()
	shuffled_positions.shuffle()

	for i in range(river_options.size()):
		river_options[i].position = shuffled_positions[i]


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


func create_round_ui() -> void:
	round_layer = CanvasLayer.new()
	round_layer.layer = 54
	add_child(round_layer)

	round_ui = RoundUi.new()
	round_layer.add_child(round_ui)

	round_ui.set_panel_corner(RoundUi.PanelCorner.TOP_RIGHT)
	round_ui.set_panel_margin(Vector2(35, 140))
	round_ui.update_round(current_round, max_rounds)


func create_simple_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	add_child(ui_layer)

	feedback_label = Label.new()
	feedback_label.position = Vector2(360, 650)
	feedback_label.size = Vector2(700, 50)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 30)
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	feedback_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback_label.add_theme_constant_override("shadow_offset_x", 3)
	feedback_label.add_theme_constant_override("shadow_offset_y", 3)
	ui_layer.add_child(feedback_label)


func create_audio() -> void:
	bass_music_player = AudioStreamPlayer.new()
	bass_music_player.stream = BASS_MUSIC
	bass_music_player.volume_db = -14
	add_child(bass_music_player)

	forest_music_player = AudioStreamPlayer.new()
	forest_music_player.stream = FOREST_MUSIC
	forest_music_player.volume_db = -8
	add_child(forest_music_player)

	correct_sound_player = AudioStreamPlayer.new()
	correct_sound_player.stream = CORRECT_SOUND
	correct_sound_player.volume_db = 0
	add_child(correct_sound_player)

	loser_sound_player = AudioStreamPlayer.new()
	loser_sound_player.stream = LOSER_SOUND
	loser_sound_player.volume_db = 0
	add_child(loser_sound_player)

	play_background_music()


func play_background_music() -> void:
	if bass_music_player != null:
		bass_music_player.play()

	if forest_music_player != null:
		forest_music_player.play()


func stop_background_music() -> void:
	if bass_music_player != null:
		bass_music_player.stop()

	if forest_music_player != null:
		forest_music_player.stop()


func play_correct_sound() -> void:
	if correct_sound_player != null:
		correct_sound_player.stop()
		correct_sound_player.play()


func play_loser_sound() -> void:
	if loser_sound_player != null:
		loser_sound_player.stop()
		loser_sound_player.play()


func connect_river_options() -> void:
	for river_option in river_options:
		if not river_option.river_selected.is_connected(_on_river_selected):
			river_option.river_selected.connect(_on_river_selected)


func start_game() -> void:
	game_active = true
	already_finished = false

	current_round = 1
	lives = lives_limit

	feedback_label.text = ""
	update_ui()
	update_lives_ui()

	if bass_music_player != null and not bass_music_player.playing:
		play_background_music()

	start_round()


func start_round() -> void:
	if river_options.size() == 0:
		print("ERROR: No hay ríos para jugar.")
		return

	game_active = true
	feedback_label.text = ""

	reset_all_rivers()
	shuffle_river_positions()
	update_ui()
	update_lives_ui()


	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 30.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 30.0

	timer_hud.detener()
	timer_hud.iniciar(TOTAL_TIME, "Tiempo", "identifica el río diferente")



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
	if round_ui != null:
		round_ui.update_round(current_round, max_rounds)


func _on_river_selected(is_different: bool) -> void:
	if not game_active or already_finished:
		return

	if is_different:
		play_correct_sound()

		timer_hud.detener()
		disable_all_rivers()

		feedback_label.text = "¡Correcto!"

		if current_round >= max_rounds:
			await get_tree().create_timer(0.8).timeout
			win_game()
		else:
			game_active = false
			current_round += 1
			update_ui()
			await get_tree().create_timer(1.0).timeout
			start_round()
	else:
		play_loser_sound()

		lives -= 1

		if lives < 0:
			lives = 0

		update_lives_ui()
		show_correct_river()

		feedback_label.text = "Incorrecto. El río correcto está marcado."

		disable_all_rivers()
		game_active = false
		timer_hud.detener()

		if lives <= 0:
			await get_tree().create_timer(1.4).timeout
			lose_game()
		else:
			await get_tree().create_timer(1.4).timeout

			if current_round >= max_rounds:
				current_round = max_rounds
			else:
				current_round += 1

			update_ui()
			start_round()


func disable_all_rivers() -> void:
	for river_option in river_options:
		river_option.disable_selection()


func show_correct_river() -> void:
	for river_option in river_options:
		if river_option.is_different:
			if river_option.has_method("show_correct_mark"):
				river_option.show_correct_mark()


func _on_time_up() -> void:
	if game_active and not already_finished:
		play_loser_sound()
		show_correct_river()
		feedback_label.text = "Se acabó el tiempo. El río correcto está marcado."

		lives -= 1

		if lives < 0:
			lives = 0

		update_lives_ui()
		disable_all_rivers()
		game_active = false
		timer_hud.detener()

		if lives <= 0:
			await get_tree().create_timer(1.4).timeout
			lose_game()
		else:
			await get_tree().create_timer(1.4).timeout

			if current_round >= max_rounds:
				current_round = max_rounds
			else:
				current_round += 1

			update_ui()
			start_round()


func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()
	disable_all_rivers()
	stop_background_music()

	if game_result_panel != null:
		game_result_panel.mostrar_ganaste()


func lose_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()
	disable_all_rivers()
	stop_background_music()

	if game_result_panel != null:
		game_result_panel.mostrar_perdiste()


func _on_back_pressed() -> void:
	stop_background_music()
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

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
