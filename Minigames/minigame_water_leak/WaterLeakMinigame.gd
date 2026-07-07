extends Node2D
class_name WaterLeakMinigame

signal game_won
signal game_lost

const GAME_RESULT_SCENE: PackedScene = preload("res://Minigames/ui_global/GameResult.tscn")

const PIPE_ROUTES: Array = [
	[
		Vector2(0.05, 0.16), Vector2(0.34, 0.16), Vector2(0.34, 0.31),
		Vector2(0.68, 0.31), Vector2(0.68, 0.16), Vector2(0.94, 0.16)
	],
	[
		Vector2(0.05, 0.43), Vector2(0.27, 0.43), Vector2(0.27, 0.56),
		Vector2(0.52, 0.56), Vector2(0.52, 0.42), Vector2(0.77, 0.42),
		Vector2(0.77, 0.56), Vector2(0.94, 0.56)
	],
	[
		Vector2(0.05, 0.76), Vector2(0.37, 0.76), Vector2(0.37, 0.88),
		Vector2(0.71, 0.88), Vector2(0.71, 0.72), Vector2(0.94, 0.72)
	],
	[
		Vector2(0.12, 0.16), Vector2(0.12, 0.76)
	],
	[
		Vector2(0.61, 0.31), Vector2(0.61, 0.72)
	]
]

const LEAK_CANDIDATES: Array[Vector2] = [
	Vector2(0.19, 0.16), Vector2(0.34, 0.24), Vector2(0.49, 0.31),
	Vector2(0.68, 0.23), Vector2(0.84, 0.16), Vector2(0.18, 0.43),
	Vector2(0.27, 0.50), Vector2(0.41, 0.56), Vector2(0.52, 0.48),
	Vector2(0.68, 0.42), Vector2(0.77, 0.50), Vector2(0.88, 0.56),
	Vector2(0.21, 0.76), Vector2(0.37, 0.82), Vector2(0.53, 0.88),
	Vector2(0.71, 0.80), Vector2(0.83, 0.72), Vector2(0.12, 0.32),
	Vector2(0.12, 0.61), Vector2(0.61, 0.48), Vector2(0.61, 0.64)
]

@export_group("Configuración del juego")
@export_range(3, 18, 1) var leak_count: int = 10
@export_range(10.0, 100.0, 1.0) var starting_water: float = 100.0
@export_range(0.0, 5.0, 0.05) var base_water_loss_per_second: float = 0.25
@export_range(0.0, 5.0, 0.05) var water_loss_per_active_leak: float = 0.35

@export_group("Dificultad inicial")
@export_range(1.0, 3.0, 0.05) var initial_water_loss_multiplier: float = 1.70
@export_range(1.0, 20.0, 0.5) var initial_fast_loss_duration: float = 7.0

@export_group("Interacción")
@export_range(20.0, 100.0, 1.0) var leak_hit_radius: float = 52.0
@export_range(15.0, 70.0, 1.0) var patch_visual_radius: float = 31.0

@export_group("Animación")
@export_range(0.0, 20.0, 1.0) var interface_bounce_amount: float = 5.0

@export_group("Animación de fugas por imágenes")
@export var leak_frame_01: Texture2D
@export var leak_frame_02: Texture2D
@export var leak_frame_03: Texture2D
@export_range(1.0, 20.0, 0.5) var leak_frame_fps: float = 8.0
@export_range(50.0, 300.0, 5.0) var leak_sprite_height: float = 155.0
@export_range(-100.0, 100.0, 1.0) var leak_sprite_vertical_offset: float = 0.0

@export_group("Audio")
@export var background_music_stream: AudioStream
@export var leak_sound_stream: AudioStream
@export var patch_sound_stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var background_music_volume_db: float = -8.0
@export_range(-40.0, 6.0, 0.5) var leak_sound_volume_db: float = -14.0
@export_range(-40.0, 6.0, 0.5) var patch_sound_volume_db: float = 0.0

var _water_level: float = 100.0
var _leaks: Array[Dictionary] = []
var _water_loss_age_multiplier: float = 1.0
var _dragging_patch: bool = false
var _drag_position: Vector2 = Vector2.ZERO
var _game_finished: bool = false
var _animation_time: float = 0.0
var _elapsed_game_time: float = 0.0
var _repair_flash_time: float = 0.0
var _repair_flash_position: Vector2 = Vector2.ZERO
var _invalid_drop_time: float = 0.0
var _invalid_drop_position: Vector2 = Vector2.ZERO
var _game_result: Node = null
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

var _background_music_player: AudioStreamPlayer = null
var _patch_sound_player: AudioStreamPlayer = null
var _leak_sound_players: Array[AudioStreamPlayer] = []

var _leak_frames: Array[Texture2D] = []
var _leak_sprites: Array[Sprite2D] = []
var _leak_visuals_root: Node2D = null
var _current_leak_frame: int = -1



func _ready() -> void:
	_random.randomize()
	_water_level = starting_water
	_elapsed_game_time = 0.0

	var player_age: int = MinigameData.player_age
	_water_loss_age_multiplier = _get_water_loss_multiplier(player_age)

	
	
	_generate_leaks()
	_setup_leak_frames()
	_create_leak_visuals()
	_create_audio_players()
	_create_game_result()

	var resize_callable: Callable = Callable(self, "_on_viewport_resized")
	if not get_viewport().size_changed.is_connected(resize_callable):
		get_viewport().size_changed.connect(resize_callable)

	queue_redraw()


func _process(delta: float) -> void:
	_animation_time += delta
	_repair_flash_time = maxf(_repair_flash_time - delta, 0.0)
	_invalid_drop_time = maxf(_invalid_drop_time - delta, 0.0)

	if not _game_finished:
		_elapsed_game_time += delta
		_update_water_level(delta)

	_update_leak_animation()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _game_finished:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_event.pressed:
			_try_start_patch_drag(mouse_event.position)
		else:
			_finish_patch_drag(mouse_event.position)

	elif event is InputEventMouseMotion and _dragging_patch:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		_drag_position = motion_event.position


func _on_viewport_resized() -> void:
	_update_leak_sprite_transforms()
	queue_redraw()


