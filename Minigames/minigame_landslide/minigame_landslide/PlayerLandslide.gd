extends CharacterBody2D

signal damaged

@export var speed := 260.0
@export var invulnerability_time := 0.9

var can_receive_damage := true

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group("player")
	z_index = 40
	set_physics_process(true)
	collision_layer = 1
	collision_mask = 2


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	var screen_size := get_viewport_rect().size

	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2(1280, 720)

	global_position.x = clamp(global_position.x, 35.0, screen_size.x - 35.0)
	global_position.y = clamp(global_position.y, 120.0, screen_size.y - 35.0)

	_update_visual(direction)


func _update_visual(direction: Vector2) -> void:
	if direction.x != 0:
		if sprite:
			sprite.flip_h = direction.x > 0
		if animated_sprite:
			animated_sprite.flip_h = direction.x > 0

	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if direction == Vector2.ZERO:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	else:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")


func receive_damage(source_position: Vector2) -> void:
	if not can_receive_damage:
		return

	can_receive_damage = false
	damaged.emit()

	var knock_direction := global_position - source_position

	if knock_direction == Vector2.ZERO:
		knock_direction = Vector2.UP

	global_position += knock_direction.normalized() * 35.0

	await _blink_effect()

	can_receive_damage = true
	visible = true
	modulate = Color.WHITE


func _blink_effect() -> void:
	var blink_time := 0.0

	while blink_time < invulnerability_time:
		visible = false
		await get_tree().create_timer(0.07).timeout
		visible = true
		await get_tree().create_timer(0.07).timeout
		blink_time += 0.14
