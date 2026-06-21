extends Node2D

@export var time_limit := 45.0
@export var max_lives := 3

@export var rock_scene: PackedScene = preload("res://Minigames/minigame_landslide/FallingRock.tscn")

const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

@export var spawn_interval := 1.05
@export var spawn_interval_fast := 0.72

# Daño de roca: más pequeño = más preciso
@export var rock_hit_x_distance := 28.0
@export var rock_hit_y_min := -75.0
@export var rock_hit_y_max := 15.0

# Victoria cerca de la cabina segura
@export var safe_win_distance := 35.0

var game_active := false
var already_finished := false

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


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

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
	# NO se crea el jugador. Se busca el que vos pusiste manualmente.
	player = get_node_or_null("Player") as CharacterBody2D

	# Por si tu jugador quedó con otro nombre, busca cualquier CharacterBody2D.
	if player == null:
		player = _find_first_character_body()

	if player:
		player.set_physics_process(true)
		player.add_to_group("player")
		player.collision_layer = 1
		player.collision_mask = 2
	else:
		push_warning("No se encontró Player. Pon tu personaje manualmente en el mapa como CharacterBody2D y nómbralo Player.")

	# Estos también son manuales.
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

	# SafeCabin NO se toca. La victoria se revisa por distancia corta.


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
	phone_overlay.position = Vector2.ZERO
	phone_overlay.size = Vector2(1280, 720)
	ui_layer.add_child(phone_overlay)

	var panel := Panel.new()
	panel.name = "PhonePanel"
	panel.size = Vector2(360, 500)
	panel.position = Vector2(460, 110)
	phone_overlay.add_child(panel)

	var title := Label.new()
	title.text = "Llamar al 911"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 18)
	title.size = Vector2(320, 35)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)

	dial_display = Label.new()
	dial_display.text = "___"
	dial_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dial_display.position = Vector2(35, 65)
	dial_display.size = Vector2(290, 55)
	dial_display.add_theme_font_size_override("font_size", 34)
	panel.add_child(dial_display)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(45, 135)
	grid.size = Vector2(270, 240)
	panel.add_child(grid)

	for number in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "BORRAR", "0", "LLAMAR"]:
		var button := Button.new()
		button.text = number
		button.custom_minimum_size = Vector2(85, 55)
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
	cancel_button.position = Vector2(90, 410)
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

	lives = max_lives
	has_called_911 = false
	player_in_phone_zone = false
	spawn_counter = 0.0
	current_spawn_interval = spawn_interval
	e_key_was_pressed = false
	keypad_open = false
	dialed_number = ""

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

	if rock_scene == null:
		return

	var spawners := rock_spawners.get_children()

	if spawners.is_empty():
		return

	var marker: Marker2D = spawners.pick_random()
	var rock := rock_scene.instantiate()

	add_child(rock)

	rock.add_to_group("falling_rocks")
	rock.set_meta("hit_player", false)

	rock.z_index = 70
	rock.global_position = marker.global_position
	rock.direction = Vector2(randf_range(-0.22, 0.22), 1).normalized()
	rock.speed = randf_range(160.0, 250.0)
	rock.rotation_speed = randf_range(-8.0, 8.0)


func _check_rock_hits() -> void:
	if player == null:
		return

	if player_in_phone_zone or keypad_open:
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

	if phone_overlay:
		phone_overlay.visible = true

	if player:
		player.set_physics_process(false)

	_show_prompt("Marca 911 y presiona LLAMAR.")


func _close_phone_keypad() -> void:
	keypad_open = false
	dialed_number = ""

	if phone_overlay:
		phone_overlay.visible = false

	if player and not already_finished:
		player.set_physics_process(true)

	_show_prompt("Presiona E para usar el teléfono.")


func _on_keypad_number_pressed(number: String) -> void:
	_add_digit(number)


func _add_digit(number: String) -> void:
	if dialed_number.length() >= 3:
		return

	dialed_number += number
	_update_dial_display()


func _backspace_digit() -> void:
	if dialed_number.length() > 0:
		dialed_number = dialed_number.substr(0, dialed_number.length() - 1)

	_update_dial_display()


func _update_dial_display() -> void:
	if dial_display:
		if dialed_number == "":
			dial_display.text = "___"
		else:
			dial_display.text = dialed_number


func _try_call_number() -> void:
	if dialed_number == "911":
		has_called_911 = true
		player_in_phone_zone = false
		current_spawn_interval = spawn_interval_fast
		keypad_open = false

		if phone_overlay:
			phone_overlay.visible = false

		if player and not already_finished:
			player.set_physics_process(true)

		_update_hud()
		_show_prompt("Llamaste al 911. Ahora llega a la cabina segura.")
	else:
		dialed_number = ""
		_update_dial_display()
		_show_prompt("Número incorrecto. Marca 911.")


func _on_player_damaged() -> void:
	if not game_active or already_finished:
		return

	if player_in_phone_zone or keypad_open:
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
		mission_label.text = "Misión: llega a la cabina segura"
	else:
		mission_label.text = "Misión: llama al 911"


func _show_prompt(message: String) -> void:
	if prompt_label:
		prompt_label.text = message
