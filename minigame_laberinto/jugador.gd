extends CharacterBody2D

@export var velocidad = 300.0
var puede_moverse = true

func _physics_process(delta):
	if not puede_moverse:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direccion = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direccion.x += 1

	if Input.is_action_pressed("ui_left"):
		direccion.x -= 1

	if Input.is_action_pressed("ui_down"):
		direccion.y += 1

	if Input.is_action_pressed("ui_up"):
		direccion.y -= 1

	if direccion.x > 0:
		$Sprite2D.flip_h = true

	if direccion.x < 0:
		$Sprite2D.flip_h = false

	velocity = direccion.normalized() * velocidad
	move_and_slide()

func bloquear_movimiento():
	puede_moverse = false
	velocity = Vector2.ZERO
