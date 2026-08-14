extends Node2D


# =========================================================
# PATHS
# =========================================================
# Ajusta estas rutas a donde tengas guardados tus scripts globales.

const TIMER_UI_SCRIPT_PATH := "res://Minigames/ui_global/TimerUI.gd"
const LIVES_UI_SCRIPT_PATH := "res://Minigames/ui_global/LivesUi.gd"


# =========================================================
# GAME SETTINGS
# =========================================================

# Tiempo total para llegar a la cima.
const GAME_TIME := 60.0
const MAX_LIVES := 3

# Velocidad de caminata a lo largo del path (píxeles/segundo).
const WALK_SPEED := 100.0

# Cada cuánto llega una racha de viento (segundos entre rachas).
const WIND_INTERVAL_MIN := 4.0
const WIND_INTERVAL_MAX := 7.0

# Cuánto tiempo se avisa ANTES de que llegue la racha, para que el
# jugador alcance a soltar el botón/tecla de caminar.
const WIND_WARNING_TIME := 1.5

# Cuánto dura cada racha de viento.
const WIND_DURATION_MIN := 1.5
const WIND_DURATION_MAX := 2.5

# Cuántos sprites de viento salen por racha.
const WIND_SPRITE_COUNT_MIN := 6
const WIND_SPRITE_COUNT_MAX := 10

# Qué tan fuerte tiembla la pantalla durante la racha.
const SHAKE_MAGNITUDE := 6.0

# Velocidad a la que se desplazan los sprites de viento por la pantalla.
const WIND_SPRITE_SPEED_MIN := 250.0
const WIND_SPRITE_SPEED_MAX := 500.0

# El personaje se va achicando a medida que avanza, para simular que
# se aleja / sube la montaña. Multiplicador sobre su escala original.
const CHARACTER_END_SCALE_MULT := 0.45


# =========================================================
# COLORES DEL PANEL DE RESULTADO PROPIO
# =========================================================

const RC_BEIGE := Color("#E5C89E")
const RC_ORANGE := Color("#E0B080")
const RC_BLUE := Color("#3E5F8F")
const RC_CYAN := Color("#30C0F0")
const RC_LIGHT_BLUE := Color("#C0E0FF")
const RC_WHITE := Color("#F5F5F5")

const RESULT_PANEL_SIZE := Vector2(500, 260)
const RESULT_BUTTON_SIZE := Vector2(240, 56)

const WIN_MESSAGE := "¡Felicidades!\nLlegaste a la cima"
const LOSE_MESSAGE := "¡Qué mal!\nNo llegaste a la cima a tiempo"
const BACK_BUTTON_TEXT := "Volver al mapa"

const WIND_WARNING_TEXT := "¡Viene el viento!\nDejá de caminar"
const WIND_WARNING_COLOR := Color("#FFF3D6")


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("Background")
var _background_sound_active: bool = false

@onready var wind_sound: AudioStreamPlayer = get_node_or_null("WindSound")
@onready var wind_warning_sound: AudioStreamPlayer = get_node_or_null("WindWarning")

var lives_layer: CanvasLayer = null
var lives_ui = null

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

# --- Aviso previo a la racha de viento ---
var warning_layer: CanvasLayer = null
var warning_label: Label = null
var _warning_blink_tween: Tween = null

# --- Panel de resultado propio (creado por código) ---
var resultado_layer: CanvasLayer = null
var resultado_panel: Panel = null
var resultado_label: Label = null
var resultado_boton: Button = null


# =========================================================
# NODOS DEL JUEGO
# =========================================================

@onready var player: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var path_node: Path2D = get_node_or_null("Path2D")
@onready var wind_template: Sprite2D = get_node_or_null("Wind")

var curve: Curve2D = null
var total_length: float = 0.0
var character_start_scale: Vector2 = Vector2(1, 1)
var character_end_scale: Vector2 = Vector2(1, 1)


# =========================================================
# VARIABLES
# =========================================================

var progress_distance: float = 0.0
var current_lives: int = MAX_LIVES
var game_over: bool = false
var game_started: bool = false

var _resultado_gano: bool = false

var meta_label: Label = null

var original_root_position: Vector2 = Vector2.ZERO

# --- Viento ---
var wind_active: bool = false
var _life_lost_this_gust: bool = false
var wind_schedule_timer: Timer = null
var wind_warning_timer: Timer = null
var wind_duration_timer: Timer = null

# Cada elemento: { "node": Sprite2D, "velocity": Vector2 }
var active_wind_sprites: Array = []

var screen_size: Vector2 = Vector2(1920, 1080)

