extends Node2D
class_name EvacuationRhythmMinigame


@export var time_limit := 40.0
@export var lives_limit := 3

@export var sequence_length := 24
@export var required_hits_to_win := 18

@export var beat_interval := 1.05
@export var note_speed := 340.0
@export var hit_window := 60.0


const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")


const C_BEIGE := Color("#E5C89E")
const C_ORANGE := Color("#E0B080")
const C_BLUE := Color("#3E5F8F")
const C_CYAN := Color("#39B5E6")
const C_WHITE := Color("#FFFFFF")
const C_RED := Color("#D63A3A")
const C_GREEN := Color("#38A169")
const C_YELLOW := Color("#F2C94C")
const C_DARK := Color("#1F2D3D")


const NOTE_SIZE := Vector2(90, 62)
const BUTTON_SIZE := Vector2(145, 76)
const COLUMN_GAP := 42.0

const COLOR_IDS: Array[String] = ["red", "blue", "yellow", "green"]

const COLOR_DATA := {
	"red": {
		"name": "ROJO",
		"key_name": "A",
		"key": KEY_A,
		"color": Color("#D63A3A")
	},
	"blue": {
		"name": "AZUL",
		"key_name": "S",
		"key": KEY_S,
		"color": Color("#3E5F8F")
	},
	"yellow": {
		"name": "AMARILLO",
		"key_name": "D",
		"key": KEY_D,
		"color": Color("#F2C94C")
	},
	"green": {
		"name": "VERDE",
		"key_name": "F",
		"key": KEY_F,
		"color": Color("#38A169")
	}
}


var screen_size := Vector2.ZERO

var ui_layer: CanvasLayer
var notes_layer: CanvasLayer

var title_label: Label
var progress_label: Label
var feedback_label: Label
var instruction_label: Label
var hit_zone_rect: ColorRect
var hit_zone_label: Label

var spawn_timer: Timer

var sequence: Array[String] = []
var spawned_index := 0
var success_count := 0
var lives := 3

var game_active := false
var already_finished := false

var column_x: Dictionary = {}
var active_notes: Array[Control] = []

var path_start := Vector2.ZERO
var path_end := Vector2.ZERO

var timer_hud: CanvasLayer
var game_result_panel: CanvasLayer

var lives_ui: Node
var lives_layer: CanvasLayer


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

	screen_size = get_viewport_rect().size

	_calculate_layout()
	_create_layers()
	create_timer()
	create_game_result_panel()
	create_lives_ui()
	_create_ui()
	_create_timers()
	_create_sequence()

	start_game()


func _calculate_layout() -> void:
	var total_columns_width: float = NOTE_SIZE.x * float(COLOR_IDS.size()) + COLUMN_GAP * float(COLOR_IDS.size() - 1)
	var start_x: float = screen_size.x / 2.0 - total_columns_width / 2.0 + NOTE_SIZE.x / 2.0

	for i in range(COLOR_IDS.size()):
		var color_id: String = COLOR_IDS[i]
		column_x[color_id] = start_x + float(i) * (NOTE_SIZE.x + COLUMN_GAP)

	path_start = Vector2(100, screen_size.y * 0.43)
	path_end = Vector2(screen_size.x - 150, screen_size.y * 0.43)


func _create_layers() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	add_child(ui_layer)

	notes_layer = CanvasLayer.new()
	notes_layer.layer = 35
	add_child(notes_layer)


func _create_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = beat_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_next_note)
	add_child(spawn_timer)


func _create_sequence() -> void:
	sequence.clear()

	for i in range(sequence_length):
		var random_color: String = COLOR_IDS[randi() % COLOR_IDS.size()]
		sequence.append(random_color)


# =========================
# TIMER Y VIDAS ESTÁNDAR
# =========================

func create_timer() -> void:
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.layer = 50
	timer_hud.visible = true
	timer_hud.time_up.connect(_on_time_up)

	if timer_hud.has_method("set_tamano_panel"):
		timer_hud.call("set_tamano_panel", 500, 60)


func create_game_result_panel() -> void:
	game_result_panel = GAME_RESULT_SCENE.instantiate()
	add_child(game_result_panel)
	game_result_panel.layer = 60


func create_lives_ui() -> void:
	var new_lives_ui: Node = LIVES_UI_SCENE.instantiate()

	if new_lives_ui is CanvasLayer:
		lives_ui = new_lives_ui
		add_child(lives_ui)
		lives_ui.layer = 55
	else:
		lives_layer = CanvasLayer.new()
		lives_layer.layer = 55
		add_child(lives_layer)

		lives_ui = new_lives_ui
		lives_layer.add_child(lives_ui)

	if lives_ui.has_method("set_panel_corner"):
		lives_ui.call("set_panel_corner", LivesUi.PanelCorner.TOP_RIGHT)

	if lives_ui.has_method("set_panel_margin"):
		lives_ui.call("set_panel_margin", Vector2(35, 20))

	setup_lives_ui()


