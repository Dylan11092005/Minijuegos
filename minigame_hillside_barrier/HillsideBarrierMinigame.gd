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

const TIMER_UI_SCENE := preload("res://ui_global/TimerUi.tscn")
const LIVES_UI_SCENE := preload("res://ui_global/LivesUi.tscn")
const GAME_RESULT_SCENE := preload("res://ui_global/GameResult.tscn")


# =========================================================
# MINIGAME SCENES
# =========================================================

const TREE_SAPLING_SCENE := preload("res://minigame_hillside_barrier/TreeSapling.tscn")
const PLANTING_SPOT_SCENE := preload("res://minigame_hillside_barrier/PlantingSpot.tscn")
const ROLLING_ROCK_SCENE := preload("res://minigame_hillside_barrier/RollingRock.tscn")


# =========================================================
# CONSTANTS
# =========================================================

const TOTAL_TIME := 45.0
const MAX_LIVES := 3
const ROCKS_TO_BLOCK := 6

const TIMER_PANEL_WIDTH := 500.0
const TIMER_PANEL_HEIGHT := 60.0

const TREE_TABLE_SCALE := Vector2(0.68, 0.68)
const ROCK_SPEED := 120.0

# Posibles lugares donde pueden aparecer los puntos.
# El juego escoge algunos al azar de esta lista.


# Posiciones de los árboles sobre la tabla de abajo.
const TREE_TABLE_POSITIONS := [
	Vector2(1050, 1000),
	Vector2(1200, 1000),
	Vector2(1350, 1000),
	Vector2(1500, 1000),
	Vector2(1650, 1000),
	Vector2(1800, 1000)
]
# Cada ruta tiene:
# start = donde aparece la roca
# spot = donde aparece el punto para sembrar
# end = donde llega la roca si no se detiene
# Zonas aleatorias donde puede aparecer la roca arriba.
const ROCK_START_X_RANGE := Vector2(1200, 1760)
const ROCK_START_Y_RANGE := Vector2(120, 330)

# Zonas aleatorias donde puede terminar la roca abajo.
const ROCK_END_X_RANGE := Vector2(560, 980)
const ROCK_END_Y_RANGE := Vector2(820, 930)

# En qué parte del camino aparece el punto para plantar.
# 0.45 = mitad del camino
# 0.65 = un poco más abajo
const SPOT_PROGRESS_RANGE := Vector2(0.45, 0.65)

# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _game_finished := false
var _round_active := false

var _lives := MAX_LIVES
var _blocked_rocks := 0

var _current_spot: Node = null
var _current_tree: Node = null

var _timer_ui: Node
var _lives_ui: Node
var _game_result: Node

var _progress_layer: CanvasLayer
var _progress_label: Label


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var _planting_spots: Node2D = get_node_or_null("PlantingSpots") as Node2D
@onready var _tree_saplings: Node2D = get_node_or_null("TreeSaplings") as Node2D
@onready var _rocks: Node2D = get_node_or_null("Rocks") as Node2D

@onready var _background_audio: AudioStreamPlayer = get_node_or_null("BackgroundAudio") as AudioStreamPlayer
@onready var _plant_audio: AudioStreamPlayer = get_node_or_null("PlantAudio") as AudioStreamPlayer
@onready var _error_audio: AudioStreamPlayer = get_node_or_null("ErrorAudio") as AudioStreamPlayer
@onready var _landslide_audio: AudioStreamPlayer = get_node_or_null("LandslideAudio") as AudioStreamPlayer


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	randomize()

	_game_finished = false
	_round_active = false
	_lives = MAX_LIVES
	_blocked_rocks = 0
	_current_spot = null
	_current_tree = null

	_setup_timer_ui()
	_setup_lives_ui()
	_setup_game_result()
	_setup_progress_ui()
	_setup_planting_spots()
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


func _setup_table_trees():
	if _tree_saplings == null:
		print("ERROR: No existe el nodo TreeSaplings")
		return

	_clear_children(_tree_saplings)

	for table_position in TREE_TABLE_POSITIONS:
		_spawn_table_tree(table_position)


func _spawn_table_tree(table_position: Vector2):
	if _tree_saplings == null:
		return

	var tree = TREE_SAPLING_SCENE.instantiate()

	tree.position = table_position
	tree.scale = TREE_TABLE_SCALE
	tree.z_index = 30
	tree.set("minigame", self)

	_tree_saplings.add_child(tree)

