extends Node2D
class_name HillsideBarrierMinigame
# =========================================================
# SIGNALS
# =========================================================

signal puzzle_completed
signal puzzle_failed


# =========================================================
# GLOBAL UI SCENES
# =========================================================

const TIMER_UI_SCENE := preload("res://Minigames/ui_global/TimerUi.tscn")
const LIVES_UI_SCENE := preload("res://Minigames/ui_global/LivesUi.tscn")
const GAME_RESULT_SCENE := preload("res://Minigames/ui_global/GameResult.tscn")


# =========================================================
# MINIGAME SCENES
# =========================================================

const TREE_SAPLING_SCENE := preload("res://Minigames/minigame_hillside_barrier/TreeSapling.tscn")
const PLANTING_SPOT_SCENE := preload("res://Minigames/minigame_hillside_barrier/PlantingSpot.tscn")
const ROLLING_ROCK_SCENE := preload("res://Minigames/minigame_hillside_barrier/RollingRock.tscn")

const BACKGROUND_SOUND := preload("res://Minigames/minigame_hillside_barrier/assets/sounds/Background.mp3")
const MOVE1_SOUND := preload("res://Minigames/minigame_hillside_barrier/assets/sounds/move1.mp3")
const MOVE2_SOUND := preload("res://Minigames/minigame_hillside_barrier/assets/sounds/move2.mp3")
const ROCKS_SOUND := preload("res://Minigames/minigame_hillside_barrier/assets/sounds/rocks.mp3")

# =========================================================
# CONSTANTS
# =========================================================

const TOTAL_TIME := 65.0
const MAX_LIVES := 3
const ROCKS_TO_BLOCK := 8

const TIMER_PANEL_WIDTH := 500.0
const TIMER_PANEL_HEIGHT := 60.0

# Árboles en la madera.
const TREE_TABLE_SCALE := Vector2(0.90, 0.90)
const TREE_COOLDOWN_SECONDS := 3.0

# Tamaño normal y rápido de rocas.
# Piedras más rápidas en general.
const NORMAL_ROCK_SPEED_RANGE := Vector2(145.0, 170.0)
const FAST_ROCK_SPEED_RANGE := Vector2(190.0, 225.0)

# Casi la mitad de las piedras pueden salir rápidas.
const FAST_ROCK_CHANCE := 0.45

# Zonas más amplias donde puede aparecer la roca.
const ROCK_START_X_RANGE := Vector2(950, 1880)
const ROCK_START_Y_RANGE := Vector2(60, 390)

# Zonas más amplias donde puede terminar la roca.
const ROCK_END_X_RANGE := Vector2(360, 1280)
const ROCK_END_Y_RANGE := Vector2(780, 1010)

# El punto puede aparecer en distintas partes del camino,
# pero siempre sobre la ruta real de la roca.
const SPOT_PROGRESS_RANGE := Vector2(0.55, 0.88)

# IMPORTANTE:
# No mover el punto hacia los lados, porque si no la roca puede pasar al lado.
const SPOT_SIDE_OFFSET_RANGE := Vector2(0.0, 0.0)

# Límites para que los puntos no se salgan de la ladera.
const SPOT_X_LIMITS := Vector2(430, 1580)
const SPOT_Y_LIMITS := Vector2(260, 850)

# Separación mínima entre puntos cuando salen 2 rocas.
const MIN_SPOT_DISTANCE := 270.0


# Posiciones de los árboles sobre la tabla de abajo.
const TREE_TABLE_POSITIONS := [
	Vector2(1050, 1000),
	Vector2(1200, 1000),
	Vector2(1350, 1000),
	Vector2(1500, 1000),
	Vector2(1650, 1000),
	Vector2(1800, 1000)
]
# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _game_finished := false
var _round_active := false

var _lives := MAX_LIVES
var _blocked_rocks := 0

var _wave_number := 0
var _wave_active_rocks := 0
var _double_wave_numbers: Array = []
# Guarda los datos de cada roca activa.
# rock_id -> { "spot": Node, "tree": Node }
var _active_challenges: Dictionary = {}

# Guarda qué punto pertenece a qué roca.
# spot_id -> rock_id
var _spot_to_rock_id: Dictionary = {}

var _timer_ui: Node
var _lives_ui: Node
var _game_result: Node

