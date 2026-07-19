extends Node2D

@export var TOTAL_TIME: float = 45.0
@export var max_lives := 3

@export var rock_scene: PackedScene = preload("res://Minigames/minigame_landslide/FallingRock.tscn")

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

const MUSIC_DIR := "res://Minigames/minigame_landslide/Music/"
const FIRE_TRUCK_PATH := "res://Minigames/minigame_landslide/assets/fire_truck.png"

const GLOBAL_SOUND_VOLUME := -10.0

@export var spawn_interval := 1.05
@export var spawn_interval_fast := 0.72

@export var safe_win_distance := 35.0

@export var rescue_truck_scale := Vector2(0.7, 0.7)
@export var rescue_truck_speed_to_player := 2.0
@export var rescue_truck_speed_to_safe := 2.6

var game_active := false
var already_finished := false
var rescue_started := false

var lives := 3
var has_called_911 := false
var player_in_phone_zone := false
var spawn_counter := 0.0
var current_spawn_interval := 1.05

var keypad_open := false
var dialed_number := ""

var player: CharacterBody2D = null
var phone_cabin: Area2D = null
var safe_cabin: Area2D = null
var rock_spawners: Node2D = null

var timer_hud: Node = null
var game_result_panel: Node = null
var lives_ui: Node = null

var ui_layer: CanvasLayer = null
var hud: Control = null
var mission_label: Label = null
var prompt_label: Label = null

var phone_overlay: ColorRect = null
var dial_display: Label = null

var alarm_sound: AudioStreamPlayer = null
var rocks_sound: AudioStreamPlayer = null
var keyboard_sound: AudioStreamPlayer = null
var firetruck_siren_sound: AudioStreamPlayer = null
var call_911_sound: AudioStreamPlayer = null

var rescue_truck: Sprite2D = null

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

	_create_audio()
	_setup_main_nodes()
	_setup_collisions()
	_create_ui()
	_create_timer()
	_create_result_panel()
	_create_lives_ui()
	_setup_damage_effect()
	_create_phone_keypad()
	_connect_signals()

	start_game()


func _process(delta: float) -> void:
	if not game_active or already_finished:
		return

	if keypad_open:
		return

	if rescue_started:
		return

	_handle_rock_spawn(delta)
	_check_safe_win()


func _input(event: InputEvent) -> void:
	if not keypad_open:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			_add_digit(str(event.keycode - KEY_0))
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			_add_digit(str(event.keycode - KEY_KP_0))
		elif event.keycode == KEY_BACKSPACE:
			_backspace_digit()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_try_call_number()
		elif event.keycode == KEY_ESCAPE:
			_close_phone_keypad()


func _setup_main_nodes() -> void:
	# --- Búsqueda robusta del jugador REAL ---
	# En vez de confiar en el nombre del nodo o en "el primer CharacterBody2D
	# que aparezca", buscamos específicamente el nodo que tiene el script
	# con receive_damage() y la señal damaged. Esto evita el bug de que el
	# manager agarre un CharacterBody2D "vacío" (sin script) que esté
	# envolviendo al verdadero jugador (ej: CharacterBody2D > PlayerLandslide).
	player = _find_player_controller()

	if player == null:
		player = get_node_or_null("Player") as CharacterBody2D

	if player == null:
		player = _find_first_character_body()

	if player:
		player.set_physics_process(true)

		if not player.is_in_group("player"):
			player.add_to_group("player")

		player.collision_layer = 1
		player.collision_mask = 2

		if not player.has_method("receive_damage"):
			push_warning("El nodo 'player' encontrado (%s) no tiene receive_damage(). Revisa que el script esté en el nodo correcto." % player.name)

		if not player.has_signal("damaged"):
			push_warning("El nodo 'player' encontrado (%s) no tiene la señal 'damaged'." % player.name)

		# --- Neutralizar cuerpos "fantasma" ---
		# Si el jugador real está envuelto por otro CharacterBody2D (un
		# contenedor vacío creado sin querer al arrastrar nodos en el
		# editor), ese contenedor puede traer su propio CollisionShape2D
		# con un tamaño gigante y quedarse en collision_layer=1 (el valor
		# por defecto de Godot), que es la MISMA capa que las rocas
		# detectan. Esto provoca que el jugador reciba daño sin que la
		# roca toque visualmente su sprite, porque en realidad está
		# chocando contra ese cuerpo fantasma inmóvil y sobredimensionado.
		_neutralize_ghost_bodies(player)
	else:
		push_warning("No se encontró Player. Pon tu personaje manualmente como CharacterBody2D y nómbralo Player.")

	phone_cabin = _find_area_node(["PhoneCabin", "Telefono", "Teléfono", "Phone", "Movil", "Móvil", "MobilePhone"])
	safe_cabin = _find_area_node(["SafeCabin", "CabinaSegura", "Refugio", "SafeZone", "Safe"])

	if phone_cabin == null:
		push_warning("No se encontró PhoneCabin. El juego sigue, pero no podrás abrir el teléfono.")

	if safe_cabin == null:
		push_warning("No se encontró SafeCabin. El juego sigue, pero no podrás ganar por cabina segura.")

	rock_spawners = get_node_or_null("RockSpawners") as Node2D

	if rock_spawners == null:
		rock_spawners = Node2D.new()
		rock_spawners.name = "RockSpawners"
		add_child(rock_spawners)

	if rock_spawners.get_child_count() == 0:
		for i in range(6):
			var marker := Marker2D.new()
			marker.name = "Marker2D" + str(i + 1)
			marker.position = Vector2(180 + (i * 190), -80)
			rock_spawners.add_child(marker)


