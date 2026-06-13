# Hud.gd — usa DisplayServer para tamaño real de ventana

extends CanvasLayer

# ── Paleta (igual que TimerUI) ────────────────────────────────────────────────
const C_BEIGE  = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE   = Color("#3E5F8F")
const C_CYAN   = Color("#39B5E6")
const C_WHITE  = Color("#FFFFFF")
const C_RED    = Color("#D63A3A")

var _sw: float
var _sh: float
const BAR_H = 34
const BAR_MARGIN_BOTTOM = 34
const BAR_MARGIN_SIDE   = 500

const BUTTON_SIZE = 160.0

var _eq_banner:    Node
var _progress_bar: ProgressBar
var _hold_button:  Button
var _win_label:    Label


func _ready() -> void:
	var win_size = DisplayServer.window_get_size()
	_sw = float(win_size.x)
	_sh = float(win_size.y)

	_build_earthquake_banner()
	_build_progress_bar()
	_build_hold_button()
	_build_win_label()


# ── Banner de terremoto (más pequeño, arriba y centrado) ──────────────────────
func _build_earthquake_banner() -> void:
	var tex = load("res://minigame_earthquake/assets/ui/earthquake_banner.png") as Texture2D
	if tex:
		var spr = Sprite2D.new()
		spr.texture  = tex
		spr.centered = false
		var target_w = _sw * 0.35
		var scale_factor = target_w / tex.get_width()
		spr.scale    = Vector2(scale_factor, scale_factor)
		spr.position = Vector2((_sw - target_w) * 0.5, 4)
		spr.z_index  = 10
		spr.visible  = false
		add_child(spr)
		_eq_banner = spr
	else:
		var banner_w = _sw * 0.35
		var banner_h = 26.0

		var bg = ColorRect.new()
		bg.color    = Color(0.85, 0.1, 0.1, 0.92)
		bg.size     = Vector2(banner_w, banner_h)
		bg.position = Vector2((_sw - banner_w) * 0.5, 4)
		bg.z_index  = 10
		bg.visible  = false
		add_child(bg)

		var lbl = Label.new()
		lbl.text = "¡TERREMOTO! — ¡Escóndete bajo la mesa!"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.size     = Vector2(banner_w, banner_h)
		lbl.position = Vector2((_sw - banner_w) * 0.5, 4)
		lbl.z_index  = 11
		lbl.visible  = false
		add_child(lbl)

		_eq_banner = bg
		_eq_banner.set_meta("label", lbl)


# ── Barra de progreso (rediseñada) ────────────────────────────────────────────
func _build_progress_bar() -> void:
	var bar_w = _sw - (BAR_MARGIN_SIDE * 2.0)
	var bar_x = BAR_MARGIN_SIDE
	var bar_y = _sh - BAR_MARGIN_BOTTOM - BAR_H

	# Etiqueta "Inicio"
	var lbl_left = Label.new()
	lbl_left.text = "Inicio"
	lbl_left.add_theme_font_size_override("font_size", 13)
	lbl_left.add_theme_color_override("font_color", C_ORANGE)
	lbl_left.position = Vector2(bar_x, bar_y - 18)
	add_child(lbl_left)

	# Etiqueta "Meta"
	var lbl_right = Label.new()
	lbl_right.text = "Meta"
	lbl_right.add_theme_font_size_override("font_size", 13)
	lbl_right.add_theme_color_override("font_color", C_ORANGE)
	lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_right.size     = Vector2(60, 18)
	lbl_right.position = Vector2(bar_x + bar_w - 60, bar_y - 18)
	add_child(lbl_right)

	# Barra de progreso
	_progress_bar           = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value     = 0
	_progress_bar.show_percentage = false
	_progress_bar.size     = Vector2(bar_w, BAR_H)
	_progress_bar.position = Vector2(bar_x, bar_y)

	# Fondo: beige con borde naranja, totalmente redondeado
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color                   = C_BEIGE
	bg_style.border_color               = C_ORANGE
	bg_style.border_width_left          = 3
	bg_style.border_width_right         = 3
	bg_style.border_width_top           = 3
	bg_style.border_width_bottom        = 3
	bg_style.corner_radius_top_left     = BAR_H
	bg_style.corner_radius_top_right    = BAR_H
	bg_style.corner_radius_bottom_left  = BAR_H
	bg_style.corner_radius_bottom_right = BAR_H
	bg_style.content_margin_left   = 3
	bg_style.content_margin_right  = 3
	bg_style.content_margin_top    = 3
	bg_style.content_margin_bottom = 3
	_progress_bar.add_theme_stylebox_override("background", bg_style)

	# Relleno: azul (mismo tono que el reloj), también redondeado
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color                   = C_BLUE
	fill_style.corner_radius_top_left     = BAR_H
	fill_style.corner_radius_top_right    = BAR_H
	fill_style.corner_radius_bottom_left  = BAR_H
	fill_style.corner_radius_bottom_right = BAR_H
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	add_child(_progress_bar)


