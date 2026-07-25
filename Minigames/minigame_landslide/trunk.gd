extends Node2D

signal trunk_touched

@export_range(0.10, 1.0, 0.05) var collision_width_percent := 0.90
@export_range(0.10, 1.0, 0.05) var collision_height_percent := 0.35
@export var collision_offset := Vector2.ZERO

var player_inside := false
var damage_area: Area2D


func _ready() -> void:
	add_to_group("thorn_obstacles")

	damage_area = get_node_or_null("DamageArea") as Area2D

	if damage_area == null:
		damage_area = Area2D.new()
		damage_area.name = "DamageArea"
		add_child(damage_area)

	# El área no choca físicamente: solamente detecta al jugador.
	damage_area.collision_layer = 0
	damage_area.collision_mask = 1
	damage_area.monitoring = true
	damage_area.monitorable = true

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision != null:
		collision.reparent(damage_area, false)
	else:
		collision = damage_area.get_node_or_null(
			"CollisionShape2D"
		) as CollisionShape2D

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		damage_area.add_child(collision)

	var sprite := _find_sprite()
	var rectangle := RectangleShape2D.new()

	if sprite != null and sprite.texture != null:
		# Calcula la colisión usando el tamaño visible real del sprite.
		var sprite_size := sprite.get_rect().size

		sprite_size.x *= abs(sprite.scale.x)
		sprite_size.y *= abs(sprite.scale.y)

		rectangle.size = Vector2(
			maxf(10.0, sprite_size.x * collision_width_percent),
			maxf(8.0, sprite_size.y * collision_height_percent)
		)

		collision.position = sprite.position + collision_offset
	else:
		rectangle.size = Vector2(120, 25)
		collision.position = collision_offset

	collision.shape = rectangle
	collision.scale = Vector2.ONE
	collision.rotation = 0.0
	collision.disabled = false

	if not damage_area.body_entered.is_connected(_on_body_entered):
		damage_area.body_entered.connect(_on_body_entered)

	if not damage_area.body_exited.is_connected(_on_body_exited):
		damage_area.body_exited.connect(_on_body_exited)


func _find_sprite() -> Sprite2D:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D

	if sprite != null:
		return sprite

	var sprites := find_children("*", "Sprite2D", true, false)

	if not sprites.is_empty():
		return sprites[0] as Sprite2D

	return null


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if player_inside:
		return

	player_inside = true
	trunk_touched.emit()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_inside = false
