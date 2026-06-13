class_name GameResult
extends CanvasLayer

@export var menu_path := "res://MenuPrincipal.tscn"

var _color_cyan := Color("#30C0F0")
var _color_dark_blue := Color("#406080")
var _color_orange := Color("#E08040")
var _color_light_blue := Color("#C0E0FF")
var _color_beige := Color("#F0D0A0")
var _color_white := Color("#F5F5F5")

var _current_message := ""

@onready var _container: Control = $Container
@onready var _background_panel: Panel = $Container/BackgroundPanel
@onready var _message_label: Label = $Container/LabelMessage
@onready var _back_button: Button = $Container/BackButton
@onready var _win_audio: AudioStreamPlayer = $WinSound
@onready var _lose_audio: AudioStreamPlayer = $LoseSound


func _ready():
	visible = false

	_setup_container()
	_setup_panel()
	_setup_label()
	_setup_button()

	_back_button.pressed.connect(_on_back_button_pressed)


func show_win():
	_current_message = "Congratulations,\nyou won the game"
	_message_label.text = _current_message
	_message_label.add_theme_color_override("font_color", _color_dark_blue)

	visible = true

	if _win_audio:
		_win_audio.volume_db = -5
		_win_audio.play()


func show_lose():
	_current_message = "Too bad,\nyou lost"
	_message_label.text = _current_message
	_message_label.add_theme_color_override("font_color", _color_dark_blue)

	visible = true

	if _lose_audio:
		_lose_audio.volume_db = -10
		_lose_audio.play()


func hide_result():
	visible = false


func _setup_container():
	_container.position = Vector2.ZERO
	_container.size = get_viewport().get_visible_rect().size
	_container.mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_panel():
	var screen := get_viewport().get_visible_rect().size

	_background_panel.custom_minimum_size = Vector2(660, 280)
	_background_panel.position = Vector2(
		(screen.x - 660) / 2,
		(screen.y - 280) / 2
	)
	_background_panel.size = Vector2(660, 280)

	var style := StyleBoxFlat.new()
	style.bg_color = _color_beige
	style.border_color = _color_orange

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

	_background_panel.add_theme_stylebox_override("panel", style)


func _setup_label():
	var screen := get_viewport().get_visible_rect().size

	_message_label.position = Vector2(
		(screen.x - 600) / 2,
		(screen.y - 120) / 2 - 15
	)

	_message_label.size = Vector2(600, 120)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_message_label.add_theme_color_override("font_color", _color_dark_blue)
	_message_label.add_theme_font_size_override("font_size", 38)

	var font = load("res://assets/fonts/Montserrat.ttf")
	if font:
		_message_label.add_theme_font_override("font", font)


func _setup_button():
	var screen := get_viewport().get_visible_rect().size

	_back_button.text = "Back to menu"
	_back_button.position = Vector2(
		(screen.x - 240) / 2,
		(screen.y / 2) + 90
	)
	_back_button.size = Vector2(240, 55)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = _color_cyan
	style_normal.border_color = _color_dark_blue
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 4
	style_normal.corner_radius_top_left = 18
	style_normal.corner_radius_top_right = 18
	style_normal.corner_radius_bottom_left = 18
	style_normal.corner_radius_bottom_right = 18

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = _color_light_blue
	style_hover.border_color = _color_dark_blue
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 4
	style_hover.corner_radius_top_left = 18
	style_hover.corner_radius_top_right = 18
	style_hover.corner_radius_bottom_left = 18
	style_hover.corner_radius_bottom_right = 18

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = _color_dark_blue
	style_pressed.border_color = _color_cyan
	style_pressed.border_width_left = 4
	style_pressed.border_width_right = 4
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 4
	style_pressed.corner_radius_top_left = 18
	style_pressed.corner_radius_top_right = 18
	style_pressed.corner_radius_bottom_left = 18
	style_pressed.corner_radius_bottom_right = 18

	_back_button.add_theme_stylebox_override("normal", style_normal)
	_back_button.add_theme_stylebox_override("hover", style_hover)
	_back_button.add_theme_stylebox_override("pressed", style_pressed)

	_back_button.add_theme_color_override("font_color", _color_white)
	_back_button.add_theme_color_override("font_hover_color", _color_dark_blue)
	_back_button.add_theme_color_override("font_pressed_color", _color_white)
	_back_button.add_theme_font_size_override("font_size", 22)

	var font = load("res://assets/fonts/Montserrat.ttf")
	if font:
		_back_button.add_theme_font_override("font", font)


func _on_back_button_pressed():
	get_tree().change_scene_to_file(menu_path)
