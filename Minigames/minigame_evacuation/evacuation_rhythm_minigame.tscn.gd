extends Node2D
class_name EvacuationRhythmMinigame


@export var time_limit := 40.0
@export var lives_limit := 3

@export var sequence_length := 24
@export var required_hits_to_win := 18

@export var beat_interval := 1.05
@export var note_speed := 340.0
@export var hit_window := 60.0

@export_group("Dificultad según edad")
@export_range(0.3, 1.5, 0.05) var note_speed_multiplier_age_under_7 := 0.60
@export_range(0.3, 1.5, 0.05) var note_speed_multiplier_age_7 := 0.65
@export_range(0.3, 1.5, 0.05) var note_speed_multiplier_age_8 := 0.75
@export_range(0.3, 1.5, 0.05) var note_speed_multiplier_age_9_plus := 1.0

@export_range(0.0, 60.0, 1.0) var extra_time_age_under_7 := 18.0
@export_range(0.0, 60.0, 1.0) var extra_time_age_7 := 14.0
@export_range(0.0, 60.0, 1.0) var extra_time_age_8 := 8.0
@export_range(0.0, 60.0, 1.0) var extra_time_age_9_plus := 0.0


const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE = preload("res://Minigames/ui_global/LivesUi.tscn")

const KIDS_TEXTURE = preload("res://Minigames/minigame_evacuation/assets/Kids.png")
const SCHOOL_TEXTURE = preload("res://Minigames/minigame_evacuation/assets/School.png")

const BACKGROUND_MUSIC = preload("res://Minigames/minigame_evacuation/music/Fon.mp3")
const CORRECT_SOUND = preload("res://Minigames/minigame_evacuation/music/Correct.mp3")
const ERROR_SOUND = preload("res://Minigames/minigame_evacuation/music/Error.mp3")

const GLOBAL_SOUND_VOLUME := -10.0

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
const BUTTON_SIZE := Vector2(130, 78)
const COLUMN_GAP := 82.0

const COLOR_IDS: Array[String] = ["red", "blue", "yellow", "green"]

