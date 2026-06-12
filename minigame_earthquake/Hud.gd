extends CanvasLayer

var earthquake_label: Label
var earthquake_bg: ColorRect
var progress_bar: ProgressBar
var hold_button: Button
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_create_earthquake_label()
	_create_progress_bar()
	_create_hold_button()

func _create_earthquake_label() -> void:
	earthquake_bg = ColorRect.new()
	earthquake_bg.color = Color(0.8, 0.1, 0.1, 0.9)
	earthquake_bg.size = Vector2(400, 70)
	earthquake_bg.position = Vector2(screen_size.x * 0.5 - 200, 20)
	earthquake_bg.visible = false
	add_child(earthquake_bg)

	earthquake_label = Label.new()
	earthquake_label.text = "¡TERREMOTO!"
	earthquake_label.add_theme_font_size_override("font_size", 48)
	earthquake_label.add_theme_color_override("font_color", Color.WHITE)
	earthquake_label.position = Vector2(screen_size.x * 0.5 - 180, 28)
	earthquake_label.visible = false
	add_child(earthquake_label)

func _create_progress_bar() -> void:
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.2)
	bar_bg.size = Vector2(screen_size.x * 0.7, 24)
	bar_bg.position = Vector2(screen_size.x * 0.15, screen_size.y - 50)
	add_child(bar_bg)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.size = Vector2(screen_size.x * 0.7, 24)
	progress_bar.position = Vector2(screen_size.x * 0.15, screen_size.y - 50)
	progress_bar.show_percentage = false
	add_child(progress_bar)

func _create_hold_button() -> void:
	hold_button = Button.new()
	hold_button.text = "MANTENER\nPRESIONADO"
	hold_button.size = Vector2(160, 100)
	hold_button.position = Vector2(30, screen_size.y - 160)
	hold_button.add_theme_font_size_override("font_size", 16)
	add_child(hold_button)
	hold_button.button_down.connect(_on_hold_button_down)
	hold_button.button_up.connect(_on_hold_button_up)

func show_earthquake_label() -> void:
	earthquake_label.visible = true
	earthquake_bg.visible = true

func hide_earthquake_label() -> void:
	earthquake_label.visible = false
	earthquake_bg.visible = false

func update_progress(value: float) -> void:
	progress_bar.value = value * 100.0

func _on_hold_button_down() -> void:
	get_node("/root/Main/Player").on_hold_button_pressed()

func _on_hold_button_up() -> void:
	get_node("/root/Main/Player").on_hold_button_released()
