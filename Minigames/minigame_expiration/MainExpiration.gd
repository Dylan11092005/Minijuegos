extends Node2D
class_name ExpirationMinigame


# =========================================================
# SIGNALS
# =========================================================

signal puzzle_completed
signal puzzle_failed
signal answer_resolved(was_correct: bool, score: int)


# =========================================================
# SCENES
# =========================================================

const TIMER_UI_SCENE := preload("res://Minigames/ui_global/TimerUi.tscn")
const GAME_RESULT_SCENE := preload("res://Minigames/ui_global/GameResult.tscn")
const LIVES_UI_SCENE := preload("res://Minigames/ui_global/LivesUi.tscn")


# =========================================================
# CONSTANTS
# =========================================================

## Nombres de mes en español, para escribir la fecha "larga"
## (ej. "26 de junio de 2026").
const MONTH_NAMES = [
	"enero", "febrero", "marzo", "abril", "mayo", "junio",
	"julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
]

const GLOBAL_SOUND_VOLUME := -10.0


# =========================================================
# EXPORTED VARIABLES
# =========================================================

## Arrastra aquí los Sprite2D de los productos que quieres que salgan al azar
## (Milk, Banana, Cereal, Cheese, Chicken, Yogurt, Bread... los que quieras
## incluir, el código no depende de cuántos sean).
@export var foods: Array[Sprite2D] = []

## El Label fijo donde se escribe la fecha de vencimiento al azar
## (el nodo "Date").
@export var date_label: Label

## El Label que muestra la fecha "de hoy" (el nodo "CurrentDate").
@export var current_date_label: Label

## Arrastra aquí directamente tus nodos "Fridge" y "Trash".
@export var fridge_drop_zone: Sprite2D
@export var trash_drop_zone: Sprite2D

## Color de las dos fechas.
@export var date_font_color: Color = Color("#0D70B7")

## Tamaño de la fecha de "hoy" (ya está perfecta, no la toques).
@export var current_date_font_size: int = 40

## Tamaño de la fecha de vencimiento (la mitad de la fecha de "hoy").
@export var expiration_date_font_size: int = 25

## Cuántos días antes o después de "hoy" puede caer la fecha de
## vencimiento sorteada (para adultos/niños mayores de 8 años). Con 30,
## la fecha puede caer hasta un mes antes (ya vencida) o hasta un mes
## después (todavía buena), con más o menos 50% de probabilidad de cada
## cosa, en vez de casi siempre caer en el mismo mes de hoy.
@export var expiration_range_days: int = 30

@export var snap_back_duration: float = 0.25
@export var resolve_duration: float = 0.3

## Arrastra aquí el ícono de "acertaste" (el nodo "Check"). Empieza
## invisible automáticamente; el script lo muestra y lo oculta solo.
@export var check_icon: Sprite2D

## Arrastra aquí el ícono de "te equivocaste" (el nodo "Error"). Empieza
## invisible automáticamente; el script lo muestra y lo oculta solo.
@export var error_icon: Sprite2D

## --- MODO NIÑOS PEQUEÑOS (8 años o menos) ---
## Para niños de 8 años o menos, en vez de fechas de vencimiento aparece
## uno de estos dos íconos al azar sobre el producto: "Good" (hay que
## guardarlo en la nevera) o "Bad" (hay que tirarlo a la basura).
## Arrastra aquí los nodos "Good" y "Bad".
@export var good_icon: Sprite2D
@export var bad_icon: Sprite2D

## Arrastra aquí TODOS los nodos que muestran fechas y que deben
## desaparecer en el modo niños pequeños: "Date", "CurrentDate", "Title"
## y "Current". No importa el orden ni el tipo exacto de cada nodo.
@export var kid_mode_date_nodes: Array[CanvasItem] = []

## Cuántos segundos se queda visible el ícono de acierto/error
## (incluyendo la animación de entrada y la de salida).
@export var feedback_duration: float = 0.5

