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

const EMPTY_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.45)
const EMPTY_SLOT_COLOR := Color(0.0, 0.0, 0.0, 0.45)
const WRONG_SLOT_COLOR := Color(1.0, 0.1, 0.1, 0.70)
const PLACED_SLOT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

const WOOD_BASE_COLOR := Color("#8A4F1F")
const WOOD_BASE_DARK := Color("#4B2A13")
const WOOD_BASE_LIGHT := Color("#C47A32")
const WOOD_SHADOW := Color(0.0, 0.0, 0.0, 0.30)


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = false
	_create_missing_nodes()


func _draw():
	if occupied:
		_draw_repair_wood_under_board()


# =========================================================
# SETUP
# =========================================================

func setup(p_board_id: int, texture_path: String, p_position: Vector2, p_scale: Vector2):
	_create_missing_nodes()
	
	board_id = p_board_id
	occupied = false
	
	global_position = p_position
	z_index = 12
	
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
	queue_redraw()


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
	
	# Se oculta el borde blanco.
	if outline_sprite:
		outline_sprite.visible = false
	
	# El slot gris se convierte en la tabla normal.
	if sprite:
		sprite.visible = true
		sprite.modulate = PLACED_SLOT_COLOR
		sprite.z_index = 5
	
	queue_redraw()


func reset_slot():
	occupied = false
	
	if outline_sprite:
		outline_sprite.visible = true
		outline_sprite.modulate = EMPTY_OUTLINE_COLOR
	
	if sprite:
		sprite.visible = true
		sprite.modulate = EMPTY_SLOT_COLOR
		sprite.z_index = 2
	
	queue_redraw()


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


# =========================================================
# DRAW REPAIR BASE
# =========================================================

func _draw_repair_wood_under_board():
	if not sprite or not sprite.texture:
		return
	
	var texture_size: Vector2 = sprite.texture.get_size() * sprite.scale
	
	var width: float = texture_size.x + 42.0
	var height: float = texture_size.y + 28.0
	
	var shadow_rect := Rect2(
		Vector2(-width * 0.5 + 7.0, -height * 0.5 + 9.0),
		Vector2(width, height)
	)
	
	var wood_rect := Rect2(
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width, height)
	)
	
	# Sombra debajo de la reparación.
	draw_rect(shadow_rect, WOOD_SHADOW, true)
	
	# Base de madera debajo de la tabla.
	draw_rect(wood_rect, WOOD_BASE_COLOR, true)
	
	# Borde oscuro.
	draw_rect(wood_rect, WOOD_BASE_DARK, false, 4.0)
	
	# Líneas para que parezca madera del puente.
	var line_count := 5
	
	for i in range(1, line_count):
		var x: float = lerpf(
			wood_rect.position.x,
			wood_rect.position.x + wood_rect.size.x,
			float(i) / float(line_count)
		)
		
		draw_line(
			Vector2(x, wood_rect.position.y + 6.0),
			Vector2(x, wood_rect.position.y + wood_rect.size.y - 6.0),
			WOOD_BASE_DARK,
			2.0
		)
		
		draw_line(
			Vector2(x + 4.0, wood_rect.position.y + 8.0),
			Vector2(x + 4.0, wood_rect.position.y + wood_rect.size.y - 8.0),
			WOOD_BASE_LIGHT,
			1.2
		)
