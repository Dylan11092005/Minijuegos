extends Area2D


# =========================================================
# SIGNALS
# =========================================================

signal extinguished(tree)
signal wrong_pressed
signal burned_out(tree)


# =========================================================
# ASSET PATHS
# =========================================================

const TREE_PATH := "res://Minigames/minigame_fire/assets/tree.png"
const BURNED_TREE_PATH := "res://Minigames/minigame_fire/assets/tree_burned.png"
const FIRE_TOP_PATH := "res://Minigames/minigame_fire/assets/fire_1.png"
const FIRE_ROOT_PATH := "res://Minigames/minigame_fire/assets/fire_2.png"
const SMOKE_PATH := "res://Minigames/minigame_fire/assets/smoke.png"


# =========================================================
# GAMEPLAY CONSTANTS
# =========================================================

const BURN_DURATION := 5.0

# Área real para poder presionar el árbol.
# La hice grande porque visualmente el árbol es grande.
const CLICK_SIZE := Vector2(260, 330)


# =========================================================
# VISUAL CONSTANTS
# =========================================================

const TREE_SCALE := Vector2(0.48, 0.48)
const TREE_OUTLINE_SCALE := Vector2(0.54, 0.54)

const BURNED_TREE_SCALE := Vector2(0.48, 0.48)
const BURNED_TREE_OUTLINE_SCALE := Vector2(0.54, 0.54)

const FIRE_TOP_SCALE := Vector2(0.22, 0.22)
const FIRE_ROOT_SCALE := Vector2(0.25, 0.25)
const SMOKE_SCALE := Vector2(0.27, 0.27)

const TREE_MODULATE := Color(1.18, 1.18, 1.18, 1.0)
const OUTLINE_COLOR := Color(0, 0, 0, 0.58)

const SHADOW_COLOR := Color(0, 0, 0, 0.46)
const SHADOW_CENTER := Vector2(0, 130)
const SHADOW_SIZE := Vector2(245, 62)

const HALO_COLOR := Color(1.0, 0.93, 0.58, 0.22)
const HALO_BORDER_COLOR := Color(1.0, 0.70, 0.18, 0.40)

const FIRE_GLOW_COLOR := Color(1.0, 0.42, 0.05, 0.26)


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var tree_outline_sprite: Sprite2D = get_node_or_null("TreeOutlineSprite")
@onready var tree_sprite: Sprite2D = get_node_or_null("TreeSprite")

@onready var burned_outline_sprite: Sprite2D = get_node_or_null("BurnedOutlineSprite")
@onready var burned_tree_sprite: Sprite2D = get_node_or_null("BurnedTreeSprite")

@onready var fire_top_sprite: Sprite2D = get_node_or_null("FireTopSprite")
@onready var fire_root_sprite: Sprite2D = get_node_or_null("FireRootSprite")
@onready var smoke_sprite: Sprite2D = get_node_or_null("SmokeSprite")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


# =========================================================
# VARIABLES
# =========================================================

var burning := false
var disabled := false
var extinguished_safe := false
var burned := false
var burn_timer := 0.0


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = true
	
	_create_missing_nodes()
	_load_textures()
	_setup_sprites()
	_setup_collision()
	reset_tree()
	queue_redraw()


func _process(delta):
	if disabled:
		return
	
	if not burning:
		return
	
	burn_timer += delta
	
	_update_fire_visual()
	queue_redraw()
	
	if burn_timer >= BURN_DURATION:
		_burn_tree()


func _draw():
	_draw_shadow()
	_draw_tree_halo()
	
	if burning:
		_draw_fire_glow()


# =========================================================
# PUBLIC METHODS
# =========================================================

func set_burning(value: bool):
	if disabled:
		return
	
	if burned and value:
		return
	
	burning = value
	
	if burning:
		extinguished_safe = false
		burn_timer = 0.0
		_show_burning_tree()
	else:
		_show_normal_tree()
	
	queue_redraw()


func reset_tree():
	burning = false
	disabled = false
	extinguished_safe = false
	burned = false
	burn_timer = 0.0
	
	_show_normal_tree()
	queue_redraw()


func set_disabled(value: bool):
	disabled = value


func can_catch_fire() -> bool:
	return not burning and not burned and not disabled


func is_burning() -> bool:
	return burning


func is_burned() -> bool:
	return burned