var _progress_layer: CanvasLayer
var _progress_label: Label

var _rng := RandomNumberGenerator.new()

# =========================================================
# NODE REFERENCES
# =========================================================

@onready var _planting_spots: Node2D = get_node_or_null("PlantingSpots") as Node2D
@onready var _tree_saplings: Node2D = get_node_or_null("TreeSaplings") as Node2D
@onready var _rocks: Node2D = get_node_or_null("Rocks") as Node2D

@onready var _background_audio: AudioStreamPlayer = get_node_or_null("BackgroundAudio") as AudioStreamPlayer
@onready var _move1_audio: AudioStreamPlayer = get_node_or_null("Move1Audio") as AudioStreamPlayer
@onready var _plant_audio: AudioStreamPlayer = get_node_or_null("PlantAudio") as AudioStreamPlayer
@onready var _rocks_audio: AudioStreamPlayer = get_node_or_null("RocksAudio") as AudioStreamPlayer
@onready var _error_audio: AudioStreamPlayer = get_node_or_null("ErrorAudio") as AudioStreamPlayer
@onready var _landslide_audio: AudioStreamPlayer = get_node_or_null("LandslideAudio") as AudioStreamPlayer


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	_rng.randomize()

	_game_finished = false
	_round_active = false
	_lives = MAX_LIVES
	_blocked_rocks = 0
	_wave_number = 0
	_wave_active_rocks = 0
	_setup_double_waves()

	_active_challenges.clear()
	_spot_to_rock_id.clear()

	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()
	_setup_progress_ui()
	_setup_planting_spots()
	_setup_rocks()
	_setup_table_trees()
	_setup_audio()

	_update_lives_ui()
	_update_progress_ui()

	_start_next_round()


func _process(_delta):
	if _game_finished:
		return

	if _lives <= 0:
		_lose_game()


# =========================================================
# SETUP METHODS
# =========================================================

func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	if _timer_ui.has_signal("time_up"):
		_timer_ui.connect("time_up", Callable(self, "_on_time_up"))
	else:
		print("ERROR: TimerUi no tiene la señal time_up")

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(TIMER_PANEL_WIDTH, TIMER_PANEL_HEIGHT)

	if _timer_ui.has_method("iniciar"):
		_timer_ui.iniciar(TOTAL_TIME, "Tiempo para el", "deslizamiento")
	else:
		print("ERROR: TimerUi no tiene el método iniciar()")


func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_lives)
	else:
		print("ERROR: LivesUi no tiene el método actualizar_vidas()")


func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)

	if _game_result is CanvasLayer:
		_game_result.layer = 50


func _setup_progress_ui():
	_progress_layer = CanvasLayer.new()
	_progress_layer.layer = 11
	add_child(_progress_layer)

	var panel := Panel.new()
	panel.position = Vector2(20, 92)
	panel.size = Vector2(430, 58)
	_progress_layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#E5C89E")
	style.border_color = Color("#E0B080")

	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4

	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18

	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)

	panel.add_theme_stylebox_override("panel", style)

	_progress_label = Label.new()
	_progress_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 23)
	_progress_label.add_theme_color_override("font_color", Color("#3E5F8F"))

	panel.add_child(_progress_label)


func _setup_planting_spots():
	if _planting_spots == null:
		print("ERROR: No existe el nodo PlantingSpots")
		return

	_clear_children(_planting_spots)


func _setup_rocks():
	if _rocks == null:
		print("ERROR: No existe el nodo Rocks")
		return

	_clear_children(_rocks)


func _setup_table_trees():
	if _tree_saplings == null:
		print("ERROR: No existe el nodo TreeSaplings")
		return

	_clear_children(_tree_saplings)

	for table_position in TREE_TABLE_POSITIONS:
		_spawn_table_tree(table_position)


func _spawn_table_tree(table_position: Vector2, start_on_cooldown := false):
	if _tree_saplings == null:
		return

	var tree = TREE_SAPLING_SCENE.instantiate()

	tree.position = table_position
	tree.scale = TREE_TABLE_SCALE
	tree.z_index = 30
	tree.set("minigame", self)

	_tree_saplings.add_child(tree)

	if start_on_cooldown:
		if tree.has_method("start_cooldown"):
			tree.start_cooldown(TREE_COOLDOWN_SECONDS)


