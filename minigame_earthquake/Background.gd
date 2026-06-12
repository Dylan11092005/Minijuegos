extends Node2D

# ─── Config ───────────────────────────────────────────────────────────────────
@export var idle_scroll_speed:   float = 30.0   # velocidad fondo en WAITING
@export var walk_scroll_speed:   float = 120.0  # velocidad fondo en WALKING
@export var total_walk_distance: float = 2000.0 # distancia total hasta zona segura

# ─── State ────────────────────────────────────────────────────────────────────
var current_speed: float = 0.0
var is_walking: bool = false
var distance_traveled: float = 0.0

# ─── Node references ──────────────────────────────────────────────────────────
@onready var parallax_sky:       ParallaxBackground = $ParallaxSky
@onready var parallax_buildings: ParallaxBackground = $ParallaxBuildings
@onready var parallax_ground:    ParallaxBackground = $ParallaxGround
@onready var safe_zone_sprite:   Sprite2D           = $SafeZoneSign
@onready var table_sprite:       Sprite2D           = $TableSprite
@onready var hud:                CanvasLayer         = get_node("/root/Main/HUD")

func _ready() -> void:
	current_speed = idle_scroll_speed
	# Posicionar la zona segura lejos a la derecha al inicio
	safe_zone_sprite.position.x = total_walk_distance + 400.0

func _process(delta: float) -> void:
	_scroll_backgrounds(delta)
	if is_walking:
		_update_progress(delta)

# ─── Scrolling ────────────────────────────────────────────────────────────────
func _scroll_backgrounds(delta: float) -> void:
	# Parallax: cada capa scrollea a distinta velocidad (efecto de profundidad)
	# Godot lo maneja con ParallaxBackground.scroll_offset
	parallax_sky.scroll_offset.x      -= current_speed * 0.2 * delta
	parallax_buildings.scroll_offset.x -= current_speed * 0.5 * delta
	parallax_ground.scroll_offset.x   -= current_speed * 1.0 * delta

	# Acercar la zona segura (se mueve con el "suelo")
	if is_walking:
		safe_zone_sprite.position.x -= current_speed * delta
		table_sprite.position.x     -= current_speed * delta

# ─── Progress tracking ────────────────────────────────────────────────────────
func _update_progress(delta: float) -> void:
	distance_traveled += current_speed * delta
	var progress = clamp(distance_traveled / total_walk_distance, 0.0, 1.0)
	hud.update_progress(progress)
	# Cuando la zona segura llega a la posición de la niña → WIN
	if safe_zone_sprite.position.x <= 300.0:
		_trigger_safe_zone()

func _trigger_safe_zone() -> void:
	is_walking = false
	current_speed = 0.0
	get_node("/root/Main/Player")._on_safe_zone_reached()

# ─── Public API ───────────────────────────────────────────────────────────────
func start_walking() -> void:
	is_walking = true
	current_speed = walk_scroll_speed

func stop_walking() -> void:
	is_walking = false
	current_speed = idle_scroll_speed