func _generate_leaks() -> void:
	_leaks.clear()
	var candidate_indexes: Array[int] = []

	for index: int in range(LEAK_CANDIDATES.size()):
		candidate_indexes.append(index)

	_shuffle_integer_array(candidate_indexes)
	var amount: int = mini(leak_count, candidate_indexes.size())

	for index: int in range(amount):
		var candidate_index: int = candidate_indexes[index]
		_leaks.append({
			"position": LEAK_CANDIDATES[candidate_index],
			"repaired": false
		})


func _shuffle_integer_array(values: Array[int]) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var random_index: int = _random.randi_range(0, index)
		var temporary_value: int = values[index]
		values[index] = values[random_index]
		values[random_index] = temporary_value


func _setup_leak_frames() -> void:
	_leak_frames.clear()

	if leak_frame_01 != null:
		_leak_frames.append(leak_frame_01)
	if leak_frame_02 != null:
		_leak_frames.append(leak_frame_02)
	if leak_frame_03 != null:
		_leak_frames.append(leak_frame_03)

	if _leak_frames.is_empty():
		push_warning(
			"No hay imágenes asignadas para las fugas. "
			+ "Asigna Leak Frame 01, 02 y 03 en el Inspector."
		)


func _create_leak_visuals() -> void:
	_leak_visuals_root = Node2D.new()
	_leak_visuals_root.name = "LeakVisuals"
	add_child(_leak_visuals_root)

	_leak_sprites.clear()

	for leak_index: int in range(_leaks.size()):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "LeakSprite%02d" % (leak_index + 1)
		sprite.centered = true
		sprite.z_index = 10
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

		if not _leak_frames.is_empty():
			sprite.texture = _leak_frames[leak_index % _leak_frames.size()]

		_leak_visuals_root.add_child(sprite)
		_leak_sprites.append(sprite)

	_update_leak_sprite_transforms()
	_update_leak_animation(true)


func _update_leak_sprite_transforms() -> void:
	if _leak_sprites.size() != _leaks.size():
		return

	var visual_scale: float = _get_visual_scale()

	for leak_index: int in range(_leak_sprites.size()):
		var sprite: Sprite2D = _leak_sprites[leak_index]
		var leak: Dictionary = _leaks[leak_index]
		var leak_position: Vector2 = _normalized_to_board(
			leak.get("position", Vector2.ZERO)
		)

		var texture_height: float = 1.0
		if sprite.texture != null:
			texture_height = maxf(float(sprite.texture.get_height()), 1.0)

		var target_height: float = leak_sprite_height * visual_scale
		var uniform_scale: float = target_height / texture_height
		sprite.scale = Vector2.ONE * uniform_scale

		# La base del chorro queda alineada con la grieta del tubo.
		sprite.position = leak_position + Vector2(
			0.0,
			-target_height * 0.5 + leak_sprite_vertical_offset * visual_scale
		)


func _update_leak_animation(force_update: bool = false) -> void:
	if _leak_frames.is_empty():
		return
	if _leak_sprites.size() != _leaks.size():
		return

	var frame_index: int = int(
		floor(_animation_time * leak_frame_fps)
	) % _leak_frames.size()

	if not force_update and frame_index == _current_leak_frame:
		return

	_current_leak_frame = frame_index

	for leak_index: int in range(_leak_sprites.size()):
		var sprite: Sprite2D = _leak_sprites[leak_index]
		var leak: Dictionary = _leaks[leak_index]
		var repaired: bool = bool(leak.get("repaired", false))

		sprite.visible = not repaired
		if repaired:
			continue

		# Desfase por fuga para que no todas cambien exactamente al mismo tiempo.
		var local_frame: int = (
			frame_index + leak_index
		) % _leak_frames.size()
		sprite.texture = _leak_frames[local_frame]

	_update_leak_sprite_transforms()


func _create_audio_players() -> void:
	# Esta versión reutiliza los AudioStreamPlayer que ya colocaste
	# manualmente en la escena. Si falta alguno, lo crea por código.
	_background_music_player = _get_or_create_audio_player("BackgroundMusic")
	_patch_sound_player = _get_or_create_audio_player("PatchSound")

	# Si asignaste los audios desde las variables exportadas, tienen prioridad.
	# Si no, se conserva el Stream colocado directamente en cada nodo.
	if background_music_stream != null:
		_background_music_player.stream = background_music_stream
	if patch_sound_stream != null:
		_patch_sound_player.stream = patch_sound_stream

	_background_music_player.bus = "Master"
	_background_music_player.volume_db = maxf(background_music_volume_db, -16.0)
	_background_music_player.max_polyphony = 1

	_patch_sound_player.bus = "Master"
	_patch_sound_player.volume_db = maxf(patch_sound_volume_db, -8.0)
	_patch_sound_player.max_polyphony = 2

	var background_finished: Callable = Callable(self, "_on_background_music_finished")
	if not _background_music_player.finished.is_connected(background_finished):
		_background_music_player.finished.connect(background_finished)

	# LeakSound01 funciona como plantilla para todas las fugas.
	var leak_template: AudioStreamPlayer = _get_or_create_audio_player("LeakSound01")
	if leak_sound_stream != null:
		leak_template.stream = leak_sound_stream

	var shared_leak_stream: AudioStream = leak_template.stream
	_leak_sound_players.clear()

	for leak_index: int in range(_leaks.size()):
		var player_name: String = "LeakSound%02d" % (leak_index + 1)
		var leak_player: AudioStreamPlayer = _get_or_create_audio_player(player_name)

		if leak_sound_stream != null:
			leak_player.stream = leak_sound_stream
		elif leak_player.stream == null:
			leak_player.stream = shared_leak_stream

		leak_player.bus = "Master"
		leak_player.volume_db = maxf(leak_sound_volume_db, -18.0)
		leak_player.pitch_scale = _random.randf_range(0.94, 1.06)
		leak_player.max_polyphony = 1

		var finished_callable: Callable = Callable(
			self,
			"_on_leak_sound_finished"
		).bind(leak_index)
		if not leak_player.finished.is_connected(finished_callable):
			leak_player.finished.connect(finished_callable)

		_leak_sound_players.append(leak_player)

	if _background_music_player.stream == null:
		push_warning(
			"BackgroundMusic no tiene un audio asignado. "
			+ "Coloca la música en el Stream del nodo BackgroundMusic."
		)

	if shared_leak_stream == null and leak_sound_stream == null:
		push_warning(
			"LeakSound01 no tiene un audio asignado. "
			+ "Coloca el sonido de fuga en el Stream de LeakSound01."
		)

	if _patch_sound_player.stream == null:
		push_warning(
			"PatchSound no tiene un audio asignado. "
			+ "Coloca el sonido del parche en el Stream del nodo PatchSound."
		)

	# Se inicia de forma diferida para garantizar que todos los nodos
	# de audio ya estén completamente dentro del árbol.
	call_deferred("_start_audio_after_ready")


