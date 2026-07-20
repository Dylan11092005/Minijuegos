extends CharacterBody2D

@export var speed := 200.0

@onready var footsteps := $FootstepsPlayer
@onready var sprite := $Sprite2D
@onready var father_follower := $FatherFollower
@onready var mother_follower := $MotherFollower
@onready var son_follower := $SonFollower
@onready var daughter_follower := $DaughterFollower

var player_front = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Player.png")
var player_back = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/player_espalda.png")

var father_front = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Father_Happy.png")
var father_back = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/papa_espalda.png")

var mother_front = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Mother_Happy.png")
var mother_back = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/mama_espalda.png")

var son_front = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Son_Happy.png")
var son_back = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/hijo_espalda.png")

var daughter_front = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Daughter_Happy.png")
var daughter_back = preload("res://Minigames/minigame_FamilyMeeting/assets/objects/hija_espalda.png")

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
	if direction.y < 0:
		sprite.texture = player_back

		father_follower.texture = father_back
		mother_follower.texture = mother_back
		son_follower.texture = son_back
		daughter_follower.texture = daughter_back

	else:
		sprite.texture = player_front

		father_follower.texture = father_front
		mother_follower.texture = mother_front
		son_follower.texture = son_front
		daughter_follower.texture = daughter_front
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
