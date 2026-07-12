extends Area2D


signal dropped(item)


var item_sprite: Sprite2D
var collision_shape: CollisionShape2D

var item_id: String = ""
var item_name: String = ""
var target_role_id: String = ""

var start_global_position: Vector2 = Vector2.ZERO
var base_sprite_scale: Vector2 = Vector2.ONE

var dragging: bool = false
var locked: bool = false
var mouse_offset: Vector2 = Vector2.ZERO
var idle_time: float = 0.0


func _ready():
	input_pickable = true
	_create_missing_nodes()


func _process(delta):
	if dragging and not locked:
		global_position = get_global_mouse_position() + mouse_offset
	
	if not dragging and not locked:
		_idle_float(delta)


func _unhandled_input(event):
	if locked:
		return
	
	if not dragging:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_drop_item()
	
	if event is InputEventScreenTouch:
		if not event.pressed:
			_drop_item()


func setup(p_item_id: String, p_item_name: String, p_target_role_id: String, texture_path: String, p_position: Vector2, p_scale: Vector2):
	_create_missing_nodes()
	
	item_id = p_item_id
	item_name = p_item_name
	target_role_id = p_target_role_id
	
	global_position = p_position
	start_global_position = p_position
	
	dragging = false
	locked = false
	visible = true
	rotation_degrees = 0
	z_index = 40
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		item_sprite.texture = texture
		
		var target_height: float = p_scale.x
		var scale_factor: float = target_height / texture.get_size().y
		
		item_sprite.scale = Vector2(scale_factor, scale_factor)
		base_sprite_scale = item_sprite.scale
		item_sprite.modulate = Color.WHITE
		
		var rect := RectangleShape2D.new()
		rect.size = texture.get_size() * item_sprite.scale
		collision_shape.shape = rect
	else:
		push_error("No se encontró objeto: " + texture_path)


func _input_event(_viewport, event, _shape_idx):
	if locked:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_drop_item()
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag()
		else:
			_drop_item()


func _start_drag():
	if locked:
		return
	
	dragging = true
	z_index = 100
	mouse_offset = global_position - get_global_mouse_position()
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(item_sprite, "scale", base_sprite_scale * 1.13, 0.12)
	tween.parallel().tween_property(self, "rotation_degrees", -5.0, 0.12)


func _drop_item():
	if not dragging:
		return
	
	dragging = false
	z_index = 40
	dropped.emit(self)


func lock_to_position(target_position: Vector2, target_scale: Vector2 = Vector2.ZERO):
	locked = true
	dragging = false
	z_index = 35
	
	var final_scale := base_sprite_scale
	
	if target_scale != Vector2.ZERO and item_sprite and item_sprite.texture:
		var target_height: float = target_scale.x
		var scale_factor: float = target_height / item_sprite.texture.get_size().y
		final_scale = Vector2(scale_factor, scale_factor)
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", target_position, 0.22)
	tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.22)
	tween.parallel().tween_property(item_sprite, "scale", final_scale * 1.15, 0.14)
	tween.tween_property(item_sprite, "scale", final_scale, 0.12)


func return_to_start():
	dragging = false
	locked = false
	z_index = 40
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", start_global_position, 0.24)
	tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.24)
	tween.parallel().tween_property(item_sprite, "scale", base_sprite_scale, 0.18)


func set_wrong_feedback():
	if not item_sprite:
		return
	
	var original_position := global_position
	
	item_sprite.modulate = Color(1.0, 0.55, 0.55, 1.0)
	
	var tween := create_tween()
	tween.tween_property(self, "global_position", original_position + Vector2(-10, 0), 0.04)
	tween.tween_property(self, "global_position", original_position + Vector2(10, 0), 0.04)
	tween.tween_property(self, "global_position", original_position + Vector2(-7, 0), 0.04)
	tween.tween_property(self, "global_position", original_position, 0.04)
	
	await tween.finished
	
	if not locked:
		item_sprite.modulate = Color.WHITE


func set_disabled(value: bool):
	locked = value


func _idle_float(delta):
	idle_time += delta
	
	var float_offset: float = sin(idle_time * 2.4 + float(item_id.length())) * 3.0
	var tiny_rotation: float = sin(idle_time * 1.7 + float(item_id.length())) * 1.3
	
	global_position.y = start_global_position.y + float_offset
	rotation_degrees = tiny_rotation


func _create_missing_nodes():
	item_sprite = get_node_or_null("ItemSprite")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	if not item_sprite:
		item_sprite = Sprite2D.new()
		item_sprite.name = "ItemSprite"
		add_child(item_sprite)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
