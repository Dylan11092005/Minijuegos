extends Area2D
class_name Lightning

@export var fall_speed := 430.0
@export var spin_speed := 0.0

var _screen_height := 720.0
var _already_hit_player := false


func _ready():
	monitoring = true
	monitorable = true

	fall_speed = randf_range(380.0, 520.0)

	rotation_degrees = randf_range(-8.0, 8.0)
	scale = Vector2.ONE * randf_range(0.85, 1.15)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta):
	_screen_height = get_viewport_rect().size.y

	position.y += fall_speed * delta

	if spin_speed != 0:
		rotation_degrees += spin_speed * delta

	_check_overlapping_bodies()

	if position.y > _screen_height + 100:
		queue_free()


func _on_body_entered(body):
	_damage_player(body)


func _check_overlapping_bodies():
	for body in get_overlapping_bodies():
		_damage_player(body)


func _damage_player(body):
	if _already_hit_player:
		return

	if body == null:
		return

	if body.has_method("take_damage"):
		_already_hit_player = true
		body.take_damage()
		queue_free()