func _find_player_controller() -> CharacterBody2D:
	# Recorre TODOS los CharacterBody2D del árbol (sin importar su nombre
	# o nivel de anidación) y devuelve el que realmente tiene el script
	# del jugador (receive_damage + señal damaged).
	var candidates := find_children("*", "CharacterBody2D", true, false)

	for candidate in candidates:
		if candidate.has_method("receive_damage") and candidate.has_signal("damaged"):
			return candidate as CharacterBody2D

	return null


func _find_first_character_body() -> CharacterBody2D:
	var children := find_children("*", "CharacterBody2D", true, false)

	if children.size() > 0:
		return children[0] as CharacterBody2D

	return null


# Busca cualquier otro PhysicsBody2D (CharacterBody2D, StaticBody2D, etc.)
# que sea ANCESTRO o HERMANO cercano del jugador real y que NO sea el
# propio jugador. Si encuentra colisiones físicas activas ahí (capa 1,
# la que detectan las rocas), las apaga para que dejen de "robar" golpes.
# No borra nodos (por si el usuario los necesita para otra cosa), solo
# desactiva su participación en colisiones físicas.
func _neutralize_ghost_bodies(real_player: CharacterBody2D) -> void:
	var parent := real_player.get_parent()

	if parent == null:
		return

	# Si el padre directo del jugador es OTRO CharacterBody2D/PhysicsBody2D
	# distinto del jugador (el caso "CharacterBody2D > PlayerLandslide"),
	# es ese envoltorio el que hay que revisar.
	if parent is CollisionObject2D and parent != real_player:
		_disable_ghost_collision(parent as CollisionObject2D, real_player)

	# También revisamos hermanos directos del jugador: si hay un
	# CollisionShape2D "suelto" que no cuelga del jugador sino de su
	# padre (como vimos en la escena: CollisionShape2D como hermano de
	# PlayerLandslide, ambos bajo el mismo CharacterBody2D contenedor),
	# lo desactivamos ahí también.
	for sibling in parent.get_children():
		if sibling == real_player:
			continue
		if sibling is CollisionShape2D:
			push_warning("Se encontró un CollisionShape2D (%s) que NO es hijo del jugador real. Se está desactivando para que no interfiera con el daño de las rocas. Bórralo del editor o muévelo dentro del nodo del jugador para limpiar la escena." % sibling.name)
			(sibling as CollisionShape2D).disabled = true
		elif sibling is CollisionObject2D and sibling != real_player:
			_disable_ghost_collision(sibling as CollisionObject2D, real_player)


func _disable_ghost_collision(body: CollisionObject2D, real_player: CharacterBody2D) -> void:
	if body == real_player:
		return

	# Si por alguna razón este nodo SÍ tiene el script del jugador (poco
	# probable, pero por seguridad), no lo tocamos.
	if body.has_method("receive_damage") and body.has_signal("damaged"):
		return

	push_warning("Se encontró un cuerpo físico fantasma '%s' envolviendo o junto al jugador, con collision_layer=%d. Se está poniendo en capa 0 para que las rocas no lo detecten." % [body.name, body.collision_layer])

	body.collision_layer = 0
	body.collision_mask = 0

	for child in body.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = true


func _find_area_node(names: Array) -> Area2D:
	for node_name in names:
		var direct := get_node_or_null(str(node_name))

		if direct and direct is Area2D:
			return direct

		var found := find_child(str(node_name), true, false)

		if found and found is Area2D:
			return found

	return null


func _setup_collisions() -> void:
	if player:
		_set_character_collision(player, Vector2(46, 155), Vector2(0, 6))

	if phone_cabin:
		_set_area_collision(phone_cabin, Vector2(100, 135), Vector2(0, 8))


func _set_character_collision(node: CharacterBody2D, size: Vector2, offset: Vector2) -> void:
	# IMPORTANTE: antes, si ya existía un CollisionShape2D con una forma
	# asignada (por ejemplo, creada a mano en el editor con un tamaño
	# equivocado), el código la dejaba intacta. Eso era exactamente el
	# bug: una forma vieja/gigante nunca se corregía y el jugador recibía
	# daño sin que la roca tocara su sprite visualmente. Ahora SIEMPRE
	# forzamos el tamaño y posición correctos, sin importar lo que hubiera
	# antes.
	var collision := node.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		node.add_child(collision)

	var shape := collision.shape as RectangleShape2D

	if shape == null:
		shape = RectangleShape2D.new()

	shape.size = size
	collision.shape = shape
	collision.position = offset
	collision.disabled = false

	# También reseteamos cualquier escala/rotación rara que se le haya
	# quedado pegada al nodo de colisión desde el editor, para que el
	# tamaño (46, 82) sea el tamaño real en píxeles y no se infle o
	# encoja por un factor de escala accidental.
	collision.scale = Vector2.ONE
	collision.rotation = 0.0


func _set_area_collision(node: Area2D, size: Vector2, offset: Vector2) -> void:
	var collision := node.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		node.add_child(collision)

	if collision.shape == null:
		var shape := RectangleShape2D.new()
		shape.size = size
		collision.shape = shape

	collision.position = offset
	node.monitoring = true
	node.monitorable = true