func setup_lives_ui() -> void:
	if lives_ui == null:
		return

	if lives_ui.has_method("set_max_lives"):
		lives_ui.call("set_max_lives", lives_limit)
	elif lives_ui.has_method("set_total_lives"):
		lives_ui.call("set_total_lives", lives_limit)
	elif lives_ui.has_method("set_max_vidas"):
		lives_ui.call("set_max_vidas", lives_limit)

	update_lives_ui()


func update_lives_ui() -> void:
	if lives_ui == null:
		return

	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.call("actualizar_vidas", lives)
	elif lives_ui.has_method("update_lives"):
		lives_ui.call("update_lives", lives)
	elif lives_ui.has_method("set_lives"):
		lives_ui.call("set_lives", lives)
	elif lives_ui.has_method("set_current_lives"):
		lives_ui.call("set_current_lives", lives)
	else:
		print("ERROR: LivesUi no tiene método para actualizar vidas.")


# =========================
# UI DEL JUEGO
# =========================

func _create_ui() -> void:
	title_label = _make_label(
		"Evacuación segura hacia la escuela",
		Vector2(0, 18),
		Vector2(screen_size.x, 42),
		30,
		C_BLUE
	)

	instruction_label = _make_label(
		"Presiona el color correcto cuando llegue a la zona de ritmo.",
		Vector2(0, 64),
		Vector2(screen_size.x, 32),
		20,
		C_DARK
	)

	progress_label = _make_panel_label(
		"Avance: 0 / 0",
		Vector2(screen_size.x / 2.0 - 120, 105),
		Vector2(240, 48),
		20,
		C_BLUE,
		C_BEIGE
	)

	var hit_zone_y: float = _get_hit_zone_y()

	hit_zone_rect = ColorRect.new()
	hit_zone_rect.color = Color(1, 1, 1, 0.28)
	hit_zone_rect.position = Vector2(55, hit_zone_y - 45)
	hit_zone_rect.size = Vector2(screen_size.x - 110, 90)
	hit_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hit_zone_rect)

	hit_zone_label = _make_label(
		"ZONA DE RITMO",
		Vector2(0, hit_zone_y - 18),
		Vector2(screen_size.x, 36),
		22,
		C_BLUE
	)

	feedback_label = _make_label(
		"",
		Vector2(0, screen_size.y - 185),
		Vector2(screen_size.x, 42),
		24,
		C_BLUE
	)

	_create_color_buttons()


func _create_color_buttons() -> void:
	var button_y: float = screen_size.y - 120

	for color_id in COLOR_IDS:
		var info: Dictionary = COLOR_DATA[color_id]
		var base_color: Color = info["color"]
		var color_name: String = str(info["name"])
		var key_name: String = str(info["key_name"])

		var button: Button = Button.new()
		button.text = "%s\nTecla %s" % [color_name, key_name]
		button.position = Vector2(float(column_x[color_id]) - BUTTON_SIZE.x / 2.0, button_y)
		button.size = BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE

		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", C_WHITE)
		button.add_theme_stylebox_override("normal", _make_stylebox(base_color, C_ORANGE, 3))
		button.add_theme_stylebox_override("hover", _make_stylebox(base_color.lightened(0.12), C_WHITE, 3))
		button.add_theme_stylebox_override("pressed", _make_stylebox(base_color.darkened(0.15), C_WHITE, 3))

		button.pressed.connect(_on_color_button_pressed.bind(color_id))
		ui_layer.add_child(button)


func _on_color_button_pressed(color_id: String) -> void:
	_try_hit(color_id)


func _make_label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	ui_layer.add_child(label)
	return label


