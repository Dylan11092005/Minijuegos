extends Area2D
class_name FloatingObject

signal clicked(floating_object)

@export var object_name := "Object"
@export var is_good := true
@export var texture: Texture2D
@export var move_speed := 90.0
@export var sway_amplitude := 12.0
@export var sway_speed := 1.4

const TARGET_SIZE := Vector2(110, 110)

var _time := 0.0
var _base_y := 0.0
var _left_limit := 0.0
var _right_limit := 0.0
var _upper_bound := 0.0
var _lower_bound := 0.0
var _sprite: Sprite2D


func _ready():
	var viewport_size: Vector2 = get_viewport_rect().size

	_left_limit = -TARGET_SIZE.x
	_right_limit = viewport_size.x + TARGET_SIZE.x
	_upper_bound = viewport_size.y / 2.0
	_lower_bound = viewport_size.y - TARGET_SIZE.y / 2.0

	_base_y = position.y

	# Collision shape, built entirely by code
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = TARGET_SIZE
	shape.shape = rect_shape
	add_child(shape)

	# Sprite, built entirely by code
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	add_child(_sprite)
	_fit_sprite_to_size()

	input_pickable = true
	input_event.connect(_on_input_event)


func _fit_sprite_to_size():
	if texture == null:
		return
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x == 0 or tex_size.y == 0:
		return
	var scale_factor: float = min(TARGET_SIZE.x / tex_size.x, TARGET_SIZE.y / tex_size.y)
	_sprite.scale = Vector2(scale_factor, scale_factor)


func _process(delta):
	_time += delta
	position.x += move_speed * delta
	position.y = _base_y + sin(_time * sway_speed) * sway_amplitude

	if position.x > _right_limit:
		_wrap_to_left()


# Instead of disappearing, the object reappears on the left side
# and picks a new random height within the lower half of the screen.
func _wrap_to_left():
	position.x = _left_limit
	_base_y = randf_range(_upper_bound, _lower_bound)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
