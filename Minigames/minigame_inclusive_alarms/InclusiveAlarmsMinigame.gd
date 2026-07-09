extends Node2D

const TOTAL_OBJECTS := 6
const MAX_ERRORS := 3

var classified_objects := 0
var errors := 0
var game_finished := false
var TOTAL_TIME: float = 25.0

@onready var timer_ui := $TimerUI
@onready var game_result := $GameResult
@onready var check_label := $Hud/StatusPanel/CheckLabel
@onready var error_label := $Hud/StatusPanel/ErrorLabel
@onready var music_player = $MusicPlayer
@onready var success_player := $Success
@onready var error_player := $Error

@onready var objects_container := $ObjectsArea/ObjectsContainer
@onready var objects_tray := $ObjectsArea/ObjectsTray

func _ready() -> void:
	_setup_random_objects()
	_update_hud()
	music_player.play()

	# Conectar la señal por código, para no depender de la conexión
	# manual del editor (que puede romperse al editar la escena).
	if not timer_ui.time_up.is_connected(_on_timer_ui_time_up):
		timer_ui.time_up.connect(_on_timer_ui_time_up)

	var player_age: int = MinigameData.player_age
	if player_age < 12:
		TOTAL_TIME = 25.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 25.0
	timer_ui.iniciar(TOTAL_TIME, "Clasifica en", "segundos")

func _process(_delta: float) -> void:
	pass

func _setup_random_objects() -> void:
	if objects_container == null:
		push_error("objects_container es null. Revisa el path $ObjectsArea/ObjectsContainer")
		return
	if objects_tray == null:
		push_error("objects_tray es null. Revisa el path $ObjectsArea/ObjectsTray")
		return

	# 1. Todos los objetos disponibles (8: 6 correctos + 2 distractores)
	var all_objects := objects_container.get_children()
	all_objects.shuffle()

	# 2. Slots disponibles en el tray, mezclados
	var slots := objects_tray.get_children()
	slots.shuffle()

	if slots.size() < all_objects.size():
		push_warning("Hay menos slots (%d) que objetos (%d)" % [slots.size(), all_objects.size()])

	# 3. Reposicionar TODOS los objetos (incluyendo distractores) en slots aleatorios.
	#    El jugador debe clasificar los 6 correctos y evitar los 2 distractores.
	for i in all_objects.size():
		if i < slots.size():
			var obj = all_objects[i]
			var slot = slots[i]

			if not obj.has_method("set_start_position"):
				push_error("El objeto " + obj.name + " NO tiene el método set_start_position(). Revisa que DraggableObject.gd esté actualizado y asignado correctamente.")
				obj.global_position = slot.global_position
				continue

			obj.set_start_position(slot.global_position)

			# Resetear offset local del Sprite2D y CollisionShape2D
			var sprite = obj.get_node_or_null("Sprite2D")
			if sprite:
				sprite.position = Vector2.ZERO

			var collision = obj.get_node_or_null("CollisionShape2D")
			if collision:
				collision.position = Vector2.ZERO

			print("Objeto: ", obj.name, " | categoria: ", obj.correct_category, " | posición: ", obj.global_position)

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
		success_player.play()
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
	print("¡_on_timer_ui_time_up() SE EJECUTÓ! game_finished actual: ", game_finished)
	if game_finished:
		print("Se ignoró porque game_finished ya era true")
		return
	game_finished = true
	music_player.stop()
	timer_ui.detener()
	error_player.play()
	game_result.show_lose()
	print("show_lose() llamado")

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
