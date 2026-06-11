extends Node2D
class_name RiverCleanupMinigame


const TIMER_HUD_SCENE = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")


@export var time_limit := 30.0
@export var drop_distance := 100.0


var trash_total := 0
var trash_collected := 0
var game_active := false
var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer


@onready var basurero = get_node_or_null("Basurero")
@onready var basuras = get_node_or_null("Basuras")
@onready var back_button = get_node_or_null("CanvasLayer/BackButton")
@onready var river_sound = get_node_or_null("RiverSound")
@onready var trash_sound = get_node_or_null("TrashSound")


func _ready():
	_setup_timer_hud()
	_setup_result_panel()
	_connect_back_button()
	_setup_trash_items()
	_play_river_sound()
	_start_game()


func _start_game():
	game_active = true

	if timer_hud != null:
		timer_hud.iniciar(time_limit, "Tiempo restante", "para limpiar el río")


func _setup_timer_hud():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	timer_hud.tiempo_agotado.connect(_on_time_finished)
	timer_hud.set_tamano_panel(500, 60)


func _setup_result_panel():
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)


func _connect_back_button():
	if back_button != null:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton")


func _setup_trash_items():
	if basuras == null:
		print("No se encontró el nodo Basuras")
		return

	trash_total = basuras.get_child_count()
	trash_collected = 0

	for trash in basuras.get_children():
		if trash.has_signal("trash_dropped"):
			trash.trash_dropped.connect(_on_trash_dropped)


func _play_river_sound():
	if river_sound != null:
		river_sound.play()


func _on_trash_dropped(trash):
	if not game_active:
		return

	if basurero == null:
		return

	var distance_to_bin = trash.global_position.distance_to(basurero.global_position)

	if distance_to_bin <= drop_distance:
		_collect_trash(trash)
	else:
		trash.return_to_start()


func _collect_trash(trash):
	trash_collected += 1

	if trash_sound != null:
		trash_sound.stop()
		trash_sound.play()

	trash.queue_free()

	if trash_collected >= trash_total:
		_win_game()


func _on_time_finished():
	if game_active:
		_lose_game()


func _win_game():
	game_active = false

	if timer_hud != null:
		timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	panel_resultado.mostrar_ganaste()


func _lose_game():
	game_active = false

	if timer_hud != null:
		timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	panel_resultado.mostrar_perdiste()


func _on_back_button_pressed():
	if river_sound != null:
		river_sound.stop()

	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