func _setup_audio():
	if _background_audio:
		_background_audio.stream = BACKGROUND_SOUND
		_background_audio.volume_db = -14
		_background_audio.play()

		if not _background_audio.finished.is_connected(_on_background_audio_finished):
			_background_audio.finished.connect(_on_background_audio_finished)

	if _move1_audio:
		_move1_audio.stream = MOVE1_SOUND
		_move1_audio.volume_db = -5

	if _plant_audio:
		_plant_audio.stream = MOVE2_SOUND
		_plant_audio.volume_db = -4

	if _rocks_audio:
		_rocks_audio.stream = ROCKS_SOUND
		_rocks_audio.volume_db = -2

	if _error_audio:
		_error_audio.volume_db = -6

	if _landslide_audio:
		_landslide_audio.volume_db = -3


# =========================================================
# RANDOM ROCK ROUTES
# =========================================================

func _get_random_rock_route() -> Dictionary:
	var start_position := Vector2(
		_rng.randf_range(ROCK_START_X_RANGE.x, ROCK_START_X_RANGE.y),
		_rng.randf_range(ROCK_START_Y_RANGE.x, ROCK_START_Y_RANGE.y)
	)

	var end_position := Vector2(
		_rng.randf_range(ROCK_END_X_RANGE.x, ROCK_END_X_RANGE.y),
		_rng.randf_range(ROCK_END_Y_RANGE.x, ROCK_END_Y_RANGE.y)
	)

	var spot_progress := _rng.randf_range(SPOT_PROGRESS_RANGE.x, SPOT_PROGRESS_RANGE.y)

	# El punto queda EXACTAMENTE en el camino de la roca.
	var spot_position := start_position.lerp(end_position, spot_progress)

	spot_position.x = clamp(spot_position.x, SPOT_X_LIMITS.x, SPOT_X_LIMITS.y)
	spot_position.y = clamp(spot_position.y, SPOT_Y_LIMITS.x, SPOT_Y_LIMITS.y)

	var rock_speed := _get_random_rock_speed()

	print("ROCA NUEVA")
	print("Inicio: ", start_position)
	print("Punto: ", spot_position)
	print("Final: ", end_position)
	print("Velocidad: ", rock_speed)

	return {
		"start": start_position,
		"spot": spot_position,
		"end": end_position,
		"speed": rock_speed
	}


func _get_random_rock_speed() -> float:
	var should_be_fast := _rng.randf() <= FAST_ROCK_CHANCE

	if should_be_fast:
		return _rng.randf_range(FAST_ROCK_SPEED_RANGE.x, FAST_ROCK_SPEED_RANGE.y)

	return _rng.randf_range(NORMAL_ROCK_SPEED_RANGE.x, NORMAL_ROCK_SPEED_RANGE.y)

func _setup_double_waves():
	_double_wave_numbers.clear()

	var possible_waves: Array = [2, 3, 4, 5, 6]
	possible_waves.shuffle()

	_double_wave_numbers.append(possible_waves[0])
	_double_wave_numbers.append(possible_waves[1])
	_double_wave_numbers.sort()

	print("Oleadas dobles: ", _double_wave_numbers)
	
	
func _get_wave_rock_amount() -> int:
	# En cada partida se eligen 2 oleadas dobles al azar.
	if _double_wave_numbers.has(_wave_number):
		return 2

	return 1


func _generate_wave_routes(amount: int) -> Array:
	var routes: Array = []
	var attempts := 0

	while routes.size() < amount and attempts < 50:
		attempts += 1

		var new_route: Dictionary = _get_random_rock_route()
		var new_spot: Vector2 = new_route["spot"]

		var valid_position := true

		for existing_route in routes:
			var existing_spot: Vector2 = existing_route["spot"]

			if new_spot.distance_to(existing_spot) < MIN_SPOT_DISTANCE:
				valid_position = false
				break

		if valid_position:
			routes.append(new_route)

	# Si por alguna razón no logró separar bien las rutas, rellena normal.
	while routes.size() < amount:
		routes.append(_get_random_rock_route())

	return routes


# =========================================================
# ROUND METHODS
# =========================================================

