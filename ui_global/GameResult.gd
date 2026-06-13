extends CanvasLayer
class_name GameResult


# =========================================================
# CONSTANTS
# =========================================================

const FONT_PATHS := [
	"res://assets/fonts/Montserrat.ttf",
	"res://assets/fonts/Montserrat-VariableFont_wght.ttf"
]

const COLOR_CYAN := Color("#30C0F0")
const COLOR_DARK_BLUE := Color("#406080")
const COLOR_ORANGE := Color("#E08040")
const COLOR_LIGHT_BLUE := Color("#C0E0FF")
const COLOR_BEIGE := Color("#F0D0A0")
const COLOR_WHITE := Color("#F5F5F5")

const PANEL_SIZE := Vector2(660, 280)
const LABEL_SIZE := Vector2(600, 125)
const BUTTON_SIZE := Vector2(260, 58)

const WIN_MESSAGE := "¡Felicidades!\nGanaste el juego"
const LOSE_MESSAGE := "¡Qué mal!\nPerdiste"
const BACK_BUTTON_TEXT := "Volver al menú"


# =========================================================
# EXPORTED VARIABLES
# =========================================================

@export var menu_path := "res://MenuPrincipal.tscn"


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var current_message := ""


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var container = $Container
@onready var background_panel = $Container/BackgroundPanel
@onready var message_label = $Container/LabelMessage
@onready var back_button = $Container/BackButton
@onready var win_audio = $WinSound
@onready var lose_audio = $LoseSound


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready():
	visible = false
	
	_setup_container()
	_setup_panel()
	_setup_label()
	_setup_button()
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)


# =========================================================
# PUBLIC METHODS
# =========================================================

func show_win():
	current_message = WIN_MESSAGE
	message_label.text = current_message
	message_label.add_theme_color_override("font_color", COLOR_DARK_BLUE)
	visible = true
	
	if win_audio:
		win_audio.volume_db = -5
		win_audio.play()


func show_lose():
	current_message = LOSE_MESSAGE
	message_label.text = current_message
	message_label.add_theme_color_override("font_color", COLOR_DARK_BLUE)
	visible = true
	
	if lose_audio:
		lose_audio.volume_db = -10
		lose_audio.play()


func hide_result():
	visible = false


# Alias para que no se rompa código viejo.
func mostrar_ganaste():
	show_win()


func mostrar_perdiste():
	show_lose()


func ocultar():
	hide_result()


# =========================================================
# PRIVATE METHODS
# =========================================================

func _setup_container():
	container.position = Vector2.ZERO
	container.size = get_viewport().get_visible_rect().size
	container.mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_panel():
	var screen := get_viewport().get_visible_rect().size
	
	background_panel.custom_minimum_size = PANEL_SIZE
	background_panel.position = Vector2(
		(screen.x - PANEL_SIZE.x) / 2,
		(screen.y - PANEL_SIZE.y) / 2
	)
	background_panel.size = PANEL_SIZE
	
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BEIGE
	style.border_color = COLOR_ORANGE
	
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_width_top = 8
	style.border_width_bottom = 8
	
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 8)
	
	background_panel.add_theme_stylebox_override("panel", style)


func _setup_label():
	var screen := get_viewport().get_visible_rect().size
	
	message_label.position = Vector2(
		(screen.x - LABEL_SIZE.x) / 2,
		(screen.y - LABEL_SIZE.y) / 2 - 20
	)
	
	message_label.size = LABEL_SIZE
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Letras más grandes, gruesas y bonitas
	message_label.add_theme_color_override("font_color", COLOR_DARK_BLUE)
	message_label.add_theme_color_override("font_outline_color", COLOR_WHITE)
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18))
	
	message_label.add_theme_constant_override("outline_size", 3)
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	message_label.add_theme_font_size_override("font_size", 46)
	
	var font = _load_font()
	if font:
		message_label.add_theme_font_override("font", font)


func _setup_button():
	var screen := get_viewport().get_visible_rect().size
	
	back_button.text = BACK_BUTTON_TEXT
	back_button.position = Vector2(
		(screen.x - BUTTON_SIZE.x) / 2,
		(screen.y / 2) + 88
	)
	back_button.size = BUTTON_SIZE
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = COLOR_CYAN
	style_normal.border_color = COLOR_DARK_BLUE
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 4
	style_normal.corner_radius_top_left = 18
	style_normal.corner_radius_top_right = 18
	style_normal.corner_radius_bottom_left = 18
	style_normal.corner_radius_bottom_right = 18
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = COLOR_LIGHT_BLUE
	style_hover.border_color = COLOR_DARK_BLUE
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 4
	style_hover.corner_radius_top_left = 18
	style_hover.corner_radius_top_right = 18
	style_hover.corner_radius_bottom_left = 18
	style_hover.corner_radius_bottom_right = 18
	
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = COLOR_DARK_BLUE
	style_pressed.border_color = COLOR_CYAN
	style_pressed.border_width_left = 4
	style_pressed.border_width_right = 4
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 4
	style_pressed.corner_radius_top_left = 18
	style_pressed.corner_radius_top_right = 18
	style_pressed.corner_radius_bottom_left = 18
	style_pressed.corner_radius_bottom_right = 18
	
	back_button.add_theme_stylebox_override("normal", style_normal)
	back_button.add_theme_stylebox_override("hover", style_hover)
	back_button.add_theme_stylebox_override("pressed", style_pressed)
	
	back_button.add_theme_color_override("font_color", COLOR_WHITE)
	back_button.add_theme_color_override("font_hover_color", COLOR_DARK_BLUE)
	back_button.add_theme_color_override("font_pressed_color", COLOR_WHITE)
	back_button.add_theme_color_override("font_outline_color", COLOR_DARK_BLUE)
	
	back_button.add_theme_constant_override("outline_size", 2)
	back_button.add_theme_font_size_override("font_size", 24)
	
	var font = _load_font()
	if font:
		back_button.add_theme_font_override("font", font)


func _load_font():
	for font_path in FONT_PATHS:
		if ResourceLoader.exists(font_path):
			return load(font_path)
	
	return null


func _on_back_button_pressed():
	get_tree().change_scene_to_file(menu_path)