func _get_or_create_audio_player(player_name: String) -> AudioStreamPlayer:
	var existing_node: Node = get_node_or_null(NodePath(player_name))
	if existing_node is AudioStreamPlayer:
		return existing_node as AudioStreamPlayer

	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	new_player.name = player_name
	add_child(new_player)
	return new_player


func _start_audio_after_ready() -> void:
	if _game_finished:
		return
	_start_background_music()
	_start_all_leak_sounds()


func _start_background_music() -> void:
	if _background_music_player == null:
		return
	if _background_music_player.stream == null:
		return
	if not _background_music_player.playing:
		_background_music_player.play(0.0)


func _on_background_music_finished() -> void:
	if _game_finished:
		return
	_start_background_music()


func _start_all_leak_sounds() -> void:
	for leak_index: int in range(_leak_sound_players.size()):
		_start_leak_sound(leak_index)


func _start_leak_sound(leak_index: int) -> void:
	if _game_finished:
		return
	if leak_index < 0 or leak_index >= _leak_sound_players.size():
		return
	if leak_index >= _leaks.size():
		return
	if bool(_leaks[leak_index].get("repaired", false)):
		return

	var leak_player: AudioStreamPlayer = _leak_sound_players[leak_index]
	if leak_player == null or leak_player.stream == null:
		return
	if leak_player.playing:
		return

	var start_position: float = 0.0
	var stream_length: float = leak_player.stream.get_length()
	if stream_length > 1.0:
		# Cada fuga empieza en un punto distinto para evitar que todas
		# suenen exactamente iguales al mismo tiempo.
		start_position = _random.randf_range(0.0, stream_length * 0.65)

	leak_player.play(start_position)


func _on_leak_sound_finished(leak_index: int) -> void:
	_start_leak_sound(leak_index)


func _stop_leak_sound(leak_index: int) -> void:
	if leak_index < 0 or leak_index >= _leak_sound_players.size():
		return

	var leak_player: AudioStreamPlayer = _leak_sound_players[leak_index]
	if leak_player != null:
		leak_player.stop()


func _play_patch_sound() -> void:
	if _patch_sound_player == null:
		return
	if _patch_sound_player.stream == null:
		return

	_patch_sound_player.stop()
	_patch_sound_player.pitch_scale = _random.randf_range(0.97, 1.03)
	_patch_sound_player.play(0.0)


func _stop_continuous_audio() -> void:
	if _background_music_player != null:
		_background_music_player.stop()

	for leak_player: AudioStreamPlayer in _leak_sound_players:
		if leak_player != null:
			leak_player.stop()


func _create_game_result() -> void:
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)


func _update_water_level(delta: float) -> void:
	var active_leaks: int = _count_active_leaks()
	if active_leaks <= 0:
		_finish_game(true)
		return

	var loss_per_second: float = (
		base_water_loss_per_second
		+ water_loss_per_active_leak * float(active_leaks)
	)

	# Durante los primeros segundos el agua se pierde más rápido.
	# El multiplicador baja suavemente hasta volver a 1.0.
	var initial_multiplier: float = 1.0

	if initial_fast_loss_duration > 0.0:
		var initial_progress: float = clampf(
			_elapsed_game_time / initial_fast_loss_duration,
			0.0,
			1.0
		)

		initial_multiplier = lerpf(
			initial_water_loss_multiplier,
			1.0,
			initial_progress
		)

	loss_per_second *= initial_multiplier
	loss_per_second *= _water_loss_age_multiplier


	_water_level = clampf(
		_water_level - loss_per_second * delta,
		0.0,
		starting_water
	)

	if _water_level <= 0.0:
		_finish_game(false)


func _count_active_leaks() -> int:
	var active_count: int = 0
	for leak: Dictionary in _leaks:
		if not bool(leak.get("repaired", false)):
			active_count += 1
	return active_count


func _try_start_patch_drag(mouse_position: Vector2) -> void:
	if not _get_patch_source_rect().has_point(mouse_position):
		return

	_dragging_patch = true
	_drag_position = mouse_position


func _finish_patch_drag(mouse_position: Vector2) -> void:
	if not _dragging_patch:
		return

	_dragging_patch = false
	_try_repair_leak(mouse_position)


func _try_repair_leak(mouse_position: Vector2) -> void:
	var maximum_distance: float = leak_hit_radius * _get_visual_scale()
	var selected_index: int = -1
	var nearest_distance: float = INF

	for index: int in range(_leaks.size()):
		var leak: Dictionary = _leaks[index]
		if bool(leak.get("repaired", false)):
			continue

		var leak_position: Vector2 = _normalized_to_board(
			leak.get("position", Vector2.ZERO)
		)
		var distance: float = mouse_position.distance_to(leak_position)

		if distance <= maximum_distance and distance < nearest_distance:
			nearest_distance = distance
			selected_index = index

	if selected_index < 0:
		_invalid_drop_position = mouse_position
		_invalid_drop_time = 0.45
		return

	var selected_leak: Dictionary = _leaks[selected_index]
	selected_leak["repaired"] = true
	_leaks[selected_index] = selected_leak
	_repair_flash_position = _normalized_to_board(
		selected_leak.get("position", Vector2.ZERO)
	)
	_repair_flash_time = 0.65

	_stop_leak_sound(selected_index)
	_play_patch_sound()
	_update_leak_animation(true)

	if _count_active_leaks() <= 0:
		_finish_game(true)


func _finish_game(did_win: bool) -> void:
	if _game_finished:
		return

	_game_finished = true
	_dragging_patch = false
	_stop_continuous_audio()

	if did_win:
		game_won.emit()
		if _game_result != null and _game_result.has_method("mostrar_ganaste"):
			_game_result.call("mostrar_ganaste")
	else:
		game_lost.emit()
		if _game_result != null and _game_result.has_method("mostrar_perdiste"):
			_game_result.call("mostrar_perdiste")


