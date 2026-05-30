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
		freeze = false
		# Sube: Piece -> HouseContainer -> HouseMinigame
		get_parent().get_parent().on_piece_detached(self)

func add_screw():
	screw_count += 1
