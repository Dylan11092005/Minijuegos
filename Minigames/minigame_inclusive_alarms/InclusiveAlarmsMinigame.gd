extends Node2D

const TOTAL_OBJECTS := 6
const MAX_ERRORS := 3
const GLOBAL_SOUND_VOLUME := -10.0

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

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null


func _ready() -> void:
	_setup_sound_volumes()
	_setup_damage_effect()
	_setup_random_objects()
	_update_hud()

	if music_player:
		music_player.play()

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


# =========================================================
# SONIDOS
# =========================================================

func _setup_sound_volumes() -> void:
	if music_player and music_player is AudioStreamPlayer:
		music_player.volume_db = GLOBAL_SOUND_VOLUME

	if success_player and success_player is AudioStreamPlayer:
		success_player.volume_db = GLOBAL_SOUND_VOLUME

	if error_player and error_player is AudioStreamPlayer:
		error_player.volume_db = GLOBAL_SOUND_VOLUME

	_set_game_result_sound_volume()


func _set_game_result_sound_volume() -> void:
	if game_result == null:
		return

	var result_sounds := [
		"WinSound",
		"win_sound",
		"AudioWin",
		"WinAudio",
		"LoseSound",
		"lose_sound",
		"AudioLose",
		"LoseAudio"
	]

	for sound_name in result_sounds:
		var sound = game_result.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


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
# OBJETOS
# =========================================================

func _setup_random_objects() -> void:
	if objects_container == null:
		push_error("objects_container es null. Revisa el path $ObjectsArea/ObjectsContainer")
		return

	if objects_tray == null:
		push_error("objects_tray es null. Revisa el path $ObjectsArea/ObjectsTray")
		return

	var all_objects := objects_container.get_children()
	all_objects.shuffle()

	var slots := objects_tray.get_children()
	slots.shuffle()

	if slots.size() < all_objects.size():
		push_warning("Hay menos slots (%d) que objetos (%d)" % [slots.size(), all_objects.size()])

	for i in all_objects.size():
		if i < slots.size():
			var obj = all_objects[i]
			var slot = slots[i]

			if not obj.has_method("set_start_position"):
				push_error("El objeto " + obj.name + " NO tiene el método set_start_position(). Revisa que DraggableObject.gd esté actualizado y asignado correctamente.")
				obj.global_position = slot.global_position
				continue

			obj.set_start_position(slot.global_position)

			var sprite = obj.get_node_or_null("Sprite2D")
			if sprite:
				sprite.position = Vector2.ZERO

			var collision = obj.get_node_or_null("CollisionShape2D")
			if collision:
				collision.position = Vector2.ZERO

			print("Objeto: ", obj.name, " | categoria: ", obj.correct_category, " | posición: ", obj.global_position)


# =========================================================
# ÁREAS DE CLASIFICACIÓN
# =========================================================

func _on_flashing_lights_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "flashing_lights")


func _on_vibration_devices_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "vibration_devices")


func _on_visual_signals_area_area_entered(area: Area2D) -> void:
	_check_answer(area, "visual_signals")


# =========================================================
# HUD
# =========================================================

func _update_hud() -> void:
	check_label.text = str(classified_objects) + "/" + str(TOTAL_OBJECTS)
	error_label.text = str(errors) + "/" + str(MAX_ERRORS)


# =========================================================
# RESPUESTAS
# =========================================================

func _check_answer(area: Area2D, target_category: String) -> void:
	if game_finished:
		return

	if area.correct_category == target_category:
		_play_sound(success_player)

		classified_objects += 1
		_update_hud()
		area.queue_free()

		if classified_objects >= TOTAL_OBJECTS:
			game_finished = true
			timer_ui.detener()

			if music_player:
				music_player.stop()

			_set_game_result_sound_volume()
			game_result.show_win()
	else:
		_play_sound(error_player)

		errors += 1
		_update_hud()
		_play_damage_effect()

		if errors >= MAX_ERRORS:
			timer_ui.detener()
			game_finished = true

			if music_player:
				music_player.stop()

			_set_game_result_sound_volume()
			game_result.show_lose()


func _on_timer_ui_time_up() -> void:
	print("¡_on_timer_ui_time_up() SE EJECUTÓ! game_finished actual: ", game_finished)

	if game_finished:
		print("Se ignoró porque game_finished ya era true")
		return

	game_finished = true

	if music_player:
		music_player.stop()

	timer_ui.detener()
	_play_sound(error_player)
	_play_damage_effect()

	_set_game_result_sound_volume()
	game_result.show_lose()

	print("show_lose() llamado")


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
