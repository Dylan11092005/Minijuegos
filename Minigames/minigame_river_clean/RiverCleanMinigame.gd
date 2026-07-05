extends Node2D

@onready var clean_effect = $CleanEffect
@onready var cleaning_glove = $CleaningGlove
@onready var clean_sound = $CleanSound
@onready var music_player = $MusicPlayer
@onready var timer_ui = $TimerUI
@onready var result_ui = $GameResult
@onready var error_player := $ErrorPlayer

@onready var heart1 = $Lives/Heart1
@onready var heart2 = $Lives/Heart2
@onready var heart3 = $Lives/Heart3
@onready var heart_empty = $Lives/HeartEmpty
var cleaned_trash = 0
var total_trash = 5
var game_active = true

var TOTAL_TIME: float = 25.0

var lives = 3


@onready var trash_items = [
	$TrashBottle,
	$TrashBag,
	$TrashCan,
	$TrashBox,
	$TrashPaper
]
@onready var fish_items = [
	$Fish1,
	$Fish2,
	$Fish3
]

func _ready() -> void:
	update_hearts()
	music_player.play()


	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 25.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 25.0

	timer_ui.iniciar(TOTAL_TIME, "Limpia el rio en", "segundos")
	timer_ui.time_up.connect(_on_time_up)



	for trash in trash_items:
		trash.visible = false
		trash.monitoring = false
	for fish in fish_items:
		fish.visible = false
		fish.monitoring = false	

	spawn_trash()

func _process(_delta):
	if game_active:
		cleaning_glove.global_position = get_global_mouse_position()

func spawn_trash() -> void:
	var last_trash = trash_items[-1]
	var items_before_last = trash_items.slice(0, trash_items.size() - 1) + fish_items
	
	items_before_last.shuffle()

	for item in items_before_last:
		if not game_active:
			return

		await get_tree().create_timer(1.9).timeout

		if not game_active:
			return

		item.visible = true
		item.monitoring = true

		if item in fish_items:
			hide_fish_after_time(item)

	await get_tree().create_timer(1.9).timeout

	if not game_active:
		return

	last_trash.visible = true
	last_trash.monitoring = true
	
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
	update_hearts()
	fish_node.queue_free()
	if lives <= 0:
		game_active = false
		music_player.stop()
		timer_ui.detener()
		result_ui.show_lose()
func _on_fish_1_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		touch_fish($Fish1)


func _on_fish_2_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		touch_fish($Fish2)


func _on_fish_3_area_entered(area: Area2D) -> void:
	if area.name == "CleaningGlove":
		touch_fish($Fish3)
		
func update_hearts():
	if lives == 2:
		heart3.texture = heart_empty.texture

	if lives == 1:
		heart2.texture = heart_empty.texture
		heart3.texture = heart_empty.texture

	if lives == 0:
		heart1.texture = heart_empty.texture
		heart2.texture = heart_empty.texture
		heart3.texture = heart_empty.texture

