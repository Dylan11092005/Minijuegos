extends Area2D


@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var board_id := 0
var occupied := false


func _ready():
	input_pickable = false


func setup(p_board_id: int, texture_path: String, p_position: Vector2, p_scale: Vector2):
	board_id = p_board_id
	occupied = false
	
	global_position = p_position
	z_index = 5
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		sprite.texture = texture
		sprite.scale = p_scale
		
		var rect := RectangleShape2D.new()
		rect.size = texture.get_size() * p_scale
		collision_shape.shape = rect
	
	# Usa la misma imagen del board, pero oscura.
	sprite.modulate = Color(0, 0, 0, 0.38)


func can_accept(p_board_id: int) -> bool:
	return not occupied and board_id == p_board_id


func place_board():
	occupied = true
	visible = false


func reset_slot():
	occupied = false
	visible = true
	sprite.modulate = Color(0, 0, 0, 0.38)


func highlight_correct():
	sprite.modulate = Color(0.2, 1.0, 0.2, 0.45)


func highlight_wrong():
	sprite.modulate = Color(1.0, 0.1, 0.1, 0.45)


func clear_highlight():
	if not occupied:
		sprite.modulate = Color(0, 0, 0, 0.38)