func _create_audio() -> void:
	var alarm_stream: AudioStream = _load_audio(["Alarm.mp3", "alarm.mp3"])
	var rocks_stream: AudioStream = _load_audio(["Rocks.mp3", "rocks.mp3"])
	var keyboard_stream: AudioStream = _load_audio(["Keyboard.mp3", "keyboard.mp3"])
	var firetruck_siren_stream: AudioStream = _load_audio(["Firetrucksiren.mp3", "firetrucksiren.mp3", "FireTruckSiren.mp3"])
	var call_911_stream: AudioStream = _load_audio(["911.mp3"])

	if alarm_stream:
		alarm_sound = AudioStreamPlayer.new()
		alarm_sound.name = "AlarmSound"
		alarm_sound.stream = alarm_stream
		alarm_sound.volume_db = GLOBAL_SOUND_VOLUME
		add_child(alarm_sound)
		alarm_sound.finished.connect(_loop_alarm_sound)
	else:
		push_warning("No se encontró Alarm.mp3 en Music.")

	if rocks_stream:
		rocks_sound = AudioStreamPlayer.new()
		rocks_sound.name = "RocksSound"
		rocks_sound.stream = rocks_stream
		rocks_sound.volume_db = GLOBAL_SOUND_VOLUME
		add_child(rocks_sound)
		rocks_sound.finished.connect(_loop_rocks_sound)
	else:
		push_warning("No se encontró Rocks.mp3 en Music.")

	if keyboard_stream:
		keyboard_sound = AudioStreamPlayer.new()
		keyboard_sound.name = "KeyboardSound"
		keyboard_sound.stream = keyboard_stream
		keyboard_sound.volume_db = GLOBAL_SOUND_VOLUME
		add_child(keyboard_sound)
	else:
		push_warning("No se encontró Keyboard.mp3 en Music.")

	if firetruck_siren_stream:
		firetruck_siren_sound = AudioStreamPlayer.new()
		firetruck_siren_sound.name = "FireTruckSirenSound"
		firetruck_siren_sound.stream = firetruck_siren_stream
		firetruck_siren_sound.volume_db = GLOBAL_SOUND_VOLUME
		add_child(firetruck_siren_sound)
		firetruck_siren_sound.finished.connect(_loop_firetruck_siren_sound)
	else:
		push_warning("No se encontró Firetrucksiren.mp3 en Music.")

	if call_911_stream:
		call_911_sound = AudioStreamPlayer.new()
		call_911_sound.name = "Call911Sound"
		call_911_sound.stream = call_911_stream
		call_911_sound.volume_db = GLOBAL_SOUND_VOLUME
		add_child(call_911_sound)
	else:
		push_warning("No se encontró 911.mp3 en Music.")


func _load_audio(file_names: Array) -> AudioStream:
	for file_name in file_names:
		var path := MUSIC_DIR + str(file_name)

		if ResourceLoader.exists(path):
			var audio := load(path)

			if audio is AudioStream:
				return audio

	return null


func _loop_alarm_sound() -> void:
	if alarm_sound and game_active and not already_finished:
		alarm_sound.volume_db = GLOBAL_SOUND_VOLUME
		alarm_sound.play()


func _loop_rocks_sound() -> void:
	if rocks_sound and game_active and not already_finished:
		rocks_sound.volume_db = GLOBAL_SOUND_VOLUME
		rocks_sound.play()


func _loop_firetruck_siren_sound() -> void:
	if firetruck_siren_sound and game_active and not already_finished and rescue_started:
		firetruck_siren_sound.volume_db = GLOBAL_SOUND_VOLUME
		firetruck_siren_sound.play()


func _set_alarm_normal_volume() -> void:
	if alarm_sound:
		alarm_sound.volume_db = GLOBAL_SOUND_VOLUME


func _set_alarm_low_volume() -> void:
	if alarm_sound:
		alarm_sound.volume_db = GLOBAL_SOUND_VOLUME


func _start_alarm_sound() -> void:
	if alarm_sound and game_active and not already_finished:
		alarm_sound.volume_db = GLOBAL_SOUND_VOLUME
		if not alarm_sound.playing:
			alarm_sound.play()


func _start_rocks_sound() -> void:
	if rocks_sound and game_active and not already_finished:
		rocks_sound.volume_db = GLOBAL_SOUND_VOLUME
		if not rocks_sound.playing:
			rocks_sound.play()


func _play_keyboard_sound() -> void:
	if keyboard_sound:
		keyboard_sound.volume_db = GLOBAL_SOUND_VOLUME
		keyboard_sound.stop()
		keyboard_sound.play()


func _stop_keyboard_sound() -> void:
	if keyboard_sound:
		keyboard_sound.stop()


func _play_911_sound() -> void:
	if call_911_sound:
		call_911_sound.volume_db = GLOBAL_SOUND_VOLUME
		call_911_sound.stop()
		call_911_sound.play()


func _play_firetruck_siren_sound() -> void:
	if firetruck_siren_sound:
		firetruck_siren_sound.volume_db = GLOBAL_SOUND_VOLUME
		firetruck_siren_sound.stop()
		firetruck_siren_sound.play()


func _stop_firetruck_siren_sound() -> void:
	if firetruck_siren_sound:
		firetruck_siren_sound.stop()


func _stop_audio() -> void:
	if alarm_sound:
		alarm_sound.stop()

	if rocks_sound:
		rocks_sound.stop()

	_stop_keyboard_sound()
	_stop_firetruck_siren_sound()

	if call_911_sound:
		call_911_sound.stop()


