# Hud.gd — usa DisplayServer para tamaño real de ventana

extends CanvasLayer

# ── Paleta ────────────────────────────────────────────────────────────────────

const C_BEIGE = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE = Color("#3E5F8F")
const C_CYAN = Color("#39B5E6")
const C_WHITE = Color("#FFFFFF")

const C_GREEN = Color("#39A845")
const C_GREEN_DARK = Color("#2C7E35")

const C_RED = Color("#D63A3A")
const C_RED_DARK = Color("#A82A2A")

const C_YELLOW = Color("#F0A92E")
const C_YELLOW_DARK = Color("#C77F18")

const C_GRAY = Color("#777777")
const C_GRAY_DARK = Color("#555555")

var _sw: float
var _sh: float

const BAR_H = 44
const BAR_MARGIN_BOTTOM = 40
const BAR_MARGIN_SIDE = 520

const BUTTON_SIZE = 140.0
const ICON_SIZE = 56.0

var _eq_banner: Node
var _progress_bar: ProgressBar
var _hold_button: Button
var _win_label: Label

var _hold_panel: Panel
var _hold_panel_style: StyleBoxFlat
var _hold_vbox: VBoxContainer
var _hold_label: Label
var _hold_base_pos := Vector2.ZERO
var _current_button_mode := "normal"


func _ready() -> void:
	var win_size = DisplayServer.window_get_size()
	_sw = float(win_size.x)
	_sh = float(win_size.y)

	_build_earthquake_banner()
	_build_progress_bar()
	_build_hold_button()
	_build_win_label()


# ── Banner de terremoto ───────────────────────────────────────────────────────

func _build_earthquake_banner() -> void:
	var tex = load("res://Minigames/minigame_earthquake/assets/ui/earthquake_banner.png") as Texture2D

	if tex:
		var spr = Sprite2D.new()
		spr.texture = tex
		spr.centered = false

		var target_w = _sw * 0.35
		var scale_factor = target_w / tex.get_width()

		spr.scale = Vector2(scale_factor, scale_factor)
		spr.position = Vector2((_sw - target_w) * 0.5, 4)
		spr.z_index = 10
		spr.visible = false

		add_child(spr)

		_eq_banner = spr
	else:
		var banner_w = _sw * 0.35
		var banner_h = 26.0

		var bg = ColorRect.new()
		bg.color = Color(0.85, 0.1, 0.1, 0.92)
		bg.size = Vector2(banner_w, banner_h)
		bg.position = Vector2((_sw - banner_w) * 0.5, 4)
		bg.z_index = 10
		bg.visible = false

		add_child(bg)

		var lbl = Label.new()
		lbl.text = "¡TERREMOTO! — ¡Escóndete bajo la mesa!"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(banner_w, banner_h)
		lbl.position = Vector2((_sw - banner_w) * 0.5, 4)
		lbl.z_index = 11
		lbl.visible = false

		add_child(lbl)

		_eq_banner = bg
		_eq_banner.set_meta("label", lbl)


# ── Barra de progreso ─────────────────────────────────────────────────────────