func _draw() -> void:
	_draw_background()
	_draw_board_surface()
	_draw_pipe_network()
	_draw_leaks()
	_draw_water_panel()
	_draw_patch_panel()
	_draw_water_mascot()
	_draw_feedback_effects()

	if _dragging_patch:
		var drag_bounce: float = 1.0 + sin(_animation_time * 9.0) * 0.05
		_draw_patch_icon(
			_drag_position,
			patch_visual_radius * _get_visual_scale() * drag_bounce,
			0.90,
			_animation_time * 0.75
		)


func _draw_background() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_rect: Rect2 = Rect2(Vector2.ZERO, viewport_size)
	var visual_scale: float = _get_visual_scale()

	_draw_vertical_gradient(
		viewport_rect,
		Color8(20, 132, 142),
		Color8(6, 67, 84),
		54
	)

	for index: int in range(18):
		var progress: float = float(index) / 17.0
		var circle_position: Vector2 = Vector2(
			progress * viewport_size.x,
			48.0 * visual_scale
			+ sin(_animation_time * 0.45 + float(index) * 0.9)
			* 10.0 * visual_scale
		)
		draw_circle(
			circle_position,
			34.0 * visual_scale,
			Color(0.24, 0.78, 0.79, 0.075)
		)

	_draw_corner_foliage()


func _draw_corner_foliage() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visual_scale: float = _get_visual_scale()
	var centers: Array[Vector2] = [
		Vector2(20.0, 20.0) * visual_scale,
		Vector2(viewport_size.x - 20.0 * visual_scale, 20.0 * visual_scale),
		Vector2(22.0 * visual_scale, viewport_size.y - 22.0 * visual_scale),
		Vector2(viewport_size.x - 25.0 * visual_scale, viewport_size.y - 20.0 * visual_scale)
	]

	for center_index: int in range(centers.size()):
		var center: Vector2 = centers[center_index]
		for leaf_index: int in range(7):
			var angle: float = (
				float(leaf_index) * TAU / 7.0
				+ sin(_animation_time * 0.35 + float(center_index)) * 0.08
			)
			var leaf_center: Vector2 = (
				center
				+ Vector2.RIGHT.rotated(angle) * 30.0 * visual_scale
			)
			_draw_ellipse_shape(
				leaf_center,
				Vector2(22.0, 12.0) * visual_scale,
				angle,
				Color8(54, 145, 68)
			)
			_draw_ellipse_shape(
				leaf_center - Vector2(4.0, 3.0) * visual_scale,
				Vector2(12.0, 5.0) * visual_scale,
				angle,
				Color8(124, 210, 86)
			)


func _draw_board_surface() -> void:
	var board_rect: Rect2 = _get_board_rect()
	var visual_scale: float = _get_visual_scale()

	_draw_rounded_rect(
		Rect2(board_rect.position + Vector2(12.0, 14.0) * visual_scale, board_rect.size),
		30.0 * visual_scale,
		Color(0.01, 0.08, 0.10, 0.55)
	)

	_draw_rounded_rect(
		board_rect,
		31.0 * visual_scale,
		Color8(135, 69, 31)
	)

	_draw_rounded_rect(
		board_rect.grow(-7.0 * visual_scale),
		26.0 * visual_scale,
		Color8(224, 149, 76)
	)

	var inner_rect: Rect2 = board_rect.grow(-15.0 * visual_scale)
	_draw_wall_gradient(inner_rect)
	_draw_wall_texture(inner_rect)


func _draw_wall_gradient(rect: Rect2) -> void:
	var visual_scale: float = _get_visual_scale()
	var steps: int = 42
	var strip_height: float = rect.size.y / float(steps)

	for index: int in range(steps):
		var progress: float = float(index) / float(steps - 1)
		var color: Color = Color8(255, 226, 181).lerp(
			Color8(231, 190, 141),
			progress
		)
		var strip_rect: Rect2 = Rect2(
			Vector2(rect.position.x, rect.position.y + strip_height * float(index)),
			Vector2(rect.size.x, strip_height + 1.0)
		)
		draw_rect(strip_rect, color, true)

	var border_points: PackedVector2Array = _rounded_rect_points(
		rect,
		20.0 * visual_scale,
		8
	)
	var closed_points: PackedVector2Array = _close_polyline(border_points)
	draw_polyline(closed_points, Color8(194, 126, 62), 4.0 * visual_scale, true)


func _draw_wall_texture(rect: Rect2) -> void:
	var visual_scale: float = _get_visual_scale()
	var brick_width: float = 150.0 * visual_scale
	var brick_height: float = 82.0 * visual_scale
	var rows: int = int(rect.size.y / brick_height) + 2
	var columns: int = int(rect.size.x / brick_width) + 3

	for row: int in range(rows):
		var x_offset: float = brick_width * 0.5 if row % 2 == 1 else 0.0
		for column: int in range(columns):
			var brick_rect: Rect2 = Rect2(
				Vector2(
					rect.position.x + float(column) * brick_width - x_offset + 7.0 * visual_scale,
					rect.position.y + float(row) * brick_height + 7.0 * visual_scale
				),
				Vector2(
					brick_width - 14.0 * visual_scale,
					brick_height - 14.0 * visual_scale
				)
			)
			draw_rect(
				brick_rect,
				Color(0.52, 0.28, 0.12, 0.07),
				false,
				2.0 * visual_scale
			)

	for stain_index: int in range(12):
		var seed_value: float = float(stain_index) * 7.31
		var stain_position: Vector2 = Vector2(
			rect.position.x + rect.size.x * (0.08 + fmod(seed_value * 0.173, 0.84)),
			rect.position.y + rect.size.y * (0.10 + fmod(seed_value * 0.291, 0.78))
		)
		var stain_radius: float = (18.0 + fmod(seed_value * 9.0, 22.0)) * visual_scale
		draw_circle(stain_position, stain_radius, Color(0.38, 0.20, 0.08, 0.035))

	for crack_index: int in range(5):
		var start: Vector2 = Vector2(
			rect.position.x + rect.size.x * (0.18 + float(crack_index) * 0.16),
			rect.position.y + rect.size.y * (0.20 + fmod(float(crack_index) * 0.27, 0.55))
		)
		_draw_wall_crack(start, 32.0 * visual_scale, float(crack_index) * 0.8)


