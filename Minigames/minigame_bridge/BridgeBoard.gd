extends Area2D


signal dropped(board)


var sprite: Sprite2D
var collision_shape: CollisionShape2D

var board_id: int = 0
var start_global_position: Vector2 = Vector2.ZERO

var dragging: bool = false
var locked: bool = false
var mouse_offset: Vector2 = Vector2.ZERO


func _ready():
	input_pickable = true
	_create_missing_nodes()


func _process(_delta):
	if dragging and not locked:
		global_position = get_global_mouse_position() + mouse_offset


func _unhandled_input(event):
	if locked:
		return
	
	if not dragging:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_drop_board()
	
	if event is InputEventScreenTouch:
		if not event.pressed:
			_drop_board()


func setup(p_board_id: int, texture_path: String, p_position: Vector2, p_scale: Vector2):
	_create_missing_nodes()
	
	board_id = p_board_id
	global_position = p_position
	start_global_position = p_position
	
	dragging = false
	locked = false
	visible = true
	
	z_index = 40
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		
		sprite.texture = texture
		sprite.scale = p_scale
		sprite.modulate = Color.WHITE
		
		var rect := RectangleShape2D.new()
		rect.size = texture.get_size() * p_scale
		collision_shape.shape = rect
	else:
		push_error("No se encontró la tabla: " + texture_path)


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
	z_index = 40
	dropped.emit(self)


func lock_to_position(target_position: Vector2):
	locked = true
	dragging = false
	z_index = 35
	
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, 0.18)


func lock_and_hide():
	locked = true
	dragging = false
	visible = false


func return_to_start():
	dragging = false
	locked = false
	z_index = 40
	
	var tween := create_tween()
	tween.tween_property(self, "global_position", start_global_position, 0.20)


func set_wrong_feedback():
	if sprite:
		sprite.modulate = Color(1.0, 0.55, 0.55, 1.0)
	
	await get_tree().create_timer(0.20).timeout
	
	if not locked and sprite:
		sprite.modulate = Color.WHITE


func _create_missing_nodes():
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
