extends Sprite2D

var game_ref: Node
var bg_width: float
var bg_copy: Sprite2D
var stopped = false

func _ready():
	game_ref = get_parent()
	bg_width = texture.get_width() * scale.x
	
	centered = false
	position.x = 0
	position.y = 0
	z_index = -10
	
	bg_copy = Sprite2D.new()
	bg_copy.texture = texture
	bg_copy.scale = scale
	bg_copy.centered = false
	bg_copy.position = Vector2(bg_width, 0)
	bg_copy.z_index = -10
	get_parent().call_deferred("add_child", bg_copy)

func stop_scroll():
	stopped = true

func _process(delta):
	if game_ref.game_over or stopped:
		return
	
	var spd = game_ref.speed
	position.x -= spd * delta
	
	if not is_instance_valid(bg_copy):
		return
	
	bg_copy.position.x = position.x + bg_width
	
	if position.x <= -bg_width:
		position.x = bg_copy.position.x
		bg_copy.position.x = position.x + bg_width
