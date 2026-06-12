extends CanvasLayer

@export var menu_path := "res://MenuPrincipal.tscn"

@onready var container = $Container
@onready var background_panel = $Container/BackgroundPanel
@onready var message_label = $Container/LabelMessage
@onready var back_button = $Container/BtnVolver
@onready var win_audio = $WinSound
@onready var lose_audio = $LoseSound

# Color palette
var color_green := Color("#60B060")
var color_light_green := Color("#80C070")
var color_light_blue := Color("#C0E0FF")
var color_cyan := Color("#30C0F0")
var color_dark_blue := Color("#406080")

var color_brown := Color("#907050")
var color_red := Color("#F02020")
var color_orange := Color("#E08040")
var color_yellow := Color("#FFF020")
var color_skin := Color("#E0B080")

var color_blue_gray := Color("#A0B0C0")
var color_beige := Color("#F0D0A0")
var color_white := Color("#F5F5F5")
var color_black := Color("#2B2B2B")
var color_gray := Color("#B2B2B2")

var current_message := ""


func _ready():
	visible = false
	
	_setup_container()
	_setup_panel()
	_setup_label()
	_setup_button()
	
	back_button.pressed.connect(_on_back_button_pressed)


func _setup_container():
	container.position = Vector2.ZERO
	container.size = get_viewport().get_visible_rect().size
	container.mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_panel():
	var screen := get_viewport().get_visible_rect().size
	
	background_panel.custom_minimum_size = Vector2(660, 280)
	background_panel.position = Vector2(
		(screen.x - 660) / 2,
		(screen.y - 280) / 2
	)
	background_panel.size = Vector2(660, 280)
	
	var style := StyleBoxFlat.new()
	style.bg_color = color_beige
	style.border_color = color_orange
	
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_width_top = 8
	style.border_width_bottom = 8
	
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	
	background_panel.add_theme_stylebox_override("panel", style)


func _setup_label():
	var screen := get_viewport().get_visible_rect().size
	
	message_label.position = Vector2(
		(screen.x - 600) / 2,
		(screen.y - 120) / 2 - 15
	)
	
	message_label.size = Vector2(600, 120)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	message_label.add_theme_color_override("font_color", color_dark_blue)
	message_label.add_theme_font_size_override("font_size", 38)
	
	var font = load("res://assets/fonts/Montserrat.ttf")
	if font:
		message_label.add_theme_font_override("font", font)


func _setup_button():
	var screen := get_viewport().get_visible_rect().size
	
	back_button.text = "Volver al menú"
	back_button.position = Vector2(
		(screen.x - 240) / 2,
		(screen.y / 2) + 90
	)
	back_button.size = Vector2(240, 55)
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = color_cyan
	style_normal.border_color = color_dark_blue
	
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 4
	
	style_normal.corner_radius_top_left = 18
	style_normal.corner_radius_top_right = 18
	style_normal.corner_radius_bottom_left = 18
	style_normal.corner_radius_bottom_right = 18
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = color_light_blue
	style_hover.border_color = color_dark_blue
	
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 4
	
	style_hover.corner_radius_top_left = 18
	style_hover.corner_radius_top_right = 18
	style_hover.corner_radius_bottom_left = 18
	style_hover.corner_radius_bottom_right = 18
	
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = color_dark_blue
	style_pressed.border_color = color_cyan
	
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
	
	back_button.add_theme_color_override("font_color", color_white)
	back_button.add_theme_color_override("font_hover_color", color_dark_blue)
	back_button.add_theme_color_override("font_pressed_color", color_white)
	back_button.add_theme_font_size_override("font_size", 22)
	
	var font = load("res://assets/fonts/Montserrat.ttf")
	if font:
		back_button.add_theme_font_override("font", font)


func mostrar_ganaste():
	current_message = "Felicidades,\nganaste el juego"
	message_label.text = current_message
	message_label.add_theme_color_override("font_color", color_dark_blue)
	visible = true
	win_audio.volume_db = -5
	win_audio.play()


func mostrar_perdiste():
	current_message = "Qué mal,\nperdiste"
	message_label.text = current_message
	message_label.add_theme_color_override("font_color", color_dark_blue)
	visible = true
	lose_audio.volume_db = -10
	lose_audio.play()


func ocultar():
	visible = false


func _on_back_button_pressed():
	get_tree().change_scene_to_file(menu_path)