func _build_progress_bar() -> void:
	var bar_w = _sw - (BAR_MARGIN_SIDE * 2.0)
	var bar_x = BAR_MARGIN_SIDE
	var bar_y = _sh - BAR_MARGIN_BOTTOM - BAR_H

	var icon_start_tex = load("res://Minigames/minigame_earthquake/assets/ui/start.png") as Texture2D

	if icon_start_tex:
		var icon_start = TextureRect.new()
		icon_start.texture = icon_start_tex
		icon_start.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_start.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_start.size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_start.position = Vector2(
			bar_x - ICON_SIZE - 8.0,
			bar_y + (BAR_H - ICON_SIZE) * 0.5
		)

		add_child(icon_start)
	else:
		var lbl_left = Label.new()
		lbl_left.text = "Inicio"
		lbl_left.add_theme_font_size_override("font_size", 14)
		lbl_left.add_theme_color_override("font_color", C_ORANGE)
		lbl_left.position = Vector2(bar_x, bar_y - 20)

		add_child(lbl_left)

	var icon_goal_tex = load("res://Minigames/minigame_earthquake/assets/ui/goal.png") as Texture2D

	if icon_goal_tex:
		var icon_goal = TextureRect.new()
		icon_goal.texture = icon_goal_tex
		icon_goal.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_goal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_goal.size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_goal.position = Vector2(
			bar_x + bar_w + 8.0,
			bar_y + (BAR_H - ICON_SIZE) * 0.5
		)

		add_child(icon_goal)
	else:
		var lbl_right = Label.new()
		lbl_right.text = "Meta"
		lbl_right.add_theme_font_size_override("font_size", 14)
		lbl_right.add_theme_color_override("font_color", C_ORANGE)
		lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_right.size = Vector2(60, 20)
		lbl_right.position = Vector2(bar_x + bar_w - 60, bar_y - 20)

		add_child(lbl_right)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	_progress_bar.size = Vector2(bar_w, BAR_H)
	_progress_bar.position = Vector2(bar_x, bar_y)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = C_BEIGE
	bg_style.border_color = C_ORANGE
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = BAR_H
	bg_style.corner_radius_top_right = BAR_H
	bg_style.corner_radius_bottom_left = BAR_H
	bg_style.corner_radius_bottom_right = BAR_H
	bg_style.content_margin_left = 3
	bg_style.content_margin_right = 3
	bg_style.content_margin_top = 3
	bg_style.content_margin_bottom = 3

	_progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = C_BLUE
	fill_style.corner_radius_top_left = BAR_H
	fill_style.corner_radius_top_right = BAR_H
	fill_style.corner_radius_bottom_left = BAR_H
	fill_style.corner_radius_bottom_right = BAR_H

	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	add_child(_progress_bar)


# ── Botón de esconderse ───────────────────────────────────────────────────────

func _build_hold_button() -> void:
	var btn_pos = Vector2(
		_sw - BUTTON_SIZE - 220.0,
		(_sh - BUTTON_SIZE) * 0.5
	)

	_hold_base_pos = btn_pos

	var shadow = Panel.new()
	shadow.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	shadow.position = btn_pos + Vector2(0, 6)
	shadow.z_index = -1

	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.18)
	shadow_style.corner_radius_top_left = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_top_right = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_bottom_left = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2.0)

	shadow.add_theme_stylebox_override("panel", shadow_style)
	add_child(shadow)

	_hold_panel = Panel.new()
	_hold_panel.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	_hold_panel.position = btn_pos
	_hold_panel.z_index = 0

	_hold_panel_style = StyleBoxFlat.new()
	_hold_panel_style.bg_color = C_RED
	_hold_panel_style.border_color = C_WHITE
	_hold_panel_style.border_width_left = 5
	_hold_panel_style.border_width_right = 5
	_hold_panel_style.border_width_top = 5
	_hold_panel_style.border_width_bottom = 5
	_hold_panel_style.corner_radius_top_left = int(BUTTON_SIZE / 2.0)
	_hold_panel_style.corner_radius_top_right = int(BUTTON_SIZE / 2.0)
	_hold_panel_style.corner_radius_bottom_left = int(BUTTON_SIZE / 2.0)
	_hold_panel_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2.0)

	_hold_panel.add_theme_stylebox_override("panel", _hold_panel_style)
	add_child(_hold_panel)

	_hold_vbox = VBoxContainer.new()
	_hold_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hold_vbox.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	_hold_vbox.position = btn_pos
	_hold_vbox.add_theme_constant_override("separation", 2)
	_hold_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var push_tex = load("res://Minigames/minigame_earthquake/assets/ui/push.png") as Texture2D

	var icon_rect = TextureRect.new()

	if push_tex:
		icon_rect.texture = push_tex

	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.custom_minimum_size = Vector2(0, 64)

	_hold_vbox.add_child(icon_rect)

	_hold_label = Label.new()
	_hold_label.text = "Esconderse"
	_hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hold_label.add_theme_font_size_override("font_size", 16)
	_hold_label.add_theme_color_override("font_color", C_WHITE)
	_hold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_hold_vbox.add_child(_hold_label)

	add_child(_hold_vbox)

	_hold_button = Button.new()
	_hold_button.text = ""
	_hold_button.flat = true
	_hold_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	_hold_button.position = btn_pos
	_hold_button.z_index = 10

	var transparent := StyleBoxEmpty.new()
	_hold_button.add_theme_stylebox_override("normal", transparent)
	_hold_button.add_theme_stylebox_override("hover", transparent)
	_hold_button.add_theme_stylebox_override("pressed", transparent)
	_hold_button.add_theme_stylebox_override("focus", transparent)

	add_child(_hold_button)

	_hold_button.button_down.connect(_on_hold_down)
	_hold_button.button_up.connect(_on_hold_up)

	set_hide_button_mode("normal")