func _make_panel_label(text: String, pos: Vector2, size: Vector2, font_size: int, text_color: Color, bg_color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_stylebox_override("normal", _make_stylebox(bg_color, C_ORANGE, 3))
	ui_layer.add_child(label)
	return label


func _make_stylebox(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 4)
	return style


# =========================
# INICIO DEL JUEGO
# =========================

func start_game() -> void:
	game_active = true
	already_finished = false

	spawned_index = 0
	success_count = 0
	lives = lives_limit

	feedback_label.text = "Mantén el ritmo y evacúa con calma."
	feedback_label.add_theme_color_override("font_color", C_BLUE)

	update_lives_ui()
	_update_progress_ui()

	if timer_hud != null:
		timer_hud.detener()
		timer_hud.iniciar(time_limit, "Tiempo", "evacúa hacia la escuela")

	spawn_timer.start()
	queue_redraw()


# =========================
# PROCESO
# =========================

func _process(delta: float) -> void:
	if not game_active:
		return

	_move_notes(delta)
	_check_end_without_enough_hits()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event

		if key_event.pressed and not key_event.echo:
			for color_id in COLOR_IDS:
				var info: Dictionary = COLOR_DATA[color_id]
				var key_code: int = int(info["key"])

				if key_event.keycode == key_code:
					_try_hit(color_id)
					return


# =========================
# NOTAS DE RITMO
# =========================

func _spawn_next_note() -> void:
	if not game_active:
		return

	if spawned_index >= sequence.size():
		spawn_timer.stop()
		return

	var color_id: String = sequence[spawned_index]
	spawned_index += 1

	var info: Dictionary = COLOR_DATA[color_id]
	var base_color: Color = info["color"]
	var color_name: String = str(info["name"])

	var note: Panel = Panel.new()
	note.position = Vector2(float(column_x[color_id]) - NOTE_SIZE.x / 2.0, 92)
	note.size = NOTE_SIZE
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.set_meta("color_id", color_id)
	note.add_theme_stylebox_override("panel", _make_stylebox(base_color, C_WHITE, 2))

	var note_label: Label = Label.new()
	note_label.text = color_name
	note_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 18)
	note_label.add_theme_color_override("font_color", C_WHITE)
	note.add_child(note_label)

	notes_layer.add_child(note)
	active_notes.append(note)


func _move_notes(delta: float) -> void:
	var missed_notes: Array[Control] = []

	for note in active_notes:
		note.position.y += note_speed * delta

		var note_center_y: float = note.position.y + NOTE_SIZE.y / 2.0

		if note_center_y > _get_hit_zone_y() + hit_window:
			missed_notes.append(note)

	for note in missed_notes:
		if active_notes.has(note):
			_miss_note(note, "Perdiste el compás. La indicación pasó.")


func _try_hit(color_id: String) -> void:
	var closest_note: Control = _get_closest_note_to_hit_zone()

	if closest_note == null:
		_lose_life("No corras. Espera el momento correcto.")
		return

	var note_color_id: String = str(closest_note.get_meta("color_id"))

	if not _is_note_inside_hit_window(closest_note):
		_lose_life("No era el momento. Mantén la calma.")
		return

	if note_color_id != color_id:
		_remove_note(closest_note)
		_lose_life("Color incorrecto. Sigue las indicaciones.")
		return

	_hit_note(closest_note)


func _hit_note(note: Control) -> void:
	_remove_note(note)

	success_count += 1
	_update_progress_ui()

	feedback_label.text = "¡Bien! Evacuación tranquila y ordenada."
	feedback_label.add_theme_color_override("font_color", C_GREEN)

	queue_redraw()

	if success_count >= required_hits_to_win:
		win_game()


func _miss_note(note: Control, message: String) -> void:
	_remove_note(note)
	_lose_life(message)


func _remove_note(note: Control) -> void:
	if active_notes.has(note):
		active_notes.erase(note)

	if is_instance_valid(note):
		note.queue_free()


func _get_closest_note_to_hit_zone() -> Control:
	if active_notes.is_empty():
		return null

	var closest_note: Control = null
	var closest_distance := 999999.0
	var hit_y: float = _get_hit_zone_y()

	for note in active_notes:
		var note_center_y: float = note.position.y + NOTE_SIZE.y / 2.0
		var distance: float = abs(note_center_y - hit_y)

		if distance < closest_distance:
			closest_distance = distance
			closest_note = note

	return closest_note


func _is_note_inside_hit_window(note: Control) -> bool:
	var note_center_y: float = note.position.y + NOTE_SIZE.y / 2.0
	var distance: float = abs(note_center_y - _get_hit_zone_y())
	return distance <= hit_window


func _get_hit_zone_y() -> float:
	return screen_size.y - 265.0


# =========================
# VIDAS Y PROGRESO
# =========================

func _lose_life(message: String) -> void:
	if not game_active:
		return

	lives -= 1

	if lives < 0:
		lives = 0

	update_lives_ui()

	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", C_RED)

	if lives <= 0:
		lose_game()


func _update_progress_ui() -> void:
	progress_label.text = "Avance: %d / %d" % [success_count, required_hits_to_win]


func _check_end_without_enough_hits() -> void:
	if spawned_index >= sequence.size() and active_notes.is_empty() and success_count < required_hits_to_win:
		lose_game()


func _on_time_up() -> void:
	if game_active and not already_finished:
		feedback_label.text = "Se acabó el tiempo. No lograste llegar a la escuela."
		feedback_label.add_theme_color_override("font_color", C_RED)
		lose_game()


# =========================
# GANAR / PERDER
# =========================