# =========================================================
# INPUT
# =========================================================

func _input_event(_viewport, event, _shape_idx):
	_handle_press_event(event)


func _unhandled_input(event):
	# Esto asegura que se pueda presionar aunque la colisión no agarre perfecto.
	if not _is_mouse_event_inside_tree(event):
		return
	
	_handle_press_event(event)


func _handle_press_event(event):
	if disabled:
		return
	
	if burned:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_press_tree()
	
	if event is InputEventScreenTouch:
		if event.pressed:
			get_viewport().set_input_as_handled()
			_press_tree()


func _is_mouse_event_inside_tree(event) -> bool:
	if disabled:
		return false
	
	if burned:
		return false
	
	if not event is InputEventMouseButton:
		return false
	
	if not event.pressed:
		return false
	
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false
	
	var click_position: Vector2 = get_global_mouse_position()
	var rect_position := global_position - CLICK_SIZE * 0.5
	var click_rect := Rect2(rect_position, CLICK_SIZE)
	
	return click_rect.has_point(click_position)


func _press_tree():
	if burning:
		_extinguish_fire()
	else:
		wrong_pressed.emit()


# =========================================================
# FIRE LOGIC
# =========================================================

func _extinguish_fire():
	burning = false
	extinguished_safe = true
	burn_timer = 0.0
	
	_show_extinguished_tree()
	extinguished.emit(self)
	queue_redraw()


func _burn_tree():
	if burned:
		return
	
	burning = false
	burned = true
	extinguished_safe = true
	disabled = true
	burn_timer = 0.0
	
	_show_burned_tree()
	burned_out.emit(self)
	queue_redraw()


# =========================================================
# CREATE MISSING NODES
# =========================================================

func _create_missing_nodes():
	if not tree_outline_sprite:
		tree_outline_sprite = Sprite2D.new()
		tree_outline_sprite.name = "TreeOutlineSprite"
		add_child(tree_outline_sprite)
	
	if not tree_sprite:
		tree_sprite = Sprite2D.new()
		tree_sprite.name = "TreeSprite"
		add_child(tree_sprite)
	
	if not burned_outline_sprite:
		burned_outline_sprite = Sprite2D.new()
		burned_outline_sprite.name = "BurnedOutlineSprite"
		add_child(burned_outline_sprite)
	
	if not burned_tree_sprite:
		burned_tree_sprite = Sprite2D.new()
		burned_tree_sprite.name = "BurnedTreeSprite"
		add_child(burned_tree_sprite)
	
	if not fire_top_sprite:
		fire_top_sprite = Sprite2D.new()
		fire_top_sprite.name = "FireTopSprite"
		add_child(fire_top_sprite)
	
	if not fire_root_sprite:
		fire_root_sprite = Sprite2D.new()
		fire_root_sprite.name = "FireRootSprite"
		add_child(fire_root_sprite)
	
	if not smoke_sprite:
		smoke_sprite = Sprite2D.new()
		smoke_sprite.name = "SmokeSprite"
		add_child(smoke_sprite)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)


# =========================================================
# SETUP
# =========================================================

func _load_textures():
	if ResourceLoader.exists(TREE_PATH):
		var tree_texture = load(TREE_PATH)
		tree_sprite.texture = tree_texture
		tree_outline_sprite.texture = tree_texture
	
	if ResourceLoader.exists(BURNED_TREE_PATH):
		var burned_texture = load(BURNED_TREE_PATH)
		burned_tree_sprite.texture = burned_texture
		burned_outline_sprite.texture = burned_texture
	
	if ResourceLoader.exists(FIRE_TOP_PATH):
		fire_top_sprite.texture = load(FIRE_TOP_PATH)
	
	if ResourceLoader.exists(FIRE_ROOT_PATH):
		fire_root_sprite.texture = load(FIRE_ROOT_PATH)
	
	if ResourceLoader.exists(SMOKE_PATH):
		smoke_sprite.texture = load(SMOKE_PATH)