func _build_win_label() -> void:
	_win_label = Label.new()
	_win_label.text = ""
	_win_label.add_theme_font_size_override("font_size", 52)
	_win_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.size = Vector2(_sw, 80)
	_win_label.position = Vector2(0, _sh * 0.35)
	_win_label.z_index = 20
	_win_label.visible = false

	add_child(_win_label)


# ── API pública ───────────────────────────────────────────────────────────────

func show_earthquake_banner() -> void:
	_eq_banner.visible = true

	if _eq_banner.has_meta("label"):
		_eq_banner.get_meta("label").visible = true


func hide_earthquake_banner() -> void:
	_eq_banner.visible = false

	if _eq_banner.has_meta("label"):
		_eq_banner.get_meta("label").visible = false


func update_progress(value: float) -> void:
	_progress_bar.value = value * 100.0


func show_win() -> void:
	_win_label.visible = true

	if _hold_button:
		_hold_button.disabled = true


func set_hide_button_mode(mode: String) -> void:
	_current_button_mode = mode

	if _hold_button == null:
		return

	if _hold_panel_style == null:
		return

	match mode:
		"normal":
			_hold_button.disabled = false
			_hold_panel_style.bg_color = C_GREEN

			if _hold_label:
				_hold_label.text = "Avanza"

		"warning":
			_hold_button.disabled = false
			_hold_panel_style.bg_color = C_YELLOW

			if _hold_label:
				_hold_label.text = "Prepárate"

		"earthquake":
			_hold_button.disabled = false
			_hold_panel_style.bg_color = C_RED

			if _hold_label:
				_hold_label.text = "¡Escóndete!"

		"disabled":
			_hold_button.disabled = true
			_hold_panel_style.bg_color = C_GRAY

			if _hold_label:
				_hold_label.text = "Terminado"


# ── Eventos del botón ─────────────────────────────────────────────────────────

func _on_hold_down() -> void:
	if _hold_panel_style:
		match _current_button_mode:
			"normal":
				_hold_panel_style.bg_color = C_GREEN_DARK

			"warning":
				_hold_panel_style.bg_color = C_YELLOW_DARK

			"earthquake":
				_hold_panel_style.bg_color = C_RED_DARK

			"disabled":
				_hold_panel_style.bg_color = C_GRAY_DARK

			_:
				_hold_panel_style.bg_color = C_GREEN_DARK

	var offset = Vector2(0, 4)

	if _hold_panel:
		_hold_panel.position = _hold_base_pos + offset

	if _hold_vbox:
		_hold_vbox.position = _hold_base_pos + offset

	var main = _get_main_node()

	if main and main.has_method("on_hide_button_pressed"):
		main.on_hide_button_pressed()

	var player = _get_player_node()

	if player and player.has_method("on_hold_button_pressed"):
		player.on_hold_button_pressed()


func _on_hold_up() -> void:
	if _hold_panel:
		_hold_panel.position = _hold_base_pos

	if _hold_vbox:
		_hold_vbox.position = _hold_base_pos

	set_hide_button_mode(_current_button_mode)

	var main = _get_main_node()

	if main and main.has_method("on_hide_button_released"):
		main.on_hide_button_released()

	var player = _get_player_node()

	if player and player.has_method("on_hold_button_released"):
		player.on_hold_button_released()


func _get_main_node() -> Node:
	var main = get_node_or_null("/root/Main")

	if main:
		return main

	if get_tree().current_scene:
		return get_tree().current_scene

	return null


func _get_player_node() -> Node:
	var player = get_node_or_null("/root/Main/Player")

	if player:
		return player

	var main = _get_main_node()

	if main:
		return main.get_node_or_null("Player")

	return null
