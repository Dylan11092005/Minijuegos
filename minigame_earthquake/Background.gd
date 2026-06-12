extends Node2D

@export var idle_scroll_speed:   float = 30.0
@export var walk_scroll_speed:   float = 120.0
@export var total_walk_distance: float = 3000.0

var current_speed: float = 0.0
var is_walking: bool = false
var distance_traveled: float = 0.0
var screen_size: Vector2

var table_node: Node2D
var safe_zone_node: Node2D

@onready var parallax_sky:       ParallaxBackground = $ParallaxSky
@onready var parallax_buildings: ParallaxBackground = $ParallaxBuildings
@onready var parallax_ground:    ParallaxBackground = $ParallaxGround

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	current_speed = idle_scroll_speed
	_create_table()
	_create_safe_zone()

func _create_table() -> void:
	table_node = Node2D.new()
	table_node.position = Vector2(screen_size.x * 0.15, screen_size.y * 0.62)
	add_child(table_node)

	var top = ColorRect.new()
	top.color = Color(0.55, 0.35, 0.15)
	top.size = Vector2(180, 20)
	top.position = Vector2(-90, -20)
	table_node.add_child(top)

	var leg_left = ColorRect.new()
	leg_left.color = Color(0.45, 0.28, 0.1)
	leg_left.size = Vector2(15, 80)
	leg_left.position = Vector2(-85, 0)
	table_node.add_child(leg_left)

	var leg_right = ColorRect.new()
	leg_right.color = Color(0.45, 0.28, 0.1)
	leg_right.size = Vector2(15, 80)
	leg_right.position = Vector2(70, 0)
	table_node.add_child(leg_right)

func _create_safe_zone() -> void:
	safe_zone_node = Node2D.new()
	safe_zone_node.position = Vector2(screen_size.x * 2.0, screen_size.y * 0.35)
	add_child(safe_zone_node)

	var sign_bg = ColorRect.new()
	sign_bg.color = Color(0.1, 0.6, 0.1)
	sign_bg.size = Vector2(220, 60)
	sign_bg.position = Vector2(-110, 0)
	safe_zone_node.add_child(sign_bg)

	var sign_text = Label.new()
	sign_text.text = "ZONA SEGURA"
	sign_text.add_theme_color_override("font_color", Color.WHITE)
	sign_text.add_theme_font_size_override("font_size", 22)
	sign_text.position = Vector2(-100, 10)
	safe_zone_node.add_child(sign_text)

	var pole = ColorRect.new()
	pole.color = Color(0.6, 0.6, 0.6)
	pole.size = Vector2(10, 100)
	pole.position = Vector2(-5, 60)
	safe_zone_node.add_child(pole)

func _process(delta: float) -> void:
	_scroll_backgrounds(delta)
	if is_walking:
		_update_progress(delta)

func _scroll_backgrounds(delta: float) -> void:
	parallax_sky.scroll_offset.x       -= current_speed * 0.2 * delta
	parallax_buildings.scroll_offset.x -= current_speed * 0.5 * delta
	parallax_ground.scroll_offset.x    -= current_speed * 1.0 * delta
	if is_walking:
		table_node.position.x     -= current_speed * delta
		safe_zone_node.position.x -= current_speed * delta

func _update_progress(delta: float) -> void:
	distance_traveled += current_speed * delta
	var progress = clamp(distance_traveled / total_walk_distance, 0.0, 1.0)
	get_node("/root/Main/Hud").update_progress(progress)
	if safe_zone_node.position.x <= screen_size.x * 0.4:
		_trigger_safe_zone()

func _trigger_safe_zone() -> void:
	is_walking = false
	current_speed = 0.0
	get_node("/root/Main/Player")._on_safe_zone_reached()

func start_walking() -> void:
	is_walking = true
	current_speed = walk_scroll_speed

func stop_walking() -> void:
	is_walking = false
	current_speed = idle_scroll_speed
