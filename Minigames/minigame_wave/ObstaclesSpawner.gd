extends Node2D

@export var obstacle_scene: PackedScene
var spawn_timer = 0.0
var spawn_interval = 2.0
var game_ref: Node

var platform_y_positions = [220.0, 557.0, 921.0]

func _ready():
	game_ref = get_parent()
	for obs in get_children():
		obs.visible = false

func _process(delta):
	if game_ref.game_over:
		return
	
	spawn_timer += delta
	var current_interval = max(0.8, spawn_interval - (game_ref.score * 0.02))
	
	if spawn_timer >= current_interval:
		spawn_timer = 0
		_spawn_obstacle()

func _spawn_obstacle():
	var available = []
	for obs in get_children():
		if not obs.visible:
			available.append(obs)
	
	if available.is_empty():
		return
	
	var obs = available[randi() % available.size()]
	var plat_y = platform_y_positions[randi() % platform_y_positions.size()]
	
	obs.position = Vector2(2000, plat_y - 40)
	obs.visible = true
	obs.activate(game_ref.speed)
