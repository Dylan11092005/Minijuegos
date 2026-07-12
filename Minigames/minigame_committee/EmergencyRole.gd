extends Area2D


var character_sprite: Sprite2D
var role_panel: Panel
var role_label: Label
var collision_shape: CollisionShape2D

var role_id: String = ""
var role_name: String = ""
var placed_items_count: int = 0


const PANEL_COLOR := Color("#E5C89E")
const PANEL_BORDER := Color("#E0B080")
const TEXT_COLOR := Color("#3E5F8F")


func _ready():
	input_pickable = false
	_create_missing_nodes()


func setup(p_role_id: String, p_role_name: String, texture_path: String, p_position: Vector2, p_scale: Vector2):
	_create_missing_nodes()
	
	role_id = p_role_id
	role_name = p_role_name
	placed_items_count = 0
	
	global_position = p_position
	z_index = 15
	
	if ResourceLoader.exists(texture_path):
		var texture: Texture2D = load(texture_path)
		character_sprite.texture = texture
		
		# Suaviza la imagen para que no se vea pixelada.
		character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		# p_scale.x ahora representa la altura deseada en píxeles.
		var target_height: float = p_scale.x
		var texture_height: float = texture.get_size().y
		
		if texture_height > 0:
			var scale_factor: float = target_height / texture_height
			character_sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		push_error("No se encontró personaje: " + texture_path)
	
	_setup_role_panel()
	_setup_collision()


func can_accept(item_role_id: String) -> bool:
	return role_id == item_role_id


func register_item():
	placed_items_count += 1


func get_next_item_position() -> Vector2:
	var positions := [
		Vector2(-48, 118),
		Vector2(0, 126),
		Vector2(48, 118),
		Vector2(-25, 162),
		Vector2(25, 162)
	]
	
	var index: int = placed_items_count % positions.size()
	return global_position + positions[index]


func reset_role():
	placed_items_count = 0


func _create_missing_nodes():
	character_sprite = get_node_or_null("CharacterSprite")
	role_panel = get_node_or_null("RolePanel")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	if not character_sprite:
		character_sprite = Sprite2D.new()
		character_sprite.name = "CharacterSprite"
		add_child(character_sprite)
	
	if not role_panel:
		role_panel = Panel.new()
		role_panel.name = "RolePanel"
		add_child(role_panel)
	
	role_label = role_panel.get_node_or_null("RoleLabel")
	
	if not role_label:
		role_label = Label.new()
		role_label.name = "RoleLabel"
		role_panel.add_child(role_label)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)


func _setup_role_panel():
	role_panel.position = Vector2(-92, 158)
	role_panel.size = Vector2(184, 44)
	role_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role_panel.z_index = 20
	
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	
	role_panel.add_theme_stylebox_override("panel", style)
	
	role_label.position = Vector2.ZERO
	role_label.size = role_panel.size
	role_label.text = role_name
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role_label.add_theme_font_size_override("font_size", 22)
	role_label.add_theme_color_override("font_color", TEXT_COLOR)
	role_label.add_theme_color_override("font_outline_color", Color.WHITE)
	role_label.add_theme_constant_override("outline_size", 2)


func _setup_collision():
	var rect := RectangleShape2D.new()
	rect.size = Vector2(230, 330)
	collision_shape.shape = rect
	collision_shape.position = Vector2(0, 25)