func _create_ui() -> void:
	ui_layer = get_node_or_null("CanvasLayer") as CanvasLayer

	if ui_layer == null:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "CanvasLayer"
		add_child(ui_layer)

	ui_layer.layer = 40

	hud = ui_layer.get_node_or_null("HUD") as Control

	if hud == null:
		hud = Control.new()
		hud.name = "HUD"
		ui_layer.add_child(hud)

	mission_label = hud.get_node_or_null("MissionLabel") as Label

	if mission_label == null:
		mission_label = Label.new()
		mission_label.name = "MissionLabel"
		hud.add_child(mission_label)

	prompt_label = hud.get_node_or_null("PromptLabel") as Label

	if prompt_label == null:
		prompt_label = Label.new()
		prompt_label.name = "PromptLabel"
		hud.add_child(prompt_label)

	hud.position = Vector2.ZERO
	hud.size = Vector2(1280, 720)

	mission_label.position = Vector2(25, 90)
	mission_label.size = Vector2(760, 30)
	mission_label.add_theme_font_size_override("font_size", 21)
	mission_label.add_theme_color_override("font_color", Color.WHITE)
	mission_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	mission_label.add_theme_constant_override("shadow_offset_x", 3)
	mission_label.add_theme_constant_override("shadow_offset_y", 3)

	prompt_label.position = Vector2(25, 125)
	prompt_label.size = Vector2(780, 70)
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 3)
	prompt_label.add_theme_constant_override("shadow_offset_y", 3)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _create_timer() -> void:
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)

	if timer_hud is CanvasLayer:
		timer_hud.layer = 50

	if timer_hud.has_signal("time_up"):
		timer_hud.time_up.connect(_on_time_up)

	if timer_hud.has_method("set_tamano_panel"):
		timer_hud.set_tamano_panel(500, 60)


func _create_result_panel() -> void:
	game_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(game_result_panel)

	if game_result_panel is CanvasLayer:
		game_result_panel.layer = 60

	game_result_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_game_result_sound_volume()


func _set_game_result_sound_volume() -> void:
	if game_result_panel == null:
		return

	var result_sounds := [
		"WinSound",
		"win_sound",
		"AudioWin",
		"WinAudio",
		"LoseSound",
		"lose_sound",
		"AudioLose",
		"LoseAudio"
	]

	for sound_name in result_sounds:
		var sound = game_result_panel.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


func _create_lives_ui() -> void:
	lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(lives_ui)

	if lives_ui is CanvasLayer:
		lives_ui.layer = 55

	if lives_ui is Control:
		lives_ui.position = Vector2(980, 25)

	update_lives_ui()


# =========================================================
# DAMAGE EFFECT
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
	
	var original_position: Vector2 = position
	
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
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)