func _draw_wall_crack(start: Vector2, length: float, angle: float) -> void:
	var visual_scale: float = _get_visual_scale()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(start)

	for index: int in range(1, 5):
		var progress: float = float(index) / 4.0
		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * length * progress
		offset += Vector2(0.0, sin(float(index) * 2.3 + angle) * 7.0 * visual_scale)
		points.append(start + offset)

	draw_polyline(points, Color(0.35, 0.18, 0.08, 0.16), 2.0 * visual_scale, true)



func _draw_pipe_network() -> void:
	var visual_scale: float = _get_visual_scale()
	var pipe_width: float = 30.0 * visual_scale

	for route_index: int in range(PIPE_ROUTES.size()):
		var route: Array = PIPE_ROUTES[route_index]
		var points: PackedVector2Array = PackedVector2Array()

		for normalized_point: Vector2 in route:
			points.append(_normalized_to_board(normalized_point))

		var shadow_points: PackedVector2Array = _offset_points(
			points,
			Vector2(7.0, 9.0) * visual_scale
		)
		var lower_shade_points: PackedVector2Array = _offset_points(
			points,
			Vector2(0.0, 4.5) * visual_scale
		)
		var upper_highlight_points: PackedVector2Array = _offset_points(
			points,
			Vector2(0.0, -5.0) * visual_scale
		)

		draw_polyline(shadow_points, Color(0.12, 0.08, 0.05, 0.38), pipe_width + 17.0 * visual_scale, true)
		draw_polyline(points, Color8(45, 53, 57), pipe_width + 14.0 * visual_scale, true)
		draw_polyline(points, Color8(107, 133, 142), pipe_width + 7.0 * visual_scale, true)
		draw_polyline(lower_shade_points, Color8(80, 108, 119), pipe_width * 0.72, true)
		draw_polyline(points, Color8(169, 196, 202), pipe_width * 0.78, true)
		draw_polyline(upper_highlight_points, Color8(230, 243, 243), pipe_width * 0.24, true)

		for segment_index: int in range(points.size() - 1):
			_draw_pipe_segment_details(
				points[segment_index],
				points[segment_index + 1],
				pipe_width,
				route_index,
				segment_index
			)

		for point: Vector2 in points:
			_draw_pipe_joint(point, pipe_width)


func _draw_pipe_segment_details(
	start: Vector2,
	end: Vector2,
	pipe_width: float,
	route_index: int,
	segment_index: int
) -> void:
	var visual_scale: float = _get_visual_scale()
	var direction: Vector2 = (end - start).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var segment_length: float = start.distance_to(end)

	if segment_length < 80.0 * visual_scale:
		return

	var collar_count: int = 1 if segment_length < 220.0 * visual_scale else 2
	for collar_index: int in range(collar_count):
		var t: float = float(collar_index + 1) / float(collar_count + 1)
		var center: Vector2 = start.lerp(end, t)
		var half_length: float = pipe_width * 0.70
		var outer_a: Vector2 = center - perpendicular * half_length
		var outer_b: Vector2 = center + perpendicular * half_length
		draw_line(outer_a, outer_b, Color8(53, 61, 63), 8.0 * visual_scale, true)
		draw_line(outer_a, outer_b, Color8(190, 207, 209), 4.0 * visual_scale, true)
		draw_line(
			outer_a + direction * 3.0 * visual_scale,
			outer_b + direction * 3.0 * visual_scale,
			Color8(98, 119, 125),
			2.0 * visual_scale,
			true
		)

	var rust_seed: float = float(route_index * 11 + segment_index * 7 + 3)
	for rust_index: int in range(2):
		var t: float = 0.22 + fmod(rust_seed * 0.173 + float(rust_index) * 0.37, 0.56)
		var rust_center: Vector2 = start.lerp(end, t)
		rust_center += perpendicular * sin(rust_seed + float(rust_index)) * pipe_width * 0.18
		draw_circle(rust_center, 3.5 * visual_scale, Color(0.53, 0.24, 0.08, 0.55))
		draw_circle(
			rust_center - Vector2(1.0, 1.0) * visual_scale,
			1.7 * visual_scale,
			Color(0.78, 0.39, 0.12, 0.55)
		)


func _draw_pipe_joint(position: Vector2, pipe_width: float) -> void:
	var visual_scale: float = _get_visual_scale()
	var outer_radius: float = pipe_width * 0.72

	draw_circle(
		position + Vector2(5.0, 6.0) * visual_scale,
		outer_radius,
		Color(0.10, 0.07, 0.05, 0.38)
	)
	draw_circle(position, outer_radius, Color8(46, 56, 60))
	draw_circle(position, outer_radius * 0.83, Color8(109, 135, 143))
	draw_circle(position, outer_radius * 0.63, Color8(177, 199, 204))
	draw_circle(
		position - Vector2(4.0, 5.0) * visual_scale,
		outer_radius * 0.24,
		Color8(235, 246, 246)
	)

	for index: int in range(4):
		var angle: float = float(index) * TAU / 4.0 + PI * 0.25
		var bolt_position: Vector2 = position + Vector2.RIGHT.rotated(angle) * outer_radius * 0.62
		draw_circle(bolt_position, 3.0 * visual_scale, Color8(45, 55, 59))
		draw_circle(
			bolt_position - Vector2(0.8, 0.8) * visual_scale,
			1.2 * visual_scale,
			Color8(204, 222, 224)
		)


func _draw_leaks() -> void:
	var visual_scale: float = _get_visual_scale()

	# Las fugas abiertas se muestran con Sprite2D animados.
	# Aquí solamente se dibujan los parches de las fugas reparadas.
	for index: int in range(_leaks.size()):
		var leak: Dictionary = _leaks[index]
		if not bool(leak.get("repaired", false)):
			continue

		var leak_position: Vector2 = _normalized_to_board(
			leak.get("position", Vector2.ZERO)
		)
		var repaired_pulse: float = (
			1.0 + sin(_animation_time * 2.4 + float(index)) * 0.025
		)
		_draw_patch_icon(
			leak_position,
			patch_visual_radius * visual_scale * repaired_pulse,
			1.0,
			0.03 * sin(float(index))
		)


