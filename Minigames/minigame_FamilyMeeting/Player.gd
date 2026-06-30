extends CharacterBody2D

@export var speed := 200.0

@onready var footsteps := $FootstepsPlayer
@onready var sprite := $Sprite2D
@onready var father_follower := $FatherFollower
@onready var mother_follower := $MotherFollower
@onready var son_follower := $SonFollower
@onready var daughter_follower := $DaughterFollower

var can_move := true

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_stop_footsteps()
		move_and_slide()
		return

	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true

	father_follower.flip_h = sprite.flip_h
	mother_follower.flip_h = sprite.flip_h
	son_follower.flip_h = sprite.flip_h
	daughter_follower.flip_h = sprite.flip_h

	velocity = direction.normalized() * speed

	if direction == Vector2.ZERO:
		_stop_footsteps()
	else:
		_play_footsteps()

	move_and_slide()

func bloquear_movimiento() -> void:
	can_move = false
	velocity = Vector2.ZERO
	_stop_footsteps()
	move_and_slide()

func _play_footsteps() -> void:
	if not footsteps.playing:
		footsteps.play()

func _stop_footsteps() -> void:
	if footsteps.playing:
		footsteps.stop()