func _create_phone_keypad() -> void:
	phone_overlay = ColorRect.new()
	phone_overlay.name = "PhoneKeypadOverlay"
	phone_overlay.color = Color(0, 0, 0, 0.55)
	phone_overlay.visible = false
	phone_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay_size := get_viewport_rect().size

	if overlay_size.x <= 0 or overlay_size.y <= 0:
		overlay_size = Vector2(1280, 720)

	phone_overlay.position = Vector2.ZERO
	phone_overlay.size = overlay_size
	ui_layer.add_child(phone_overlay)

	# --- Cuerpo del teléfono (estilo baquelita retro) ---
	var phone_panel := Panel.new()
	phone_panel.name = "PhoneKeypadPanel"
	phone_panel.size = Vector2(420, 640)
	phone_panel.position = (overlay_size - phone_panel.size) / 2.0
	phone_overlay.add_child(phone_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#7A1E1E")
	panel_style.border_color = Color("#4A1010")
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.corner_radius_top_left = 26
	panel_style.corner_radius_top_right = 26
	panel_style.corner_radius_bottom_left = 46
	panel_style.corner_radius_bottom_right = 46
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 8)
	phone_panel.add_theme_stylebox_override("panel", panel_style)

	# --- Auricular (bocina) apoyado arriba del cuerpo, como los
	# teléfonos de disco clásicos ---
	var handset := Panel.new()
	handset.size = Vector2(310, 66)
	handset.position = Vector2((phone_panel.size.x - handset.size.x) / 2.0, -34)

	var handset_style := StyleBoxFlat.new()
	handset_style.bg_color = Color("#2B2B2B")
	handset_style.border_color = Color("#141414")
	handset_style.border_width_left = 3
	handset_style.border_width_right = 3
	handset_style.border_width_top = 3
	handset_style.border_width_bottom = 3
	handset_style.corner_radius_top_left = 33
	handset_style.corner_radius_top_right = 33
	handset_style.corner_radius_bottom_left = 33
	handset_style.corner_radius_bottom_right = 33
	handset_style.shadow_color = Color(0, 0, 0, 0.35)
	handset_style.shadow_size = 8
	handset_style.shadow_offset = Vector2(0, 4)
	handset.add_theme_stylebox_override("panel", handset_style)
	phone_panel.add_child(handset)

	# Auriculares (los dos extremos redondos del auricular)
	for ear_x in [8.0, handset.size.x - 62.0]:
		var earpiece := Panel.new()
		earpiece.size = Vector2(54, 54)
		earpiece.position = Vector2(ear_x, 6)

		var earpiece_style := StyleBoxFlat.new()
		earpiece_style.bg_color = Color("#1A1A1A")
		earpiece_style.border_color = Color("#000000")
		earpiece_style.border_width_left = 2
		earpiece_style.border_width_right = 2
		earpiece_style.border_width_top = 2
		earpiece_style.border_width_bottom = 2
		earpiece_style.corner_radius_top_left = 27
		earpiece_style.corner_radius_top_right = 27
		earpiece_style.corner_radius_bottom_left = 27
		earpiece_style.corner_radius_bottom_right = 27
		earpiece.add_theme_stylebox_override("panel", earpiece_style)
		handset.add_child(earpiece)

	# --- Título ---
	var title := Label.new()
	title.text = "Marca el 911"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 44)
	title.size = Vector2(380, 40)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#F3E7C9"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	phone_panel.add_child(title)

	# --- Tarjetita de número marcado (como las etiquetas de cartón de
	# las cabinas viejas, no una pantalla digital) ---
	var display_card := Panel.new()
	display_card.size = Vector2(180, 56)
	display_card.position = Vector2((phone_panel.size.x - display_card.size.x) / 2.0, 92)

	var display_style := StyleBoxFlat.new()
	display_style.bg_color = Color("#F3E7C9")
	display_style.border_color = Color("#8A6B3D")
	display_style.border_width_left = 3
	display_style.border_width_right = 3
	display_style.border_width_top = 3
	display_style.border_width_bottom = 3
	display_style.corner_radius_top_left = 6
	display_style.corner_radius_top_right = 6
	display_style.corner_radius_bottom_left = 6
	display_style.corner_radius_bottom_right = 6
	display_card.add_theme_stylebox_override("panel", display_style)
	phone_panel.add_child(display_card)

	dial_display = Label.new()
	dial_display.text = "— — —"
	dial_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dial_display.position = Vector2.ZERO
	dial_display.size = display_card.size
	dial_display.add_theme_font_size_override("font_size", 26)
	dial_display.add_theme_color_override("font_color", Color("#3A2A12"))
	display_card.add_child(dial_display)

	# --- Disco giratorio ---
	var dial_center := Vector2(phone_panel.size.x / 2.0, 340.0)
	var dial_outer_radius := 155.0
	var hole_orbit_radius := 108.0
	var hole_size := 56.0

	# Aro metálico exterior del disco
	var dial_rim := Panel.new()
	dial_rim.size = Vector2(dial_outer_radius * 2.0, dial_outer_radius * 2.0)
	dial_rim.position = dial_center - dial_rim.size / 2.0

	var dial_rim_style := StyleBoxFlat.new()
	dial_rim_style.bg_color = Color("#4A1010")
	dial_rim_style.border_color = Color("#2E0808")
	dial_rim_style.border_width_left = 4
	dial_rim_style.border_width_right = 4
	dial_rim_style.border_width_top = 4
	dial_rim_style.border_width_bottom = 4
	dial_rim_style.corner_radius_top_left = int(dial_outer_radius)
	dial_rim_style.corner_radius_top_right = int(dial_outer_radius)
	dial_rim_style.corner_radius_bottom_left = int(dial_outer_radius)
	dial_rim_style.corner_radius_bottom_right = int(dial_outer_radius)
	dial_rim_style.shadow_color = Color(0, 0, 0, 0.3)
	dial_rim_style.shadow_size = 6
	dial_rim.add_theme_stylebox_override("panel", dial_rim_style)
	phone_panel.add_child(dial_rim)

	# Disco blanco/marfil (el plato giratorio en sí)
	var dial_face_radius := dial_outer_radius - 14.0
	var dial_face := Panel.new()
	dial_face.size = Vector2(dial_face_radius * 2.0, dial_face_radius * 2.0)
	dial_face.position = dial_center - dial_face.size / 2.0

	var dial_face_style := StyleBoxFlat.new()
	dial_face_style.bg_color = Color("#F3E7C9")
	dial_face_style.border_color = Color("#C9B27C")
	dial_face_style.border_width_left = 3
	dial_face_style.border_width_right = 3
	dial_face_style.border_width_top = 3
	dial_face_style.border_width_bottom = 3
	dial_face_style.corner_radius_top_left = int(dial_face_radius)
	dial_face_style.corner_radius_top_right = int(dial_face_radius)
	dial_face_style.corner_radius_bottom_left = int(dial_face_radius)
	dial_face_style.corner_radius_bottom_right = int(dial_face_radius)
	dial_face.add_theme_stylebox_override("panel", dial_face_style)
	phone_panel.add_child(dial_face)

	# Centro metálico
	var dial_hub := Panel.new()
	dial_hub.size = Vector2(34, 34)
	dial_hub.position = dial_center - dial_hub.size / 2.0

	var dial_hub_style := StyleBoxFlat.new()
	dial_hub_style.bg_color = Color("#8A8A8A")
	dial_hub_style.border_color = Color("#5A5A5A")
	dial_hub_style.border_width_left = 2
	dial_hub_style.border_width_right = 2
	dial_hub_style.border_width_top = 2
	dial_hub_style.border_width_bottom = 2
	dial_hub_style.corner_radius_top_left = 17
	dial_hub_style.corner_radius_top_right = 17
	dial_hub_style.corner_radius_bottom_left = 17
	dial_hub_style.corner_radius_bottom_right = 17
	dial_hub.add_theme_stylebox_override("panel", dial_hub_style)
	phone_panel.add_child(dial_hub)

	# Los 10 "huequitos" numerados alrededor del disco, en el orden
	# clásico de un teléfono de disco: 1 arriba, y el resto en sentido
	# horario terminando en 0.
	var digits := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

	for i in range(digits.size()):
		var digit: String = digits[i]
		var angle := deg_to_rad(-90.0 + float(i) * 36.0)
		var hole_center := dial_center + Vector2(cos(angle), sin(angle)) * hole_orbit_radius

		var hole_button := Button.new()
		hole_button.text = digit
		hole_button.size = Vector2(hole_size, hole_size)
		hole_button.position = hole_center - hole_button.size / 2.0
		hole_button.add_theme_font_size_override("font_size", 22)
		hole_button.add_theme_stylebox_override("normal", _create_dial_hole_style(Color("#2B2B2B"), Color("#111111")))
		hole_button.add_theme_stylebox_override("hover", _create_dial_hole_style(Color("#3A3A3A"), Color("#111111")))
		hole_button.add_theme_stylebox_override("pressed", _create_dial_hole_style(Color("#1A1A1A"), Color("#000000")))
		hole_button.add_theme_color_override("font_color", Color("#F3E7C9"))
		hole_button.pressed.connect(_on_keypad_number_pressed.bind(digit))
		phone_panel.add_child(hole_button)

	# --- Tope del disco (el pequeño "gancho" fijo donde se detiene el
	# dedo al marcar). Puramente decorativo. ---
	var finger_stop := Panel.new()
	finger_stop.size = Vector2(20, 46)
	var stop_angle := deg_to_rad(-90.0 + 9.0 * 36.0 + 20.0)
	var stop_center := dial_center + Vector2(cos(stop_angle), sin(stop_angle)) * (dial_face_radius - 10.0)
	finger_stop.position = stop_center - finger_stop.size / 2.0
	finger_stop.rotation = stop_angle + PI / 2.0

	var finger_stop_style := StyleBoxFlat.new()
	finger_stop_style.bg_color = Color("#8A8A8A")
	finger_stop_style.border_color = Color("#5A5A5A")
	finger_stop_style.border_width_left = 2
	finger_stop_style.border_width_right = 2
	finger_stop_style.border_width_top = 2
	finger_stop_style.border_width_bottom = 2
	finger_stop_style.corner_radius_top_left = 6
	finger_stop_style.corner_radius_top_right = 6
	finger_stop_style.corner_radius_bottom_left = 6
	finger_stop_style.corner_radius_bottom_right = 6
	finger_stop.add_theme_stylebox_override("panel", finger_stop_style)
	phone_panel.add_child(finger_stop)

	# --- Botones pequeños de abajo: corregir y colgar ---
	var correct_button := Button.new()
	correct_button.text = "⌫ Corregir"
	correct_button.position = Vector2(30, phone_panel.size.y - 74)
	correct_button.size = Vector2(160, 46)
	correct_button.add_theme_font_size_override("font_size", 16)
	correct_button.add_theme_stylebox_override("normal", _create_key_button_style(Color("#5A2323"), Color("#3A1414")))
	correct_button.add_theme_stylebox_override("hover", _create_key_button_style(Color("#6E2C2C"), Color("#3A1414")))
	correct_button.add_theme_stylebox_override("pressed", _create_key_button_style(Color("#421A1A"), Color("#2A0E0E")))
	correct_button.add_theme_color_override("font_color", Color("#F3E7C9"))
	correct_button.pressed.connect(_backspace_digit)
	phone_panel.add_child(correct_button)

	var cancel_button := Button.new()
	cancel_button.text = "Colgar"
	cancel_button.position = Vector2(phone_panel.size.x - 190, phone_panel.size.y - 74)
	cancel_button.size = Vector2(160, 46)
	cancel_button.add_theme_font_size_override("font_size", 16)
	cancel_button.add_theme_stylebox_override("normal", _create_key_button_style(Color("#2B2B2B"), Color("#111111")))
	cancel_button.add_theme_stylebox_override("hover", _create_key_button_style(Color("#3A3A3A"), Color("#111111")))
	cancel_button.add_theme_stylebox_override("pressed", _create_key_button_style(Color("#1A1A1A"), Color("#000000")))
	cancel_button.add_theme_color_override("font_color", Color("#F3E7C9"))
	cancel_button.pressed.connect(_close_phone_keypad)
	phone_panel.add_child(cancel_button)


