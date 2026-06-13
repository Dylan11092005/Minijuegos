extends CanvasLayer

signal time_up

const C_BEIGE  = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE   = Color("#3E5F8F")
const C_CYAN   = Color("#39B5E6")
const C_WHITE  = Color("#FFFFFF")
const C_RED    = Color("#D63A3A")

const C_PHASE_BLUE   = Color("#3E5F8F")
const C_PHASE_ORANGE = Color("#E07820")
const C_PHASE_RED    = Color("#D63A3A")

var panel: Panel
var hbox: HBoxContainer

var label_before:  Label
var label_time:    Label
var label_after:   Label

var clock: Control

var total_time     := 60.0
var remaining_time := 60.0
var active         := false

var rot_minutes := 0.0
var rot_seconds := 0.0

var active_color := C_PHASE_BLUE

# ── Audio ──────────────────────────────────────────────────────────────────────
var time_audio: AudioStreamPlayer

# Normal segment: second 0 to 10, constant loop
const LOOP_NORMAL_START: float = 0.0
const LOOP_NORMAL_END:   float = 10.0

# Urgent segment: second 10 to 12, when <= 2 seconds remain
const LOOP_URGENT_START: float = 10.0
const LOOP_URGENT_END:   float = 12.0

# How many game seconds remain before switching to urgent segment
const URGENT_THRESHOLD: float = 2.0

var _urgent_phase: bool = false
# ──────────────────────────────────────────────────────────────────────────────

func _ready():
	layer   = 10
	visible = false
	_build_ui()
	await get_tree().process_frame
	_find_audio()

func _find_audio():
	time_audio = get_parent().get_node_or_null("TimeSound")

	if time_audio == null:
		time_audio = get_tree().current_scene.find_child("TimeSound", true, false)

	if time_audio == null:
		push_warning("TimerUI: no se encontró el nodo TimeSound")
		return

	print("TimerUI: TimeSound encontrado → ", time_audio.get_path())

func _build_ui():
	panel          = Panel.new()
	panel.position = Vector2(20, 20)
	panel.size     = Vector2(430, 60)

	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color                   = C_BEIGE
	style.border_color               = C_ORANGE
	style.border_width_left          = 4
	style.border_width_right         = 4
	style.border_width_top           = 4
	style.border_width_bottom        = 4
	style.corner_radius_top_left     = 22
	style.corner_radius_top_right    = 22
	style.corner_radius_bottom_left  = 22
	style.corner_radius_bottom_right = 22

	panel.add_theme_stylebox_override("panel", style)

	hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left   = 12
	hbox.offset_right  = -12
	hbox.offset_top    = 6
	hbox.offset_bottom = -6
	hbox.add_theme_constant_override("separation", 10)

	panel.add_child(hbox)

	label_before                    = Label.new()
	label_before.visible            = false
	label_before.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_before.add_theme_font_size_override("font_size", 22)
	label_before.add_theme_color_override("font_color", active_color)

	hbox.add_child(label_before)

	clock = Control.new()
	clock.custom_minimum_size = Vector2(48, 48)

	hbox.add_child(clock)

	clock.draw.connect(_draw_clock)

	label_time                      = Label.new()
	label_time.text                 = "60"
	label_time.custom_minimum_size  = Vector2(0, 0)
	label_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_time.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label_time.add_theme_font_size_override("font_size", 30)
	label_time.add_theme_color_override("font_color", active_color)

	hbox.add_child(label_time)

	label_after                    = Label.new()
	label_after.visible            = false
	label_after.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_after.add_theme_font_size_override("font_size", 22)
	label_after.add_theme_color_override("font_color", active_color)

	hbox.add_child(label_after)

func set_tamano_panel(width: float, height: float):
	panel.size = Vector2(width, height)