func _start_next_round():
	if _game_finished:
		return

	if _round_active:
		return

	if _blocked_rocks >= ROCKS_TO_BLOCK:
		_win_game()
		return

	if _rocks == null:
		print("ERROR: No existe el nodo Rocks")
		return

	_wave_number += 1

	var remaining_rocks: int = ROCKS_TO_BLOCK - _blocked_rocks
	var wanted_rocks: int = _get_wave_rock_amount()
	var rocks_in_wave: int = int(min(wanted_rocks, remaining_rocks))

	_round_active = true
	_wave_active_rocks = 0

	_active_challenges.clear()
	_spot_to_rock_id.clear()

	_clear_children(_planting_spots)

	var routes: Array = _generate_wave_routes(rocks_in_wave)
	var spawned_rock_data: Array = []

	for route in routes:
		var start_position: Vector2 = route["start"]
		var end_position: Vector2 = route["end"]
		var rock_speed: float = route["speed"]

		var rock: Node = _spawn_rock(start_position, end_position, rock_speed)

		if rock == null:
			continue

		var rock_id: int = rock.get_instance_id()

		_active_challenges[rock_id] = {
			"spot": null,
			"tree": null
		}

		_wave_active_rocks += 1

		spawned_rock_data.append({
			"rock_id": rock_id,
			"spot": route["spot"]
		})

	await get_tree().create_timer(0.35).timeout

	if _game_finished:
		return

	if not _round_active:
		return

	for rock_data in spawned_rock_data:
		var rock_id: int = rock_data["rock_id"]

		if not _active_challenges.has(rock_id):
			continue

		var spot_position: Vector2 = rock_data["spot"]
		var spot_index: int = _rng.randi_range(0, 999)

		var spot: Node = _spawn_planting_spot(spot_position, spot_index, rock_id)

		if spot == null:
			continue

		var data: Dictionary = _active_challenges[rock_id]
		data["spot"] = spot
		_active_challenges[rock_id] = data
		
func _spawn_planting_spot(spot_position: Vector2, spot_index: int, rock_id: int) -> Node:
	if _planting_spots == null:
		return null

	var spot = PLANTING_SPOT_SCENE.instantiate()

	spot.position = spot_position
	spot.set("spot_index", spot_index)
	spot.set("visible_marker", true)

	# Este punto pertenece únicamente a esta roca.
	spot.set_meta("rock_id", rock_id)

	_planting_spots.add_child(spot)

	_spot_to_rock_id[spot.get_instance_id()] = rock_id

	return spot


func _spawn_rock(start_position: Vector2, end_position: Vector2, rock_speed: float) -> Node:
	if _rocks == null:
		print("ERROR: No existe el nodo Rocks")
		return null

	if _rocks_audio:
		_rocks_audio.stop()
		_rocks_audio.play()

	var rock = ROLLING_ROCK_SCENE.instantiate()
	rock.z_index = 35

	_rocks.add_child(rock)

	rock.setup(
		start_position,
		end_position,
		rock_speed,
		self
	)

	return rock


# =========================================================
# TREE METHODS
# =========================================================

func register_tree_grabbed(_tree: Node):
	if _game_finished:
		return

	if _move1_audio:
		_move1_audio.stop()
		_move1_audio.play()


func register_successful_tree(tree: Node, spot: Node, table_position: Vector2):
	if _game_finished:
		return

	# Árbol infinito con cooldown:
	# aparece otro árbol en la misma posición, pero gris por 3 segundos.
	_spawn_table_tree(table_position, true)

	if spot != null and is_instance_valid(spot):
		var rock_id: int = -1

		if spot.has_meta("rock_id"):
			rock_id = int(spot.get_meta("rock_id"))

		if rock_id != -1 and _active_challenges.has(rock_id):
			var data: Dictionary = _active_challenges[rock_id]
			data["tree"] = tree
			_active_challenges[rock_id] = data

	if _plant_audio:
		_plant_audio.stop()
		_plant_audio.play()


func register_failed_drop(_tree: Node):
	if _game_finished:
		return

	_lives -= 1
	_lives = max(_lives, 0)

	_update_lives_ui()

	if _error_audio:
		_error_audio.stop()
		_error_audio.play()

	if _lives <= 0:
		_lose_game()


# =========================================================
# ROCK METHODS
# =========================================================