func _draw_patch_icon(center: Vector2, radius: float, alpha: float, rotation: float) -> void:
	draw_circle(
		center + Vector2(5.0, 7.0),
		radius * 1.11,
		Color(0.12, 0.05, 0.02, alpha * 0.45)
	)
	draw_circle(center, radius * 1.10, Color(0.53, 0.22, 0.04, alpha))
	draw_circle(center, radius, Color(0.96, 0.47, 0.10, alpha))
	draw_circle(
		center - Vector2(radius * 0.17, radius * 0.20),
		radius * 0.68,
		Color(1.0, 0.72, 0.25, alpha)
	)

	var local_corners: Array[Vector2] = [
		Vector2(-0.58, -0.45) * radius,
		Vector2(0.58, -0.45) * radius,
		Vector2(0.58, 0.45) * radius,
		Vector2(-0.58, 0.45) * radius
	]
	var patch_points: PackedVector2Array = PackedVector2Array()

	for local_point: Vector2 in local_corners:
		patch_points.append(center + local_point.rotated(rotation))

	draw_colored_polygon(patch_points, Color(0.35, 0.17, 0.08, alpha))
	_draw_polygon_border(patch_points, Color(0.17, 0.07, 0.03, alpha), 3.0)

	var inset_points: PackedVector2Array = PackedVector2Array()
	for local_point: Vector2 in local_corners:
		inset_points.append(center + (local_point * 0.76).rotated(rotation))
	_draw_dashed_polygon_border(
		inset_points,
		Color(1.0, 0.83, 0.50, alpha),
		2.5,
		7
	)

	for corner: Vector2 in patch_points:
		draw_circle(corner, 2.7, Color(0.95, 0.79, 0.47, alpha))


func _draw_water_panel() -> void:
	var visual_scale: float = _get_visual_scale()
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_rect: Rect2 = Rect2(
		Vector2(
			viewport_size.x - 252.0 * visual_scale,
			30.0 * visual_scale
		),
		Vector2(215.0, 455.0) * visual_scale
	)

	# Paleta inspirada en el panel de derrota de GameResult.
	var panel_shadow_color: Color = Color(0.22, 0.12, 0.06, 0.42)
	var panel_border_color: Color = Color8(221, 121, 55)
	var panel_background_color: Color = Color8(239, 207, 160)
	var panel_inner_color: Color = Color8(247, 222, 183)
	var panel_text_color: Color = Color8(58, 88, 137)
	var panel_highlight_color: Color = Color(1.0, 0.96, 0.84, 0.45)

	# Sombra y cuerpo principal del panel.
	_draw_rounded_rect(
		Rect2(
			panel_rect.position + Vector2(7.0, 10.0) * visual_scale,
			panel_rect.size
		),
		30.0 * visual_scale,
		panel_shadow_color
	)
	_draw_rounded_rect(
		panel_rect,
		30.0 * visual_scale,
		panel_border_color
	)
	_draw_rounded_rect(
		panel_rect.grow(-7.0 * visual_scale),
		24.0 * visual_scale,
		panel_background_color
	)
	_draw_rounded_rect(
		panel_rect.grow(-13.0 * visual_scale),
		19.0 * visual_scale,
		panel_inner_color
	)

	# Brillo suave superior para dar volumen.
	_draw_rounded_rect(
		Rect2(
			panel_rect.position + Vector2(18.0, 14.0) * visual_scale,
			Vector2(
				panel_rect.size.x - 36.0 * visual_scale,
				18.0 * visual_scale
			)
		),
		8.0 * visual_scale,
		panel_highlight_color
	)

	# Encabezado beige con borde naranja, igual al cuadro de resultado.
	var header_rect: Rect2 = Rect2(
		panel_rect.position + Vector2(17.0, 18.0) * visual_scale,
		Vector2(
			panel_rect.size.x - 34.0 * visual_scale,
			55.0 * visual_scale
		)
	)
	_draw_rounded_rect(
		header_rect,
		18.0 * visual_scale,
		panel_border_color
	)
	_draw_rounded_rect(
		header_rect.grow(-4.0 * visual_scale),
		14.0 * visual_scale,
		Color8(242, 211, 165)
	)

	var font: Font = ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(
			header_rect.position.x,
			header_rect.position.y + 38.0 * visual_scale
		),
		"AGUA",
		HORIZONTAL_ALIGNMENT_CENTER,
		header_rect.size.x,
		int(27.0 * visual_scale),
		panel_text_color
	)

	# Marco del tanque con la misma paleta cálida del panel.
	var tank_rect: Rect2 = Rect2(
		panel_rect.position + Vector2(59.0, 95.0) * visual_scale,
		Vector2(97.0, 275.0) * visual_scale
	)
	_draw_rounded_rect(
		Rect2(
			tank_rect.position + Vector2(4.0, 6.0) * visual_scale,
			tank_rect.size
		),
		21.0 * visual_scale,
		Color(0.22, 0.12, 0.06, 0.35)
	)
	_draw_rounded_rect(
		tank_rect,
		21.0 * visual_scale,
		panel_border_color
	)
	_draw_rounded_rect(
		tank_rect.grow(-5.0 * visual_scale),
		16.0 * visual_scale,
		Color8(250, 228, 193)
	)
	_draw_rounded_rect(
		tank_rect.grow(-10.0 * visual_scale),
		12.0 * visual_scale,
		Color8(18, 49, 76)
	)

	var inner_tank: Rect2 = tank_rect.grow(-15.0 * visual_scale)
	var water_percentage: float = _water_level / starting_water
	var water_height: float = inner_tank.size.y * water_percentage
	var water_rect: Rect2 = Rect2(
		Vector2(
			inner_tank.position.x,
			inner_tank.end.y - water_height
		),
		Vector2(inner_tank.size.x, water_height)
	)

	var water_color: Color = Color8(37, 177, 239)
	if water_percentage <= 0.50:
		water_color = Color8(244, 166, 44)
	if water_percentage <= 0.25:
		water_color = Color8(233, 72, 58)

	if water_height > 0.0:
		_draw_vertical_gradient(
			water_rect,
			water_color.lightened(0.18),
			water_color.darkened(0.18),
			28
		)
		_draw_water_surface(
			inner_tank,
			water_rect,
			water_color,
			visual_scale
		)
		_draw_tank_bubbles(
			inner_tank,
			water_rect,
			visual_scale
		)

	# Reflejo del vidrio.
	_draw_rounded_rect(
		Rect2(
			inner_tank.position + Vector2(7.0, 10.0) * visual_scale,
			Vector2(
				10.0 * visual_scale,
				inner_tank.size.y - 20.0 * visual_scale
			)
		),
		5.0 * visual_scale,
		Color(0.90, 0.98, 1.0, 0.24)
	)

	var percentage_text: String = str(int(round(_water_level))) + "%"
	var danger_pulse: float = 1.0
	if water_percentage <= 0.25:
		danger_pulse = 1.0 + sin(_animation_time * 8.0) * 0.08

	draw_string(
		font,
		Vector2(
			panel_rect.position.x,
			panel_rect.end.y - 39.0 * visual_scale
		),
		percentage_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		int(34.0 * visual_scale * danger_pulse),
		panel_text_color
	)
	draw_string(
		font,
		Vector2(
			panel_rect.position.x,
			panel_rect.end.y - 10.0 * visual_scale
		),
		"Fugas: " + str(_count_active_leaks()),
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		int(17.0 * visual_scale),
		panel_text_color
	)