# --- Input de "caminar" (touch/mouse sostenido) ---
var _touch_held: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()

	screen_size = get_viewport().get_visible_rect().size
	original_root_position = position

	_setup_player_and_path()
	_setup_wind_template()
	_setup_timer_ui()
	_setup_resultado_ui()
	_setup_resultado_sound()
	_setup_lives_ui()
	_setup_damage_effect()
	_setup_warning_ui()
	_setup_wind_timers()
	_setup_meta_label()

	call_deferred("_start_game")


func _process(delta: float) -> void:
	if not game_started or game_over:
		return

	if wind_active:
		_apply_wind_shake()
		_update_wind_sprites(delta)

		if _is_walk_input_held() and not _life_lost_this_gust:
			_life_lost_this_gust = true
			_on_moved_during_wind()

		return

	# Si no hay viento, la pantalla queda quieta.
	position = original_root_position

	_update_walking(delta)


# =========================================================
# JUGADOR Y PATH
# =========================================================

func _setup_player_and_path():
	if not player:
		push_error("No se encontró el nodo AnimatedSprite2D del personaje.")
	else:
		if player.sprite_frames:
			player.play("default")
		character_start_scale = player.scale
		character_end_scale = character_start_scale * CHARACTER_END_SCALE_MULT

	if not path_node or not path_node.curve:
		push_error("No se encontró el Path2D o su Curve2D.")
		return

	curve = path_node.curve
	total_length = curve.get_baked_length()


func _is_walk_input_held() -> bool:
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return true
	return _touch_held


func _update_walking(delta: float) -> void:
	if not curve or not player:
		return

	if _is_walk_input_held():
		progress_distance += WALK_SPEED * delta
		progress_distance = clamp(progress_distance, 0.0, total_length)

	var point: Vector2 = curve.sample_baked(progress_distance)
	player.position = path_node.position + point

	var fraction: float = 0.0
	if total_length > 0.0:
		fraction = progress_distance / total_length

	player.scale = character_start_scale.lerp(character_end_scale, fraction)
	_update_meta_label(fraction)

	if progress_distance >= total_length:
		_win_game()


func _unhandled_input(event: InputEvent) -> void:
	if game_over or not game_started:
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_touch_held = touch_event.pressed

	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_touch_held = mouse_event.pressed


# =========================================================
# VIENTO
# =========================================================

func _setup_meta_label():
	var meta_layer := CanvasLayer.new()
	meta_layer.name = "MetaLayer"
	meta_layer.layer = 90
	add_child(meta_layer)

	meta_label = Label.new()
	meta_label.add_theme_color_override("font_color", RC_WHITE)
	meta_label.add_theme_font_size_override("font_size", 24)
	meta_label.add_theme_constant_override("outline_size", 7)
	meta_label.add_theme_color_override("font_outline_color", RC_BLUE)
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	meta_label.position = Vector2(-250, 90)
	meta_label.custom_minimum_size = Vector2(500, 36)

	meta_layer.add_child(meta_label)


func _update_meta_label(fraction: float):
	if not meta_label:
		return
	meta_label.text = "Camino recorrido hacia la cima: %d%%" % int(round(fraction * 100.0))


func _setup_wind_template():
	if not wind_template:
		push_error("No se encontró el nodo Wind (plantilla) en la escena.")
		return

	wind_template.visible = false


func _setup_wind_timers():
	wind_schedule_timer = Timer.new()
	wind_schedule_timer.one_shot = true
	add_child(wind_schedule_timer)
	wind_schedule_timer.timeout.connect(_on_wind_schedule_timeout)

	wind_warning_timer = Timer.new()
	wind_warning_timer.one_shot = true
	add_child(wind_warning_timer)
	wind_warning_timer.timeout.connect(_on_wind_warning_timeout)

	wind_duration_timer = Timer.new()
	wind_duration_timer.one_shot = true
	add_child(wind_duration_timer)
	wind_duration_timer.timeout.connect(_on_wind_duration_timeout)


func _schedule_next_wind():
	if game_over:
		return
	wind_schedule_timer.start(randf_range(WIND_INTERVAL_MIN, WIND_INTERVAL_MAX))


func _on_wind_schedule_timeout():
	if not game_over:
		_show_wind_warning()


func _on_wind_warning_timeout():
	_hide_wind_warning()
	if not game_over:
		_start_wind_gust()


func _start_wind_gust():
	wind_active = true
	_life_lost_this_gust = false

	_play_wind_sound()
	_spawn_wind_sprites()

	wind_duration_timer.start(randf_range(WIND_DURATION_MIN, WIND_DURATION_MAX))


func _on_wind_duration_timeout():
	wind_active = false
	position = original_root_position
	_clear_wind_sprites()
	_stop_wind_sound()

	_schedule_next_wind()


