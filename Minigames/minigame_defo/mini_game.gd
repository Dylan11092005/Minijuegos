extends Node2D

@export var time_limit := 30.0
@export var bad_holes_amount := 6

var game_active := false
var already_finished := false

var health := 100
var current_damage := 10

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")

const BACKGROUND_MUSIC = preload("res://Minigames/minigame_defo/Music/Fondo.mp3")
const PLANT_SOUND = preload("res://Minigames/minigame_defo/Music/Plantar.mp3")
const WATER_SOUND = preload("res://Minigames/minigame_defo/Music/Regadera.mp3")
const WIN_SOUND = preload("res://Minigames/minigame_defo/Music/MusicaVictoria.mp3")
const LOSE_SOUND = preload("res://Minigames/minigame_defo/Music/JuegoPerdido.mp3")

const GLOBAL_SOUND_VOLUME := -10.0

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var background_music: AudioStreamPlayer
var plant_sound: AudioStreamPlayer
var water_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var lose_sound: AudioStreamPlayer

var health_layer: CanvasLayer
var health_ui: HealthBarUi

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

@onready var back_button = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	randomize()
	add_to_group("game_manager")

	create_audio()
	create_timer()
	create_game_result_panel()
	create_health_ui()
	_setup_damage_effect()
	connect_back_button()

	timer_hud.set_tamano_panel(600, 60)

	await get_tree().process_frame
	randomize_bad_holes()

	start_game()


func _process(_delta):
	if game_active and not already_finished:
		check_win_condition()


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


# =========================================================
# AUDIO
# =========================================================

func create_audio():
	background_music = AudioStreamPlayer.new()
	background_music.stream = BACKGROUND_MUSIC
	background_music.volume_db = GLOBAL_SOUND_VOLUME
	add_child(background_music)
	background_music.play()

	plant_sound = AudioStreamPlayer.new()
	plant_sound.stream = PLANT_SOUND
	plant_sound.volume_db = GLOBAL_SOUND_VOLUME
	add_child(plant_sound)

	water_sound = AudioStreamPlayer.new()
	water_sound.stream = WATER_SOUND
	water_sound.volume_db = GLOBAL_SOUND_VOLUME
	add_child(water_sound)

	win_sound = AudioStreamPlayer.new()
	win_sound.stream = WIN_SOUND
	win_sound.volume_db = GLOBAL_SOUND_VOLUME
	add_child(win_sound)

	lose_sound = AudioStreamPlayer.new()
	lose_sound.stream = LOSE_SOUND
	lose_sound.volume_db = GLOBAL_SOUND_VOLUME
	add_child(lose_sound)


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


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


# =========================================================
# TIMER
# =========================================================

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
	game_result_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	_set_game_result_sound_volume()


# =========================================================
# HEALTH UI
# =========================================================

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
	_play_damage_effect()

	if health <= 0:
		await get_tree().create_timer(0.25).timeout
		lose_game()


func connect_back_button():
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("CanvasLayer/BackButton was not found, but the game can continue.")


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


# =========================================================
# GAME START
# =========================================================

func start_game():
	game_active = true
	already_finished = false

	health = 100
	current_damage = 10
	update_health_bar()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		time_limit = 30.0 + _get_time_bonus(player_age)
	else:
		time_limit = 30.0

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


# =========================================================
# WIN / LOSE
# =========================================================

func win_game():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if background_music != null:
		background_music.stop()

	_set_game_result_sound_volume()
	_play_sound(win_sound)

	game_result_panel.mostrar_ganaste()


func lose_game():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if background_music != null:
		background_music.stop()

	_set_game_result_sound_volume()
	_play_sound(lose_sound)

	game_result_panel.mostrar_perdiste()


# =========================================================
# PUBLIC SOUND METHODS
# =========================================================

func play_plant_sound():
	_play_sound(plant_sound)


func play_water_sound():
	_play_sound(water_sound)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
