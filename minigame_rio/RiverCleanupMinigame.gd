extends Node2D

@export var time_limit := 30
@export var drop_distance := 100.0

var trash_total := 0
var trash_collected := 0
var game_finished := false

@onready var basurero = $Basurero
@onready var basuras = $Basuras
@onready var game_timer = $GameTimer
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var result_label = $CanvasLayer/ResultLabel
@onready var back_button = $CanvasLayer/BackButton


func _ready():
	result_label.visible = false

	trash_total = basuras.get_child_count()

	for trash in basuras.get_children():
		trash.dropped.connect(_on_trash_dropped)

	game_timer.wait_time = time_limit
	game_timer.one_shot = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	game_timer.start()

	back_button.pressed.connect(_on_back_button_pressed)


func _process(delta):
	if game_finished:
		return

	timer_label.text = "Tiempo: " + str(ceil(game_timer.time_left))


func _on_trash_dropped(trash):
	if game_finished:
		return

	var distance_to_bin = trash.global_position.distance_to(basurero.global_position)

	if distance_to_bin <= drop_distance:
		trash_collected += 1
		trash.queue_free()

		if trash_collected >= trash_total:
			_win_game()
	else:
		trash.return_to_start()


func _win_game():
	game_finished = true
	game_timer.stop()

	result_label.text = "¡GANASTE!\nEl río quedó limpio"
	result_label.visible = true
	result_label.scale = Vector2(0.3, 0.3)
	result_label.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_label, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_label, "modulate", Color(1, 1, 1, 1), 0.25)

	tween.set_parallel(false)
	tween.tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.2)


func _on_game_timer_timeout():
	if trash_collected < trash_total:
		game_finished = true
		result_label.text = "¡Tiempo agotado!\nInténtalo de nuevo"
		result_label.visible = true
		result_label.scale = Vector2(0.3, 0.3)
		result_label.modulate = Color(1, 1, 1, 0)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(result_label, "scale", Vector2(1.1, 1.1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(result_label, "modulate", Color(1, 1, 1, 1), 0.25)

		tween.set_parallel(false)
		tween.tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.2)


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