# ── Botón de esconderse (redondo, rojo, lado derecho, centrado verticalmente) ──
func _build_hold_button() -> void:
	_hold_button = Button.new()
	_hold_button.text = "¡Esconderse!"
	_hold_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	_hold_button.position = Vector2(
		_sw - BUTTON_SIZE - 400.0,
		(_sh - BUTTON_SIZE) * 0.5
	)
	_hold_button.add_theme_font_size_override("font_size", 22)
	_hold_button.add_theme_color_override("font_color", C_WHITE)
	_hold_button.add_theme_color_override("font_focus_color", C_WHITE)
	_hold_button.add_theme_color_override("font_hover_color", C_WHITE)
	_hold_button.add_theme_color_override("font_pressed_color", C_WHITE)
	_hold_button.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hold_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hold_button.clip_text = true

	# Estilo redondo y rojo (normal, hover, pressed)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color                   = C_RED
	normal_style.corner_radius_top_left     = int(BUTTON_SIZE / 2.0)
	normal_style.corner_radius_top_right    = int(BUTTON_SIZE / 2.0)
	normal_style.corner_radius_bottom_left  = int(BUTTON_SIZE / 2.0)
	normal_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2.0)

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = C_RED.lightened(0.1)

	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = C_RED.darkened(0.15)

	_hold_button.add_theme_stylebox_override("normal",  normal_style)
	_hold_button.add_theme_stylebox_override("hover",   hover_style)
	_hold_button.add_theme_stylebox_override("pressed", pressed_style)
	_hold_button.add_theme_stylebox_override("focus",   normal_style)

	add_child(_hold_button)
	# Conectar a Main (lógica de vidas) Y a Player (animación)
	_hold_button.button_down.connect(_on_hold_down)
	_hold_button.button_up.connect(_on_hold_up)


func _build_win_label() -> void:
	_win_label = Label.new()
	_win_label.text = ""
	_win_label.add_theme_font_size_override("font_size", 52)
	_win_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.size     = Vector2(_sw, 80)
	_win_label.position = Vector2(0, _sh * 0.35)
	_win_label.z_index  = 20
	_win_label.visible  = false
	add_child(_win_label)


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
	_win_label.visible    = true
	_hold_button.disabled = true


func _on_hold_down() -> void:
	# Notifica a Main (lógica de vidas/estados)
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("on_hide_button_pressed"):
		main.on_hide_button_pressed()

	# Notifica a Player (animación de esconderse)
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("on_hold_button_pressed"):
		player.on_hold_button_pressed()


func _on_hold_up() -> void:
	# Notifica a Main (lógica de vidas/estados)
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("on_hide_button_released"):
		main.on_hide_button_released()

	# Notifica a Player (animación de esconderse)
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("on_hold_button_released"):
		player.on_hold_button_released()