func _draw_water_surface(
	inner_tank: Rect2,
	water_rect: Rect2,
	water_color: Color,
	visual_scale: float
) -> void:
	var wave_points: PackedVector2Array = PackedVector2Array()
	for index: int in range(17):
		var progress: float = float(index) / 16.0
		var x: float = inner_tank.position.x + progress * inner_tank.size.x
		var y: float = water_rect.position.y + sin(
			progress * TAU * 2.0 + _animation_time * 4.2
		) * 4.5 * visual_scale
		wave_points.append(Vector2(x, y))

	draw_polyline(
		wave_points,
		water_color.lightened(0.42),
		5.0 * visual_scale,
		true
	)


func _draw_tank_bubbles(inner_tank: Rect2, water_rect: Rect2, visual_scale: float) -> void:
	for bubble_index: int in range(8):
		var progress: float = fmod(
			_animation_time * (0.22 + float(bubble_index) * 0.015)
			+ float(bubble_index) * 0.13,
			1.0
		)
		var x_progress: float = 0.14 + fmod(float(bubble_index) * 0.23, 0.72)
		var bubble_position: Vector2 = Vector2(
			inner_tank.position.x + inner_tank.size.x * x_progress,
			inner_tank.end.y - progress * water_rect.size.y
		)
		if bubble_position.y >= water_rect.position.y:
			draw_circle(
				bubble_position,
				(2.5 + float(bubble_index % 3)) * visual_scale,
				Color(0.78, 0.95, 1.0, 0.55)
			)


func _draw_patch_panel() -> void:
	var panel_rect: Rect2 = _get_patch_source_rect()
	var visual_scale: float = _get_visual_scale()
	var glow_alpha: float = 0.18 + (sin(_animation_time * 3.0) + 1.0) * 0.08

	_draw_rounded_rect(
		panel_rect.grow(8.0 * visual_scale),
		28.0 * visual_scale,
		Color(1.0, 0.65, 0.10, glow_alpha)
	)
	_draw_rounded_rect(
		Rect2(panel_rect.position + Vector2(7.0, 9.0) * visual_scale, panel_rect.size),
		25.0 * visual_scale,
		Color(0.16, 0.07, 0.02, 0.48)
	)
	_draw_rounded_rect(panel_rect, 25.0 * visual_scale, Color8(136, 67, 16))
	_draw_rounded_rect(panel_rect.grow(-6.0 * visual_scale), 20.0 * visual_scale, Color8(249, 190, 70))
	_draw_rounded_rect(panel_rect.grow(-12.0 * visual_scale), 15.0 * visual_scale, Color8(255, 224, 145))

	var font: Font = ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 36.0 * visual_scale),
		"ARRASTRA",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		int(21.0 * visual_scale),
		Color8(99, 49, 16)
	)
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 62.0 * visual_scale),
		"EL PARCHE",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		int(21.0 * visual_scale),
		Color8(99, 49, 16)
	)

	var patch_bounce: float = sin(_animation_time * 3.0) * interface_bounce_amount * visual_scale
	var patch_center: Vector2 = Vector2(
		panel_rect.get_center().x,
		panel_rect.position.y + panel_rect.size.y * 0.71 + patch_bounce
	)
	_draw_patch_icon(
		patch_center,
		patch_visual_radius * visual_scale,
		1.0,
		sin(_animation_time * 2.0) * 0.08
	)

	for index: int in range(4):
		var angle: float = _animation_time * 1.5 + float(index) * TAU / 4.0
		var sparkle_position: Vector2 = patch_center + Vector2.RIGHT.rotated(angle) * 52.0 * visual_scale
		draw_circle(sparkle_position, 3.5 * visual_scale, Color8(255, 250, 188))


func _draw_water_mascot() -> void:
	var board_rect: Rect2 = _get_board_rect()
	var visual_scale: float = _get_visual_scale()
	var bob: float = sin(_animation_time * 2.4) * 5.0 * visual_scale
	var center: Vector2 = Vector2(
		board_rect.position.x + 47.0 * visual_scale,
		board_rect.end.y - 45.0 * visual_scale + bob
	)
	var radius: float = 28.0 * visual_scale
	var drop_points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -radius * 1.45),
		center + Vector2(radius * 0.86, -radius * 0.14),
		center + Vector2(radius * 0.74, radius * 0.65),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.74, radius * 0.65),
		center + Vector2(-radius * 0.86, -radius * 0.14)
	])

	draw_colored_polygon(drop_points, Color8(45, 178, 238))
	_draw_polygon_border(drop_points, Color8(12, 95, 154), 3.0 * visual_scale)
	draw_circle(
		center - Vector2(8.0, 14.0) * visual_scale,
		10.0 * visual_scale,
		Color(0.76, 0.95, 1.0, 0.72)
	)

	var blinking: bool = fmod(_animation_time, 4.0) > 3.78
	var eye_height: float = 1.5 if blinking else 8.0

	for eye_x: float in [-9.0, 9.0]:
		_draw_ellipse_shape(
			center + Vector2(eye_x, 3.0) * visual_scale,
			Vector2(4.0, eye_height) * visual_scale,
			0.0,
			Color8(17, 47, 68)
		)

	draw_arc(
		center + Vector2(0.0, 14.0) * visual_scale,
		8.0 * visual_scale,
		0.15,
		PI - 0.15,
		18,
		Color8(17, 47, 68),
		3.0 * visual_scale,
		true
	)