## Cuántas vidas tiene el jugador antes de perder el minijuego.
@export var max_lives: int = 3

## Cuántos segundos debe sobrevivir el jugador (sin quedarse sin vidas)
## para ganar el minijuego. Calculado para 8 artículos (5 segundos cada uno).
@export var TOTAL_TIME: float = 40.0

## --- SONIDOS ---
## Arrastra aquí el nodo "BackgroundSound": empieza a sonar (en loop) en
## cuanto arranca el minijuego y se detiene cuando este termina.
@export var background_sound: AudioStreamPlayer

## Arrastra aquí el nodo "SuccessSound": suena cada vez que aciertas
## (guardar algo que no estaba vencido, o tirar algo que sí lo estaba).
@export var success_sound: AudioStreamPlayer

## Arrastra aquí el nodo "ErrorSound": suena cada vez que te equivocas.
@export var error_sound: AudioStreamPlayer


# =========================================================
# PRIVATE VARIABLES
# =========================================================

var _game_finished := false
var _lives: int = 0
var _score: int = 0
var _foods_resolved: int = 0

var _home_positions: Dictionary = {}
var _spawn_order: Array[Sprite2D] = []
var _current_food: Sprite2D
var _current_expiration_unix: int = 0
var _today_unix: int = 0
var _busy: bool = false

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

## Guarda la escala "original" de cada ícono de feedback (Check/Error)
## tal como la dejaste en el editor, para poder animarlos y devolverlos
## siempre a su tamaño correcto.
var _icon_base_scale: Dictionary = {}
var _feedback_tween: Tween

var _timer_ui: Node
var _game_result: Node
var _lives_ui: Node
var _progress_ui: Node2D

## true si el jugador tiene 8 años o menos: en ese caso se usa el modo
## Good/Bad en vez de fechas de vencimiento.
var _kid_mode: bool = false

