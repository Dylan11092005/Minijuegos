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

# Cuánto tiempo hay que sobrevivir esquivando rocas para ganar.
const GAME_TIME := 45.0
const MAX_LIVES := 3

# Cada cuánto cae una roca nueva.
const SPAWN_INTERVAL_MIN := 1.2
const SPAWN_INTERVAL_MAX := 2.2

# Velocidad de caída (píxeles/segundo). Las rocas más grandes caen
# un poco más rápido que las chicas para que sean más peligrosas.
const FALL_SPEED_MIN := 260.0
const FALL_SPEED_MAX := 520.0

# Tamaño de las rocas: multiplicador aplicado sobre la escala original
# del nodo "Rock" de la escena (que actúa como plantilla/molde).
const ROCK_SCALE_MULT_MIN := 0.5
const ROCK_SCALE_MULT_MAX := 1.1

# Reduce un poco el área de colisión respecto al tamaño visual, para que
# el juego se sienta más "justo" con el jugador.
const ROCK_HITBOX_SHRINK := 0.65
const PLAYER_HITBOX_SHRINK := 0.3

# Margen (en px) para no dejar que el personaje salga del todo de pantalla.
const SCREEN_MARGIN := 20.0

# Velocidad de movimiento del personaje con teclado (para probar en editor).
const PLAYER_KEYBOARD_SPEED := 700.0

# Qué tan rápido el personaje "sigue" el dedo/mouse al arrastrar.
const DRAG_FOLLOW_SPEED := 18.0


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

const WIN_MESSAGE := "¡Felicidades!\nEsquivaste todas las rocas"
const LOSE_MESSAGE := "¡Qué mal!\nTe cayeron demasiadas rocas"
const BACK_BUTTON_TEXT := "Volver al mapa"


# =========================================================
# NODE / UI GLOBAL
# =========================================================

var timer_ui = null

@onready var background_sound: AudioStreamPlayer = get_node_or_null("Background")
var _background_sound_active: bool = false

@onready var hit_sound: AudioStreamPlayer = get_node_or_null("PainRocks")

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
# NODOS DEL JUEGO
# =========================================================

@onready var player: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var rock_template: Sprite2D = get_node_or_null("Rock")

var rock_base_scale: Vector2 = Vector2(1, 1)
var rock_texture_size: Vector2 = Vector2(1, 1)
var player_texture_size: Vector2 = Vector2(1, 1)


# =========================================================
# VARIABLES
# =========================================================

var current_lives: int = MAX_LIVES
var game_over: bool = false
var game_started: bool = false

var _resultado_gano: bool = false

# Rocas actualmente cayendo. Cada elemento es un diccionario:
# { "node": Sprite2D, "speed": float, "half_size": Vector2 }
var active_rocks: Array = []

var screen_size: Vector2 = Vector2(1920, 1080)

# Control de movimiento por arrastre (touch/mouse).
var _dragging: bool = false
var _target_x: float = 0.0


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()

	screen_size = get_viewport().get_visible_rect().size

	_setup_player()
	_setup_rock_template()
	_setup_timer_ui()
	_setup_resultado_ui()
	_setup_lives_ui()
	_setup_damage_effect()
	_setup_spawn_timer()

	call_deferred("_start_game")


func _process(delta: float) -> void:
	if not game_started or game_over:
		return

	_update_player_movement(delta)
	_update_rocks(delta)


# =========================================================
# JUGADOR
# =========================================================

func _setup_player():
	if not player:
		push_error("No se encontró el nodo AnimatedSprite2D del personaje.")
		return

	if player.sprite_frames:
		player.play("default")

	_target_x = player.position.x

	var frame_texture: Texture2D = null
	if player.sprite_frames and player.sprite_frames.has_animation("default"):
		frame_texture = player.sprite_frames.get_frame_texture("default", 0)

	if frame_texture:
		player_texture_size = frame_texture.get_size() * player.scale


func _update_player_movement(delta: float) -> void:
	if not player:
		return

	# Teclado (para probar en el editor / PC).
	var keyboard_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		keyboard_dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		keyboard_dir += 1.0

	if keyboard_dir != 0.0:
		_target_x = player.position.x + keyboard_dir * PLAYER_KEYBOARD_SPEED * delta
		player.position.x = _target_x
	elif _dragging:
		player.position.x = lerp(player.position.x, _target_x, min(DRAG_FOLLOW_SPEED * delta, 1.0))

	var half_width: float = player_texture_size.x * 0.5
	player.position.x = clamp(player.position.x, SCREEN_MARGIN + half_width, screen_size.x - SCREEN_MARGIN - half_width)


