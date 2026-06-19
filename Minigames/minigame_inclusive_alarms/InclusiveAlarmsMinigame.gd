extends Node2D

const TOTAL_OBJECTS := 6
const MAX_ERRORS := 3

var classified_objects := 0
var errors := 0
var game_finished := false

@onready var timer_ui := $TimerUI
@onready var game_result := $GameResult
@onready var check_label := $Hud/StatusPanel/CheckLabel
@onready var error_label := $Hud/StatusPanel/ErrorLabel
@onready var music_player = $MusicPlayer
@onready var correct_player = $CorrectPlayer
@onready var error_player = $ErrorPlayer


func _ready() -> void:
	_update_hud()
	music_player.play()
	timer_ui.iniciar(25)
	timer_ui.iniciar(25, "Clasifica en", "segundos")
	timer_ui.time_up.connect(_on_timer_ui_time_up)

func _process(_delta: float) -> void:
	pass

func _on_flashing_lights_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "flashing_lights")

func _on_vibration_devices_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "vibration_devices")

func _on_visual_signals_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "visual_signals")

func _update_hud() -> void:
	check_label.text = str(classified_objects) + "/" + str(TOTAL_OBJECTS)
	error_label.text = str(errors) + "/" + str(MAX_ERRORS)

func _check_answer(area: Area2D, target_category: String) -> void:
	if game_finished:
		return

	if area.correct_category == target_category:
		correct_player.play()
		classified_objects += 1
		_update_hud()
		area.queue_free()

		if classified_objects >= TOTAL_OBJECTS:
			game_finished = true
			timer_ui.detener()
			music_player.stop()
			game_result.show_win()
	else:
		error_player.play()
		errors += 1
		_update_hud()

		if errors >= MAX_ERRORS:
			timer_ui.detener()
			game_finished = true
			music_player.stop()
			game_result.show_lose()
			
func _on_timer_ui_time_up() -> void:
	if game_finished:
		return

	game_finished = true
	music_player.stop()
	timer_ui.detener()
	game_result.show_lose()			



	
	
	
