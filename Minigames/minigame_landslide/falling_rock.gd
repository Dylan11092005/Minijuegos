extends Node2D

# =========================================================
# CONFIGURACIÓN DE ROCA
# =========================================================

const ASSETS_DIR := "res://Minigames/minigame_landslide/assets/"

const ROTATION_SPEED := 7.5
const ROCK_SCALE := Vector2(0.16, 0.16)

# Si tu roca es sprite sheet de 3 frames, esto lo anima.
# Si es una sola imagen normal, también funciona sin problema.
const FRAME_COUNT := 3
const FRAME_WIDTH := 512
const FRAME_HEIGHT := 864
const ANIMATION_SPEED := 10.0

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var speed := 160.0
var distance := 1.0
var progress := 0.0
var active := false

var rotation_speed := ROTATION_SPEED
var animation_time := 0.0
var current_frame := 0

@onready var rock_sprite: Sprite2D = get_node_or_null("RockSprite") as Sprite2D


func setup(p_start: Vector2, p_end: Vector2, p_speed: float) -> void:
	start_position = p_start
	end_position = p_end
	speed = p_speed

	global_position = start_position
	distance = max(start_position.distance_to(end_position), 1.0)
	progress = 0.0
	active = true

	_setup_sprite()


func _ready() -> void:
	if rock_sprite == null:
		rock_sprite = get_node_or_null("Sprite2D") as Sprite2D

	if rock_sprite == null:
		rock_sprite = Sprite2D.new()
		rock_sprite.name = "RockSprite"
		add_child(rock_sprite)

	_setup_sprite()


func _process(delta: float) -> void:
	if not active:
		return

	progress += (speed * delta) / distance
	progress = clamp(progress, 0.0, 1.0)

	global_position = start_position.lerp(end_position, progress)

	rotation += rotation_speed * delta

	_update_animation(delta)

	if progress >= 1.0:
		active = false
		queue_free()


func _setup_sprite() -> void:
	if rock_sprite == null:
		return

	if rock_sprite.texture == null:
		var rock_texture := _load_texture(["rock", "roca", "piedra"])

		if rock_texture:
			rock_sprite.texture = rock_texture

	rock_sprite.centered = true
	rock_sprite.z_index = 35

	if rock_sprite.texture:
		var texture_size := rock_sprite.texture.get_size()

		# Si parece sprite sheet, activa región.
		if texture_size.x >= FRAME_WIDTH * FRAME_COUNT and texture_size.y >= FRAME_HEIGHT:
			rock_sprite.region_enabled = true
			rock_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
			rock_sprite.scale = ROCK_SCALE
		else:
			rock_sprite.region_enabled = false

			var desired_width := 70.0

			if texture_size.x > 0:
				var final_scale := desired_width / texture_size.x
				rock_sprite.scale = Vector2(final_scale, final_scale)


func _update_animation(delta: float) -> void:
	if rock_sprite == null:
		return

	if rock_sprite.texture == null:
		return

	if not rock_sprite.region_enabled:
		return

	animation_time += delta * ANIMATION_SPEED

	var new_frame: int = int(animation_time) % FRAME_COUNT

	if new_frame == current_frame:
		return

	current_frame = new_frame

	rock_sprite.region_rect = Rect2(
		current_frame * FRAME_WIDTH,
		0,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)


func _load_texture(keywords: Array) -> Texture2D:
	var dir := DirAccess.open(ASSETS_DIR)

	if dir == null:
		return null

	for file in dir.get_files():
		var extension := file.get_extension().to_lower()

		if extension not in ["png", "jpg", "jpeg", "webp"]:
			continue

		var lower := file.to_lower()

		for keyword in keywords:
			if lower.find(str(keyword).to_lower()) != -1:
				var path := ASSETS_DIR + file
				var texture := load(path)

				if texture is Texture2D:
					return texture

	return null