## En modo niños pequeños, indica si el producto actual es "Good"
## (hay que guardarlo) o "Bad" (hay que tirarlo).
var _current_is_good: bool = true


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready() -> void:
	randomize()

	_game_finished = false
	_lives = max_lives

	# --- Modo niños pequeños (8 años o menos): en vez de fechas, se usan
	# los íconos Good/Bad. Se calcula una sola vez acá, al arrancar. ---
	_kid_mode = MinigameData.player_age <= 8
	print("DEBUG MinigameData.player_age = ", MinigameData.player_age, " | _kid_mode = ", _kid_mode)

	# --- Color y tamaño de las dos fechas ---
	current_date_label.add_theme_color_override("font_color", date_font_color)
	current_date_label.add_theme_font_size_override("font_size", current_date_font_size)

	date_label.add_theme_color_override("font_color", date_font_color)
	date_label.add_theme_font_size_override("font_size", expiration_date_font_size)

	# Guardamos la posición original (global) de cada producto, para poder
	# devolverlo a su sitio cada vez que vuelva a aparecer o si lo sueltan
	# en un lugar que no cuenta.
	for f in foods:
		_home_positions[f] = f.global_position

	# Orden en el que van a aparecer las comidas: cada una sale una sola
	# vez, en un orden distinto cada partida.
	_spawn_order = foods.duplicate()
	_spawn_order.shuffle()

	# --- Íconos de feedback (Check / Error): guardamos su escala original
	# y nos asegurarnos de que arranquen invisibles, sin importar cómo
	# hayan quedado en la escena. ---
	if check_icon:
		_icon_base_scale[check_icon] = _safe_icon_scale(check_icon)
		check_icon.modulate.a = 1.0
		check_icon.visible = false
		print("DEBUG check_icon listo. escala base = ", _icon_base_scale[check_icon])
	else:
		print("DEBUG check_icon NO está asignado en el Inspector")

	if error_icon:
		_icon_base_scale[error_icon] = _safe_icon_scale(error_icon)
		error_icon.modulate.a = 1.0
		error_icon.visible = false
		print("DEBUG error_icon listo. escala base = ", _icon_base_scale[error_icon])
	else:
		print("DEBUG error_icon NO está asignado en el Inspector")

	# --- Modo niños pequeños: ocultamos las fechas y dejamos listos
	# (invisibles) los íconos Good/Bad, que se van mostrando uno a la vez
	# en _generate_good_or_bad(). ---
	if _kid_mode:
		print("DEBUG kid_mode_date_nodes.size() = ", kid_mode_date_nodes.size())
		for node in kid_mode_date_nodes:
			if node:
				node.visible = false
				print("DEBUG ocultando nodo: ", node.name)
			else:
				print("DEBUG hay un elemento vacío (null) en kid_mode_date_nodes")

		if good_icon:
			good_icon.visible = false
		else:
			print("DEBUG good_icon NO está asignado en el Inspector")

		if bad_icon:
			bad_icon.visible = false
		else:
			print("DEBUG bad_icon NO está asignado en el Inspector")

	# --- Sonido de fondo: arranca apenas empieza el minijuego y se repite
	# en bucle para siempre (sin importar si el recurso de audio tiene o
	# no activado su propio "loop"), conectando la señal "finished" para
	# volver a reproducirlo cada vez que termina. ---
	if background_sound:
		background_sound.volume_db = GLOBAL_SOUND_VOLUME
		if not background_sound.finished.is_connected(_on_background_sound_finished):
			background_sound.finished.connect(_on_background_sound_finished)
		background_sound.play()
	else:
		print("DEBUG background_sound NO está asignado en el Inspector")

	if success_sound:
		success_sound.volume_db = GLOBAL_SOUND_VOLUME
	else:
		print("DEBUG success_sound NO está asignado en el Inspector")

	if error_sound:
		error_sound.volume_db = GLOBAL_SOUND_VOLUME
	else:
		print("DEBUG error_sound NO está asignado en el Inspector")

	# "Hoy" lo fijamos a la medianoche del día real del sistema.
	var now: Dictionary = Time.get_datetime_dict_from_system()
	_today_unix = Time.get_unix_time_from_datetime_dict({
		"year": now.year, "month": now.month, "day": now.day,
		"hour": 0, "minute": 0, "second": 0
	})
	current_date_label.text = _format_date(_today_unix)

	_setup_timer_ui()
	_setup_lives_ui()
	_setup_progress_ui()
	_setup_game_result()

	_spawn_random_food()


func _input(event: InputEvent) -> void:
	if _game_finished or _busy or _current_food == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _point_inside_sprite(get_global_mouse_position(), _current_food):
				_dragging = true
				_drag_offset = _current_food.global_position - get_global_mouse_position()
		else:
			if _dragging:
				_dragging = false
				_on_drop()

	elif event is InputEventMouseMotion and _dragging:
		_current_food.global_position = get_global_mouse_position() + _drag_offset


# =========================================================
# SETUP METHODS
# =========================================================

func _setup_timer_ui():
	_timer_ui = TIMER_UI_SCENE.instantiate()
	add_child(_timer_ui)

	# Tu TimerUi global emite la señal "time_up"

	if _timer_ui.has_signal("time_up"):
		_timer_ui.connect("time_up", Callable(self, "_on_time_up"))
	else:
		print("ERROR: El TimerUi no tiene la señal time_up")

	if _timer_ui.has_method("set_tamano_panel"):
		_timer_ui.set_tamano_panel(500, 60)

	if _timer_ui.has_method("iniciar"):
		var player_age: int = MinigameData.player_age

		if player_age < 12:
			TOTAL_TIME = 40.0 + _get_time_bonus(player_age)
		else:
			TOTAL_TIME = 40.0

		_timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para ganar")
	else:
		print("ERROR: El TimerUi no tiene el método iniciar()")


func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_lives)
	else:
		print("ERROR: LivesUi no tiene el método actualizar_vidas()")


