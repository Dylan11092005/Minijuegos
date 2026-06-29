extends Node2D


# =========================================================
# PATHS
# =========================================================

const REPAIR_STAGE_PATHS := [
	"res://Minigames/minigame_bridge/assets/repair/bridge_stage_0.png",
	"res://Minigames/minigame_bridge/assets/repair/bridge_stage_1.png",
	"res://Minigames/minigame_bridge/assets/repair/bridge_stage_2.png",
	"res://Minigames/minigame_bridge/assets/repair/bridge_stage_3.png",
	"res://Minigames/minigame_bridge/assets/repair/bridge_stage_4.png",
]


# =========================================================
# SETTINGS
# =========================================================

const TOTAL_REPAIR_STAGES := 4


# =========================================================
# VARIABLES
# =========================================================

var bridge_sprite: Sprite2D
var current_stage: int = 0


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	z_index = 8
	_create_sprite()
	reset_bridge()


# =========================================================
# PUBLIC METHODS
# =========================================================

func reset_bridge():
	current_stage = 0
	_update_bridge_image()


func repair_next_part():
	if current_stage >= TOTAL_REPAIR_STAGES:
		return
	
	current_stage += 1
	_update_bridge_image()


func repair_to_stage(stage: int):
	current_stage = clampi(stage, 0, TOTAL_REPAIR_STAGES)
	_update_bridge_image()


func get_drop_position(index: int) -> Vector2:
	var screen_size: Vector2 = get_viewport_rect().size
	
	var positions := [
		Vector2(screen_size.x * 0.38, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.46, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.54, screen_size.y * 0.50),
		Vector2(screen_size.x * 0.62, screen_size.y * 0.50)
	]
	
	if index < 0:
		index = 0
	
	if index >= positions.size():
		index = positions.size() - 1
	
	return positions[index]


func get_drop_size() -> Vector2:
	var screen_size: Vector2 = get_viewport_rect().size
	return Vector2(screen_size.x * 0.12, screen_size.y * 0.20)


# =========================================================
# INTERNAL METHODS
# =========================================================

func _create_sprite():
	bridge_sprite = get_node_or_null("BridgeSprite")
	
	if not bridge_sprite:
		bridge_sprite = Sprite2D.new()
		bridge_sprite.name = "BridgeSprite"
		add_child(bridge_sprite)
	
	bridge_sprite.centered = true
	bridge_sprite.z_index = 8


func _update_bridge_image():
	if current_stage < 0:
		current_stage = 0
	
	if current_stage >= REPAIR_STAGE_PATHS.size():
		current_stage = REPAIR_STAGE_PATHS.size() - 1
	
	var path: String = REPAIR_STAGE_PATHS[current_stage]
	
	if not ResourceLoader.exists(path):
		push_error("No se encontró la imagen del puente: " + path)
		return
	
	bridge_sprite.texture = load(path)
	_position_and_scale_bridge()


func _position_and_scale_bridge():
	if not bridge_sprite or not bridge_sprite.texture:
		return
	
	var screen_size: Vector2 = get_viewport_rect().size
	var texture_size: Vector2 = bridge_sprite.texture.get_size()
	
	# Posición del puente en el centro del río.
	bridge_sprite.position = Vector2(screen_size.x * 0.50, screen_size.y * 0.50)
	
	# Ajusta el tamaño del puente para que conecte con los lados del fondo.
	var desired_width: float = screen_size.x * 0.58
	var scale_factor: float = desired_width / texture_size.x
	
	bridge_sprite.scale = Vector2(scale_factor, scale_factor)