func _setup_sprites():
	tree_outline_sprite.position = Vector2.ZERO
	tree_outline_sprite.scale = TREE_OUTLINE_SCALE
	tree_outline_sprite.z_index = 1
	tree_outline_sprite.modulate = OUTLINE_COLOR
	
	tree_sprite.position = Vector2.ZERO
	tree_sprite.scale = TREE_SCALE
	tree_sprite.z_index = 2
	tree_sprite.modulate = TREE_MODULATE
	
	burned_outline_sprite.position = Vector2.ZERO
	burned_outline_sprite.scale = BURNED_TREE_OUTLINE_SCALE
	burned_outline_sprite.z_index = 1
	burned_outline_sprite.modulate = OUTLINE_COLOR
	
	burned_tree_sprite.position = Vector2.ZERO
	burned_tree_sprite.scale = BURNED_TREE_SCALE
	burned_tree_sprite.z_index = 2
	
	fire_top_sprite.position = Vector2(0, -95)
	fire_top_sprite.scale = FIRE_TOP_SCALE
	fire_top_sprite.z_index = 5
	
	fire_root_sprite.position = Vector2(0, 102)
	fire_root_sprite.scale = FIRE_ROOT_SCALE
	fire_root_sprite.z_index = 4
	
	smoke_sprite.position = Vector2(0, -140)
	smoke_sprite.scale = SMOKE_SCALE
	smoke_sprite.z_index = 6


func _setup_collision():
	var rect := RectangleShape2D.new()
	rect.size = CLICK_SIZE
	
	collision_shape.shape = rect
	collision_shape.position = Vector2.ZERO


# =========================================================
# VISUAL STATES
# =========================================================

func _show_normal_tree():
	tree_outline_sprite.visible = true
	tree_sprite.visible = true
	
	burned_outline_sprite.visible = false
	burned_tree_sprite.visible = false
	
	fire_top_sprite.visible = false
	fire_root_sprite.visible = false
	smoke_sprite.visible = false


func _show_burning_tree():
	tree_outline_sprite.visible = true
	tree_sprite.visible = true
	
	burned_outline_sprite.visible = false
	burned_tree_sprite.visible = false
	
	fire_top_sprite.visible = true
	fire_root_sprite.visible = true
	smoke_sprite.visible = false


func _show_extinguished_tree():
	tree_outline_sprite.visible = true
	tree_sprite.visible = true
	
	burned_outline_sprite.visible = false
	burned_tree_sprite.visible = false
	
	fire_top_sprite.visible = false
	fire_root_sprite.visible = false
	smoke_sprite.visible = true
	
	await get_tree().create_timer(0.45).timeout
	
	if not burning and not burned:
		smoke_sprite.visible = false
		extinguished_safe = false
		queue_redraw()


func _show_burned_tree():
	tree_outline_sprite.visible = false
	tree_sprite.visible = false
	
	burned_outline_sprite.visible = true
	burned_tree_sprite.visible = true
	
	fire_top_sprite.visible = false
	fire_root_sprite.visible = false
	smoke_sprite.visible = true


# =========================================================
# VISUAL HELPERS
# =========================================================

func _update_fire_visual():
	var danger: float = clampf(burn_timer / BURN_DURATION, 0.0, 1.0)
	var pulse: float = 1.0 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.06
	
	if fire_top_sprite:
		fire_top_sprite.scale = FIRE_TOP_SCALE * pulse * (1.0 + danger * 0.25)
	
	if fire_root_sprite:
		fire_root_sprite.scale = FIRE_ROOT_SCALE * pulse * (1.0 + danger * 0.20)


func _draw_shadow():
	var points := PackedVector2Array()
	var total_points := 48
	
	for i in range(total_points):
		var angle := TAU * float(i) / float(total_points)
		
		var point := Vector2(
			SHADOW_CENTER.x + cos(angle) * SHADOW_SIZE.x * 0.5,
			SHADOW_CENTER.y + sin(angle) * SHADOW_SIZE.y * 0.5
		)
		
		points.append(point)
	
	draw_colored_polygon(points, SHADOW_COLOR)


func _draw_tree_halo():
	if burned:
		return
	
	draw_circle(
		Vector2(0, 15),
		135,
		HALO_COLOR
	)
	
	draw_arc(
		Vector2(0, 15),
		137,
		0,
		TAU,
		64,
		HALO_BORDER_COLOR,
		3.0
	)


func _draw_fire_glow():
	draw_circle(
		Vector2(0, 5),
		145,
		FIRE_GLOW_COLOR
	)
	
	draw_arc(
		Vector2(0, 5),
		147,
		0,
		TAU,
		64,
		Color(1.0, 0.65, 0.1, 0.50),
		5.0
	)
