extends Node2D


# =========================================================
# PATHS
# =========================================================
# Ajusta estas rutas a donde tengas guardados tus scripts globales.

const TIMER_UI_SCRIPT_PATH := "res://Minigames/ui_global/TimerUI.gd"
const LIVES_UI_SCRIPT_PATH := "res://Minigames/ui_global/LivesUi.gd"

const FLAMES_GROUP := "flames"

# Ajusta esta ruta a donde tengas guardado Flame.tscn en tu proyecto.
const FLAME_SCENE_PATH := "res://Minigames/minigame_deluxe/mini_minigame_level3/Flame.tscn"


# =========================================================
# GAME SETTINGS
# =========================================================

const GAME_TIME := 60.0
const MAX_LIVES := 3

# Cuántas llamas hay que apagar a tiempo para ganar la partida.
const TARGET_EXTINGUISHED := 12

# Cada cuánto aparece una llama nueva.
const SPAWN_INTERVAL_MIN := 0.5
const SPAWN_INTERVAL_MAX := 1.1

# Perspectiva: entre más abajo, más grande; entre más arriba, más chica.
# Perspectiva: entre más abajo, más grande; entre más arriba, más chica.
const MIN_SCALE := 0.175   # arriba del rango permitido (antes 0.35)
const MAX_SCALE := 0.7     # abajo de la pantalla (antes 1.4)

# Las llamas solo aparecen de la mitad de la pantalla hacia abajo (un poco más).
# 0.55 = empiezan un poquito pasando la mitad. Ajusta a tu gusto (0.6, 0.65, etc).
const SPAWN_Y_MIN_RATIO := 0.55

# Cuánto tarda una llama en "madurar" (ponerse muy grande) si no se apaga.
const GROWTH_TIME_MIN := 5.0
const GROWTH_TIME_MAX := 8.0

# Cuánto crece (multiplicador) una llama entre que aparece y madura.
const GROWTH_MULTIPLIER := 1.9

# Cuántos clicks hacen falta para apagar una llama.
const HITS_TO_EXTINGUISH := 3


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

const WIN_MESSAGE := "¡Felicidades!\nApagaste las llamas a tiempo"
const LOSE_MESSAGE := "¡Qué mal!\nLa ciudad se quemó"
const BACK_BUTTON_TEXT := "Volver al mapa"


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("BackgroundSound")
var _background_sound_active: bool = false

@onready var extinguish_flame_sound: AudioStreamPlayer = get_node_or_null("ExtinguishFlameSound")

var lives_layer: CanvasLayer = null
var lives_ui = null

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var spawn_timer: Timer = null

# --- Panel de resultado propio (creado por código) ---
var resultado_layer: CanvasLayer = null
var resultado_panel: Panel = null
var resultado_label: Label = null
var resultado_boton: Button = null


# =========================================================
# VARIABLES
# =========================================================

var current_lives: int = MAX_LIVES
var extinguished_count: int = 0
var game_over: bool = false
var game_started: bool = false

var _resultado_gano: bool = false

var meta_label: Label = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()

	_setup_timer_ui()
	_setup_resultado_ui()
	_setup_resultado_sound()
	_setup_lives_ui()
	_setup_damage_effect()
	_setup_spawn_timer()
	_setup_meta_label()

	call_deferred("_start_game")


# =========================================================
# TIMER UI GLOBAL
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


func _update_meta_label():
	if not meta_label:
		return
	meta_label.text = "Llamas apagadas: %d / %d" % [extinguished_count, TARGET_EXTINGUISHED]

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
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para apagar las llamas")
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
# EFECTO DE DAÑO (mismo rojo y shake que en el juego de las llaves)
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


func _play_extinguish_flame_sound() -> void:
	if extinguish_flame_sound:
		extinguish_flame_sound.play()


# =========================================================
# LLAMAS
# =========================================================

func _setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _schedule_next_spawn():
	if game_over:
		return
	spawn_timer.start(randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX))


func _on_spawn_timer_timeout():
	if not game_over:
		_spawn_flame()
	_schedule_next_spawn()


func _spawn_flame():
	if not ResourceLoader.exists(FLAME_SCENE_PATH):
		push_error("No se encontró Flame.tscn en: " + FLAME_SCENE_PATH)
		return

	var flame_scene = load(FLAME_SCENE_PATH)
	var flame = flame_scene.instantiate()

	var viewport_size: Vector2 = get_viewport_rect().size

	# Solo aparecen de SPAWN_Y_MIN_RATIO hacia abajo (no en el "cielo").
	var min_y: float = viewport_size.y * SPAWN_Y_MIN_RATIO
	var x: float = randf_range(0, viewport_size.x)
	var y: float = randf_range(min_y, viewport_size.y)

	# Perspectiva calculada solo dentro del rango permitido (min_y -> abajo).
	var base_scale: float = remap(y, min_y, viewport_size.y, MIN_SCALE, MAX_SCALE)
	var growth_time: float = randf_range(GROWTH_TIME_MIN, GROWTH_TIME_MAX)

	flame.configure(base_scale, growth_time, GROWTH_MULTIPLIER, HITS_TO_EXTINGUISH)
	flame.position = Vector2(x, y)

	add_child(flame)
	flame.add_to_group(FLAMES_GROUP)

	if not flame.extinguished.is_connected(_on_flame_extinguished):
		flame.extinguished.connect(_on_flame_extinguished)
	if not flame.matured.is_connected(_on_flame_matured):
		flame.matured.connect(_on_flame_matured)


func _clear_all_flames():
	for flame in get_tree().get_nodes_in_group(FLAMES_GROUP):
		flame.queue_free()


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	extinguished_count = 0
	current_lives = MAX_LIVES

	_update_lives_ui()
	_update_meta_label()
	_schedule_next_spawn()
	_start_global_timer()
	_start_background_sound()


# =========================================================
# RESULTADO DE CLICKS EN LLAMAS
# =========================================================

func _on_flame_extinguished(_flame: Node):
	if game_over:
		return

	_play_extinguish_flame_sound()

	extinguished_count += 1
	_update_meta_label()
	if extinguished_count >= TARGET_EXTINGUISHED:
		_win_game()


func _on_flame_matured(_flame: Node):
	if game_over:
		return

	_lose_life()


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

	_stop_global_timer()
	_stop_background_sound()
	if spawn_timer:
		spawn_timer.stop()

	_clear_all_flames()
	_mostrar_resultado(true)


func _lose_game():
	if game_over:
		return

	game_over = true
	game_started = false

	_stop_global_timer()
	_stop_background_sound()
	if spawn_timer:
		spawn_timer.stop()

	_clear_all_flames()
	_mostrar_resultado(false)
