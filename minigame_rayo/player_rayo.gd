extends CharacterBody2D

@export var speed := 600
var vidas := 3
var puede_recibir_daño := true

func _ready():
	vidas = 3


func _physics_process(delta):
	var direccion := 0

	# Movimiento con flechas
	if Input.is_action_pressed("ui_left"):
		direccion -= 1

	if Input.is_action_pressed("ui_right"):
		direccion += 1

	# Movimiento con A y D
	if Input.is_key_pressed(KEY_A):
		direccion -= 1

	if Input.is_key_pressed(KEY_D):
		direccion += 1

	velocity.x = direccion * speed
	velocity.y = 0

	move_and_slide()

	# Límites para pantalla 1280 x 720
	position.x = clamp(position.x, 648, 1280)
	position.y = 848


func recibir_daño():
	if puede_recibir_daño == false:
		return

	vidas -= 1
	vidas = max(vidas, 0)

	puede_recibir_daño = false
	parpadear_daño()

	await get_tree().create_timer(0.8).timeout
	puede_recibir_daño = true


func parpadear_daño():
	for i in range(4):
		visible = false
		await get_tree().create_timer(0.08).timeout
		visible = true
		await get_tree().create_timer(0.08).timeout
