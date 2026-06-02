extends Area2D

@export var velocidad_caida := 350

func _process(delta):
	position.y += velocidad_caida * delta

	if position.y > 850:
		queue_free()

func _on_body_entered(body):
	if body.name == "PlayerRayo":
		body.vidas -= 1
		queue_free()
