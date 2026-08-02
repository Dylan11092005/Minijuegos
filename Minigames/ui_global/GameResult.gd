extends Node2D


# =========================================================
# PATHS
# =========================================================

const FLOATING_OBJECT_SCENE_PATH := "res://Minigames/minigame_deluxe/mini_minigame_level1/FloatingObject.tscn"
const OBJECTS_FOLDER := "res://Minigames/minigame_deluxe/mini_minigame_level1/assets/"

const TIMER_UI_SCRIPT_PATH := "res://Minigames/ui_global/TimerUI.gd"
const GAME_RESULT_SCENE_PATH := "res://Minigames/ui_global/GameResult.tscn"
const LIVES_UI_SCRIPT_PATH := "res://Minigames/ui_global/LivesUi.gd"


# =========================================================
# GAME SETTINGS
# =========================================================

const GAME_TIME := 60.0
const MAX_LIVES := 3

const SPAWN_INTERVAL_MIN := 1.0
const SPAWN_INTERVAL_MAX := 1.8

const GOOD_OBJECTS := ["flashlight", "kit", "life_jacket", "radio", "water_bottle"]
const BAD_OBJECTS := ["ball", "flowers", "game_console", "guitar", "party_hat"]


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null
var game_result = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("BackgroundSound")
var _background_sound_active: bool = false

@onready var pick_object_sound: AudioStreamPlayer = get_node_or_null("PickObject")

var lives_layer: CanvasLayer = null
var lives_ui = null

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var spawn_timer: Timer = null


# =========================================================
# VARIABLES
# =========================================================

var pending_objects: Array = []
var current_lives: int = MAX_LIVES
var rescued: int = 0
var game_over: bool = false
var game_started: bool = false

# NUEVO: guarda si el resultado final fue victoria, para cuando se presione el botón
var _resultado_gano: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()

	_setup_timer_ui()
	_setup_game_result()
	_setup_lives_ui()
	_setup_damage_effect()
	_setup_spawn_timer()

	call_deferred("_start_game")


# =========================================================
# TIMER UI GLOBAL
# =========================================================

func _setup_timer_ui():
	if ResourceLoader.exists(TIMER_UI_SCRIPT_PATH):
		var timer_script = load(TIMER_UI_SCRIPT_PATH)
		timer_ui = timer_script.new()
		timer_ui.name = "TimerUI"
		add_child(timer_ui)
	else:
		push_error("No se encontró el script de TimerUI en: " + TIMER_UI_SCRIPT_PATH)
		return

	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)


func _start_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("set_tamano_panel"):
		timer_ui.set_tamano_panel(650, 60)

	if timer_ui.has_method("iniciar"):
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para salvar los objetos")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# GAME RESULT GLOBAL
# =========================================================

func _setup_game_result():
	if ResourceLoader.exists(GAME_RESULT_SCENE_PATH):
		var result_scene = load(GAME_RESULT_SCENE_PATH)
		game_result = result_scene.instantiate()
		game_result.name = "GameResult"
		add_child(game_result)
		_reconectar_boton_volver()
	else:
		push_error("No se encontró GameResult.tscn en: " + GAME_RESULT_SCENE_PATH)


# NUEVO: quita la conexión original del botón (que iba al menú principal)
# y la reemplaza por una que nos regresa a nuestro Map.tscn.
# No toca GameResult.gd para nada.
func _reconectar_boton_volver():
	if not game_result:
		return

	var boton: Button = game_result.get("back_button")
	if boton == null:
		push_warning("No se encontró back_button en GameResult; revisa el nombre de la variable.")
		return

	# Desconecta TODAS las conexiones existentes de esa señal (la original hacia menu_path)
	for conexion in boton.pressed.get_connections():
		boton.pressed.disconnect(conexion["callable"])

	# Conecta nuestra propia función
	boton.pressed.connect(_on_volver_al_mapa_pressed)


# NUEVO: esta es la función que se ejecuta al presionar "Volver al menú"
func _on_volver_al_mapa_pressed():
	GameState.volver_al_mapa_con_resultado(_resultado_gano)


# =========================================================
# VIDAS GLOBAL
# =========================================================

func _setup_lives_ui():
	if lives_layer:
		return

	lives_layer = CanvasLayer.new()
	lives_layer.name = "LivesLayer"
	lives_layer.layer = 120
	add_child(lives_layer)

	if ResourceLoader.exists(LIVES_UI_SCRIPT_PATH):
		var lives_script = load(LIVES_UI_SCRIPT_PATH)
		lives_ui = Node2D.new()
		lives_ui.name = "LivesUI"
		lives_ui.set_script(lives_script)
		lives_layer.add_child(lives_ui)
	else:
		push_error("No se encontró LivesUi.gd en: " + LIVES_UI_SCRIPT_PATH)
		return

	if lives_ui.has_method("set_max_lives"):
		lives_ui.set_max_lives(MAX_LIVES)
	else:
		lives_ui.set("max_lives", MAX_LIVES)

	_update_lives_ui()


