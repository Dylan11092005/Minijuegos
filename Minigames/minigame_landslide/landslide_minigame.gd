extends Node2D

@export var time_limit := 45.0
@export var max_lives := 3

@export var rock_scene: PackedScene = preload("res://Minigames/minigame_landslide/FallingRock.tscn")

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

const MUSIC_DIR := "res://Minigames/minigame_landslide/Music/"
const FIRE_TRUCK_PATH := "res://Minigames/minigame_landslide/assets/fire_truck.png"

@export var spawn_interval := 1.05
@export var spawn_interval_fast := 0.72

@export var rock_hit_x_distance := 28.0
@export var rock_hit_y_min := -75.0
@export var rock_hit_y_max := 15.0

@export var safe_win_distance := 35.0

@export var rescue_truck_scale := Vector2(0.35, 0.35)
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
var e_key_was_pressed := false

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
	_check_rock_hits()
	_check_interaction()
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
	player = get_node_or_null("Player") as CharacterBody2D

	if player == null:
		player = _find_first_character_body()

	if player:
		player.set_physics_process(true)
		player.add_to_group("player")
		player.collision_layer = 1
		player.collision_mask = 2
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


func _find_first_character_body() -> CharacterBody2D:
	var children := find_children("*", "CharacterBody2D", true, false)

	if children.size() > 0:
		return children[0] as CharacterBody2D

	return null


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
		_set_character_collision(player, Vector2(46, 82), Vector2(0, 18))

	if phone_cabin:
		_set_area_collision(phone_cabin, Vector2(100, 135), Vector2(0, 8))


func _set_character_collision(node: CharacterBody2D, size: Vector2, offset: Vector2) -> void:
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
		alarm_sound.volume_db = -2
		add_child(alarm_sound)
		alarm_sound.finished.connect(_loop_alarm_sound)
	else:
		push_warning("No se encontró Alarm.mp3 en Music.")

	if rocks_stream:
		rocks_sound = AudioStreamPlayer.new()
		rocks_sound.name = "RocksSound"
		rocks_sound.stream = rocks_stream
		rocks_sound.volume_db = -10
		add_child(rocks_sound)
		rocks_sound.finished.connect(_loop_rocks_sound)
	else:
		push_warning("No se encontró Rocks.mp3 en Music.")

	if keyboard_stream:
		keyboard_sound = AudioStreamPlayer.new()
		keyboard_sound.name = "KeyboardSound"
		keyboard_sound.stream = keyboard_stream
		keyboard_sound.volume_db = 0
		add_child(keyboard_sound)
	else:
		push_warning("No se encontró Keyboard.mp3 en Music.")

	if firetruck_siren_stream:
		firetruck_siren_sound = AudioStreamPlayer.new()
		firetruck_siren_sound.name = "FireTruckSirenSound"
		firetruck_siren_sound.stream = firetruck_siren_stream
		firetruck_siren_sound.volume_db = -1
		add_child(firetruck_siren_sound)
		firetruck_siren_sound.finished.connect(_loop_firetruck_siren_sound)
	else:
		push_warning("No se encontró Firetrucksiren.mp3 en Music.")

	if call_911_stream:
		call_911_sound = AudioStreamPlayer.new()
		call_911_sound.name = "Call911Sound"
		call_911_sound.stream = call_911_stream
		call_911_sound.volume_db = 0
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
		alarm_sound.play()


func _loop_rocks_sound() -> void:
	if rocks_sound and game_active and not already_finished:
		rocks_sound.play()


func _loop_firetruck_siren_sound() -> void:
	if firetruck_siren_sound and game_active and not already_finished and rescue_started:
		firetruck_siren_sound.play()


func _set_alarm_normal_volume() -> void:
	if alarm_sound:
		alarm_sound.volume_db = -2


func _set_alarm_low_volume() -> void:
	if alarm_sound:
		alarm_sound.volume_db = -18


func _start_alarm_sound() -> void:
	if alarm_sound and game_active and not already_finished:
		if not alarm_sound.playing:
			alarm_sound.play()


func _start_rocks_sound() -> void:
	if rocks_sound and game_active and not already_finished:
		if not rocks_sound.playing:
			rocks_sound.play()


func _play_keyboard_sound() -> void:
	if keyboard_sound:
		keyboard_sound.stop()
		keyboard_sound.play()


func _stop_keyboard_sound() -> void:
	if keyboard_sound:
		keyboard_sound.stop()


func _play_911_sound() -> void:
	if call_911_sound:
		call_911_sound.stop()
		call_911_sound.play()


func _play_firetruck_siren_sound() -> void:
	if firetruck_siren_sound:
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


