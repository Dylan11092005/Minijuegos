extends CharacterBody2D
@onready var sprite = $BoyAnimated
@export var jump_force := -800.0
@export var gravity := 800.0
@export var flicker_duration := 0.6
@export var flicker_interval := 0.08
var on_ground := true
var last_on_ground := true
var jumping_up := false
var game_ref: Node
var current_level := 2
var is_flickering := false
const LEVELS = [-350.0, 0.0, 350.0]
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
		_play_jump_sound()
func _go_down():
	if current_level < LEVELS.size() - 1 and on_ground:
		current_level += 1
		on_ground = false
		velocity.y = abs(jump_force) * 0.4
		_play_jump_sound()

# =========================================================
# SONIDO DE SALTO
# =========================================================
func _play_jump_sound():
	if game_ref and game_ref.has_method("play_jump_sound"):
		game_ref.play_jump_sound()

# =========================================================
# DAÑO / PARPADEO
# =========================================================
func take_damage_feedback():
	if is_flickering:
		return
	is_flickering = true
	
	var tween = create_tween()
	var blinks = int(flicker_duration / flicker_interval)
	
	for i in range(blinks):
		var target_alpha = 0.2 if i % 2 == 0 else 1.0
		tween.tween_property(sprite, "modulate:a", target_alpha, flicker_interval * 0.5)
	
	tween.tween_property(sprite, "modulate:a", 1.0, flicker_interval * 0.5)
	tween.finished.connect(func(): is_flickering = false)
