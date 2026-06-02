extends Area2D

@export var velocidad_caida := 430
@export var velocidad_giro := 0.0

var pantalla_alto := 720.0


func _ready():
	# Hace que cada rayo tenga una velocidad un poco diferente
	velocidad_caida = randf_range(380, 520)

	# Pequeña variación visual
	rotation_degrees = randf_range(-8, 8)
	scale = Vector2.ONE * randf_range(0.85, 1.15)


func _process(delta):
	pantalla_alto = get_viewport_rect().size.y

	position.y += velocidad_caida * delta

	if velocidad_giro != 0:
		rotation_degrees += velocidad_giro * delta

	# Cuando sale de la pantalla, se elimina
	if position.y > pantalla_alto + 100:
		queue_free()


func _on_body_entered(body):
	if body.name == "PlayerRayo":
		if body.has_method("recibir_daño"):
			body.recibir_daño()
		else:
			body.vidas -= 1

		queue_free()