func _unhandled_input(event: InputEvent) -> void:
	if game_over or not game_started:
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_dragging = true
			_target_x = touch_event.position.x
		else:
			_dragging = false

	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_dragging = true
		_target_x = drag_event.position.x

	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_dragging = true
				_target_x = mouse_event.position.x
			else:
				_dragging = false

	elif event is InputEventMouseMotion:
		if _dragging:
			var motion_event := event as InputEventMouseMotion
			_target_x = motion_event.position.x


# =========================================================
# ROCAS
# =========================================================

func _setup_rock_template():
	if not rock_template:
		push_error("No se encontró el nodo Rock (plantilla) en la escena.")
		return

	rock_template.visible = false
	rock_base_scale = rock_template.scale

	if rock_template.texture:
		rock_texture_size = rock_template.texture.get_size()


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
		_spawn_rock()
	_schedule_next_spawn()


func _spawn_rock():
	if not rock_template:
		return

	var new_rock: Sprite2D = rock_template.duplicate()
	new_rock.visible = true

	var size_mult: float = randf_range(ROCK_SCALE_MULT_MIN, ROCK_SCALE_MULT_MAX)
	new_rock.scale = rock_base_scale * size_mult

	var half_size: Vector2 = (rock_texture_size * new_rock.scale) * 0.5

	var spawn_x: float = randf_range(SCREEN_MARGIN + half_size.x, screen_size.x - SCREEN_MARGIN - half_size.x)
	new_rock.position = Vector2(spawn_x, -half_size.y)

	add_child(new_rock)

	# Las rocas más grandes (size_mult más alto) caen un poco más rápido.
	var size_factor: float = inverse_lerp(ROCK_SCALE_MULT_MIN, ROCK_SCALE_MULT_MAX, size_mult)
	var speed: float = lerp(FALL_SPEED_MIN, FALL_SPEED_MAX, size_factor)

	active_rocks.append({
		"node": new_rock,
		"speed": speed,
		"half_size": half_size,
	})


func _update_rocks(delta: float) -> void:
	var to_remove: Array = []

	for rock_data in active_rocks:
		var node: Sprite2D = rock_data["node"]
		if not is_instance_valid(node):
			to_remove.append(rock_data)
			continue

		node.position.y += rock_data["speed"] * delta

		if _check_collision(rock_data):
			_on_player_hit()
			node.queue_free()
			to_remove.append(rock_data)
			continue

		if node.position.y - rock_data["half_size"].y > screen_size.y:
			node.queue_free()
			to_remove.append(rock_data)

	for rock_data in to_remove:
		active_rocks.erase(rock_data)


func _check_collision(rock_data: Dictionary) -> bool:
	if not player:
		return false

	var node: Sprite2D = rock_data["node"]

	var rock_half: Vector2 = rock_data["half_size"] * ROCK_HITBOX_SHRINK
	var player_half: Vector2 = (player_texture_size * 0.5) * PLAYER_HITBOX_SHRINK

	var rock_rect := Rect2(node.position - rock_half, rock_half * 2.0)
	var player_rect := Rect2(player.position - player_half, player_half * 2.0)

	return rock_rect.intersects(player_rect)


func _clear_all_rocks():
	for rock_data in active_rocks:
		var node: Sprite2D = rock_data["node"]
		if is_instance_valid(node):
			node.queue_free()

	active_rocks.clear()


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
		timer_ui.iniciar(GAME_TIME, "Tiempo restante", "para esquivar las rocas")
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


func _mostrar_resultado(gano: bool):
	_resultado_gano = gano
	resultado_label.text = WIN_MESSAGE if gano else LOSE_MESSAGE

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


func _play_hit_sound() -> void:
	if hit_sound:
		hit_sound.play()


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false

	current_lives = MAX_LIVES

	_clear_all_rocks()
	_update_lives_ui()
	_schedule_next_spawn()
	_start_global_timer()
	_start_background_sound()


# =========================================================
# IMPACTOS
# =========================================================

func _on_player_hit():
	if game_over:
		return

	_play_hit_sound()
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
# WIN / LOSE
# =========================================================

func _on_time_up():
	if game_over:
		return

	_win_game()


func _win_game():
	if game_over:
		return

	game_over = true
	game_started = false

	_stop_global_timer()
	_stop_background_sound()
	if spawn_timer:
		spawn_timer.stop()
	_clear_all_rocks()

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
	_clear_all_rocks()

	_mostrar_resultado(false)
