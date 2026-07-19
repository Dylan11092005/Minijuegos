extends Node2D

# =========================================================
# SCENES
# =========================================================
const LIVES_UI_SCENE := preload("res://Minigames/ui_global/LivesUi.tscn")

@onready var clean_effect = $CleanEffect
@onready var cleaning_glove = $CleaningGlove
@onready var clean_sound = $CleanSound
@onready var music_player = $MusicPlayer
@onready var timer_ui = $TimerUI
@onready var result_ui = $GameResult
@onready var error_player := $ErrorPlayer

var _lives_ui: Node

var cleaned_trash = 0
var total_trash = 7
var game_active = true

var TOTAL_TIME: float = 25.0
var lives = 3

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

@onready var trash_items = _get_existing_nodes([
	"TrashBottle",
	"TrashBag",
	"TrashCan",
	"TrashBox",
	"TrashPaper",
	"TrashBottle2",
	"TrashBox2"
])

@onready var fish_items = _get_existing_nodes([
	"Fish1",
	"Fish2",
	"Fish3",
	"Fish4",
	"Fish5"
])

func _ready() -> void:
	_setup_lives_ui()
	_setup_damage_effect()
	music_player.play()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 25.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 25.0

	timer_ui.iniciar(TOTAL_TIME, "Limpia el rio en", "segundos")
	timer_ui.time_up.connect(_on_time_up)

	total_trash = trash_items.size()

	for trash in trash_items:
		trash.visible = false
		trash.monitoring = false
		trash.area_entered.connect(_on_trash_area_entered.bind(trash))

	for fish in fish_items:
		fish.visible = false
		fish.monitoring = false
		fish.area_entered.connect(_on_fish_area_entered.bind(fish))

	spawn_trash()

func _process(_delta):
	if game_active:
		cleaning_glove.global_position = get_global_mouse_position()

# =========================================================
# LIVES UI
# =========================================================
func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)
	_update_lives_ui()

func _update_lives_ui():
	if _lives_ui == null:
		return
	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(lives)
	if _lives_ui.has_method("set_max_lives"):
		_lives_ui.set_max_lives(3)

# =========================================================
# DAMAGE EFFECT
# =========================================================

func _setup_damage_effect():
	damage_layer = CanvasLayer.new()
	damage_layer.name = "DamageLayer"
	damage_layer.layer = 200
	add_child(damage_layer)
	
	damage_rect = ColorRect.new()
	damage_rect.name = "DamageRect"
	damage_rect.color = Color(1, 0, 0)
	damage_rect.modulate.a = 0.0
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	damage_layer.add_child(damage_rect)


func _play_damage_effect():
	if not damage_rect:
		return
	
	var original_position: Vector2 = position
	
	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)
	
	var shake_tween := create_tween()
	
	for i in range(6):
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)

# =========================================================
# HELPERS
# =========================================================
func _get_existing_nodes(names: Array) -> Array:
	var result := []
	for n in names:
		if has_node(n):
			result.append(get_node(n))
		else:
			push_warning("Nodo no encontrado, revisa la escena: " + n)
	return result

# =========================================================
# SPAWN
# =========================================================
func spawn_trash() -> void:
	var all_items = trash_items + fish_items
	all_items.shuffle()

	for item in all_items:
		if not game_active:
			return

		await get_tree().create_timer(1.9).timeout

		if not game_active:
			return

		item.visible = true
		item.monitoring = true

		if item in fish_items:
			hide_fish_after_time(item)

func hide_fish_after_time(fish_node) -> void:
	await get_tree().create_timer(2.0).timeout

	if not game_active:
		return

	if is_instance_valid(fish_node):
		fish_node.visible = false
		fish_node.monitoring = false

func clean_trash(trash_node):
	if not game_active:
		return

	show_clean_effect($CleaningGlove.global_position)

	cleaned_trash += 1
	clean_sound.play()
	trash_node.queue_free()

	check_victory()

func _on_trash_area_entered(area: Area2D, trash_node) -> void:
	if area.name == "CleaningGlove":
		clean_trash(trash_node)

func _on_fish_area_entered(area: Area2D, fish_node) -> void:
	if area.name == "CleaningGlove":
		touch_fish(fish_node)

func check_victory():
	if cleaned_trash >= total_trash:
		game_active = false
		music_player.stop()
		timer_ui.detener()
		result_ui.show_win()

func _on_time_up():
	game_active = false
	music_player.stop()
	timer_ui.detener()
	_play_damage_effect()
	result_ui.show_lose()

func show_clean_effect(position_effect):
	clean_effect.global_position = position_effect
	clean_effect.visible = true

	await get_tree().create_timer(0.3).timeout

	clean_effect.visible = false

# =========================================================
# TIME BONUS POR EDAD
# =========================================================
func _get_time_bonus(age: int) -> float:
	match age:
		11:
			return 2.0
		10:
			return 3.0
		9:
			return 5.0
		8:
			return 7.0
		7:
			return 10.0
		_:
			return 10.0 if age < 7 else 0.0

func touch_fish(fish_node):
	if not game_active:
		return
	lives -= 1
	error_player.play()
	_update_lives_ui()
	_play_damage_effect()
	fish_node.queue_free()
	if lives <= 0:
		game_active = false
		music_player.stop()
		timer_ui.detener()
		result_ui.show_lose()
