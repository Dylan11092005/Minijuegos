extends Node2D

signal trunk_touched

var player_inside := false


func _ready() -> void:
	var damage_area := Area2D.new()
	damage_area.name = "DamageArea"
	damage_area.collision_layer = 2
	damage_area.collision_mask = 1
	damage_area.monitoring = true
	add_child(damage_area)

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision != null:
		collision.reparent(damage_area, false)
	else:
		collision = CollisionShape2D.new()

		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(170, 65)

		collision.shape = rectangle
		damage_area.add_child(collision)

	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if player_inside:
		return

	player_inside = true

	# Avisa al juego para quitar exactamente una vida.
	trunk_touched.emit()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
