extends Sprite2D

var speed = 300.0
var active = false
var game_ref: Node

func _ready():
	game_ref = get_tree().get_root().get_node("WaveGame")
	visible = false

func activate(spd: float):
	speed = spd
	active = true
	visible = true

func _process(delta):
	if not active or game_ref.game_over:
		return
	
	position.x -= speed * delta
	
	if position.x < -200:
		visible = false
		active = false
