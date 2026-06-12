extends CharacterBody2D

enum PlayerState { IDLE, HIDING, WALKING, WIN }
var current_state: PlayerState = PlayerState.IDLE
var is_holding_button: bool = false
var earthquake_active: bool = false

var girl_visual: ColorRect
var hiding_visual: ColorRect
var main_node: Node
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_create_visuals()
	await get_tree().process_frame
	main_node = get_parent()
	main_node.earthquake_started.connect(_on_earthquake_started)
	main_node.earthquake_ended.connect(_on_earthquake_ended)

func _create_visuals() -> void:
	girl_visual = ColorRect.new()
	girl_visual.color = Color(0.9, 0.5, 0.5)
	girl_visual.size = Vector2(50, 100)
	girl_visual.position = Vector2(-25, -100)
	add_child(girl_visual)

	hiding_visual = ColorRect.new()
	hiding_visual.color = Color(0.5, 0.5, 0.9)
	hiding_visual.size = Vector2(60, 40)
	hiding_visual.position = Vector2(-30, -40)
	hiding_visual.visible = false
	add_child(hiding_visual)

	position = Vector2(screen_size.x * 0.25, screen_size.y * 0.62)

func on_hold_button_pressed() -> void:
	is_holding_button = true
	if earthquake_active:
		_enter_hiding()

func on_hold_button_released() -> void:
	is_holding_button = false
	if earthquake_active and current_state == PlayerState.HIDING:
		_exit_hiding_without_earthquake_end()

func _enter_hiding() -> void:
	current_state = PlayerState.HIDING
	girl_visual.visible = false
	hiding_visual.visible = true

func _exit_hiding_without_earthquake_end() -> void:
	current_state = PlayerState.IDLE
	hiding_visual.visible = false
	girl_visual.visible = true

func _enter_walking() -> void:
	current_state = PlayerState.WALKING
	hiding_visual.visible = false
	girl_visual.visible = true
	get_node("/root/Main/Background").start_walking()

func _enter_win() -> void:
	current_state = PlayerState.WIN
	girl_visual.color = Color(0.2, 0.9, 0.2)

func _on_earthquake_started() -> void:
	earthquake_active = true
	if is_holding_button:
		_enter_hiding()

func _on_earthquake_ended() -> void:
	earthquake_active = false
	if current_state == PlayerState.HIDING or current_state == PlayerState.IDLE:
		_enter_walking()

func _on_safe_zone_reached() -> void:
	_enter_win()
	main_node.on_player_reached_safe_zone()