## Crea el panel visual "FALTAN X / Y" con el mismo estilo de LivesUi
## (beige, borde naranja, texto azul). Se construye como un script en
## memoria (sin crear ningún archivo nuevo en el proyecto) y se agrega
## como un NODO HIJO al final de _ready(), exactamente igual que
## _setup_lives_ui(): así queda dibujado por encima del fondo y de las
## comidas, en vez de quedar escondido detrás de ellos.
func _setup_progress_ui():
	var script := GDScript.new()
	script.source_code = _get_progress_ui_script_source()
	script.reload()

	_progress_ui = Node2D.new()
	_progress_ui.set_script(script)
	add_child(_progress_ui)

	_update_progress_ui()


func _update_progress_ui():
	if _progress_ui == null:
		return

	# IMPORTANTE: usamos _foods_resolved (todos los productos ya jugados,
	# acertados o no) y NO _score (solo los aciertos). El juego se gana
	# cuando se terminan de jugar todos los productos (ver
	# _spawn_random_food()), sin importar si te equivocaste en alguno.
	# Si acá usáramos _score, la barra podía quedarse "a medias" (con
	# ítems marcados como "faltantes") aunque ya hubieras ganado el
	# minijuego, porque _score y _foods_resolved dejaban de coincidir en
	# cuanto fallabas una vez. Con _foods_resolved, la barra siempre
	# llega al 100% justo cuando se gana.
	if _progress_ui.has_method("actualizar_progreso"):
		_progress_ui.actualizar_progreso(_foods_resolved, _spawn_order.size())


func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)
	_game_result.process_mode = Node.PROCESS_MODE_ALWAYS

	if _game_result is CanvasLayer:
		_game_result.layer = 50

	_set_game_result_sound_volume()


func _set_game_result_sound_volume() -> void:
	if _game_result == null:
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
		var sound = _game_result.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


# =========================================================
# TIMER METHODS
# =========================================================

func _on_time_up():
	if _game_finished:
		return

	# Si llegamos aquí es porque todavía no había repartido los artículos.
	# Si ya los hubiera repartido todos, el juego ya habría terminado en
	# victoria antes de que sonara el tiempo (ver _spawn_random_food()).
	_lose_game()



func _stop_timer_ui():
	if _timer_ui == null:
		return

	if _timer_ui.has_method("detener"):
		_timer_ui.detener()


# =========================================================
# LIVES METHODS
# =========================================================

func _update_lives_ui():
	if _lives_ui == null:
		return

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_lives)


func _lose_life():
	_lives -= 1
	_update_lives_ui()

	if _lives <= 0:
		_lose_game()


# =========================================================
# COMIDA / ARRASTRE
# =========================================================

func _point_inside_sprite(point: Vector2, sprite: Sprite2D) -> bool:
	if sprite == null or sprite.texture == null:
		return false
	var size: Vector2 = sprite.texture.get_size() * sprite.scale
	var top_left: Vector2 = sprite.global_position - size * 0.5
	return Rect2(top_left, size).has_point(point)


func _on_drop() -> void:
	var p: Vector2 = _current_food.global_position
	if _point_inside_sprite(p, fridge_drop_zone):
		_resolve_choice(true)
	elif _point_inside_sprite(p, trash_drop_zone):
		_resolve_choice(false)
	else:
		_snap_back()


func _snap_back() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_current_food, "global_position", _home_positions[_current_food], snap_back_duration)


func _hide_all_foods() -> void:
	for f in foods:
		f.visible = false
		f.global_position = _home_positions[f]

	if _kid_mode:
		if good_icon:
			good_icon.visible = false
		if bad_icon:
			bad_icon.visible = false


func _spawn_random_food() -> void:
	if _game_finished:
		return

	if foods.is_empty():
		push_warning("No hay productos asignados en 'foods'.")
		return

	# Ya se repartieron todas las comidas: se gana de inmediato, sin
	# esperar a que se acabe el tiempo.
	if _foods_resolved >= _spawn_order.size():
		_win_game()
		return

	_busy = false
	_dragging = false
	_hide_all_foods()

	_current_food = _spawn_order[_foods_resolved]
	_current_food.visible = true

	if _kid_mode:
		print("DEBUG spawn: modo niños, generando Good/Bad para ", _current_food.name)
		_generate_good_or_bad()
	else:
		_generate_random_expiration()