func _create_lives_ui() -> void:
	lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(lives_ui)

	if lives_ui is CanvasLayer:
		lives_ui.layer = 55

	if lives_ui is Control:
		lives_ui.position = Vector2(980, 25)

	update_lives_ui()


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

	var panel := Panel.new()
	panel.name = "PhonePanel"
	panel.size = Vector2(380, 510)
	panel.position = (overlay_size - panel.size) / 2.0
	phone_overlay.add_child(panel)

	var title := Label.new()
	title.text = "Llamar al 911"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 18)
	title.size = Vector2(340, 35)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)

	dial_display = Label.new()
	dial_display.text = "___"
	dial_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dial_display.position = Vector2(35, 68)
	dial_display.size = Vector2(310, 55)
	dial_display.add_theme_font_size_override("font_size", 34)
	panel.add_child(dial_display)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(52, 140)
	grid.size = Vector2(276, 245)
	panel.add_child(grid)

	for number in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "BORRAR", "0", "LLAMAR"]:
		var button := Button.new()
		button.text = number
		button.custom_minimum_size = Vector2(88, 58)
		button.add_theme_font_size_override("font_size", 18)
		grid.add_child(button)

		if number == "BORRAR":
			button.pressed.connect(_backspace_digit)
		elif number == "LLAMAR":
			button.pressed.connect(_try_call_number)
		else:
			button.pressed.connect(_on_keypad_number_pressed.bind(number))

	var cancel_button := Button.new()
	cancel_button.text = "CERRAR"
	cancel_button.position = Vector2(100, 425)
	cancel_button.size = Vector2(180, 45)
	cancel_button.add_theme_font_size_override("font_size", 18)
	cancel_button.pressed.connect(_close_phone_keypad)
	panel.add_child(cancel_button)


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
	e_key_was_pressed = false
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

	if timer_hud.has_method("iniciar"):
		timer_hud.iniciar(time_limit, "Tiempo", "para evacuar")
	elif timer_hud.has_method("start_timer"):
		timer_hud.start_timer(time_limit)
	elif timer_hud.has_method("start"):
		timer_hud.start(time_limit)


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

	var rock_speed := randf_range(180.0, 260.0)

	if rock.has_method("setup"):
		rock.setup(start_position, end_position, rock_speed)
	else:
		rock.global_position = start_position


func _clear_rocks() -> void:
	for rock in get_tree().get_nodes_in_group("falling_rocks"):
		if is_instance_valid(rock):
			rock.queue_free()


func _check_rock_hits() -> void:
	if player == null:
		return

	if player_in_phone_zone or keypad_open or rescue_started:
		return

	for rock in get_tree().get_nodes_in_group("falling_rocks"):
		if not is_instance_valid(rock):
			continue

		if rock.get_meta("hit_player", false):
			continue

		var rock_node: Node2D = rock as Node2D

		if rock_node == null:
			continue

		var x_distance: float = abs(rock_node.global_position.x - player.global_position.x)
		var y_difference: float = rock_node.global_position.y - player.global_position.y

		if x_distance <= rock_hit_x_distance and y_difference >= rock_hit_y_min and y_difference <= rock_hit_y_max:
			rock.set_meta("hit_player", true)

			if player.has_method("receive_damage"):
				player.receive_damage(rock_node.global_position)

			if is_instance_valid(rock):
				rock.queue_free()

			return


func _check_interaction() -> void:
	var e_now := Input.is_key_pressed(KEY_E)
	var interact_pressed := false

	if InputMap.has_action("interact"):
		interact_pressed = Input.is_action_just_pressed("interact")

	if player_in_phone_zone and not has_called_911:
		if interact_pressed or (e_now and not e_key_was_pressed):
			_open_phone_keypad()

	e_key_was_pressed = e_now


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

	_show_prompt("Marca 911 y presiona LLAMAR.")


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

	_show_prompt("Presiona E para usar el teléfono.")


func _on_keypad_number_pressed(number: String) -> void:
	_add_digit(number)


func _add_digit(number: String) -> void:
	if dialed_number.length() >= 3:
		return

	_play_keyboard_sound()

	dialed_number += number
	_update_dial_display()

	if dialed_number == "911":
		_stop_keyboard_sound()


func _backspace_digit() -> void:
	if dialed_number.length() > 0:
		_play_keyboard_sound()
		dialed_number = dialed_number.substr(0, dialed_number.length() - 1)

	_update_dial_display()


func _update_dial_display() -> void:
	if dial_display:
		if dialed_number == "":
			dial_display.text = "___"
		else:
			dial_display.text = dialed_number


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

	print("Vidas actuales: ", lives)

	update_lives_ui()

	if lives <= 0:
		lose_game()
		return

	current_spawn_interval = spawn_interval_fast
	_show_prompt("¡Cuidado! Una roca te cayó encima. Perdiste una vida.")


func _on_phone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_phone_zone = true

	if not has_called_911:
		_show_prompt("Presiona E para usar el teléfono.")


func _on_phone_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_phone_zone = false

	if not has_called_911 and not keypad_open:
		_show_prompt("Debes llamar al 911 antes de ir a la cabina segura.")


func _on_time_up() -> void:
	if game_active and not already_finished:
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
