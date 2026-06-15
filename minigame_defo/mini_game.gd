extends Node2D

@export var time_limit := 30.0
@export var bad_holes_amount := 6

var game_active := false
var already_finished := false

var health := 100
var current_damage := 10

const TIMER_HUD_SCENE = preload("res://ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://ui_global/GameResult.tscn")

const BACKGROUND_MUSIC = preload("res://minigame_defo/Music/Fondo.mp3")
const PLANT_SOUND = preload("res://minigame_defo/Music/Plantar.mp3")
const WATER_SOUND = preload("res://minigame_defo/Music/Regadera.mp3")
const WIN_SOUND = preload("res://minigame_defo/Music/MusicaVictoria.mp3")
const LOSE_SOUND = preload("res://minigame_defo/Music/JuegoPerdido.mp3")

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var background_music: AudioStreamPlayer
var plant_sound: AudioStreamPlayer
var water_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var lose_sound: AudioStreamPlayer

var health_layer: CanvasLayer
var health_ui: HealthBarUi

@onready var back_button = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	add_to_group("game_manager")

	create_audio()
	create_timer()
	create_game_result_panel()
	create_health_ui()
	connect_back_button()

	timer_hud.set_tamano_panel(600, 60)

	randomize_bad_holes()

	start_game()


func _process(_delta):
	if game_active and not already_finished:
		check_win_condition()


func randomize_bad_holes():
	var holes = get_tree().get_nodes_in_group("holes")

	if holes.size() == 0:
		print("No holes found in the holes group")
		return

	for hole in holes:
		hole.reset_hole()

	holes.shuffle()

	var amount = min(bad_holes_amount, holes.size())

	for i in range(amount):
		holes[i].set_invalid()

	print("Random bad holes: ", amount)


func create_audio():
	background_music = AudioStreamPlayer.new()
	background_music.stream = BACKGROUND_MUSIC
	background_music.volume_db = -8
	add_child(background_music)
	background_music.play()

	plant_sound = AudioStreamPlayer.new()
	plant_sound.stream = PLANT_SOUND
	plant_sound.volume_db = 0
	add_child(plant_sound)

	water_sound = AudioStreamPlayer.new()
	water_sound.stream = WATER_SOUND
	water_sound.volume_db = 0
	add_child(water_sound)

	win_sound = AudioStreamPlayer.new()
	win_sound.stream = WIN_SOUND
	win_sound.volume_db = 0
	add_child(win_sound)

	lose_sound = AudioStreamPlayer.new()
	lose_sound.stream = LOSE_SOUND
	lose_sound.volume_db = 0
	add_child(lose_sound)


func create_timer():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true
	timer_hud.time_up.connect(_on_time_up)
	timer_hud.set_tamano_panel(500, 60)


func create_game_result_panel():
	game_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(game_result_panel)
	game_result_panel.layer = 60


func create_health_ui():
	health_layer = CanvasLayer.new()
	health_layer.layer = 55
	add_child(health_layer)

	health_ui = HealthBarUi.new()
	health_layer.add_child(health_ui)

	health_ui.set_max_health(100)
	health_ui.set_panel_corner(HealthBarUi.PanelCorner.TOP_RIGHT)
	health_ui.set_panel_margin(Vector2(35, 20))
	health_ui.update_health(health)


func update_health_bar():
	if health_ui != null:
		health_ui.update_health(health)


func receive_bad_hole_damage():
	if not game_active or already_finished:
		return

	health -= current_damage

	if health < 0:
		health = 0

	print("Bad hole touched. Damage: ", current_damage, " Health: ", health)

	current_damage += 10
	update_health_bar()

	if health <= 0:
		lose_game()


func connect_back_button():
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("CanvasLayer/BackButton was not found, but the game can continue.")


func start_game():
	game_active = true
	already_finished = false

	health = 100
	current_damage = 10
	update_health_bar()

	timer_hud.iniciar(time_limit, "Tiempo", "para reforestar el bosque")


func check_win_condition():
	var total_valid_holes := 0
	var total_completed_holes := 0

	var holes = get_tree().get_nodes_in_group("holes")

	for hole in holes:
		if hole.current_state != hole.State.INVALID:
			total_valid_holes += 1

			if hole.current_state == hole.State.WATERED:
				total_completed_holes += 1

	if total_valid_holes > 0 and total_completed_holes >= total_valid_holes:
		win_game()


func _on_time_up():
	if game_active and not already_finished:
		lose_game()


func win_game():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if background_music != null:
		background_music.stop()

	if win_sound != null:
		win_sound.play()

	game_result_panel.mostrar_ganaste()


func lose_game():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if background_music != null:
		background_music.stop()

	if lose_sound != null:
		lose_sound.play()

	game_result_panel.mostrar_perdiste()


func play_plant_sound():
	if plant_sound != null:
		plant_sound.play()


func play_water_sound():
	if water_sound != null:
		water_sound.play()


func _on_back_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
