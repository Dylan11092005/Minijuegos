extends Area2D

signal screw_clicked(screw)

var parent_piece: RigidBody2D = null
var is_removed: bool = false

@export var screw_color: String = "red"

func _ready():
	input_pickable = true
	set_process_unhandled_input(true)

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
	emit_signal("screw_clicked", self)

	var base_scale = scale
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", base_scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "rotation", rotation + PI * 2, 0.3)
	await tween.finished

	if parent_piece and parent_piece.has_method("on_screw_removed"):
		parent_piece.on_screw_removed()
	queue_free()
