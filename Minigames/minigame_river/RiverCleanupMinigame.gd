extends Node2D
class_name RiverCleanupMinigame


const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")


@export var time_limit := 30.0
@export var drop_distance := 170.0
@export var max_lives := 3


var trash_total := 0
var trash_collected := 0
var current_lives := 3

var game_active := false

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer
var lives_ui: Node
var lives_layer: CanvasLayer


@onready var garbagecollector = get_node_or_null("GarbageCollector")
@onready var trash = get_node_or_null("Trash")
@onready var fish = get_node_or_null("Fish")
@onready var back_button = get_node_or_null("CanvasLayer/BackButton")
@onready var river_sound = get_node_or_null("RiverSound")
@onready var trash_sound = get_node_or_null("TrashSound")


func _ready():
	_setup_timer_hud()
	_setup_result_panel()
	_setup_lives_ui()
	_connect_back_button()
	_setup_trash_items()
	_setup_fish_items()
	_play_river_sound()
	_start_game()


func _start_game():
	game_active = true
	current_lives = max_lives
	_update_lives_ui()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		time_limit = 30.0 + _get_time_bonus(player_age)
	else:
		time_limit = 30.0

	if timer_hud != null:
		timer_hud.iniciar(time_limit, "Tiempo restante", "para limpiar el río")


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


func _setup_timer_hud():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	timer_hud.time_up.connect(_on_time_finished)
	timer_hud.set_tamano_panel(500, 60)


func _setup_result_panel():
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)


func _setup_lives_ui():
	lives_layer = CanvasLayer.new()
	lives_layer.layer = 55
	add_child(lives_layer)

	lives_ui = LIVES_UI_SCENE.instantiate()
	lives_layer.add_child(lives_ui)

	if lives_ui.has_method("set_max_lives"):
		lives_ui.set_max_lives(max_lives)
	elif lives_ui.has_method("set_total_lives"):
		lives_ui.set_total_lives(max_lives)
	elif lives_ui.has_method("set_max_vidas"):
		lives_ui.set_max_vidas(max_lives)

	if lives_ui.has_method("set_panel_corner"):
		lives_ui.set_panel_corner(LivesUi.PanelCorner.TOP_RIGHT)

	if lives_ui.has_method("set_panel_margin"):
		lives_ui.set_panel_margin(Vector2(35, 20))

	_update_lives_ui()


func _update_lives_ui():
	if lives_ui == null:
		return

	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.actualizar_vidas(current_lives)
	elif lives_ui.has_method("update_lives"):
		lives_ui.update_lives(current_lives)
	elif lives_ui.has_method("set_lives"):
		lives_ui.set_lives(current_lives)
	elif lives_ui.has_method("set_current_lives"):
		lives_ui.set_current_lives(current_lives)


func _connect_back_button():
	if back_button != null:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton")


func _setup_trash_items():
	if trash == null:
		print("No se encontró el nodo Trash")
		return

	trash_total = trash.get_child_count()
	trash_collected = 0

	for trash_item in trash.get_children():
		if trash_item.has_signal("trash_dropped"):
			trash_item.trash_dropped.connect(_on_trash_dropped)


func _setup_fish_items():
	if fish == null:
		print("No se encontró el nodo Fish. Puedes crearlo y poner ahí los peces.")
		return

	for fish_item in fish.get_children():
		if fish_item.has_signal("trash_dropped"):
			fish_item.trash_dropped.connect(_on_fish_dropped)


func _play_river_sound():
	if river_sound != null:
		river_sound.play()


func _on_trash_dropped(trash_item):
	if not game_active:
		return

	if garbagecollector == null:
		return

	var distance_to_bin = trash_item.global_position.distance_to(garbagecollector.global_position)

	if distance_to_bin <= drop_distance:
		_collect_trash(trash_item)
	else:
		if trash_item.has_method("return_to_start"):
			trash_item.return_to_start()


func _on_fish_dropped(fish_item):
	if not game_active:
		return

	if garbagecollector == null:
		return

	var distance_to_bin = fish_item.global_position.distance_to(garbagecollector.global_position)

	if distance_to_bin <= drop_distance:
		_lose_life()

		if game_active and fish_item.has_method("return_to_start"):
			fish_item.return_to_start()
	else:
		if fish_item.has_method("return_to_start"):
			fish_item.return_to_start()


func _collect_trash(trash_item):
	trash_collected += 1

	if trash_sound != null:
		trash_sound.stop()
		trash_sound.play()

	trash_item.queue_free()

	if trash_collected >= trash_total:
		_win_game()


func _lose_life():
	current_lives -= 1

	if current_lives < 0:
		current_lives = 0

	_update_lives_ui()

	if current_lives <= 0:
		_lose_game()


func _on_time_finished():
	if game_active:
		_lose_game()


func _win_game():
	game_active = false

	if timer_hud != null:
		timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	_lock_all_items()

	panel_resultado.mostrar_ganaste()


func _lose_game():
	game_active = false

	if timer_hud != null:
		timer_hud.detener()

	if river_sound != null:
		river_sound.stop()

	_lock_all_items()

	panel_resultado.mostrar_perdiste()


func _lock_all_items():
	if trash != null:
		for trash_item in trash.get_children():
			if "locked" in trash_item:
				trash_item.locked = true

	if fish != null:
		for fish_item in fish.get_children():
			if "locked" in fish_item:
				fish_item.locked = true


func _on_back_button_pressed():
	game_active = false

	if river_sound != null:
		river_sound.stop()

	if timer_hud != null:
		timer_hud.detener()

	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
