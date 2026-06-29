extends Area2D


signal dropped(board)


@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var board_id := 0
var start_global_position := Vector2.ZERO

var dragging := false
var locked := false
var mouse_offset := Vector2.ZERO


func _ready():
	input_pickable = true


func _process(_delta):
	if dragging and not locked:
		global_position = get_global_mouse_position() + mouse_offset


func setup(p_board_id: int, texture_path: String, p_position: Vector2, p_scale: Vector2):
	board_id = p_board_id
	global_position = p_position
	start_global_position = p_position
	locked = false
	dragging = false
	
	z_index = 20
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		sprite.texture = texture
		sprite.scale = p_scale
		
		var rect := RectangleShape2D.new()
		rect.size = texture.get_size() * p_scale
		collision_shape.shape = rect
	
	sprite.modulate = Color.WHITE


func _input_event(_viewport, event, _shape_idx):
	if locked:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_drop_board()
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag()
		else:
			_drop_board()


func _start_drag():
	if locked:
		return
	
	dragging = true
	z_index = 100
	mouse_offset = global_position - get_global_mouse_position()


func _drop_board():
	if not dragging:
		return
	
	dragging = false
	z_index = 20
	dropped.emit(self)


func lock_to_position(target_position: Vector2):
	locked = true
	dragging = false
	z_index = 15
	
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, 0.15)


func return_to_start():
	dragging = false
	locked = false
	z_index = 20
	
	var tween := create_tween()
	tween.tween_property(self, "global_position", start_global_position, 0.20)


func set_correct_feedback():
	sprite.modulate = Color(0.75, 1.0, 0.75, 1.0)


func set_wrong_feedback():
	sprite.modulate = Color(1.0, 0.55, 0.55, 1.0)
	
	await get_tree().create_timer(0.20).timeout
	
	if not locked:
		sprite.modulate = Color.WHITE
