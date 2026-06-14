extends CharacterBody2D
class_name StormPlayer

const SCREEN_MARGIN := 70.0

# Más grande = el jugador queda más arriba.
# Antes estaba en 150.0. Ahora lo subimos más.
const GROUND_OFFSET := 220.0

const DAMAGE_COOLDOWN := 0.8
const BLINK_TIME := 0.08
const BLINK_REPETITIONS := 4

const WALK_ANIMATION_SPEED := 10.0
const WALK_BOUNCE_HEIGHT := 4.0
const WALK_TILT_AMOUNT := 5.0
const WALK_SQUASH_AMOUNT := 0.04

@export var speed := 600.0

var lives := 3
var _can_take_damage := true
var _walk_time := 0.0
var _base_scale := Vector2.ONE

@onready var _sprite: Sprite2D = $Sprite2D


func _ready():
	lives = 3

	if _sprite:
		_base_scale = _sprite.scale


func _physics_process(delta):
	var direction := _get_movement_direction()

	velocity.x = direction * speed
	velocity.y = 0

	move_and_slide()

	_keep_player_inside_screen()
	_update_walk_animation(delta, direction)


func take_damage():
	if not _can_take_damage:
		return

	lives -= 1
	lives = max(lives, 0)

	_can_take_damage = false
	_blink_damage()

	await get_tree().create_timer(DAMAGE_COOLDOWN).timeout
	_can_take_damage = true


func _get_movement_direction() -> int:
	var direction := 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1

	if Input.is_action_pressed("ui_right"):
		direction += 1

	if Input.is_key_pressed(KEY_A):
		direction -= 1

	if Input.is_key_pressed(KEY_D):
		direction += 1

	return direction


func _keep_player_inside_screen():
	var screen_size := get_viewport_rect().size

	position.x = clamp(position.x, SCREEN_MARGIN, screen_size.x - SCREEN_MARGIN)
	position.y = screen_size.y - GROUND_OFFSET


func _update_walk_animation(delta, direction: int):
	if _sprite == null:
		return

	if direction != 0:
		_walk_time += delta * WALK_ANIMATION_SPEED

		# CORREGIDO:
		# Si antes al ir a la derecha se veía de espalda,
		# esta línea lo invierte para que quede al lado correcto.
		_sprite.flip_h = direction > 0

		var bounce: float = abs(sin(_walk_time)) * WALK_BOUNCE_HEIGHT
		var tilt: float = sin(_walk_time) * WALK_TILT_AMOUNT
		var squash: float = abs(sin(_walk_time)) * WALK_SQUASH_AMOUNT

		_sprite.position.y = -bounce
		_sprite.rotation_degrees = tilt * direction
		_sprite.scale = Vector2(
			_base_scale.x + squash,
			_base_scale.y - squash
		)
	else:
		_sprite.position.y = lerp(_sprite.position.y, 0.0, 0.15)
		_sprite.rotation_degrees = lerp(_sprite.rotation_degrees, 0.0, 0.15)
		_sprite.scale = _sprite.scale.lerp(_base_scale, 0.15)


func _blink_damage():
	for index in range(BLINK_REPETITIONS):
		visible = false
		await get_tree().create_timer(BLINK_TIME).timeout

		visible = true
		await get_tree().create_timer(BLINK_TIME).timeout
