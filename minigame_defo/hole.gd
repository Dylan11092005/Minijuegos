extends Area2D

signal hole_completed

enum State { EMPTY, INVALID, PLANTED, WATERED }
@export var current_state: State = State.EMPTY

var completed_emitted := false

@onready var sprite_empty = $SpriteEmpty
@onready var sprite_invalid = $SpriteInvalid
@onready var sprite_planted = $SpritePlanted
@onready var sprite_watered = $SpriteWatered


func _ready():
	add_to_group("holes")
	update_visual()


func update_visual():
	sprite_empty.visible = false
	sprite_invalid.visible = false
	sprite_planted.visible = false
	sprite_watered.visible = false

	if current_state == State.EMPTY:
		sprite_empty.visible = true
	elif current_state == State.INVALID:
		sprite_invalid.visible = true
	elif current_state == State.PLANTED:
		sprite_planted.visible = true
	elif current_state == State.WATERED:
		sprite_watered.visible = true


func try_plant() -> bool:
	if current_state == State.EMPTY:
		current_state = State.PLANTED
		update_visual()
		get_tree().call_group("game_manager", "play_plant_sound")
		return true

	return false


func try_water() -> bool:
	if current_state == State.PLANTED:
		current_state = State.WATERED
		update_visual()
		get_tree().call_group("game_manager", "play_water_sound")

		if not completed_emitted:
			completed_emitted = true
			hole_completed.emit()

		return true

	return false
