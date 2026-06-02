extends Area2D

@export var velocidad_caida := 420

func _process(delta):
	position.y += velocidad_caida * delta

	if position.y > 760:
		queue_free()


func _on_body_entered(body):
	if body.name == "PlayerRayo":
		body.recibir_daño()
		queue_free()
