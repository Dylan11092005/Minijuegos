# Hud.gd
# UI del juego:
#   - Banner "¡TERREMOTO!" (usa earthquake_banner.png si existe)
#   - Barra de progreso hacia la zona segura
#   - Botón "MANTENER PRESIONADO" para esconderse

extends CanvasLayer

const SCREEN_W = 1152
const SCREEN_H = 648

var _eq_banner:    Node          # Sprite2D o ColorRect+Label
var _progress_bar: ProgressBar
var _hold_button:  Button
var _win_label:    Label


func _ready() -> void:
	_build_earthquake_banner()
	_build_progress_bar()
	_build_hold_button()
	_build_win_label()


# ---------------------------------------------------------------------------
func _build_earthquake_banner() -> void:
	var tex = load("res://minigame_earthquake/assets/ui/earthquake_banner.png") as Texture2D
	if tex:
		var spr = Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		# Escalar para que ocupe ~todo el ancho, alto proporcional
		var scale_x = float(SCREEN_W) / tex.get_width()
		spr.scale = Vector2(scale_x, scale_x)
		spr.position = Vector2(0, 10)
		spr.z_index = 10
		spr.visible = false
		add_child(spr)
		_eq_banner = spr
	else:
		# Fallback por código
		var bg = ColorRect.new()
		bg.color = Color(0.85, 0.1, 0.1, 0.92)
		bg.size = Vector2(SCREEN_W, 80)
		bg.position = Vector2(0, 10)
		bg.z_index = 10
		bg.visible = false
		add_child(bg)

		var lbl = Label.new()
		lbl.text = "¡TERREMOTO! — ¡Escóndete bajo la mesa!"
		lbl.add_theme_font_size_override("font_size", 38)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(SCREEN_W, 80)
		lbl.position = Vector2(0, 10)
		lbl.z_index = 11
		lbl.visible = false
		add_child(lbl)

		# Guardamos referencia al bg para show/hide (la label es hija del mismo padre)
		_eq_banner = bg
		_eq_banner.set_meta("label", lbl)


# ---------------------------------------------------------------------------
func _build_progress_bar() -> void:
	# Fondo oscuro
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.15, 0.15, 0.15, 0.85)
	bar_bg.size = Vector2(SCREEN_W * 0.70, 28)
	bar_bg.position = Vector2(SCREEN_W * 0.15, SCREEN_H - 52)
	add_child(bar_bg)

	# Etiqueta izquierda
	var lbl_left = Label.new()
	lbl_left.text = "Inicio"
	lbl_left.add_theme_font_size_override("font_size", 14)
	lbl_left.add_theme_color_override("font_color", Color.WHITE)
	lbl_left.position = Vector2(SCREEN_W * 0.15 - 44, SCREEN_H - 52)
	add_child(lbl_left)

	# Etiqueta derecha
	var lbl_right = Label.new()
	lbl_right.text = "Meta"
	lbl_right.add_theme_font_size_override("font_size", 14)
	lbl_right.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	lbl_right.position = Vector2(SCREEN_W * 0.85 + 4, SCREEN_H - 52)
	add_child(lbl_right)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.size = Vector2(SCREEN_W * 0.70, 28)
	_progress_bar.position = Vector2(SCREEN_W * 0.15, SCREEN_H - 52)
	_progress_bar.show_percentage = false
	add_child(_progress_bar)


# ---------------------------------------------------------------------------
func _build_hold_button() -> void:
	_hold_button = Button.new()
	_hold_button.text = "🛡  MANTENER\nPRESIONADO"
	_hold_button.size = Vector2(180, 110)
	_hold_button.position = Vector2(20, SCREEN_H - 170)
	_hold_button.add_theme_font_size_override("font_size", 17)
	add_child(_hold_button)

	_hold_button.button_down.connect(_on_hold_down)
	_hold_button.button_up.connect(_on_hold_up)


# ---------------------------------------------------------------------------
func _build_win_label() -> void:
	_win_label = Label.new()
	_win_label.text = "¡LLEGASTE A LA ZONA SEGURA!"
	_win_label.add_theme_font_size_override("font_size", 52)
	_win_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.size = Vector2(SCREEN_W, 80)
	_win_label.position = Vector2(0, SCREEN_H * 0.35)
	_win_label.z_index = 20
	_win_label.visible = false
	add_child(_win_label)


# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------
func show_earthquake_banner() -> void:
	_eq_banner.visible = true
	if _eq_banner.has_meta("label"):
		_eq_banner.get_meta("label").visible = true

func hide_earthquake_banner() -> void:
	_eq_banner.visible = false
	if _eq_banner.has_meta("label"):
		_eq_banner.get_meta("label").visible = false

func update_progress(value: float) -> void:
	# value: 0.0 → 1.0
	_progress_bar.value = value * 100.0

func show_win() -> void:
	_win_label.visible = true
	_hold_button.disabled = true


# ---------------------------------------------------------------------------
func _on_hold_down() -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.on_hold_button_pressed()

func _on_hold_up() -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player:
		player.on_hold_button_released()
