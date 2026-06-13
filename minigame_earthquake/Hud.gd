# Hud.gd — usa DisplayServer para tamaño real de ventana

extends CanvasLayer

var _sw: float
var _sh: float
const BAR_H = 20

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


func _build_earthquake_banner() -> void:
	var tex = load("res://minigame_earthquake/assets/ui/earthquake_banner.png") as Texture2D
	if tex:
		var spr = Sprite2D.new()
		spr.texture  = tex
		spr.centered = false
		spr.scale    = Vector2(_sw / tex.get_width(), _sw / tex.get_width())
		spr.position = Vector2(0, 10)
		spr.z_index  = 10
		spr.visible  = false
		add_child(spr)
		_eq_banner = spr
	else:
		var bg = ColorRect.new()
		bg.color    = Color(0.85, 0.1, 0.1, 0.92)
		bg.size     = Vector2(_sw, 74)
		bg.position = Vector2(0, 10)
		bg.z_index  = 10
		bg.visible  = false
		add_child(bg)

		var lbl = Label.new()
		lbl.text = "¡TERREMOTO! — ¡Escóndete bajo la mesa!"
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.size     = Vector2(_sw, 74)
		lbl.position = Vector2(0, 10)
		lbl.z_index  = 11
		lbl.visible  = false
		add_child(lbl)

		_eq_banner = bg
		_eq_banner.set_meta("label", lbl)


func _build_progress_bar() -> void:
	var bar_y = _sh - BAR_H

	var bar_bg = ColorRect.new()
	bar_bg.color    = Color(0.08, 0.08, 0.08, 0.95)
	bar_bg.size     = Vector2(_sw, BAR_H + 2)
	bar_bg.position = Vector2(0.0, bar_y - 2)
	add_child(bar_bg)

	var lbl_left = Label.new()
	lbl_left.text = "Inicio"
	lbl_left.add_theme_font_size_override("font_size", 12)
	lbl_left.add_theme_color_override("font_color", Color.WHITE)
	lbl_left.position = Vector2(4, bar_y - 16)
	add_child(lbl_left)

	var lbl_right = Label.new()
	lbl_right.text = "Meta"
	lbl_right.add_theme_font_size_override("font_size", 12)
	lbl_right.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	lbl_right.position = Vector2(_sw - 42, bar_y - 16)
	add_child(lbl_right)

	_progress_bar          = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value     = 0
	_progress_bar.show_percentage = false
	_progress_bar.size     = Vector2(_sw, BAR_H)
	_progress_bar.position = Vector2(0.0, bar_y)
	add_child(_progress_bar)


func _build_hold_button() -> void:
	var bar_y = _sh - BAR_H
	_hold_button = Button.new()
	_hold_button.text = "🛡  MANTENER\nPRESIONADO"
	_hold_button.size = Vector2(155, 85)
	_hold_button.position = Vector2(10, bar_y - 95)
	_hold_button.add_theme_font_size_override("font_size", 14)
	add_child(_hold_button)
	# Conectar a Main (lógica de vidas) Y a Player (animación)
	_hold_button.button_down.connect(_on_hold_down)
	_hold_button.button_up.connect(_on_hold_up)


func _build_win_label() -> void:
	_win_label = Label.new()
	_win_label.text = "¡LLEGASTE A LA ZONA SEGURA!"
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
