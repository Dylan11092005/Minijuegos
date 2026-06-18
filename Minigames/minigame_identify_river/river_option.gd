extends Area2D
class_name RiverOption

signal river_selected(is_different: bool)

enum State { NORMAL, HIGH, DARK, FOAM }

@export var current_state: State = State.NORMAL

var is_different := false
var can_select := true

@onready var sprite_normal: Sprite2D = $SpriteNormal
@onready var sprite_high: Sprite2D = $SpriteHigh
@onready var sprite_dark: Sprite2D = $SpriteDark
@onready var sprite_foam: Sprite2D = $SpriteFoam


func _ready() -> void:
	add_to_group("river_options")
	input_pickable = true
	update_visual()


func setup(new_state: State, new_is_different: bool) -> void:
	current_state = new_state
	is_different = new_is_different
	can_select = true
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
	update_visual()


func set_high() -> void:
	current_state = State.HIGH
	is_different = true
	can_select = true
	update_visual()


func set_dark() -> void:
	current_state = State.DARK
	is_different = true
	can_select = true
	update_visual()


func set_foam() -> void:
	current_state = State.FOAM
	is_different = true
	can_select = true
	update_visual()


func disable_selection() -> void:
	can_select = false


func try_select() -> void:
	if not can_select:
		return

	river_selected.emit(is_different)


func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_select()