func register_rock_blocked(rock: Node, tree: Node):
	if _game_finished:
		return

	var rock_id: int = rock.get_instance_id()

	if not _active_challenges.has(rock_id):
		return

	_blocked_rocks += 1
	_update_progress_ui()

	_resolve_rock_challenge(rock, tree)

	if _blocked_rocks >= ROCKS_TO_BLOCK:
		_win_game()
		return

	if _wave_active_rocks <= 0:
		await get_tree().create_timer(1.0).timeout
		_start_next_round()


func register_rock_reached_bottom(rock: Node):
	if _game_finished:
		return

	var rock_id: int = rock.get_instance_id()

	if not _active_challenges.has(rock_id):
		return

	_resolve_rock_challenge(rock, null)

	_lives -= 1
	_lives = max(_lives, 0)

	_update_lives_ui()

	if _landslide_audio:
		_landslide_audio.stop()
		_landslide_audio.play()

	if _lives <= 0:
		_lose_game()
		return

	if _wave_active_rocks <= 0:
		await get_tree().create_timer(1.0).timeout
		_start_next_round()


func _resolve_rock_challenge(rock: Node, collided_tree: Node):
	if rock == null:
		return

	if not is_instance_valid(rock):
		return

	var rock_id: int = rock.get_instance_id()

	if not _active_challenges.has(rock_id):
		return

	var data: Dictionary = _active_challenges[rock_id]

	var spot_value = data.get("spot", null)
	var tree_value = data.get("tree", null)

	if spot_value != null and is_instance_valid(spot_value):
		var spot_node: Node = spot_value
		_spot_to_rock_id.erase(spot_node.get_instance_id())
		spot_node.queue_free()

	var tree_to_remove = collided_tree

	if tree_to_remove == null:
		tree_to_remove = tree_value

	if tree_to_remove != null and is_instance_valid(tree_to_remove):
		tree_to_remove.queue_free()

	_active_challenges.erase(rock_id)

	_wave_active_rocks -= 1
	_wave_active_rocks = max(_wave_active_rocks, 0)

	if _wave_active_rocks <= 0:
		_round_active = false

		if _rocks_audio:
			_rocks_audio.stop()

# =========================================================
# UI METHODS
# =========================================================

func _update_lives_ui():
	if _lives_ui == null:
		return

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_lives)


func _update_progress_ui():
	if _progress_label == null:
		return

	_progress_label.text = "Rocas detenidas: %d / %d" % [
		_blocked_rocks,
		ROCKS_TO_BLOCK
	]


func _stop_timer_ui():
	if _timer_ui == null:
		return

	if _timer_ui.has_method("detener"):
		_timer_ui.detener()


# =========================================================
# TIMER METHODS
# =========================================================

func _on_time_up():
	if _game_finished:
		return

	if _blocked_rocks >= ROCKS_TO_BLOCK:
		_win_game()
	else:
		_lose_game()


# =========================================================
# AUDIO METHODS
# =========================================================

func _on_background_audio_finished():
	if not _game_finished and _background_audio:
		_background_audio.play()


# =========================================================
# RESULT METHODS
# =========================================================

func _win_game():
	if _game_finished:
		return

	_game_finished = true
	_round_active = false

	if _rocks_audio:
		_rocks_audio.stop()

	_stop_timer_ui()
	_clear_children(_planting_spots)
	_clear_children(_rocks)

	if _background_audio:
		_background_audio.stop()

	if _game_result:
		if _game_result.has_method("show_win"):
			_game_result.show_win()
		elif _game_result.has_method("mostrar_ganaste"):
			_game_result.mostrar_ganaste()

	emit_signal("puzzle_completed")


func _lose_game():
	if _game_finished:
		return

	_game_finished = true
	_round_active = false

	if _rocks_audio:
		_rocks_audio.stop()

	_stop_timer_ui()
	_clear_children(_planting_spots)
	_clear_children(_rocks)

	if _background_audio:
		_background_audio.stop()

	if _landslide_audio:
		_landslide_audio.stop()
		_landslide_audio.play()

	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

	emit_signal("puzzle_failed")


# =========================================================
# UTILITY METHODS
# =========================================================

func _clear_children(parent: Node):
	if parent == null:
		return

	for child in parent.get_children():
		child.queue_free()