func _spawn_wind_sprites():
	if not wind_template:
		return

	var amount: int = randi_range(WIND_SPRITE_COUNT_MIN, WIND_SPRITE_COUNT_MAX)

	for i in range(amount):
		var new_wind: Sprite2D = wind_template.duplicate()
		new_wind.visible = true

		var spawn_x: float = randf_range(screen_size.x * 0.6, screen_size.x + 150.0)
		var spawn_y: float = randf_range(0.0, screen_size.y)
		new_wind.position = Vector2(spawn_x, spawn_y)

		add_child(new_wind)

		var speed: float = randf_range(WIND_SPRITE_SPEED_MIN, WIND_SPRITE_SPEED_MAX)
		var velocity := Vector2(-speed, randf_range(-30.0, 30.0))

		active_wind_sprites.append({
			"node": new_wind,
			"velocity": velocity,
		})


func _update_wind_sprites(delta: float) -> void:
	var to_remove: Array = []

	for wind_data in active_wind_sprites:
		var node: Sprite2D = wind_data["node"]
		if not is_instance_valid(node):
			to_remove.append(wind_data)
			continue

		node.position += wind_data["velocity"] * delta

		if node.position.x < -200.0:
			node.queue_free()
			to_remove.append(wind_data)

	for wind_data in to_remove:
		active_wind_sprites.erase(wind_data)


func _clear_wind_sprites():
	for wind_data in active_wind_sprites:
		var node: Sprite2D = wind_data["node"]
		if is_instance_valid(node):
			node.queue_free()

	active_wind_sprites.clear()


func _apply_wind_shake() -> void:
	position = original_root_position + Vector2(
		randf_range(-SHAKE_MAGNITUDE, SHAKE_MAGNITUDE),
		randf_range(-SHAKE_MAGNITUDE, SHAKE_MAGNITUDE)
	)


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
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para llegar a la cima")
	else:
		push_error("TimerUI no tiene el método iniciar(p_time, p_text_before, p_text_after).")


func _stop_global_timer():
	if not timer_ui:
		return

	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# PANEL DE RESULTADO PROPIO (100% por código, no usa GameResult.tscn)
# =========================================================

