extends Node2D

@onready var game_result := $GameResult
@onready var timer_ui := $TimerUI
@onready var correct_label := $Hud/StatusPanel/CorrectLabel
@onready var error_label := $Hud/StatusPanel/ErrorLabel
@onready var correct_player := $CorrectPlayer
@onready var error_player := $ErrorPlayer
@onready var number_a := $Formula/NumberA
@onready var operator := $Formula/Operator
@onready var number_b := $Formula/NumberB
@onready var equal := $Formula/Equal
@onready var answer := $Formula/Answer
@onready var music_player := $MusicPlayer

var current_answer := 0
var correct_answers := 0
var wrong_answers := 0
var game_finished := false

const REQUIRED_ANSWERS := 10
const MAX_ERRORS := 3
const SYMBOL_PATH := "res://Minigames/minigame_mathChallenge/assets/objects/math_symbols/"
var TOTAL_TIME: float = 50.0

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null


func _ready() -> void:
	_setup_damage_effect()
	update_hud()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 50.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 50.0

	timer_ui.iniciar(TOTAL_TIME, "Calcula en", "segundos")
	timer_ui.time_up.connect(_on_timer_ui_time_up)
	music_player.play()
	randomize()
	generate_question()



func generate_question() -> void:
	var player_age: int = MinigameData.player_age
	var a := 0
	var b := 0

	# Reinicia la rotación y el tamaño por defecto (suma/resta usan el símbolo tal cual)
	operator.rotation_degrees = 0
	operator.scale = Vector2(1.0, 1.0)

	if player_age >= 10:
		# A partir de los 10 años: se mezclan suma, resta y multiplicación.
		# A partir de los 11 (más de 10) también se suma la división.
		var max_op_type := 3 if player_age > 10 else 2
		var op_type := randi_range(0, max_op_type)
		match op_type:
			0:
				a = randi_range(0, 9)
				b = randi_range(0, 9 - a)
				current_answer = a + b
				operator.texture = load(SYMBOL_PATH + "+.png")
			1:
				a = randi_range(0, 9)
				b = randi_range(0, a)
				current_answer = a - b
				operator.texture = load(SYMBOL_PATH + "-.png")
			2:
				# Se limita el producto a un solo dígito (0-9) porque los
				# botones de respuesta solo cubren ese rango.
				a = randi_range(1, 3)
				b = randi_range(0, int(9.0 / a))
				current_answer = a * b
				operator.texture = load(SYMBOL_PATH + "+.png")
				operator.rotation_degrees = 45  # "+" rotado 45° se ve como "x"
			3:
				# Se elige un divisor y un cociente de un solo dígito para
				# que el dividendo (a) también quepa en la textura 0-9.
				b = randi_range(1, 3)
				var q := randi_range(0, int(9.0 / b))
				a = b * q
				current_answer = q
				operator.texture = load(SYMBOL_PATH + "division.png")
				operator.scale = Vector2(0.5, 0.5)
	else:
		var is_addition := randi_range(0, 1) == 0
		if is_addition:
			a = randi_range(0, 9)
			b = randi_range(0, 9 - a)
			current_answer = a + b
			operator.texture = load(SYMBOL_PATH + "+.png")
		else:
			a = randi_range(0, 9)
			b = randi_range(0, a)
			current_answer = a - b
			operator.texture = load(SYMBOL_PATH + "-.png")

	number_a.texture = load(SYMBOL_PATH + str(a) + ".png")
	number_b.texture = load(SYMBOL_PATH + str(b) + ".png")
	equal.texture = load(SYMBOL_PATH + "=.png")
	answer.texture = load(SYMBOL_PATH + "_.png")

	print("Respuesta correcta:", current_answer)

func check_answer(selected_number: int) -> void:
	if game_finished:
		return

	answer.texture = load(SYMBOL_PATH + str(selected_number) + ".png")

	if selected_number == current_answer:
		correct_answers += 1
		correct_player.play()
	else:
		wrong_answers += 1
		error_player.play()
		_play_damage_effect()

	update_hud()

	if correct_answers >= REQUIRED_ANSWERS:
		game_finished = true
		timer_ui.detener()
		music_player.stop()
		game_result.show_win()
		return

	if wrong_answers >= MAX_ERRORS:
		game_finished = true
		timer_ui.detener()
		music_player.stop()
		game_result.show_lose()
		return

	await get_tree().create_timer(0.4).timeout

	if game_finished:
		return

	generate_question()

func update_hud() -> void:
	correct_label.text = str(correct_answers) + "/" + str(REQUIRED_ANSWERS)
	error_label.text = str(wrong_answers) + "/" + str(MAX_ERRORS)

func _on_button_0_pressed() -> void:
	check_answer(0)

func _on_button_1_pressed() -> void:
	check_answer(1)

func _on_button_2_pressed() -> void:
	check_answer(2)

func _on_button_3_pressed() -> void:
	check_answer(3)

func _on_button_4_pressed() -> void:
	check_answer(4)

func _on_button_5_pressed() -> void:
	check_answer(5)

func _on_button_6_pressed() -> void:
	check_answer(6)

func _on_button_7_pressed() -> void:
	check_answer(7)

func _on_button_8_pressed() -> void:
	check_answer(8)

func _on_button_9_pressed() -> void:
	check_answer(9)

func _on_timer_ui_time_up() -> void:
	if game_finished:
		return

	game_finished = true
	music_player.stop()
	_play_damage_effect()
	game_result.show_lose()


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
