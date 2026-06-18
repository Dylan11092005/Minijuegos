extends CharacterBody2D

@export var velocidad = 300.0
@export var aceleracion = 1800.0
@export var friccion = 1200.0

var puede_moverse = true

func _physics_process(delta):
	if not puede_moverse:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)
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

	# Flip del sprite
	if direccion.x > 0:
		$Sprite2D.flip_h = true
	elif direccion.x < 0:
		$Sprite2D.flip_h = false

	if direccion != Vector2.ZERO:
		# Aceleración gradual hacia la velocidad máxima
		velocity = velocity.move_toward(direccion.normalized() * velocidad, aceleracion * delta)
	else:
		# Desaceleración con fricción (no frena en seco)
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)

	move_and_slide()

func bloquear_movimiento():
	puede_moverse = false
	velocity = Vector2.ZERO
