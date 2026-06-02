extends CharacterBody2D

@export var speed := 400
var vidas := 3

func _physics_process(delta):
	var direccion := 0

	if Input.is_action_pressed("ui_left"):
		direccion -= 1

	if Input.is_action_pressed("ui_right"):
		direccion += 1

	velocity.x = direccion * speed
	velocity.y = 0

	move_and_slide()

	# Para que no se salga de la pantalla
	position.x = clamp(position.x, 50, 670)