func _setup_audio():
	if _background_audio:
		_background_audio.volume_db = -14
		_background_audio.play()

		if not _background_audio.finished.is_connected(_on_background_audio_finished):
			_background_audio.finished.connect(_on_background_audio_finished)

	if _plant_audio:
		_plant_audio.volume_db = -4

	if _error_audio:
		_error_audio.volume_db = -6

	if _landslide_audio:
		_landslide_audio.volume_db = -3


# =========================================================
# ROUND METHODS
# =========================================================
func _get_random_rock_route() -> Dictionary:
	var start_position := Vector2(
		randf_range(ROCK_START_X_RANGE.x, ROCK_START_X_RANGE.y),
		randf_range(ROCK_START_Y_RANGE.x, ROCK_START_Y_RANGE.y)
	)

	var end_position := Vector2(
		randf_range(ROCK_END_X_RANGE.x, ROCK_END_X_RANGE.y),
		randf_range(ROCK_END_Y_RANGE.x, ROCK_END_Y_RANGE.y)
	)

	var spot_progress := randf_range(SPOT_PROGRESS_RANGE.x, SPOT_PROGRESS_RANGE.y)
	var spot_position := start_position.lerp(end_position, spot_progress)

	return {
		"start": start_position,
		"spot": spot_position,
		"end": end_position
	}
	
func _start_next_round():
	if _game_finished:
		return

	if _round_active:
		return

	if _blocked_rocks >= ROCKS_TO_BLOCK:
		_win_game()
		return

	_round_active = true
	_current_tree = null

	_clear_children(_planting_spots)
	var route: Dictionary = _get_random_rock_route()

	_spawn_rock(route["start"], route["end"])
	_spawn_rock(route["start"], route["end"])

	await get_tree().create_timer(0.8).timeout

	if _game_finished:
		return

	if not _round_active:
		return

	_spawn_planting_spot(route["spot"], randi_range(0, 100))


func _spawn_planting_spot(spot_position: Vector2, spot_index: int):
	if _planting_spots == null:
		return

	var spot = PLANTING_SPOT_SCENE.instantiate()

	spot.position = spot_position
	spot.set("spot_index", spot_index)
	spot.set("visible_marker", true)

	_planting_spots.add_child(spot)
	_current_spot = spot


func _spawn_rock(start_position: Vector2, end_position: Vector2):
	if _rocks == null:
		print("ERROR: No existe el nodo Rocks")
		return

	var rock = ROLLING_ROCK_SCENE.instantiate()
	rock.z_index = 35

	_rocks.add_child(rock)

	rock.setup(
		start_position,
		end_position,
		ROCK_SPEED,
		self
	)


# =========================================================
# TREE METHODS
# =========================================================

func register_successful_tree(tree: Node, _spot: Node, table_position: Vector2):
	if _game_finished:
		return

	_current_tree = tree

	# Aparece otro árbol nuevo en la tabla.
	# Así los árboles son prácticamente infinitos.
	_spawn_table_tree(table_position)

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

func register_rock_blocked(_rock: Node, tree: Node):
	if _game_finished:
		return

	_blocked_rocks += 1
	_update_progress_ui()

	if tree != null and is_instance_valid(tree):
		tree.queue_free()

	if _current_spot != null and is_instance_valid(_current_spot):
		_current_spot.queue_free()

	_current_spot = null
	_current_tree = null
	_round_active = false

	if _blocked_rocks >= ROCKS_TO_BLOCK:
		_win_game()
	else:
		await get_tree().create_timer(1.0).timeout
		_start_next_round()


func register_rock_reached_bottom(_rock: Node):
	if _game_finished:
		return

	if _current_spot != null and is_instance_valid(_current_spot):
		_current_spot.queue_free()

	if _current_tree != null and is_instance_valid(_current_tree):
		_current_tree.queue_free()

	_current_spot = null
	_current_tree = null
	_round_active = false

	_lives -= 1
	_lives = max(_lives, 0)

	_update_lives_ui()

	if _landslide_audio:
		_landslide_audio.stop()
		_landslide_audio.play()

	if _lives <= 0:
		_lose_game()
	else:
		await get_tree().create_timer(1.0).timeout
		_start_next_round()


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

	_stop_timer_ui()

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

	_stop_timer_ui()

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
	for child in parent.get_children():
		child.queue_free()
