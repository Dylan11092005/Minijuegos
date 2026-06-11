extends Node2D

@export var time_limit := 30.0
@export var cantidad_huecos_malos := 6

var game_active := false
var already_finished := false

var vida := 100
var dano_actual := 10

const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

const MUSICA_FONDO = preload("res://minigame_defo/Musica/Fondo.mp3")
const SONIDO_PLANTAR = preload("res://minigame_defo/Musica/Plantar.mp3")
const SONIDO_REGADERA = preload("res://minigame_defo/Musica/Regadera.mp3")
const SONIDO_GANAR = preload("res://minigame_defo/Musica/MusicaVictoria.mp3")
const SONIDO_PERDER = preload("res://minigame_defo/Musica/JuegoPerdido.mp3")

# Paleta de colores del juego
const C_BEIGE   = Color("#E5C89E")
const C_NARANJA = Color("#E0B080")
const C_AZUL    = Color("#3E5F8F")
const C_CELESTE = Color("#39B5E6")
const C_BLANCO  = Color("#FFFFFF")
const C_ROJO    = Color("#D63A3A")

const C_FASE_ROJA    = Color("f82564ff")
const C_FASE_NARANJA = Color("#E07820")
const C_FASE_ROJO    = Color("#D63A3A")

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

var musica_fondo: AudioStreamPlayer
var sonido_plantar: AudioStreamPlayer
var sonido_regadera: AudioStreamPlayer
var sonido_ganar: AudioStreamPlayer
var sonido_perder: AudioStreamPlayer

var health_layer: CanvasLayer
var health_panel: Panel
var health_bar: ProgressBar
var health_label: Label

@onready var btn_back = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	add_to_group("game_manager")

	crear_audio()
	crear_timer()
	crear_panel_resultado()
	crear_barra_vida()
	conectar_boton_back()

	timer_hud.set_tamano_panel(600, 60)

	randomizar_huecos_malos()

	_start_game()


func _process(_delta):
	if game_active and not already_finished:
		check_win_condition()


func randomizar_huecos_malos():
	var holes = get_tree().get_nodes_in_group("holes")

	if holes.size() == 0:
		print("No se encontraron huecos en el grupo holes")
		return

	for hole in holes:
		hole.reset_hole()

	holes.shuffle()

	var cantidad = min(cantidad_huecos_malos, holes.size())

	for i in range(cantidad):
		holes[i].set_invalid()

	print("Huecos malos aleatorios: ", cantidad)


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


func crear_barra_vida():
	health_layer = CanvasLayer.new()
	health_layer.layer = 55
	add_child(health_layer)

	# Panel principal de vida
	health_panel = Panel.new()
	health_panel.name = "PanelVida"
	health_panel.size = Vector2(340, 85)
	health_panel.position = Vector2(900, 25)
	health_layer.add_child(health_panel)

	var estilo_panel = StyleBoxFlat.new()
	estilo_panel.bg_color = C_AZUL
	estilo_panel.border_color = C_BEIGE
	estilo_panel.border_width_left = 3
	estilo_panel.border_width_right = 3
	estilo_panel.border_width_top = 3
	estilo_panel.border_width_bottom = 3
	estilo_panel.corner_radius_top_left = 12
	estilo_panel.corner_radius_top_right = 12
	estilo_panel.corner_radius_bottom_left = 12
	estilo_panel.corner_radius_bottom_right = 12
	health_panel.add_theme_stylebox_override("panel", estilo_panel)

	# Texto de vida
	health_label = Label.new()
	health_label.text = "Vida: 100"
	health_label.position = Vector2(20, 8)
	health_label.size = Vector2(300, 25)
	health_label.add_theme_color_override("font_color", C_BLANCO)
	health_label.add_theme_font_size_override("font_size", 20)
	health_panel.add_child(health_label)

	# Barra de vida
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = vida
	health_bar.position = Vector2(20, 45)
	health_bar.size = Vector2(300, 25)
	health_bar.show_percentage = false
	health_panel.add_child(health_bar)

	actualizar_barra_vida()


func actualizar_barra_vida():
	if health_bar != null:
		health_bar.value = vida

	if health_label != null:
		health_label.text = "Vida: " + str(vida)

	actualizar_estilo_barra_vida()


func actualizar_estilo_barra_vida():
	if health_bar == null:
		return

	var estilo_fondo = StyleBoxFlat.new()
	estilo_fondo.bg_color = C_BEIGE
	estilo_fondo.corner_radius_top_left = 8
	estilo_fondo.corner_radius_top_right = 8
	estilo_fondo.corner_radius_bottom_left = 8
	estilo_fondo.corner_radius_bottom_right = 8

	var estilo_relleno = StyleBoxFlat.new()

	if vida > 60:
		estilo_relleno.bg_color = C_FASE_ROJA
	elif vida > 30:
		estilo_relleno.bg_color = C_FASE_NARANJA
	else:
		estilo_relleno.bg_color = C_FASE_ROJO

	estilo_relleno.corner_radius_top_left = 8
	estilo_relleno.corner_radius_top_right = 8
	estilo_relleno.corner_radius_bottom_left = 8
	estilo_relleno.corner_radius_bottom_right = 8

	health_bar.add_theme_stylebox_override("background", estilo_fondo)
	health_bar.add_theme_stylebox_override("fill", estilo_relleno)


func recibir_dano_por_hueco_malo():
	if not game_active or already_finished:
		return

	vida -= dano_actual

	if vida < 0:
		vida = 0

	print("Tocaste hueco malo. Daño: ", dano_actual, " Vida: ", vida)

	dano_actual += 10
	actualizar_barra_vida()

	if vida <= 0:
		_lose()


func conectar_boton_back():
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton, pero el juego puede continuar.")


func _start_game():
	game_active = true
	already_finished = false
	vida = 100
	dano_actual = 10
	actualizar_barra_vida()
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