func _generate_random_expiration() -> void:
	# Sorteamos cuántos días antes o después de "hoy" cae la fecha de
	# vencimiento. Un número negativo cae en el pasado (ya vencido), uno
	# positivo cae en el futuro (todavía bueno). Al ir sumando/restando
	# segundos directamente sobre _today_unix (en vez de generar el día
	# dentro del mismo mes), la fecha puede cruzar tranquilamente a un
	# mes anterior o posterior, y Godot calcula solo el mes/año/día
	# correctos, sin que tengamos que preocuparnos por cuántos días
	# tiene cada mes ni por años bisiestos.
	var offset_days: int = randi_range(-expiration_range_days, expiration_range_days)
	_current_expiration_unix = _today_unix + (offset_days * 86400)
	date_label.text = _format_date(_current_expiration_unix)


## Modo niños pequeños (8 años o menos): en vez de una fecha, sortea si el
## producto actual es "Good" (hay que guardarlo en la nevera) o "Bad" (hay
## que tirarlo a la basura), y muestra el ícono correspondiente.
func _generate_good_or_bad() -> void:
	_current_is_good = (randi() % 2 == 0)
	print("DEBUG _generate_good_or_bad: _current_is_good = ", _current_is_good, " | good_icon asignado = ", good_icon != null, " | bad_icon asignado = ", bad_icon != null)

	if good_icon:
		good_icon.visible = _current_is_good
		print("DEBUG good_icon.visible = ", good_icon.visible, " global_position = ", good_icon.global_position)

	if bad_icon:
		bad_icon.visible = not _current_is_good
		print("DEBUG bad_icon.visible = ", bad_icon.visible, " global_position = ", bad_icon.global_position)


func _format_date(unix_time: int) -> String:
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%d de %s de %d" % [d.day, MONTH_NAMES[d.month - 1], d.year]


func _is_expired() -> bool:
	return _current_expiration_unix < _today_unix


# =========================================================
# FEEDBACK VISUAL (ÍCONOS CHECK / ERROR)
# =========================================================

## Muestra el ícono de acierto (Check) o de error (Error) con una
## animación de "pop" (aparece chiquito y girado, rebota a su tamaño
## normal) y luego se desvanece solo, después de `feedback_duration`
## segundos en total.
## Si el ícono estaba "oculto" poniéndole escala (0,0) en el editor (en vez
## de destildar "visible"), usamos Vector2.ONE como respaldo: de lo
## contrario toda la animación de "pop" se haría a tamaño cero y nunca se
## vería nada, aunque el resto del código funcione bien.
func _safe_icon_scale(icon: Sprite2D) -> Vector2:
	if icon.scale.length() < 0.01:
		return Vector2.ONE
	return icon.scale


