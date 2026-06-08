extends Node2D

@export var time_limit := 30.0

var holes_total := 0
var holes_completed := 0
var game_active := false

const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

var regadera_actual = null
var seed_actual = null

@onready var spawn_point = get_node_or_null("SpawnPoint")
@onready var spawn_point_regadera = get_node_or_null("SpawnPointRegadera")
@onready var holes = get_node_or_null("Holes")
@onready var btn_back = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	add_to_group("game_manager")

	# Crear timer global
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true
	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	# Crear panel de resultado global
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)
	panel_resultado.layer = 60

	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton")

	if holes == null:
		print("No se encontró el nodo Holes. El timer igual debería verse, pero el juego no podrá contar hoyos.")
		holes_total = 0
	else:
		holes_total = holes.get_child_count()

		for hole in holes.get_children():
			if hole.has_signal("hole_completed"):
				hole.hole_completed.connect(_on_hole_completed)

	holes_completed = 0

	_start_game()


func _start_game():
	game_active = true
	timer_hud.iniciar(time_limit, "Tiempo restante", "para reforestar el bosque")

	spawn_new_seed()
	spawn_regadera()


func spawn_new_seed():
	if not game_active:
		return

	if spawn_point == null:
		print("No se encontró SpawnPoint")
		return

	# Aquí va la lógica para crear la semilla.


func spawn_regadera():
	if not game_active:
		return

	if spawn_point_regadera == null:
		print("No se encontró SpawnPointRegadera")
		return

	if regadera_actual != null:
		return

	# Aquí va la lógica para crear la regadera.


func _on_hole_completed():
	if not game_active:
		return

	holes_completed += 1

	if holes_total > 0 and holes_completed >= holes_total:
		_win()


func _on_tiempo_agotado():
	if game_active:
		_lose()


func _win():
	game_active = false
	timer_hud.detener()
	panel_resultado.mostrar_ganaste()


func _lose():
	game_active = false
	timer_hud.detener()
	panel_resultado.mostrar_perdiste()


func _on_back_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