func _create_key_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 23
	style.corner_radius_top_right = 23
	style.corner_radius_bottom_left = 23
	style.corner_radius_bottom_right = 23
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


# Estilo circular para los "huequitos" numerados del disco giratorio.
func _create_dial_hole_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style


func _connect_signals() -> void:
	if player and player.has_signal("damaged"):
		if not player.damaged.is_connected(_on_player_damaged):
			player.damaged.connect(_on_player_damaged)

	if phone_cabin:
		if not phone_cabin.body_entered.is_connected(_on_phone_entered):
			phone_cabin.body_entered.connect(_on_phone_entered)

		if not phone_cabin.body_exited.is_connected(_on_phone_exited):
			phone_cabin.body_exited.connect(_on_phone_exited)


func start_game() -> void:
	game_active = true
	already_finished = false
	rescue_started = false

	lives = max_lives
	has_called_911 = false
	player_in_phone_zone = false
	spawn_counter = 0.0
	current_spawn_interval = spawn_interval
	keypad_open = false
	dialed_number = ""

	if rescue_truck and is_instance_valid(rescue_truck):
		rescue_truck.queue_free()
		rescue_truck = null

	if player:
		player.visible = true
		player.set_physics_process(true)

	_set_alarm_normal_volume()
	_start_alarm_sound()
	_start_rocks_sound()

	update_lives_ui()
	_update_hud()
	_show_prompt("Busca el teléfono y llama al 911.")

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 45.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 45.0

	if timer_hud.has_method("iniciar"):
		timer_hud.iniciar(TOTAL_TIME, "Tiempo", "para evacuar")
	elif timer_hud.has_method("start_timer"):
		timer_hud.start_timer(TOTAL_TIME)
	elif timer_hud.has_method("start"):
		timer_hud.start(TOTAL_TIME)


