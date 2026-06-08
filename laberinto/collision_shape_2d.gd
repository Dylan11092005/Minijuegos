extends CharacterBody2D

var velocidad = 160
var juego_activo = true

func _ready():
	# Configurar la forma de colisión
	var forma = $CollisionShape2D
	var rectangulo = RectangleShape2D.new()
	rectangulo.size = Vector2(30, 30)
	forma.shape = rectangulo

	# Configurar la imagen del personaje
	var sprite = $Sprite2D
	var textura = load("res://assets/niño.png")
	if textura:
		sprite.texture = textura
		sprite.scale = Vector2(
			35.0 / textura.get_width(),
			35.0 / textura.get_height()
		)

func _physics_process(delta):
	if not juego_activo:
		velocity = Vector2.ZERO
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

	velocity = direccion.normalized() * velocidad
	move_and_slide()
