extends Node2D


const RIVER_TEXTURE_PATH := "res://Minigames/minigame_bridge/assets/river.png"

const MOVE_SPEED := 28.0
const WATER_ALPHA := 0.55
const WATER_HEIGHT_PERCENT := 0.43
const WATER_START_Y_PERCENT := 0.52

var river_sprites: Array = []
var display_width := 0.0


func _ready():
	z_index = -5
	_create_river()


func _process(delta):
	if river_sprites.is_empty():
		return
	
	for sprite in river_sprites:
		sprite.position.x += MOVE_SPEED * delta
	
	for sprite in river_sprites:
		if sprite.position.x > display_width * 2.0:
			var min_x := _get_min_sprite_x()
			sprite.position.x = min_x - display_width


func _create_river():
	if not ResourceLoader.exists(RIVER_TEXTURE_PATH):
		push_error("No se encontró river.png en: " + RIVER_TEXTURE_PATH)
		return
	
	var river_texture: Texture2D = load(RIVER_TEXTURE_PATH)
	var texture_size := river_texture.get_size()
	var screen_size := get_viewport_rect().size
	
	var region_height := texture_size.y * 0.50
	var region_y := texture_size.y - region_height
	
	var desired_height := screen_size.y * WATER_HEIGHT_PERCENT
	var scale_factor := desired_height / region_height
	
	display_width = texture_size.x * scale_factor
	
	position = Vector2(0, screen_size.y * WATER_START_Y_PERCENT)
	
	for i in range(3):
		var sprite := Sprite2D.new()
		sprite.texture = river_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, region_y, texture_size.x, region_height)
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2((i - 1) * display_width, 0)
		sprite.modulate.a = WATER_ALPHA
		sprite.z_index = -5
		
		add_child(sprite)
		river_sprites.append(sprite)


func _get_min_sprite_x() -> float:
	var min_x := 999999.0
	
	for sprite in river_sprites:
		if sprite.position.x < min_x:
			min_x = sprite.position.x
	
	return min_x
