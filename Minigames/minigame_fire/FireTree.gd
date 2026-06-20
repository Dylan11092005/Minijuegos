extends Area2D


# =========================================================
# SIGNALS
# =========================================================

signal extinguished(tree)
signal wrong_pressed


# =========================================================
# ASSET PATHS
# =========================================================

const TREE_PATH := "res://Minigames/minigame_fire/assets/tree.png"
const BURNED_TREE_PATH := "res://Minigames/minigame_fire/assets/tree_burned.png"
const FIRE_TOP_PATH := "res://Minigames/minigame_fire/assets/fire_1.png"
const FIRE_ROOT_PATH := "res://Minigames/minigame_fire/assets/fire_2.png"
const SMOKE_PATH := "res://Minigames/minigame_fire/assets/smoke.png"


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var tree_sprite: Sprite2D = $TreeSprite
@onready var burned_tree_sprite: Sprite2D = $BurnedTreeSprite
@onready var fire_top_sprite: Sprite2D = $FireTopSprite
@onready var fire_root_sprite: Sprite2D = $FireRootSprite
@onready var smoke_sprite: Sprite2D = $SmokeSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# =========================================================
# VARIABLES
# =========================================================

var burning := false
var disabled := false
var extinguished_safe := false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	input_pickable = true
	
	_load_textures()
	_setup_sprites()
	_setup_collision()
	reset_tree()


# =========================================================
# PUBLIC METHODS
# =========================================================

func set_burning(value: bool):
	if disabled:
		return
	
	if extinguished_safe and value:
		return
	
	burning = value
	
	if burning:
		_show_burning_tree()
	else:
		_show_normal_tree()


func reset_tree():
	burning = false
	disabled = false
	extinguished_safe = false
	_show_normal_tree()


func set_disabled(value: bool):
	disabled = value


func can_catch_fire() -> bool:
	return not burning and not extinguished_safe and not disabled


func is_burning() -> bool:
	return burning


# =========================================================
# INPUT
# =========================================================

func _input_event(_viewport, event, _shape_idx):
	if disabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_press_tree()
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_tree()


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
	
	_show_extinguished_tree()
	extinguished.emit(self)


# =========================================================
# SPRITE SETUP
# =========================================================

func _load_textures():
	if ResourceLoader.exists(TREE_PATH):
		tree_sprite.texture = load(TREE_PATH)
	
	if ResourceLoader.exists(BURNED_TREE_PATH):
		burned_tree_sprite.texture = load(BURNED_TREE_PATH)
	
	if ResourceLoader.exists(FIRE_TOP_PATH):
		fire_top_sprite.texture = load(FIRE_TOP_PATH)
	
	if ResourceLoader.exists(FIRE_ROOT_PATH):
		fire_root_sprite.texture = load(FIRE_ROOT_PATH)
	
	if ResourceLoader.exists(SMOKE_PATH):
		smoke_sprite.texture = load(SMOKE_PATH)


func _setup_sprites():
	# Árbol normal
	tree_sprite.position = Vector2(0, 0)
	tree_sprite.scale = Vector2(0.28, 0.28)
	tree_sprite.z_index = 1
	
	# Árbol quemado
	# Este aparece cuando el jugador apaga el fuego.
	burned_tree_sprite.position = Vector2(0, 15)
	burned_tree_sprite.scale = Vector2(0.35, 0.35)
	burned_tree_sprite.z_index = 1
	
	# Fire1
	# Fuego en la parte media o superior del árbol.
	fire_top_sprite.position = Vector2(0, -55)
	fire_top_sprite.scale = Vector2(0.28, 0.28)
	fire_top_sprite.z_index = 4
	
	# Fire2
	# Fuego abajo, cerca de las raíces.
	fire_root_sprite.position = Vector2(0, 65)
	fire_root_sprite.scale = Vector2(0.32, 0.32)
	fire_root_sprite.z_index = 3
	
	# Smoke
	# Humo arriba del árbol quemado.
	smoke_sprite.position = Vector2(0, -90)
	smoke_sprite.scale = Vector2(0.30, 0.30)
	smoke_sprite.z_index = 5


func _setup_collision():
	var rect := RectangleShape2D.new()
	rect.size = Vector2(160, 230)
	
	collision_shape.shape = rect
	collision_shape.position = Vector2(0, 0)


# =========================================================
# VISUAL STATES
# =========================================================

func _show_normal_tree():
	tree_sprite.visible = true
	burned_tree_sprite.visible = false
	
	fire_top_sprite.visible = false
	fire_root_sprite.visible = false
	smoke_sprite.visible = false


func _show_burning_tree():
	tree_sprite.visible = true
	burned_tree_sprite.visible = false
	
	fire_top_sprite.visible = true
	fire_root_sprite.visible = true
	smoke_sprite.visible = false


func _show_extinguished_tree():
	tree_sprite.visible = false
	burned_tree_sprite.visible = true
	
	fire_top_sprite.visible = false
	fire_root_sprite.visible = false
	smoke_sprite.visible = true
	
	await get_tree().create_timer(0.7).timeout
	
	if not burning:
		smoke_sprite.visible = false
