extends Node2D

var speed = 300.0
var active = false
var game_ref: Node
var boy_ref: Node

func _ready():
	game_ref = get_parent().get_parent()
	boy_ref = game_ref.get_node("CharacterBody2D/BoyAnimated")
	z_index = -1  # Detrás de la ola, delante del fondo

func activate(spd: float):
	speed = spd
	active = true

func _process(delta):
	if not active or game_ref.game_over:
		return
	
	position.x -= speed * delta
	
	if position.x < -200:
		visible = false
		active = false
		return
	
	var dist = global_position.distance_to(boy_ref.global_position)
	if dist < 50:
		game_ref.trigger_game_over()