func _update_lives_ui():
	if not lives_ui:
		return

	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.actualizar_vidas(current_lives)
	else:
		lives_ui.set("current_lives", current_lives)

	if lives_ui.has_method("queue_redraw"):
		lives_ui.queue_redraw()


# =========================================================
# EFECTO DE DAÑO
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

	var original_pos: Vector2 = position

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

		shake_tween.tween_property(self, "position", original_pos + offset, 0.03)

	shake_tween.tween_property(self, "position", original_pos, 0.05)


# =========================================================
# SONIDO DE FONDO
# =========================================================

func _start_background_sound() -> void:
	_background_sound_active = true

	if not background_sound:
		return

	if background_sound.stream:
		if background_sound.stream is AudioStreamWAV:
			background_sound.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif background_sound.stream is AudioStreamOggVorbis:
			background_sound.stream.loop = true

	if not background_sound.finished.is_connected(_on_background_sound_finished):
		background_sound.finished.connect(_on_background_sound_finished)

	background_sound.play()


func _on_background_sound_finished() -> void:
	if _background_sound_active and background_sound:
		background_sound.play()


func _stop_background_sound() -> void:
	_background_sound_active = false

	if background_sound:
		background_sound.stop()


func _play_pick_object_sound() -> void:
	if pick_object_sound:
		pick_object_sound.play()


# =========================================================
# SPAWN DE OBJETOS
# =========================================================

func _setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _build_object_pool():
	pending_objects.clear()

	for obj_name in GOOD_OBJECTS:
		pending_objects.append({"name": obj_name, "is_good": true})

	for obj_name in BAD_OBJECTS:
		pending_objects.append({"name": obj_name, "is_good": false})

	pending_objects.shuffle()


func _schedule_next_spawn():
	if game_over or pending_objects.is_empty():
		return
	spawn_timer.start(randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX))


func _on_spawn_timer_timeout():
	if game_over or pending_objects.is_empty():
		return

	var data: Dictionary = pending_objects.pop_back()
	_spawn_object(data)
	_schedule_next_spawn()


func _spawn_object(data: Dictionary):
	if not ResourceLoader.exists(FLOATING_OBJECT_SCENE_PATH):
		push_error("No se encontró FloatingObject.tscn en: " + FLOATING_OBJECT_SCENE_PATH)
		return

	var object_scene = load(FLOATING_OBJECT_SCENE_PATH)
	var obj = object_scene.instantiate()

	obj.object_name = data["name"]
	obj.is_good = data["is_good"]
	obj.texture = _load_texture(data["name"])

	var viewport_size: Vector2 = get_viewport_rect().size
	var lower_half_top: float = viewport_size.y / 2.0
	var y: float = randf_range(lower_half_top, viewport_size.y - 60)
	obj.position = Vector2(-140, y)

	obj.clicked.connect(_on_object_clicked)

	add_child(obj)


func _load_texture(obj_name: String) -> Texture2D:
	var file_name: String = obj_name.to_lower().replace(" ", "_")
	var path: String = OBJECTS_FOLDER + file_name + ".png"
	return load(path)


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	rescued = 0
	current_lives = MAX_LIVES

	_update_lives_ui()
	_build_object_pool()
	_schedule_next_spawn()
	_start_global_timer()
	_start_background_sound()


# =========================================================
# CLICKS EN OBJETOS
# =========================================================

func _on_object_clicked(obj):
	if game_over:
		return

	_play_pick_object_sound()

	if obj.is_good:
		rescued += 1
		if rescued >= GOOD_OBJECTS.size():
			_win_game()
	else:
		_lose_life()

	obj.queue_free()


# =========================================================
# VIDAS
# =========================================================

func _lose_life():
	current_lives -= 1
	current_lives = max(current_lives, 0)

	_update_lives_ui()
	_play_damage_effect()

	if current_lives <= 0:
		await get_tree().create_timer(0.2).timeout
		_lose_game()


# =========================================================
# WIN / LOSE
# =========================================================

func _on_time_up():
	if game_over:
		return

	_lose_game()


func _win_game():
	if game_over:
		return

	game_over = true
	game_started = false
	_resultado_gano = true  # NUEVO

	_stop_global_timer()
	_stop_background_sound()
	if spawn_timer:
		spawn_timer.stop()
	_clear_objects()

	if game_result:
		if game_result.has_method("show_win"):
			game_result.show_win()
		elif game_result.has_method("mostrar_ganaste"):
			game_result.mostrar_ganaste()
	# Ya no navega solo — el botón "Volver al menú" (reconectado) se encarga


func _lose_game():
	if game_over:
		return

	game_over = true
	game_started = false
	_resultado_gano = false  # NUEVO

	_stop_global_timer()
	_stop_background_sound()
	if spawn_timer:
		spawn_timer.stop()
	_clear_objects()

	if game_result:
		if game_result.has_method("show_lose"):
			game_result.show_lose()
		elif game_result.has_method("mostrar_perdiste"):
			game_result.mostrar_perdiste()
	# Ya no navega solo — el botón "Volver al menú" (reconectado) se encarga


func _clear_objects():
	for child in get_children():
		if child is FloatingObject:
			child.queue_free()