func _draw_clock():
	var center = Vector2(24, 24)
	var radius  = 22.0

	clock.draw_circle(center, radius, Color("#D8ECF6"))
	clock.draw_arc(center, radius, 0.0, TAU, 64, active_color, 3.0, true)

	for i in range(12):
		var ang = i * TAU / 12.0 - PI / 2.0
		var p1  = center + Vector2(cos(ang), sin(ang)) * 17
		var p2  = center + Vector2(cos(ang), sin(ang)) * 21
		clock.draw_line(p1, p2, active_color, 1.5)

	var ang_min = rot_minutes - PI / 2
	var pmin    = center + Vector2(cos(ang_min), sin(ang_min)) * 12
	clock.draw_line(center, pmin, C_ORANGE, 3.0)

	var ang_sec = rot_seconds - PI / 2
	var psec    = center + Vector2(cos(ang_sec), sin(ang_sec)) * 18
	clock.draw_line(center, psec, active_color, 2.0)

	clock.draw_circle(center, 3, C_WHITE)

func _process(delta):
	if !active:
		return

	remaining_time -= delta

	if remaining_time < 0.0:
		remaining_time = 0.0

	_update_display()
	_animate_hands()
	_manage_audio()
	clock.queue_redraw()

	if remaining_time <= 0.0:
		active = false
		_stop_audio()
		time_up.emit()

func iniciar(p_time: float, p_text_before := "", p_text_after := ""):
	total_time     = p_time
	remaining_time = p_time
	active         = true
	visible        = true

	_urgent_phase = false
	_stop_audio()

	label_before.text    = p_text_before
	label_before.visible = p_text_before != ""

	label_after.text    = p_text_after
	label_after.visible = p_text_after != ""

	# Start normal loop from the beginning
	if time_audio != null:
		time_audio.play(LOOP_NORMAL_START)

	_update_display()
	_animate_hands()
	clock.queue_redraw()

func detener():
	active = false
	_stop_audio()

func ocultar():
	active  = false
	visible = false
	_stop_audio()

func get_remaining_time():
	return remaining_time

func _get_phase_color() -> Color:
	var fraction: float = remaining_time / total_time
	if fraction > 0.5:
		return C_PHASE_BLUE
	elif fraction > 0.25:
		return C_PHASE_ORANGE
	else:
		return C_PHASE_RED

func _update_display():
	var segs: int = int(ceil(remaining_time))
	var mins: int = segs / 60
	var secs: int = segs % 60

	if mins > 0:
		label_time.text = "%d:%02d" % [mins, secs]
	else:
		label_time.text = str(secs)

	active_color = _get_phase_color()

	label_time.add_theme_color_override("font_color",   active_color)
	label_before.add_theme_color_override("font_color", active_color)
	label_after.add_theme_color_override("font_color",  active_color)

func _animate_hands():
	if total_time <= 0:
		return

	var progress: float  = 1.0 - (remaining_time / total_time)
	rot_minutes          = progress * TAU

	var sec_cycle: float = fmod(total_time - remaining_time, 60.0) / 60.0
	rot_seconds          = sec_cycle * TAU

# ── Audio logic ────────────────────────────────────────────────────────────────

func _manage_audio():
	if time_audio == null:
		return

	var pos: float = time_audio.get_playback_position()

	if remaining_time > URGENT_THRESHOLD:
		# ── NORMAL LOOP: segment 0s → 10s ──
		if _urgent_phase:
			# Back to normal (shouldn't happen, but just in case)
			_urgent_phase = false
			time_audio.stop()
			time_audio.play(LOOP_NORMAL_START)
		elif pos >= LOOP_NORMAL_END or not time_audio.playing:
			# Reached end of segment, loop back
			time_audio.stop()
			time_audio.play(LOOP_NORMAL_START)

	else:
		# ── URGENT LOOP: segment 10s → 12s ──
		if not _urgent_phase:
			_urgent_phase = true
			time_audio.stop()
			time_audio.play(LOOP_URGENT_START)
		elif pos >= LOOP_URGENT_END or not time_audio.playing:
			# Reached end of urgent segment, repeat
			time_audio.stop()
			time_audio.play(LOOP_URGENT_START)

func _stop_audio():
	if time_audio != null:
		time_audio.stop()
	_urgent_phase = false