func win_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	if spawn_timer != null:
		spawn_timer.stop()

	if timer_hud != null:
		timer_hud.detener()

	_clear_notes()

	feedback_label.text = "¡Llegaste a la escuela de forma segura!"
	feedback_label.add_theme_color_override("font_color", C_GREEN)

	queue_redraw()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_ganaste"):
			game_result_panel.call("mostrar_ganaste")
		elif game_result_panel.has_method("show_win"):
			game_result_panel.call("show_win")


func lose_game() -> void:
	if already_finished:
		return

	already_finished = true
	game_active = false

	if spawn_timer != null:
		spawn_timer.stop()

	if timer_hud != null:
		timer_hud.detener()

	_clear_notes()

	if game_result_panel != null:
		if game_result_panel.has_method("mostrar_perdiste"):
			game_result_panel.call("mostrar_perdiste")
		elif game_result_panel.has_method("show_lose"):
			game_result_panel.call("show_lose")


func _clear_notes() -> void:
	for note in active_notes:
		if is_instance_valid(note):
			note.queue_free()

	active_notes.clear()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")


# =========================
# DIBUJO DEL MAPA
# =========================

func _draw() -> void:
	_draw_background()
	_draw_path()
	_draw_school()
	_draw_character()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#DFF6FF"))

	draw_rect(
		Rect2(Vector2(0, screen_size.y * 0.50), Vector2(screen_size.x, screen_size.y * 0.50)),
		Color("#C8E6C9")
	)

	draw_circle(Vector2(120, 120), 34, Color(1, 1, 1, 0.75))
	draw_circle(Vector2(155, 112), 42, Color(1, 1, 1, 0.75))
	draw_circle(Vector2(195, 125), 32, Color(1, 1, 1, 0.75))

	draw_circle(Vector2(screen_size.x - 170, 110), 34, Color(1, 1, 1, 0.75))
	draw_circle(Vector2(screen_size.x - 130, 100), 45, Color(1, 1, 1, 0.75))
	draw_circle(Vector2(screen_size.x - 85, 118), 30, Color(1, 1, 1, 0.75))


func _draw_path() -> void:
	var path_color := Color("#A67C52")
	var border_color := Color("#7A5837")

	draw_line(path_start, path_end, border_color, 34.0)
	draw_line(path_start, path_end, path_color, 25.0)

	var progress: float = clampf(float(success_count) / float(required_hits_to_win), 0.0, 1.0)
	var current_pos: Vector2 = path_start.lerp(path_end, progress)

	draw_line(path_start, current_pos, C_CYAN, 12.0)


func _draw_school() -> void:
	var school_pos: Vector2 = path_end + Vector2(-48, -115)

	draw_rect(Rect2(school_pos, Vector2(105, 85)), C_BEIGE)
	draw_rect(Rect2(school_pos, Vector2(105, 85)), C_BLUE, false, 4.0)

	var roof_points := PackedVector2Array([
		school_pos + Vector2(-10, 0),
		school_pos + Vector2(52, -48),
		school_pos + Vector2(115, 0)
	])

	draw_colored_polygon(roof_points, C_RED)

	draw_rect(Rect2(school_pos + Vector2(42, 38), Vector2(25, 47)), C_BLUE)

	draw_rect(Rect2(school_pos + Vector2(15, 25), Vector2(22, 20)), C_CYAN)
	draw_rect(Rect2(school_pos + Vector2(70, 25), Vector2(22, 20)), C_CYAN)

	draw_string(
		ThemeDB.fallback_font,
		school_pos + Vector2(18, 72),
		"ESCUELA",
		HORIZONTAL_ALIGNMENT_LEFT,
		80,
		16,
		C_BLUE
	)


func _draw_character() -> void:
	var progress: float = clampf(float(success_count) / float(required_hits_to_win), 0.0, 1.0)
	var pos: Vector2 = path_start.lerp(path_end, progress)

	draw_ellipse(pos + Vector2(0, 35), 25.0, 7.0, Color(0, 0, 0, 0.20))

	draw_circle(pos + Vector2(0, -38), 17, Color("#F2C9A0"))

	draw_rect(Rect2(pos + Vector2(-15, -22), Vector2(30, 45)), C_BLUE)

	draw_rect(Rect2(pos + Vector2(-24, -15), Vector2(12, 30)), C_ORANGE)

	draw_line(pos + Vector2(-8, 22), pos + Vector2(-13, 45), C_DARK, 5.0)
	draw_line(pos + Vector2(8, 22), pos + Vector2(13, 45), C_DARK, 5.0)

	draw_line(pos + Vector2(-15, -8), pos + Vector2(-30, 8), C_DARK, 4.0)
	draw_line(pos + Vector2(15, -8), pos + Vector2(30, 8), C_DARK, 4.0)
