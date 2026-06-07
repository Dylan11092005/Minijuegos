extends Node2D

@export var time_limit := 30.0

var holes_total := 0
var holes_completed := 0
var game_active := false

const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

const SEED_SCENE = preload("res://seed.tscn")
const REGADERA_SCENE = preload("res://regadera.tscn")

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

var regadera_actual = null
var seed_actual = null

@onready var spawn_point = $SpawnPoint
@onready var spawn_point_regadera = $SpawnPointRegadera
@onready var holes = $Holes
@onready var btn_back = $CanvasLayer/BackButton


func _ready():
	add_to_group("game_manager")

	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	btn_back.pressed.connect(_on_back_pressed)

	holes_total = holes.get_child_count()
	holes_completed = 0

	for hole in holes.get_children():
		if hole.has_signal("hole_completed"):
			hole.hole_completed.connect(_on_hole_completed)

	_start_game()


func _start_game():
	game_active = true
	timer_hud.iniciar(time_limit, "Tiempo restante", "para reforestar el bosque")
	spawn_new_seed()
	spawn_regadera()


func spawn_new_seed():
	if not game_active:
		return

	seed_actual = SEED_SCENE.instantiate()
	seed_actual.global_position = spawn_point.global_position
	add_child(seed_actual)


func spawn_regadera():
	if not game_active:
		return

	if regadera_actual != null:
		return

	regadera_actual = REGADERA_SCENE.instantiate()
	regadera_actual.global_position = spawn_point_regadera.global_position
	add_child(regadera_actual)


func _on_hole_completed():
	if not game_active:
		return

	holes_completed += 1

	if holes_completed >= holes_total:
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