func _show_feedback_icon(correct: bool) -> void:
	print("DEBUG _show_feedback_icon llamada. correct = ", correct)

	var icon: Sprite2D = check_icon if correct else error_icon
	if icon == null:
		print("DEBUG El ícono correspondiente es null, no se puede mostrar")
		return

	var other_icon: Sprite2D = error_icon if correct else check_icon
	if other_icon != null:
		other_icon.visible = false

	# Si venía de una animación anterior (jugador muy rápido), la cortamos
	# para que no se pisen dos efectos a la vez.
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var base_scale: Vector2 = _icon_base_scale.get(icon, icon.scale)

	# Estado inicial: invisible, chiquito y ligeramente girado.
	icon.modulate.a = 0.0
	icon.scale = base_scale * 0.3
	icon.rotation_degrees = -12.0 if correct else 12.0
	icon.visible = true

	print("DEBUG icono visible=", icon.visible, " global_position=", icon.global_position, " base_scale=", base_scale, " z_index=", icon.z_index)

	var tween: Tween = create_tween()
	_feedback_tween = tween

	# Entrada: aparece de golpe con un rebote elástico y se endereza.
	tween.tween_property(icon, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(icon, "scale", base_scale * 1.25, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "rotation_degrees", 0.0, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Pequeño rebote de vuelta a su tamaño normal.
	tween.tween_property(icon, "scale", base_scale, 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Se mantiene visible el tiempo que falte para llegar a feedback_duration.
	var hold_time: float = max(feedback_duration - 0.4, 0.0)
	tween.tween_interval(hold_time)

	# Salida: se desvanece y se oculta.
	tween.tween_property(icon, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): icon.visible = false)


# =========================================================
# SONIDOS (Success / Error / Background)
# =========================================================

## Reproduce el sonido de acierto o de error. Si el sonido ya estaba
## sonando (jugador muy rápido), lo reinicia desde el principio para que
## siempre se escuche completo.
func _play_feedback_sound(correct: bool) -> void:
	var player: AudioStreamPlayer = success_sound if correct else error_sound
	if player == null:
		return

	player.volume_db = GLOBAL_SOUND_VOLUME
	player.stop()
	player.play()


func _on_background_sound_finished() -> void:
	# Mientras el minijuego no haya terminado, lo volvemos a reproducir
	# para que suene en bucle infinito.
	if not _game_finished and background_sound:
		background_sound.volume_db = GLOBAL_SOUND_VOLUME
		background_sound.play()


func _stop_background_sound() -> void:
	if background_sound == null:
		return

	# Desconectamos la señal para que no se vuelva a disparar el play()
	# justo después de detenerlo.
	if background_sound.finished.is_connected(_on_background_sound_finished):
		background_sound.finished.disconnect(_on_background_sound_finished)

	if background_sound.playing:
		background_sound.stop()


# =========================================================
# RESOLVER ELECCIÓN
# =========================================================

func _resolve_choice(chose_save: bool) -> void:
	if _game_finished:
		return

	_busy = true
	_foods_resolved += 1

	var correct: bool
	if _kid_mode:
		# Good -> hay que guardarlo (fridge). Bad -> hay que tirarlo (trash).
		correct = (chose_save == _current_is_good)
	else:
		correct = (chose_save != _is_expired())

	if correct:
		_score += 1
	else:
		_lose_life()

	# Actualizamos el panel de "FALTAN" con base en lo que ya se jugó
	# (_foods_resolved), no en los aciertos, para que llegue siempre al
	# 100% justo cuando se gana el minijuego.
	_update_progress_ui()

	_show_feedback_icon(correct)
	_play_feedback_sound(correct)

	answer_resolved.emit(correct, _score)

	if _game_finished:
		return

	var target: Vector2 = trash_drop_zone.global_position
	if chose_save:
		target = fridge_drop_zone.global_position

	var tween: Tween = create_tween()
	tween.tween_property(_current_food, "global_position", target, resolve_duration)
	tween.tween_callback(_spawn_random_food)


# =========================================================
# RESULT METHODS
# =========================================================

func _win_game():
	if _game_finished:
		return

	_game_finished = true

	_stop_timer_ui()
	_stop_background_sound()
	_set_game_result_sound_volume()

	if _game_result:
		if _game_result.has_method("show_win"):
			_game_result.show_win()
		elif _game_result.has_method("mostrar_ganaste"):
			_game_result.mostrar_ganaste()

	emit_signal("puzzle_completed")


func _lose_game():
	if _game_finished:
		return

	_game_finished = true

	_stop_timer_ui()
	_stop_background_sound()
	_set_game_result_sound_volume()

	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

	emit_signal("puzzle_failed")


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


# =========================================================
# CÓDIGO FUENTE DEL PANEL "FALTAN X / Y"
# =========================================================
## Este string contiene el script completo de un mini-nodo que dibuja el
## panel de progreso, con el mismo estilo visual de LivesUi (beige, borde
## naranja, texto azul, sombra y brillo). Se construye en memoria con
## GDScript.new() para NO tener que crear ningún archivo .gd nuevo en el
## proyecto, y se agrega como nodo hijo (ver _setup_progress_ui()) para
## que quede dibujado ENCIMA del fondo y de las comidas, en vez de detrás
## de ellos (que es lo que pasaba cuando el dibujo estaba en el _draw()
## del nodo raíz).
func _get_progress_ui_script_source() -> String:
	return """
extends Node2D

const C_BEIGE = Color(\"#E5C89E\")
const C_ORANGE = Color(\"#E0B080\")
const C_BLUE = Color(\"#3E5F8F\")

const PANEL_SIZE := Vector2(240, 96)
const PANEL_RADIUS := 22.0
const PANEL_SHADOW_OFFSET := Vector2(4, 5)

## Separación vertical debajo del panel del timer (que mide ~60px de alto
## y suele empezar cerca de la parte superior de la pantalla).
const TOP_OFFSET := 95.0

## Separación horizontal desde el borde izquierdo de la pantalla. Antes
## el panel se calculaba centrado; ahora queda pegado a la esquina
## izquierda, debajo/alineado con el resto de los paneles de la UI.
const LEFT_OFFSET := 24.0

const PANEL_BACKGROUND_COLOR := C_BEIGE
const PANEL_SHINE_COLOR := Color(1.0, 0.92, 0.78, 0.32)
const PANEL_BORDER_COLOR := C_ORANGE
const PANEL_LINE_COLOR := Color(1.0, 0.95, 0.84, 0.35)
const PANEL_SHADOW_COLOR := Color(0.35, 0.20, 0.10, 0.18)

const TITLE_TEXT := \"FALTAN\"
const TITLE_FONT_SIZE := 20
const NUMBER_FONT_SIZE := 30

const TITLE_COLOR := C_BLUE
const TITLE_SHADOW_COLOR := Color(1.0, 0.95, 0.86, 0.55)
const NUMBER_COLOR := C_BLUE
const NUMBER_SHADOW_COLOR := Color(1.0, 0.95, 0.86, 0.55)

const BAR_BG_COLOR := Color(0.35, 0.20, 0.10, 0.18)
const BAR_FILL_COLOR := C_ORANGE
const BAR_FILL_SHINE_COLOR := Color(1.0, 0.92, 0.78, 0.45)
const BAR_BORDER_COLOR := Color(0.35, 0.20, 0.10, 0.35)

var _total := 1
var _remaining := 1


func actualizar_progreso(resolved: int, total: int) -> void:
	_total = max(total, 1)
	_remaining = clampi(total - resolved, 0, _total)
	queue_redraw()


func _draw() -> void:
	var panel_position := _get_panel_position()
	_draw_panel(panel_position)
	_draw_texts(panel_position)
	_draw_bar(panel_position)


func _get_panel_position() -> Vector2:
	return Vector2(LEFT_OFFSET, TOP_OFFSET)


func _draw_panel(panel_position: Vector2) -> void:
	_draw_rounded_rect(panel_position + PANEL_SHADOW_OFFSET, PANEL_SIZE, PANEL_RADIUS, PANEL_SHADOW_COLOR)
	_draw_rounded_rect(panel_position, PANEL_SIZE, PANEL_RADIUS, PANEL_BACKGROUND_COLOR)
	_draw_rounded_rect(panel_position + Vector2(5, 5), PANEL_SIZE - Vector2(10, 10), 16, PANEL_SHINE_COLOR)
	_draw_rounded_border(panel_position, PANEL_SIZE, PANEL_RADIUS, PANEL_BORDER_COLOR, 4)
	draw_line(panel_position + Vector2(35, 9), panel_position + Vector2(PANEL_SIZE.x - 35, 9), PANEL_LINE_COLOR, 2)


func _draw_texts(panel_position: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var number_text := str(_remaining) + \" / \" + str(_total)

	draw_string(font, panel_position + Vector2(2, 33), TITLE_TEXT, HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, TITLE_FONT_SIZE, TITLE_SHADOW_COLOR)
	draw_string(font, panel_position + Vector2(0, 31), TITLE_TEXT, HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, TITLE_FONT_SIZE, TITLE_COLOR)
	draw_string(font, panel_position + Vector2(2, 65), number_text, HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, NUMBER_FONT_SIZE, NUMBER_SHADOW_COLOR)
	draw_string(font, panel_position + Vector2(0, 63), number_text, HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, NUMBER_FONT_SIZE, NUMBER_COLOR)


func _draw_bar(panel_position: Vector2) -> void:
	var bar_position := panel_position + Vector2(24, 76)
	var bar_size := Vector2(PANEL_SIZE.x - 48, 12)

	var resolved: int = _total - _remaining
	var fraction: float = clampf(float(resolved) / float(_total), 0.0, 1.0)

	_draw_rounded_rect(bar_position, bar_size, bar_size.y * 0.5, BAR_BG_COLOR)

	var fill_width: float = bar_size.x * fraction
	if fill_width > 1.0:
		var fill_size := Vector2(fill_width, bar_size.y)
		_draw_rounded_rect(bar_position, fill_size, bar_size.y * 0.5, BAR_FILL_COLOR)
		_draw_rounded_rect(
			bar_position + Vector2(2, 2),
			Vector2(max(fill_width - 4.0, 0.0), bar_size.y - 4),
			(bar_size.y - 4) * 0.5,
			BAR_FILL_SHINE_COLOR
		)

	_draw_rounded_border(bar_position, bar_size, bar_size.y * 0.5, BAR_BORDER_COLOR, 2)


func _draw_rounded_rect(rect_position: Vector2, rect_size: Vector2, radius: float, color: Color) -> void:
	radius = min(radius, min(rect_size.x, rect_size.y) * 0.5)
	draw_rect(Rect2(rect_position.x + radius, rect_position.y, rect_size.x - radius * 2, rect_size.y), color)
	draw_rect(Rect2(rect_position.x, rect_position.y + radius, rect_size.x, rect_size.y - radius * 2), color)
	draw_circle(rect_position + Vector2(radius, radius), radius, color)
	draw_circle(rect_position + Vector2(rect_size.x - radius, radius), radius, color)
	draw_circle(rect_position + Vector2(radius, rect_size.y - radius), radius, color)
	draw_circle(rect_position + Vector2(rect_size.x - radius, rect_size.y - radius), radius, color)


func _draw_rounded_border(rect_position: Vector2, rect_size: Vector2, radius: float, color: Color, border_width: float) -> void:
	radius = min(radius, min(rect_size.x, rect_size.y) * 0.5)
	draw_line(rect_position + Vector2(radius, 0), rect_position + Vector2(rect_size.x - radius, 0), color, border_width)
	draw_line(rect_position + Vector2(radius, rect_size.y), rect_position + Vector2(rect_size.x - radius, rect_size.y), color, border_width)
	draw_line(rect_position + Vector2(0, radius), rect_position + Vector2(0, rect_size.y - radius), color, border_width)
	draw_line(rect_position + Vector2(rect_size.x, radius), rect_position + Vector2(rect_size.x, rect_size.y - radius), color, border_width)
	draw_arc(rect_position + Vector2(radius, radius), radius, PI, PI * 1.5, 18, color, border_width)
	draw_arc(rect_position + Vector2(rect_size.x - radius, radius), radius, PI * 1.5, TAU, 18, color, border_width)
	draw_arc(rect_position + Vector2(radius, rect_size.y - radius), radius, PI * 0.5, PI, 18, color, border_width)
	draw_arc(rect_position + Vector2(rect_size.x - radius, rect_size.y - radius), radius, 0, PI * 0.5, 18, color, border_width)
"""