func _setup_resultado_ui():
	resultado_layer = CanvasLayer.new()
	resultado_layer.name = "ResultadoLayer"
	resultado_layer.layer = 150
	add_child(resultado_layer)

	resultado_panel = Panel.new()
	resultado_panel.custom_minimum_size = RESULT_PANEL_SIZE
	resultado_panel.visible = false
	resultado_layer.add_child(resultado_panel)

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = RC_BEIGE
	estilo_panel.border_color = RC_ORANGE
	estilo_panel.set_border_width_all(6)
	estilo_panel.set_corner_radius_all(28)
	estilo_panel.shadow_color = Color(0, 0, 0, 0.28)
	estilo_panel.shadow_size = 16
	estilo_panel.content_margin_left = 24
	estilo_panel.content_margin_right = 24
	estilo_panel.content_margin_top = 24
	estilo_panel.content_margin_bottom = 24
	resultado_panel.add_theme_stylebox_override("panel", estilo_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	resultado_panel.add_child(vbox)

	resultado_label = Label.new()
	resultado_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado_label.add_theme_color_override("font_color", RC_BLUE)
	resultado_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(resultado_label)

	resultado_boton = Button.new()
	resultado_boton.text = BACK_BUTTON_TEXT
	resultado_boton.custom_minimum_size = RESULT_BUTTON_SIZE
	resultado_boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var estilo_normal := StyleBoxFlat.new()
	estilo_normal.bg_color = RC_CYAN
	estilo_normal.border_color = RC_BLUE
	estilo_normal.set_border_width_all(4)
	estilo_normal.set_corner_radius_all(18)

	var estilo_hover := estilo_normal.duplicate()
	estilo_hover.bg_color = RC_LIGHT_BLUE

	var estilo_pressed := estilo_normal.duplicate()
	estilo_pressed.bg_color = RC_BLUE
	estilo_pressed.border_color = RC_CYAN

	resultado_boton.add_theme_stylebox_override("normal", estilo_normal)
	resultado_boton.add_theme_stylebox_override("hover", estilo_hover)
	resultado_boton.add_theme_stylebox_override("pressed", estilo_pressed)
	resultado_boton.add_theme_color_override("font_color", RC_WHITE)
	resultado_boton.add_theme_font_size_override("font_size", 22)

	resultado_boton.pressed.connect(_on_volver_al_mapa_pressed)
	vbox.add_child(resultado_boton)


# =========================================================
# SONIDO DE GANAR / PERDER (compartido por todos los minijuegos)
# =========================================================

const WIN_SOUND_PATH := "res://Minigames/ui_global/music/MusicaVictoria.mp3"
const LOSE_SOUND_PATH := "res://Minigames/ui_global/music/JuegoPerdido.mp3"

var resultado_sound_player: AudioStreamPlayer = null


func _setup_resultado_sound():
	resultado_sound_player = AudioStreamPlayer.new()
	resultado_sound_player.name = "ResultadoSoundPlayer"
	add_child(resultado_sound_player)


func _play_resultado_sound(gano: bool):
	if not resultado_sound_player:
		return

	var path: String = WIN_SOUND_PATH if gano else LOSE_SOUND_PATH
	if not ResourceLoader.exists(path):
		push_error("No se encontró el sonido de resultado en: " + path)
		return

	resultado_sound_player.stream = load(path)
	resultado_sound_player.play()


func _mostrar_resultado(gano: bool):
	_resultado_gano = gano
	resultado_label.text = WIN_MESSAGE if gano else LOSE_MESSAGE
	_play_resultado_sound(gano)

	var screen := get_viewport().get_visible_rect().size
	resultado_panel.position = (screen - RESULT_PANEL_SIZE) / 2.0
	resultado_panel.visible = true


func _on_volver_al_mapa_pressed():
	GameState.volver_al_mapa_con_resultado(_resultado_gano)


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


func _play_wind_sound() -> void:
	if wind_sound:
		wind_sound.play()


func _stop_wind_sound() -> void:
	if wind_sound:
		wind_sound.stop()


func _play_wind_warning_sound() -> void:
	if wind_warning_sound:
		wind_warning_sound.play()


# =========================================================
# AVISO PREVIO A LA RACHA DE VIENTO
# =========================================================

func _setup_warning_ui():
	warning_layer = CanvasLayer.new()
	warning_layer.name = "WarningLayer"
	warning_layer.layer = 170
	add_child(warning_layer)

	warning_label = Label.new()
	warning_label.text = WIND_WARNING_TEXT
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.add_theme_color_override("font_color", WIND_WARNING_COLOR)
	warning_label.add_theme_font_size_override("font_size", 40)
	warning_label.add_theme_constant_override("outline_size", 8)
	warning_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	warning_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_label.position = Vector2(-250, 60)
	warning_label.custom_minimum_size = Vector2(500, 100)
	warning_label.visible = false

	warning_layer.add_child(warning_label)


func _show_wind_warning():
	if not warning_label:
		return

	_play_wind_warning_sound()

	warning_label.visible = true
	warning_label.modulate.a = 1.0

	if _warning_blink_tween:
		_warning_blink_tween.kill()

	_warning_blink_tween = create_tween()
	_warning_blink_tween.set_loops()
	_warning_blink_tween.tween_property(warning_label, "modulate:a", 0.25, 0.25)
	_warning_blink_tween.tween_property(warning_label, "modulate:a", 1.0, 0.25)

	wind_warning_timer.start(WIND_WARNING_TIME)


func _hide_wind_warning():
	if not warning_label:
		return

	if _warning_blink_tween:
		_warning_blink_tween.kill()
		_warning_blink_tween = null

	warning_label.visible = false


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
# EFECTO DE DAÑO (solo destello, la pantalla ya tiembla por el viento)
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

	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)


# =========================================================
# MOVERSE DURANTE EL VIENTO
# =========================================================

func _on_moved_during_wind():
	if game_over:
		return

	_lose_life()


func _lose_life():
	current_lives -= 1
	current_lives = max(current_lives, 0)

	_update_lives_ui()
	_play_damage_effect()

	if current_lives <= 0:
		await get_tree().create_timer(0.2).timeout
		_lose_game()


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	progress_distance = 0.0
	current_lives = MAX_LIVES
	wind_active = false
	_clear_wind_sprites()
	_update_lives_ui()
	_update_meta_label(0.0)

	if player and curve:
		player.position = path_node.position + curve.sample_baked(0.0)
		player.scale = character_start_scale

	_schedule_next_wind()
	_start_global_timer()
	_start_background_sound()


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

	_stop_global_timer()
	_stop_background_sound()
	_stop_wind_sound()
	if wind_schedule_timer:
		wind_schedule_timer.stop()
	if wind_warning_timer:
		wind_warning_timer.stop()
	if wind_duration_timer:
		wind_duration_timer.stop()
	_hide_wind_warning()
	position = original_root_position
	_clear_wind_sprites()

	_mostrar_resultado(true)


func _lose_game():
	if game_over:
		return

	game_over = true
	game_started = false

	_stop_global_timer()
	_stop_background_sound()
	_stop_wind_sound()
	if wind_schedule_timer:
		wind_schedule_timer.stop()
	if wind_warning_timer:
		wind_warning_timer.stop()
	if wind_duration_timer:
		wind_duration_timer.stop()
	_hide_wind_warning()
	position = original_root_position
	_clear_wind_sprites()

	_mostrar_resultado(false)
