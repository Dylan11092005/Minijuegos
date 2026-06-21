extends Node2D

@export var speed := 230.0
@export var gravity := 60.0
@export var lifetime := 8.0
@export var rotation_speed := 6.0

const ASSETS_DIR := "res://Minigames/minigame_landslide/assets/"

var direction := Vector2.DOWN
var life_counter := 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var hitbox: Area2D = get_node_or_null("Hitbox")


func _ready() -> void:
	z_index = 70

	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	var rock_texture := _load_texture(["rock", "roca", "piedra"])

	if rock_texture:
		sprite.texture = rock_texture

	sprite.centered = true
	sprite.z_index = 5

	if sprite.texture:
		var desired_width := 70.0
		var texture_size := sprite.texture.get_size()

		if texture_size.x > 0:
			var final_scale := desired_width / texture_size.x
			sprite.scale = Vector2(final_scale, final_scale)

	if hitbox == null:
		hitbox = Area2D.new()
		hitbox.name = "Hitbox"
		add_child(hitbox)

	var collision: CollisionShape2D = hitbox.get_node_or_null("CollisionShape2D")

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		hitbox.add_child(collision)

	var shape := CircleShape2D.new()
	shape.radius = 32
	collision.shape = shape

	hitbox.monitoring = true
	hitbox.monitorable = true


func _physics_process(delta: float) -> void:
	speed += gravity * delta
	global_position += direction * speed * delta
	rotation += rotation_speed * delta

	life_counter += delta

	if life_counter >= lifetime:
		queue_free()


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
