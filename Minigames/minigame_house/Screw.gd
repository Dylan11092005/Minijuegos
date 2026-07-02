extends Area2D
signal screw_clicked(screw)
var parent_piece: RigidBody2D = null
var is_removed: bool = false
@export var screw_color: String = "red"

## Cuánto más grande que el sprite querés que sea el área clickeable.
## 1.0 = mismo tamaño que la forma original. Subilo si todavía cuesta
## acertarle (probá 1.5, 1.8, 2.0...).
@export var hit_area_multiplier: float = 1.8

func _ready():
	input_pickable = true
	set_process_unhandled_input(true)
	_enlarge_hit_area()

func _enlarge_hit_area() -> void:
	# Agranda SOLO la forma de colisión (el área donde detecta el clic),
	# sin tocar el sprite ni la escala/posición del tornillo.
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			# Duplicamos el shape para no afectar a los demás tornillos
			# que puedan estar compartiendo el mismo recurso.
			var new_shape: Shape2D = child.shape.duplicate()
			if new_shape is CircleShape2D:
				new_shape.radius *= hit_area_multiplier
			elif new_shape is RectangleShape2D:
				new_shape.size *= hit_area_multiplier
			elif new_shape is CapsuleShape2D:
				new_shape.radius *= hit_area_multiplier
				new_shape.height *= hit_area_multiplier
			child.shape = new_shape

func _unhandled_input(event):
	if is_removed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var space = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = event.global_position
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var results = space.intersect_point(query)
			for result in results:
				if result.collider == self:
					remove_screw()
					get_viewport().set_input_as_handled()
					return

func remove_screw():
	if is_removed:
		return
	is_removed = true
	# Notifica ANTES de la animación
	emit_signal("screw_clicked", self)
	if parent_piece and parent_piece.has_method("on_screw_removed"):
		parent_piece.on_screw_removed()
	var base_scale = scale
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", base_scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "rotation", rotation + PI * 2, 0.3)
	await tween.finished
	queue_free()