const COLOR_DATA := {
	"red": {
		"name": "ROJO",
		"key_name": "←",
		"key": KEY_LEFT,
		"color": Color("#D63A3A")
	},
	"blue": {
		"name": "AZUL",
		"key_name": "↓",
		"key": KEY_DOWN,
		"color": Color("#3E5F8F")
	},
	"yellow": {
		"name": "AMARILLO",
		"key_name": "↑",
		"key": KEY_UP,
		"color": Color("#F2C94C")
	},
	"green": {
		"name": "VERDE",
		"key_name": "→",
		"key": KEY_RIGHT,
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
var hit_zone_rect: Panel
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

var background_music_player: AudioStreamPlayer
var correct_sound_player: AudioStreamPlayer
var error_sound_player: AudioStreamPlayer

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var _note_speed_age_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("game_manager")
	randomize()

	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	screen_size = get_viewport_rect().size

	_apply_age_difficulty()

	_calculate_layout()
	_create_layers()
	create_timer()
	create_game_result_panel()
	create_lives_ui()
	create_audio()
	_create_ui()
	_create_timers()
	_create_sequence()
	_setup_damage_effect()

	start_game()


# =========================
# DIFICULTAD SEGÚN EDAD
# =========================

func _apply_age_difficulty() -> void:
	var player_age: int = MinigameData.player_age

	_note_speed_age_multiplier = _get_note_speed_multiplier_for_age(player_age)
	note_speed *= _note_speed_age_multiplier

	var extra_time: float = _get_extra_time_for_age(player_age)
	time_limit += extra_time


func _get_note_speed_multiplier_for_age(age: int) -> float:
	match age:
		8:
			return note_speed_multiplier_age_8
		7:
			return note_speed_multiplier_age_7
		_:
			return note_speed_multiplier_age_under_7 if age < 7 else note_speed_multiplier_age_9_plus


func _get_extra_time_for_age(age: int) -> float:
	match age:
		8:
			return extra_time_age_8
		7:
			return extra_time_age_7
		_:
			return extra_time_age_under_7 if age < 7 else extra_time_age_9_plus


func _calculate_layout() -> void:
	var total_columns_width: float = NOTE_SIZE.x * float(COLOR_IDS.size()) + COLUMN_GAP * float(COLOR_IDS.size() - 1)
	var start_x: float = screen_size.x / 2.0 - total_columns_width / 2.0 + NOTE_SIZE.x / 2.0

	for i in range(COLOR_IDS.size()):
		var color_id: String = COLOR_IDS[i]
		column_x[color_id] = start_x + float(i) * (NOTE_SIZE.x + COLUMN_GAP)

	path_start = Vector2(115, screen_size.y * 0.43)
	path_end = Vector2(screen_size.x - 235, screen_size.y * 0.43)


func _create_layers() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	add_child(ui_layer)

	notes_layer = CanvasLayer.new()
	notes_layer.layer = 45
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
# AUDIO
# =========================

func create_audio() -> void:
	background_music_player = AudioStreamPlayer.new()
	background_music_player.stream = BACKGROUND_MUSIC
	background_music_player.volume_db = GLOBAL_SOUND_VOLUME
	background_music_player.finished.connect(_on_background_music_finished)
	add_child(background_music_player)

	correct_sound_player = AudioStreamPlayer.new()
	correct_sound_player.stream = CORRECT_SOUND
	correct_sound_player.volume_db = GLOBAL_SOUND_VOLUME
	add_child(correct_sound_player)

	error_sound_player = AudioStreamPlayer.new()
	error_sound_player.stream = ERROR_SOUND
	error_sound_player.volume_db = GLOBAL_SOUND_VOLUME
	add_child(error_sound_player)


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


func play_background_music() -> void:
	if background_music_player != null:
		background_music_player.volume_db = GLOBAL_SOUND_VOLUME

		if not background_music_player.playing:
			background_music_player.play()


func stop_background_music() -> void:
	if background_music_player != null:
		background_music_player.stop()


func _on_background_music_finished() -> void:
	if game_active and not already_finished:
		play_background_music()


func play_correct_sound() -> void:
	_play_sound(correct_sound_player)


func play_error_sound() -> void:
	_play_sound(error_sound_player)


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
	game_result_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	_set_game_result_sound_volume()


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
		"Usa las flechas del teclado y presiona el color correcto en la zona de ritmo.",
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

	hit_zone_rect = Panel.new()
	hit_zone_rect.position = Vector2(70, hit_zone_y - 55)
	hit_zone_rect.size = Vector2(screen_size.x - 140, 110)
	hit_zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_zone_rect.add_theme_stylebox_override("panel", _make_hit_zone_stylebox())
	ui_layer.add_child(hit_zone_rect)

	_create_hit_zone_markers()

	hit_zone_label = _make_label(
		"PRESIONA AQUÍ",
		Vector2(0, hit_zone_y - 22),
		Vector2(screen_size.x, 44),
		25,
		C_WHITE
	)

	hit_zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	hit_zone_label.add_theme_constant_override("shadow_offset_x", 3)
	hit_zone_label.add_theme_constant_override("shadow_offset_y", 3)

	feedback_label = _make_label(
		"",
		Vector2(0, screen_size.y - 185),
		Vector2(screen_size.x, 42),
		24,
		C_BLUE
	)

	_create_color_buttons()


func _create_hit_zone_markers() -> void:
	var hit_zone_y: float = _get_hit_zone_y()

	for color_id in COLOR_IDS:
		var info: Dictionary = COLOR_DATA[color_id]
		var base_color: Color = info["color"]

		var marker: Panel = Panel.new()
		marker.position = Vector2(float(column_x[color_id]) - NOTE_SIZE.x / 2.0, hit_zone_y - NOTE_SIZE.y / 2.0)
		marker.size = NOTE_SIZE
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.18)
		style.border_color = Color(base_color.r, base_color.g, base_color.b, 0.95)
		style.set_border_width_all(4)
		style.set_corner_radius_all(16)
		style.shadow_color = Color(0, 0, 0, 0.25)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 3)

		marker.add_theme_stylebox_override("panel", style)
		ui_layer.add_child(marker)


func _make_hit_zone_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.18, 0.30, 0.38)
	style.border_color = C_CYAN
	style.set_border_width_all(5)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 6)
	return style


