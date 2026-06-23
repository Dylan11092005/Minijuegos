extends Area2D
class_name RiverOption

signal river_selected(is_different: bool)

enum State { NORMAL, HIGH, DARK, FOAM }

@export var current_state: State = State.NORMAL

var is_different := false
var can_select := true

var correct_mark: Label = null
var wrong_mark: Label = null

@onready var sprite_normal: Sprite2D = $SpriteNormal
@onready var sprite_high: Sprite2D = $SpriteHigh
@onready var sprite_dark: Sprite2D = $SpriteDark
@onready var sprite_foam: Sprite2D = $SpriteFoam


func _ready() -> void:
	add_to_group("river_options")
	input_pickable = true
	create_marks()
	update_visual()


func create_marks() -> void:
	correct_mark = Label.new()
	correct_mark.name = "CorrectMark"
	correct_mark.text = "✓"
	correct_mark.visible = false
	correct_mark.z_index = 100
	correct_mark.position = Vector2(-35, -60)
	correct_mark.add_theme_font_size_override("font_size", 70)
	correct_mark.add_theme_color_override("font_color", Color("#00FF55"))
	correct_mark.add_theme_color_override("font_shadow_color", Color.BLACK)
	correct_mark.add_theme_constant_override("shadow_offset_x", 4)
	correct_mark.add_theme_constant_override("shadow_offset_y", 4)
	add_child(correct_mark)

	wrong_mark = Label.new()
	wrong_mark.name = "WrongMark"
	wrong_mark.text = "X"
	wrong_mark.visible = false
	wrong_mark.z_index = 100
	wrong_mark.position = Vector2(-35, -60)
	wrong_mark.add_theme_font_size_override("font_size", 65)
	wrong_mark.add_theme_color_override("font_color", Color("#FF2B2B"))
	wrong_mark.add_theme_color_override("font_shadow_color", Color.BLACK)
	wrong_mark.add_theme_constant_override("shadow_offset_x", 4)
	wrong_mark.add_theme_constant_override("shadow_offset_y", 4)
	add_child(wrong_mark)


func setup(new_state: State, new_is_different: bool) -> void:
	current_state = new_state
	is_different = new_is_different
	can_select = true
	hide_marks()
	update_visual()


func update_visual() -> void:
	sprite_normal.visible = false
	sprite_high.visible = false
	sprite_dark.visible = false
	sprite_foam.visible = false

	if current_state == State.NORMAL:
		sprite_normal.visible = true
	elif current_state == State.HIGH:
		sprite_high.visible = true
	elif current_state == State.DARK:
		sprite_dark.visible = true
	elif current_state == State.FOAM:
		sprite_foam.visible = true


func reset_river() -> void:
	current_state = State.NORMAL
	is_different = false
	can_select = true
	hide_marks()
	update_visual()


func set_high() -> void:
	current_state = State.HIGH
	is_different = true
	can_select = true
	hide_marks()
	update_visual()


func set_dark() -> void:
	current_state = State.DARK
	is_different = true
	can_select = true
	hide_marks()
	update_visual()


func set_foam() -> void:
	current_state = State.FOAM
	is_different = true
	can_select = true
	hide_marks()
	update_visual()


func show_correct_mark() -> void:
	if correct_mark:
		correct_mark.visible = true


func show_wrong_mark() -> void:
	if wrong_mark:
		wrong_mark.visible = true


func hide_marks() -> void:
	if correct_mark:
		correct_mark.visible = false

	if wrong_mark:
		wrong_mark.visible = false


func disable_selection() -> void:
	can_select = false


func try_select() -> void:
	if not can_select:
		return

	if not is_different:
		show_wrong_mark()

	river_selected.emit(is_different)


func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_select()