func _draw_feedback_effects() -> void:
	var visual_scale: float = _get_visual_scale()

	if _repair_flash_time > 0.0:
		var repair_progress: float = 1.0 - _repair_flash_time / 0.65
		var flash_radius: float = (25.0 + repair_progress * 55.0) * visual_scale
		draw_arc(
			_repair_flash_position,
			flash_radius,
			0.0,
			TAU,
			36,
			Color(1.0, 0.91, 0.27, 1.0 - repair_progress),
			6.0 * visual_scale,
			true
		)

		for index: int in range(10):
			var angle: float = float(index) * TAU / 10.0
			var sparkle_position: Vector2 = _repair_flash_position + Vector2.RIGHT.rotated(angle) * flash_radius
			draw_circle(
				sparkle_position,
				5.0 * visual_scale,
				Color(1.0, 0.96, 0.45, 1.0 - repair_progress)
			)

	if _invalid_drop_time > 0.0:
		var invalid_progress: float = 1.0 - _invalid_drop_time / 0.45
		draw_arc(
			_invalid_drop_position,
			(25.0 + invalid_progress * 30.0) * visual_scale,
			0.0,
			TAU,
			30,
			Color(1.0, 0.18, 0.12, 1.0 - invalid_progress),
			5.0 * visual_scale,
			true
		)


func _get_board_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visual_scale: float = _get_visual_scale()
	var margin: float = 28.0 * visual_scale
	var top_margin: float = 30.0 * visual_scale
	var right_panel_width: float = 294.0 * visual_scale

	return Rect2(
		Vector2(margin, top_margin),
		Vector2(
			viewport_size.x - right_panel_width - margin * 2.0,
			viewport_size.y - top_margin - margin
		)
	)


func _get_patch_source_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visual_scale: float = _get_visual_scale()
	return Rect2(
		Vector2(
			viewport_size.x - 252.0 * visual_scale,
			viewport_size.y - 292.0 * visual_scale
		),
		Vector2(215.0, 248.0) * visual_scale
	)


func _normalized_to_board(normalized_position: Vector2) -> Vector2:
	var board_rect: Rect2 = _get_board_rect()
	return board_rect.position + Vector2(
		normalized_position.x * board_rect.size.x,
		normalized_position.y * board_rect.size.y
	)


func _get_visual_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return clampf(
		minf(viewport_size.x / 1536.0, viewport_size.y / 1024.0),
		0.65,
		1.30
	)


func _draw_vertical_gradient(
	rect: Rect2,
	top_color: Color,
	bottom_color: Color,
	steps: int
) -> void:
	if steps <= 0 or rect.size.y <= 0.0:
		return

	var strip_height: float = rect.size.y / float(steps)
	for index: int in range(steps):
		var progress: float = float(index) / float(maxi(steps - 1, 1))
		var strip_color: Color = top_color.lerp(bottom_color, progress)
		draw_rect(
			Rect2(
				Vector2(rect.position.x, rect.position.y + strip_height * float(index)),
				Vector2(rect.size.x, strip_height + 1.0)
			),
			strip_color,
			true
		)


func _draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = _rounded_rect_points(rect, radius, 9)
	if points.size() >= 3:
		draw_colored_polygon(points, color)


func _rounded_rect_points(
	rect: Rect2,
	radius: float,
	segments_per_corner: int
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_radius: float = minf(
		radius,
		minf(rect.size.x, rect.size.y) * 0.5
	)
	var corner_centers: Array[Vector2] = [
		rect.position + Vector2(safe_radius, safe_radius),
		Vector2(rect.end.x - safe_radius, rect.position.y + safe_radius),
		rect.end - Vector2(safe_radius, safe_radius),
		Vector2(rect.position.x + safe_radius, rect.end.y - safe_radius)
	]
	var start_angles: Array[float] = [PI, -PI * 0.5, 0.0, PI * 0.5]

	for corner_index: int in range(4):
		for segment_index: int in range(segments_per_corner + 1):
			var progress: float = float(segment_index) / float(segments_per_corner)
			var angle: float = start_angles[corner_index] + progress * PI * 0.5
			points.append(
				corner_centers[corner_index]
				+ Vector2(cos(angle), sin(angle)) * safe_radius
			)

	return points


func _close_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var closed_points: PackedVector2Array = PackedVector2Array(points)
	if points.size() > 0:
		closed_points.append(points[0])
	return closed_points


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(point + offset)
	return result


func _draw_polygon_border(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(_close_polyline(points), color, width, true)


func _draw_dashed_polygon_border(
	points: PackedVector2Array,
	color: Color,
	width: float,
	dashes_per_side: int
) -> void:
	if points.size() < 2:
		return

	for index: int in range(points.size()):
		var start: Vector2 = points[index]
		var end: Vector2 = points[(index + 1) % points.size()]
		for dash_index: int in range(dashes_per_side):
			if dash_index % 2 == 1:
				continue
			var t0: float = float(dash_index) / float(dashes_per_side)
			var t1: float = float(dash_index + 1) / float(dashes_per_side)
			draw_line(start.lerp(end, t0), start.lerp(end, t1), color, width, true)


func _draw_ellipse_shape(
	center: Vector2,
	radius: Vector2,
	rotation: float,
	color: Color
) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(32):
		var angle: float = float(index) * TAU / 32.0
		var local_point: Vector2 = Vector2(
			cos(angle) * radius.x,
			sin(angle) * radius.y
		)
		points.append(center + local_point.rotated(rotation))
	draw_colored_polygon(points, color)


func _draw_star(
	center: Vector2,
	outer_radius: float,
	inner_radius: float,
	rotation: float
) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(10):
		var radius: float = outer_radius if index % 2 == 0 else inner_radius
		var angle: float = rotation - PI * 0.5 + float(index) * TAU / 10.0
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	draw_colored_polygon(points, Color8(255, 213, 49))
	_draw_polygon_border(points, Color8(157, 83, 10), 2.5)


func _draw_water_drop(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -radius * 1.45),
		center + Vector2(radius * 0.70, -radius * 0.10),
		center + Vector2(radius * 0.55, radius * 0.65),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.55, radius * 0.65),
		center + Vector2(-radius * 0.70, -radius * 0.10)
	])
	draw_colored_polygon(points, color)

# =========================================================
# WATER LOSS POR EDAD
# =========================================================
func _get_water_loss_multiplier(age: int) -> float:
	match age:
		11:
			return 0.75
		10:
			return 0.70
		9:
			return 0.65
		8:
			return 0.60
		7:
			return 0.55
		_:
			return 0.50 if age < 7 else 1.0
