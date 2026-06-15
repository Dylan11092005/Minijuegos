extends Node2D

@onready var clean_effect = $CleanEffect
@onready var cleaning_glove = $CleaningGlove
@onready var clean_sound = $CleanSound
@onready var music_player = $MusicPlayer
@onready var timer_ui = $TimerUI
@onready var result_ui = $GameResult

var cleaned_trash = 0
var total_trash = 5
var game_active = true

@onready var trash_items = [
	$TrashBottle,
	$TrashBag,
	$TrashCan,
	$TrashBox,
	$TrashPaper
]

func _ready() -> void:
	music_player.play()

	timer_ui.iniciar(25, "Limpia el rio en", "segundos")
	timer_ui.time_up.connect(_on_time_up)

	for trash in trash_items:
		trash.visible = false
		trash.monitoring = false

	spawn_trash()

func _process(_delta):
	if game_active:
		cleaning_glove.global_position = get_global_mouse_position()

func spawn_trash() -> void:
	for trash in trash_items:
		if not game_active:
			return

		await get_tree().create_timer(1.9).timeout

		if not game_active:
			return

		trash.visible = true
		trash.monitoring = true

func clean_trash(trash_node):
	if not game_active:
		return

	show_clean_effect($CleaningGlove.global_position)

	cleaned_trash += 1
	clean_sound.play()
	trash_node.queue_free()

	check_victory()

func _on_trash_bottle_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		clean_trash($TrashBottle)

func _on_trash_bag_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		clean_trash($TrashBag)

func _on_trash_can_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		clean_trash($TrashCan)

func _on_trash_box_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		clean_trash($TrashBox)

func _on_trash_paper_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		clean_trash($TrashPaper)

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
	result_ui.show_lose()

func show_clean_effect(position_effect):
	clean_effect.global_position = position_effect
	clean_effect.visible = true

	await get_tree().create_timer(0.3).timeout

	clean_effect.visible = false
