extends Node2D

@export var time_limit := 30.0
@export var drop_distance := 100.0

var trash_total := 0
var trash_collected := 0
var game_active := false

const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

@onready var basurero = $Basurero
@onready var basuras = $Basuras
@onready var btn_back = $CanvasLayer/BackButton

@onready var river_sound = $RiverSound
@onready var trash_sound = $TrashSound


func _ready():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	btn_back.pressed.connect(_on_back_pressed)

	trash_total = basuras.get_child_count()
	trash_collected = 0

	for trash in basuras.get_children():
		trash.dropped.connect(_on_trash_dropped)

	if river_sound != null:
		river_sound.play()

	_start_game()


func _start_game():
	game_active = true
	timer_hud.iniciar(time_limit, "Tiempo restante", "para limpiar el río")


func _on_trash_dropped(trash):
	if not game_active:
		return

	var distance_to_bin = trash.global_position.distance_to(basurero.global_position)

	if distance_to_bin <= drop_distance:
		trash_collected += 1

		if trash_sound != null:
			trash_sound.play()

		trash.queue_free()

		if trash_collected >= trash_total:
			_win()
	else:
		trash.return_to_start()


func _on_tiempo_agotado():
	if game_active:
		_lose()


func _win():
	game_active = false
	timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	panel_resultado.mostrar_ganaste()


func _lose():
	game_active = false
	timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	panel_resultado.mostrar_perdiste()


func _on_back_pressed():
	if river_sound != null:
		river_sound.stop()

	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
