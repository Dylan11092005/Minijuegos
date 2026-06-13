# Hud.gd — usa DisplayServer para tamaño real de ventana

extends CanvasLayer

# ── Paleta ────────────────────────────────────────────────────────────────────
const C_BEIGE  = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE   = Color("#3E5F8F")
const C_CYAN   = Color("#39B5E6")
const C_WHITE  = Color("#FFFFFF")
const C_RED    = Color("#D63A3A")

var _sw: float
var _sh: float

const BAR_H             = 28
const BAR_MARGIN_BOTTOM = 40
const BAR_MARGIN_SIDE   = 420

const BUTTON_SIZE = 140.0
const ICON_SIZE   = 48.0

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


# ── Banner de terremoto ───────────────────────────────────────────────────────
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


# ── Barra de progreso con iconos de inicio y meta ────────────────────────────
func _build_progress_bar() -> void:
	var bar_w = _sw - (BAR_MARGIN_SIDE * 2.0)
	var bar_x = BAR_MARGIN_SIDE
	var bar_y = _sh - BAR_MARGIN_BOTTOM - BAR_H

	# ── Icono INICIO (izquierda) ──
	var icon_start_tex = load("res://minigame_earthquake/assets/ui/start.png") as Texture2D
	if icon_start_tex:
		var icon_start = TextureRect.new()
		icon_start.texture      = icon_start_tex
		icon_start.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_start.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_start.size         = Vector2(ICON_SIZE, ICON_SIZE)
		icon_start.position     = Vector2(
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

	# ── Icono META (derecha) ──
	var icon_goal_tex = load("res://minigame_earthquake/assets/ui/goal.png") as Texture2D
	if icon_goal_tex:
		var icon_goal = TextureRect.new()
		icon_goal.texture      = icon_goal_tex
		icon_goal.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_goal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_goal.size         = Vector2(ICON_SIZE, ICON_SIZE)
		icon_goal.position     = Vector2(
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
		lbl_right.size     = Vector2(60, 20)
		lbl_right.position = Vector2(bar_x + bar_w - 60, bar_y - 20)
		add_child(lbl_right)

	# ── Barra de progreso ──
	_progress_bar           = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value     = 0
	_progress_bar.show_percentage = false
	_progress_bar.size     = Vector2(bar_w, BAR_H)
	_progress_bar.position = Vector2(bar_x, bar_y)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color                   = C_BEIGE
	bg_style.border_color               = C_ORANGE
	bg_style.border_width_left          = 2
	bg_style.border_width_right         = 2
	bg_style.border_width_top           = 2
	bg_style.border_width_bottom        = 2
	bg_style.corner_radius_top_left     = BAR_H
	bg_style.corner_radius_top_right    = BAR_H
	bg_style.corner_radius_bottom_left  = BAR_H
	bg_style.corner_radius_bottom_right = BAR_H
	bg_style.content_margin_left   = 3
	bg_style.content_margin_right  = 3
	bg_style.content_margin_top    = 3
	bg_style.content_margin_bottom = 3
	_progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color                   = C_BLUE
	fill_style.corner_radius_top_left     = BAR_H
	fill_style.corner_radius_top_right    = BAR_H
	fill_style.corner_radius_bottom_left  = BAR_H
	fill_style.corner_radius_bottom_right = BAR_H
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	add_child(_progress_bar)


# ── Botón de esconderse: blanco con borde rojo, texto arriba e icono abajo ───
func _build_hold_button() -> void:
	var btn_pos = Vector2(
		_sw - BUTTON_SIZE - 60.0,
		(_sh - BUTTON_SIZE) * 0.5
	)

	# Fondo circular blanco con borde rojo y sombra suave
	var shadow = Panel.new()
	shadow.size     = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	shadow.position = btn_pos + Vector2(0, 6)
	shadow.z_index  = -1

	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.18)
	shadow_style.corner_radius_top_left     = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_top_right    = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_bottom_left  = int(BUTTON_SIZE / 2.0)
	shadow_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2.0)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	add_child(shadow)

	var panel = Panel.new()
	panel.size     = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	panel.position = btn_pos
	panel.z_index  = 0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color                   = C_WHITE
	panel_style.border_color               = C_RED
	panel_style.border_width_left          = 5
	panel_style.border_width_right         = 5
	panel_style.border_width_top           = 5
	panel_style.border_width_bottom        = 5
	panel_style.corner_radius_top_left     = int(BUTTON_SIZE / 2.0)
	panel_style.corner_radius_top_right    = int(BUTTON_SIZE / 2.0)
	panel_style.corner_radius_bottom_left  = int(BUTTON_SIZE / 2.0)
	panel_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# Contenedor VBox para apilar icono + texto, centrado dentro del círculo
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size      = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	vbox.position  = btn_pos
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icono push
	var push_tex = load("res://minigame_earthquake/assets/ui/push.png") as Texture2D
	var icon_rect = TextureRect.new()
	if push_tex:
		icon_rect.texture = push_tex
	icon_rect.expand_mode    = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.custom_minimum_size   = Vector2(0, 64)
	vbox.add_child(icon_rect)

	# Etiqueta "Esconderse"
	var lbl = Label.new()
	lbl.text                  = "Esconderse"
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", C_RED)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl)

	add_child(vbox)

	# Botón invisible encima de todo para capturar los eventos táctiles/click
	_hold_button          = Button.new()
	_hold_button.text     = ""
	_hold_button.flat     = true
	_hold_button.size     = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	_hold_button.position = btn_pos
	_hold_button.z_index  = 10

	# Estilo transparente (el Panel de abajo da el aspecto visual)
	var transparent := StyleBoxEmpty.new()
	_hold_button.add_theme_stylebox_override("normal",  transparent)
	_hold_button.add_theme_stylebox_override("hover",   transparent)
	_hold_button.add_theme_stylebox_override("pressed", transparent)
	_hold_button.add_theme_stylebox_override("focus",   transparent)

	add_child(_hold_button)
	_hold_button.button_down.connect(_on_hold_down)
	_hold_button.button_up.connect(_on_hold_up)

	# Guardar referencias para animación al presionar
	_hold_button.set_meta("panel", panel)
	_hold_button.set_meta("panel_style", panel_style)
	_hold_button.set_meta("vbox", vbox)
	_hold_button.set_meta("base_pos", btn_pos)


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
	# Feedback visual: fondo gris + efecto "presionado" (escala + desplazamiento)
	if _hold_button.has_meta("panel_style"):
		var ps = _hold_button.get_meta("panel_style") as StyleBoxFlat
		ps.bg_color = Color("#E0E0E0")

	var panel = _hold_button.get_meta("panel") as Panel
	var vbox  = _hold_button.get_meta("vbox") as VBoxContainer
	var base_pos = _hold_button.get_meta("base_pos") as Vector2

	var offset = Vector2(0, 4)
	panel.position = base_pos + offset
	vbox.position   = base_pos + offset

	var main = get_node_or_null("/root/Main")
	if main and main.has_method("on_hide_button_pressed"):
		main.on_hide_button_pressed()

	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("on_hold_button_pressed"):
		player.on_hold_button_pressed()


func _on_hold_up() -> void:
	# Restaurar fondo blanco y posición original
	if _hold_button.has_meta("panel_style"):
		var ps = _hold_button.get_meta("panel_style") as StyleBoxFlat
		ps.bg_color = C_WHITE

	var panel = _hold_button.get_meta("panel") as Panel
	var vbox  = _hold_button.get_meta("vbox") as VBoxContainer
	var base_pos = _hold_button.get_meta("base_pos") as Vector2

	panel.position = base_pos
	vbox.position   = base_pos

	var main = get_node_or_null("/root/Main")
	if main and main.has_method("on_hide_button_released"):
		main.on_hide_button_released()

	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("on_hold_button_released"):
		player.on_hold_button_released()
