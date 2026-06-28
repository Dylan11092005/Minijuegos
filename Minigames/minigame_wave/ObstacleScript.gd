extends Node2D

var speed = 300.0
var active = false
var game_ref: Node
var boy_ref: Node
var hit = false  # ✅ Evitar múltiples choques

func _ready():
	game_ref = get_parent().get_parent()
	boy_ref = game_ref.get_node("CharacterBody2D/BoyAnimated")
	z_index = -1

func activate(spd: float):
	speed = spd
	active = true
	hit = false

func _process(delta):
	if not active or game_ref.game_over:
		return
	
	position.x -= speed * delta
	
	if position.x < -200:
		visible = false
		active = false
		return
	
	if not hit:
		var dist = global_position.distance_to(boy_ref.global_position)
		if dist < 50:
			hit = true
			visible = false  # ✅ Obstáculo desaparece
			active = false
			game_ref.register_hit()  # ✅ Avisar al juego