func _handle_rock_spawn(delta: float) -> void:
	spawn_counter += delta

	if spawn_counter >= current_spawn_interval:
		spawn_counter = 0.0
		_spawn_rock()


func _spawn_rock() -> void:
	if not game_active or already_finished:
		return

	if rescue_started:
		return

	if rock_scene == null:
		return

	if rock_spawners == null:
		return

	var spawners := rock_spawners.get_children()

	if spawners.is_empty():
		return

	var marker := spawners.pick_random() as Marker2D

	if marker == null:
		return

	var rock := rock_scene.instantiate()

	add_child(rock)

	rock.add_to_group("falling_rocks")
	rock.set_meta("hit_player", false)

	rock.z_index = 70

	var screen_size := get_viewport_rect().size

	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2(1280, 720)

	var start_position := marker.global_position

	var end_position := Vector2(
		randf_range(80.0, screen_size.x - 80.0),
		screen_size.y + 120.0
	)

	# --- Variedad de tamaño y velocidad ---
	# size_multiplier: 0.7 = roca chica, 1.5 = roca grande.
	# La velocidad se correlaciona de forma inversa con el tamaño (las
	# rocas chicas caen más rápido y son más difíciles de ver venir; las
	# grandes caen más lento pero ocupan más espacio y son más difíciles
	# de esquivar por su tamaño). Encima le sumamos un rango aleatorio
	# independiente para que no sea 100% predecible.
	var size_multiplier := randf_range(0.7, 1.5)

	var base_speed := randf_range(160.0, 250.0)
	var speed_from_size := remap(size_multiplier, 0.7, 1.5, 1.35, 0.8)
	var rock_speed := base_speed * speed_from_size

	# De vez en cuando (1 de cada 6), generamos una roca "sorpresa": chica
	# Y rápida a la vez, rompiendo la correlación normal para que el
	# jugador no pueda memorizar el patrón "grande = lenta, chica = rápida".
	if randf() < 0.16:
		size_multiplier = randf_range(0.65, 0.85)
		rock_speed = randf_range(300.0, 360.0)

	if rock.has_method("setup"):
		rock.setup(start_position, end_position, rock_speed, size_multiplier)
	else:
		rock.global_position = start_position


func _clear_rocks() -> void:
	for rock in get_tree().get_nodes_in_group("falling_rocks"):
		if is_instance_valid(rock):
			rock.queue_free()


func _register_rock_hit(rock: Node, body: Node) -> void:
	if not game_active or already_finished:
		return

	if player_in_phone_zone or keypad_open or rescue_started:
		return

	# Resolvemos el nodo que realmente debe recibir el daño. Si "body"
	# (el que chocó físicamente) no tiene receive_damage, probamos con
	# la referencia "player" que guardó el manager. Esto cubre el caso
	# de jerarquías donde el CollisionShape2D está en un nodo distinto
	# al que tiene el script.
	var target: Node = null

	if body and body.has_method("receive_damage"):
		target = body
	elif player and player.has_method("receive_damage"):
		target = player

	if target == null:
		push_warning("No se encontró un nodo con receive_damage() para aplicar el daño.")
		return

	var rock_node := rock as Node2D
	var source_position: Vector2 = target.global_position

	if rock_node:
		source_position = rock_node.global_position

	target.receive_damage(source_position)


func _check_safe_win() -> void:
	if rescue_started:
		return

	if not game_active or already_finished:
		return

	if not has_called_911:
		return

	if player == null or safe_cabin == null:
		return

	var distance: float = player.global_position.distance_to(safe_cabin.global_position)

	if distance <= safe_win_distance:
		win_game()


func _open_phone_keypad() -> void:
	if has_called_911:
		return

	keypad_open = true
	dialed_number = ""
	_update_dial_display()

	_set_alarm_low_volume()

	if alarm_sound and not alarm_sound.playing:
		alarm_sound.play()

	_start_rocks_sound()

	if phone_overlay:
		phone_overlay.visible = true

	if player:
		player.set_physics_process(false)

	_show_prompt("Gira el disco para marcar el 911.")


func _close_phone_keypad() -> void:
	_stop_keyboard_sound()

	keypad_open = false
	dialed_number = ""

	if phone_overlay:
		phone_overlay.visible = false

	if player and not already_finished:
		player.set_physics_process(true)

	_set_alarm_normal_volume()
	_start_alarm_sound()
	_start_rocks_sound()

	if not has_called_911:
		_show_prompt("Colgaste. Acércate de nuevo a la cabina para reintentar.")


func _on_keypad_number_pressed(number: String) -> void:
	_add_digit(number)


func _add_digit(number: String) -> void:
	if dialed_number.length() >= 3:
		return

	_play_keyboard_sound()

	dialed_number += number
	_update_dial_display()

	if dialed_number.length() >= 3:
		_stop_keyboard_sound()
		# El disco "termina de girar" solo, como en un teléfono real:
		# apenas se completan los 3 dígitos, se intenta la llamada
		# automáticamente, sin necesidad de un botón de LLAMAR.
		await get_tree().create_timer(0.4).timeout
		_try_call_number()


func _backspace_digit() -> void:
	if dialed_number.length() > 0:
		_play_keyboard_sound()
		dialed_number = dialed_number.substr(0, dialed_number.length() - 1)

	_update_dial_display()


func _update_dial_display() -> void:
	if dial_display:
		if dialed_number == "":
			dial_display.text = "— — —"
		else:
			var spaced := ""
			for i in range(dialed_number.length()):
				if i > 0:
					spaced += " "
				spaced += dialed_number[i]
			dial_display.text = spaced