func _create_color_buttons() -> void:
	var button_y: float = screen_size.y - 118

	for color_id in COLOR_IDS:
		var info: Dictionary = COLOR_DATA[color_id]
		var base_color: Color = info["color"]
		var color_name: String = str(info["name"])
		var key_name: String = str(info["key_name"])

		var button: Button = Button.new()
		button.text = "%s\n%s" % [key_name, color_name]
		button.position = Vector2(float(column_x[color_id]) - BUTTON_SIZE.x / 2.0, button_y)
		button.size = BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE

		button.add_theme_font_size_override("font_size", 23)
		button.add_theme_color_override("font_color", C_WHITE)
		button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.60))
		button.add_theme_constant_override("shadow_offset_x", 2)
		button.add_theme_constant_override("shadow_offset_y", 2)

		button.add_theme_stylebox_override("normal", _make_stylebox(base_color, C_WHITE, 3))
		button.add_theme_stylebox_override("hover", _make_stylebox(base_color.lightened(0.14), C_WHITE, 4))
		button.add_theme_stylebox_override("pressed", _make_stylebox(base_color.darkened(0.18), C_CYAN, 4))

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
# DAMAGE EFFECT
# =========================

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

	play_background_music()

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
	note.add_theme_stylebox_override("panel", _make_note_stylebox(base_color))

	var note_label: Label = Label.new()
	note_label.text = color_name
	note_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 18)
	note_label.add_theme_color_override("font_color", C_WHITE)
	note_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	note_label.add_theme_constant_override("shadow_offset_x", 2)
	note_label.add_theme_constant_override("shadow_offset_y", 2)
	note.add_child(note_label)

	notes_layer.add_child(note)
	active_notes.append(note)


func _make_note_stylebox(base_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = C_WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 5)
	return style


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

	play_correct_sound()

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
	var closest_distance: float = 999999.0
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

	play_error_sound()

	lives -= 1

	if lives < 0:
		lives = 0

	update_lives_ui()
	_play_damage_effect()

	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", C_RED)

	if lives <= 0:
		lose_game()


func _update_progress_ui() -> void:
	progress_label.text = "Avance: %d / %d" % [success_count, required_hits_to_win]


func _check_end_without_enough_hits() -> void:
	if spawned_index >= sequence.size() and active_notes.is_empty() and success_count < required_hits_to_win:
		play_error_sound()
		lose_game()


func _on_time_up() -> void:
	if game_active and not already_finished:
		play_error_sound()
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

	stop_background_music()
	_clear_notes()

	feedback_label.text = "¡Llegaste a la escuela de forma segura!"
	feedback_label.add_theme_color_override("font_color", C_GREEN)

	queue_redraw()

	_set_game_result_sound_volume()

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

	stop_background_music()
	_clear_notes()

	_set_game_result_sound_volume()

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
	stop_background_music()
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
	var road_shadow := Color(0, 0, 0, 0.22)
	var road_border := Color("#6B4A2E")
	var road_color := Color("#A67C52")
	var road_light := Color("#C99A6B")

	draw_line(path_start + Vector2(0, 8), path_end + Vector2(0, 8), road_shadow, 48.0)

	draw_line(path_start, path_end, road_border, 42.0)
	draw_circle(path_start, 21.0, road_border)
	draw_circle(path_end, 21.0, road_border)

	draw_line(path_start, path_end, road_color, 32.0)
	draw_circle(path_start, 16.0, road_color)
	draw_circle(path_end, 16.0, road_color)

	draw_line(path_start + Vector2(0, -5), path_end + Vector2(0, -5), road_light, 6.0)

	var progress: float = clampf(float(success_count) / float(required_hits_to_win), 0.0, 1.0)
	var current_pos: Vector2 = path_start.lerp(path_end, progress)

	draw_line(path_start, current_pos, C_CYAN, 16.0)
	draw_circle(path_start, 8.0, C_CYAN)
	draw_circle(current_pos, 15.0, C_CYAN)
	draw_circle(current_pos, 7.0, C_WHITE)

	for i in range(1, 7):
		var mark_progress: float = float(i) / 7.0
		var mark_pos: Vector2 = path_start.lerp(path_end, mark_progress)
		draw_circle(mark_pos, 4.0, Color(1, 1, 1, 0.55))


func _draw_school() -> void:
	var school_rect: Rect2 = Rect2(path_end + Vector2(-165, -250), Vector2(330, 250))
	draw_texture_rect(SCHOOL_TEXTURE, school_rect, false)


func _draw_character() -> void:
	var progress: float = clampf(float(success_count) / float(required_hits_to_win), 0.0, 1.0)
	var pos: Vector2 = path_start.lerp(path_end, progress)

	draw_ellipse(pos + Vector2(0, 45), 58.0, 14.0, Color(0, 0, 0, 0.20))

	var kids_rect: Rect2 = Rect2(pos + Vector2(-73, -148), Vector2(146, 190))
	draw_texture_rect(KIDS_TEXTURE, kids_rect, false)
