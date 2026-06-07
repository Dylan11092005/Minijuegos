extends Node2D

@export var seed_scene: PackedScene 
@onready var spawn_point = $SpawnPoint
var seed_scene = preload("res://scenes/semilla1.tscn")

var seed_spawn_position = Vector2(200, 600)

func _ready():
	spawn_new_seed()

func spawn_new_seed():
	var new_seed = seed_scene.instantiate()
	new_seed.global_position = seed_spawn_position
	get_parent().add_child(new_seed)
