extends Area2D

enum State { EMPTY, INVALID, PLANTED, WATERED }
var current_state = State.EMPTY

@onready var sprite = $Sprite2D

@export var img_hueco_bueno: Texture2D
@export var img_hueco_malo: Texture2D
@export var img_hueco_con_semilla: Texture2D
@export var img_arbusto: Texture2D

func _ready():
	add_to_group("holes")
	update_visual()

func update_visual():
	if current_state == State.EMPTY:
		sprite.texture = img_hueco_bueno
	elif current_state == State.INVALID:
		sprite.texture = img_hueco_malo
	elif current_state == State.PLANTED:
		sprite.texture = img_hueco_con_semilla
	elif current_state == State.WATERED:
		sprite.texture = img_arbusto

func try_plant() -> bool:
	if current_state == State.EMPTY:
		current_state = State.PLANTED
		update_visual()
		return true
	return false

func try_water() -> bool:
	if current_state == State.PLANTED:
		current_state = State.WATERED
		update_visual()
		return true
	return false