func _try_call_number() -> void:
	_stop_keyboard_sound()

	if dialed_number == "911":
		has_called_911 = true
		player_in_phone_zone = false
		current_spawn_interval = spawn_interval_fast
		keypad_open = false

		if phone_overlay:
			phone_overlay.visible = false

		_play_911_sound()

		_set_alarm_normal_volume()
		_start_alarm_sound()
		_start_rocks_sound()

		_update_hud()
		_show_prompt("Llamaste al 911. Los bomberos vienen en camino.")

		_start_rescue_sequence()
	else:
		dialed_number = ""
		_update_dial_display()
		_show_prompt("Número incorrecto. Marca 911.")


func _start_rescue_sequence() -> void:
	if rescue_started:
		return

	if player == null or safe_cabin == null:
		return

	rescue_started = true
	_clear_rocks()

	if player:
		player.set_physics_process(false)

	rescue_truck = Sprite2D.new()
	rescue_truck.name = "FireTruck"
	rescue_truck.z_index = 90
	rescue_truck.scale = rescue_truck_scale

	var truck_texture := load(FIRE_TRUCK_PATH)

	if truck_texture is Texture2D:
		rescue_truck.texture = truck_texture
	else:
		push_warning("No se encontró fire_truck.png en assets.")
		rescue_truck = null
		win_game()
		return

	add_child(rescue_truck)

	var start_position := Vector2(-220, player.global_position.y)
	var pickup_position := Vector2(player.global_position.x - 90, player.global_position.y)
	var safe_position := Vector2(safe_cabin.global_position.x, safe_cabin.global_position.y)

	rescue_truck.global_position = start_position

	_show_prompt("Ya casi viene la ayuda...")
	_play_firetruck_siren_sound()

	rescue_truck.flip_h = false

	var tween := create_tween()

	tween.tween_property(
		rescue_truck,
		"global_position",
		pickup_position,
		rescue_truck_speed_to_player
	)

	tween.tween_callback(func():
		_show_prompt("Los bomberos llegaron por ti.")

		if player:
			player.visible = false

		if safe_position.x < rescue_truck.global_position.x:
			rescue_truck.flip_h = true
		else:
			rescue_truck.flip_h = false
	)

	tween.tween_interval(0.4)

	tween.tween_property(
		rescue_truck,
		"global_position",
		safe_position,
		rescue_truck_speed_to_safe
	)

	tween.tween_callback(func():
		_stop_firetruck_siren_sound()
		win_game()
	)


func _on_player_damaged() -> void:
	if not game_active or already_finished:
		return

	if player_in_phone_zone or keypad_open or rescue_started:
		return

	lives -= 1

	if lives < 0:
		lives = 0

	update_lives_ui()
	_play_damage_effect()

	if lives <= 0:
		lose_game()
		return

	current_spawn_interval = spawn_interval_fast
	_show_prompt("¡Cuidado! Una roca te cayó encima. Perdiste una vida.")


func _on_phone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_phone_zone = true

	if not has_called_911 and not keypad_open:
		_open_phone_keypad()


func _on_phone_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_phone_zone = false

	if not has_called_911 and not keypad_open:
		_show_prompt("Debes llamar al 911 antes de ir a la cabina segura.")


func _on_time_up() -> void:
	if game_active and not already_finished:
		_play_damage_effect()
		lose_game()


func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false
	_stop_audio()

	if player:
		player.set_physics_process(false)

	if timer_hud != null:
		if timer_hud.has_method("detener"):
			timer_hud.detener()
		elif timer_hud.has_method("stop_timer"):
			timer_hud.stop_timer()

	_set_game_result_sound_volume()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_ganaste"):
			game_result_panel.mostrar_ganaste()
		elif game_result_panel.has_method("show_win"):
			game_result_panel.show_win()


func lose_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false
	_stop_audio()

	if player:
		player.set_physics_process(false)

	if timer_hud != null:
		if timer_hud.has_method("detener"):
			timer_hud.detener()
		elif timer_hud.has_method("stop_timer"):
			timer_hud.stop_timer()

	_set_game_result_sound_volume()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_perdiste"):
			game_result_panel.mostrar_perdiste()
		elif game_result_panel.has_method("show_lose"):
			game_result_panel.show_lose()


func update_lives_ui() -> void:
	if lives_ui == null:
		return

	if _call_lives_method("set_lives"):
		return

	if _call_lives_method("update_lives"):
		return

	if _call_lives_method("set_current_lives"):
		return

	if _call_lives_method("set_health"):
		return

	if _call_lives_method("actualizar_vidas"):
		return

	if _call_lives_method("actualizar"):
		return

	var label := lives_ui.find_child("LivesLabel", true, false)

	if label and label is Label:
		label.text = "Vidas: " + str(lives)


func _call_lives_method(method_name: String) -> bool:
	if lives_ui == null:
		return false

	for method in lives_ui.get_method_list():
		if str(method.get("name", "")) == method_name:
			var args: Array = method.get("args", [])
			var count := args.size()

			if count >= 2:
				lives_ui.call(method_name, lives, max_lives)
			elif count == 1:
				lives_ui.call(method_name, lives)
			else:
				lives_ui.call(method_name)

			return true

	return false


func _update_hud() -> void:
	if has_called_911:
		mission_label.text = "Misión: espera a los bomberos"
	else:
		mission_label.text = "Misión: llama al 911"


func _show_prompt(message: String) -> void:
	if prompt_label:
		prompt_label.text = message

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
