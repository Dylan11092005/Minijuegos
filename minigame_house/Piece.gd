extends RigidBody2D

var screw_count: int = 0
var original_position: Vector2
var original_rotation: float

func _ready():
	original_position = global_position
	original_rotation = global_rotation
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

func on_screw_removed():
	screw_count -= 1
	if screw_count <= 0:
		var gpos = global_position
		var gscale = global_scale
		var groot = get_tree().current_scene
		
		get_parent().remove_child(self)
		groot.add_child(self)
		
		# Asignar global_scale DESPUÉS de añadir al nuevo padre
		global_position = gpos
		global_scale = gscale
		
		freeze = false

func add_screw():
	screw_count += 1
