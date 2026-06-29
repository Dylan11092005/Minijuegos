extends Area2D


# =========================================================
# NODES
# =========================================================

var outline_sprite: Sprite2D
var sprite: Sprite2D
var collision_shape: CollisionShape2D


# =========================================================
# VARIABLES
# =========================================================

var board_id: int = 0
var occupied: bool = false


# =========================================================
# COLORS
# =========================================================

const EMPTY_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.42)
const EMPTY_SLOT_COLOR := Color(0.0, 0.0, 0.0, 0.42)
const WRONG_SLOT_COLOR := Color(1.0, 0.1, 0.1, 0.72)

# Color más oscuro para que combine con el puente del fondo.
const PLACED_SLOT_COLOR := Color(0.72, 0.52, 0.33, 1.0)


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = false
	_create_missing_nodes()


# =========================================================
# SETUP
# =========================================================

func setup(p_board_id: int, texture_path: String, p_position: Vector2, p_scale: Vector2):
	_create_missing_nodes()
	
	board_id = p_board_id
	occupied = false
	
	global_position = p_position
	z_index = 18
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		
		outline_sprite.texture = texture
		outline_sprite.scale = p_scale * 1.08
		outline_sprite.modulate = EMPTY_OUTLINE_COLOR
		outline_sprite.z_index = 1
		outline_sprite.visible = true
		
		sprite.texture = texture
		sprite.scale = p_scale
		sprite.modulate = EMPTY_SLOT_COLOR
		sprite.z_index = 2
		sprite.visible = true
		
		var rect := RectangleShape2D.new()
		rect.size = texture.get_size() * p_scale
		collision_shape.shape = rect
	
	visible = true


func _create_missing_nodes():
	outline_sprite = get_node_or_null("OutlineSprite")
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	if not outline_sprite:
		outline_sprite = Sprite2D.new()
		outline_sprite.name = "OutlineSprite"
		add_child(outline_sprite)
	
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)


# =========================================================
# PUBLIC METHODS
# =========================================================

func can_accept(p_board_id: int) -> bool:
	return not occupied and board_id == p_board_id


func place_board():
	occupied = true
	
	# Quita el borde blanco.
	if outline_sprite:
		outline_sprite.visible = false
	
	# La figura gris se convierte en madera colocada.
	if sprite:
		sprite.visible = true
		sprite.modulate = PLACED_SLOT_COLOR
		sprite.z_index = 5


func reset_slot():
	occupied = false
	
	if outline_sprite:
		outline_sprite.visible = true
		outline_sprite.modulate = EMPTY_OUTLINE_COLOR
	
	if sprite:
		sprite.visible = true
		sprite.modulate = EMPTY_SLOT_COLOR
		sprite.z_index = 2


func highlight_wrong():
	if occupied:
		return
	
	if sprite:
		sprite.modulate = WRONG_SLOT_COLOR


func clear_highlight():
	if occupied:
		return
	
	if sprite:
		sprite.modulate = EMPTY_SLOT_COLOR


func get_center_position() -> Vector2:
	return global_position
