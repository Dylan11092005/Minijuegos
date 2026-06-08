extends Node2D

@export var time_limit := 30.0

var game_active := false
var already_finished := false

const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

const MUSICA_FONDO = preload("res://minigame_defo/Musica/Fondo.mp3")
const SONIDO_PLANTAR = preload("res://minigame_defo/Musica/Plantar.mp3")
const SONIDO_REGADERA = preload("res://minigame_defo/Musica/Regadera.mp3")
const SONIDO_GANAR = preload("res://minigame_defo/Musica/MusicaVictoria.mp3")
const SONIDO_PERDER = preload("res://minigame_defo/Musica/JuegoPerdido.mp3")

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

var musica_fondo: AudioStreamPlayer
var sonido_plantar: AudioStreamPlayer
var sonido_regadera: AudioStreamPlayer
var sonido_ganar: AudioStreamPlayer
var sonido_perder: AudioStreamPlayer

@onready var btn_back = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	add_to_group("game_manager")

	crear_audio()
	crear_timer()
	crear_panel_resultado()
	conectar_boton_back()
	timer_hud.set_tamano_panel(600, 60)

	_start_game()


func _process(_delta):
	if game_active and not already_finished:
		check_win_condition()


func crear_audio():
	musica_fondo = AudioStreamPlayer.new()
	musica_fondo.stream = MUSICA_FONDO
	musica_fondo.volume_db = -8
	add_child(musica_fondo)
	musica_fondo.play()

	sonido_plantar = AudioStreamPlayer.new()
	sonido_plantar.stream = SONIDO_PLANTAR
	sonido_plantar.volume_db = 0
	add_child(sonido_plantar)

	sonido_regadera = AudioStreamPlayer.new()
	sonido_regadera.stream = SONIDO_REGADERA
	sonido_regadera.volume_db = 0
	add_child(sonido_regadera)
	
	sonido_ganar = AudioStreamPlayer.new()
	sonido_ganar.stream = SONIDO_GANAR
	sonido_ganar.volume_db = 0
	add_child(sonido_ganar)

	sonido_perder = AudioStreamPlayer.new()
	sonido_perder.stream = SONIDO_PERDER
	sonido_perder.volume_db = 0
	add_child(sonido_perder)


func crear_timer():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true
	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)


func crear_panel_resultado():
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)
	panel_resultado.layer = 60


func conectar_boton_back():
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton, pero el juego puede continuar.")


func _start_game():
	game_active = true
	already_finished = false
	timer_hud.iniciar(time_limit, "Tiempo restante", "para reforestar el bosque")


func check_win_condition():
	var total_validos := 0
	var total_completados := 0

	var holes = get_tree().get_nodes_in_group("holes")

	for hole in holes:
		if hole.current_state != hole.State.INVALID:
			total_validos += 1

			if hole.current_state == hole.State.WATERED:
				total_completados += 1

	print("Progreso: ", total_completados, "/", total_validos)

	if total_validos > 0 and total_completados >= total_validos:
		_win()


func _on_tiempo_agotado():
	if game_active and not already_finished:
		_lose()


func _win():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if musica_fondo != null:
		musica_fondo.stop()

	if sonido_ganar != null:
		sonido_ganar.play()

	panel_resultado.mostrar_ganaste()


func _lose():
	if already_finished:
		return

	already_finished = true
	game_active = false

	timer_hud.detener()

	if musica_fondo != null:
		musica_fondo.stop()

	if sonido_perder != null:
		sonido_perder.play()

	panel_resultado.mostrar_perdiste()


func play_plant_sound():
	if sonido_plantar != null:
		sonido_plantar.play()


func play_water_sound():
	if sonido_regadera != null:
		sonido_regadera.play()


func _on_back_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
