extends CharacterBody2D

@onready var sprite = $BoyAnimated
@export var jump_force := -600.0
@export var gravity := 800.0

var on_ground := true
var last_on_ground := true
var jumping_up := false
var game_ref: Node
var current_level := 2

const LEVELS = [-350.0, 0.0, 390.0]

func _ready():
	game_ref = get_parent()
	position.x = 400
	position.y = LEVELS[current_level]
	sprite.play("run")

func _process(_delta):
	if game_ref.game_over:
		return
	if Input.is_action_just_pressed("ui_up"):
		_go_up()
	if Input.is_action_just_pressed("ui_down"):
		_go_down()

func _physics_process(delta):
	if game_ref.game_over:
		return
	
	if !on_ground:
		velocity.y += gravity * delta
	
	move_and_slide()
	
	var target_y = LEVELS[current_level]
	
	if jumping_up and velocity.y < 0:
		return
	else:
		jumping_up = false
	
	if position.y >= target_y:
		position.y = target_y
		velocity.y = 0
		on_ground = true
	else:
		on_ground = false
	
	if on_ground and sprite.animation != "run":
		sprite.play("run")
	elif not on_ground and sprite.animation != "jump":
		sprite.play("jump")
	
	last_on_ground = on_ground

func _go_up():
	if current_level > 0 and on_ground:
		current_level -= 1
		on_ground = false
		jumping_up = true
		velocity.y = jump_force
		if sprite.animation != "jump":
			sprite.play("jump")
		last_on_ground = false

func _go_down():
	if current_level < LEVELS.size() - 1 and on_ground:
		current_level += 1
		on_ground = false
		velocity.y = abs(jump_force) * 0.4
