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

@export var snap_back_duration: float = 0.25
@export var resolve_duration: float = 0.3

## Arrastra aquí el ícono de "acertaste" (el nodo "Check"). Empieza
## invisible automáticamente; el script lo muestra y lo oculta solo.
@export var check_icon: Sprite2D

## Arrastra aquí el ícono de "te equivocaste" (el nodo "Error"). Empieza
## invisible automáticamente; el script lo muestra y lo oculta solo.
@export var error_icon: Sprite2D

## Cuántos segundos se queda visible el ícono de acierto/error
## (incluyendo la animación de entrada y la de salida).
@export var feedback_duration: float = 0.5

## Cuántas vidas tiene el jugador antes de perder el minijuego.
@export var max_lives: int = 3

## Cuántos segundos debe sobrevivir el jugador (sin quedarse sin vidas)
## para ganar el minijuego. Calculado para 8 artículos (5 segundos cada uno).
@export var total_time: float = 40.0


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


# =========================================================
# LIFECYCLE METHODS
# =========================================================

func _ready() -> void:
	randomize()

	_game_finished = false
	_lives = max_lives

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

	# "Hoy" lo fijamos a la medianoche del día real del sistema.
	var now: Dictionary = Time.get_datetime_dict_from_system()
	_today_unix = Time.get_unix_time_from_datetime_dict({
		"year": now.year, "month": now.month, "day": now.day,
		"hour": 0, "minute": 0, "second": 0
	})
	current_date_label.text = _format_date(_today_unix)

	_setup_timer_ui()
	_setup_lives_ui()
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
		_timer_ui.iniciar(total_time, "Tiempo restante", "para ganar")
	else:
		print("ERROR: El TimerUi no tiene el método iniciar()")


func _setup_lives_ui():
	_lives_ui = LIVES_UI_SCENE.instantiate()
	add_child(_lives_ui)

	if _lives_ui.has_method("actualizar_vidas"):
		_lives_ui.actualizar_vidas(_lives)
	else:
		print("ERROR: LivesUi no tiene el método actualizar_vidas()")


func _setup_game_result():
	_game_result = GAME_RESULT_SCENE.instantiate()
	add_child(_game_result)

	if _game_result is CanvasLayer:
		_game_result.layer = 50


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

	_generate_random_expiration()


func _generate_random_expiration() -> void:
	var today_dict: Dictionary = Time.get_datetime_dict_from_unix_time(_today_unix)

	# El mes y el año son siempre los mismos que los de "hoy": así la fecha
	# de vencimiento y la fecha actual nunca caen en un mes o un año
	# distinto. Solo el día se elige al azar dentro de ese mismo mes.
	var month: int = today_dict.month
	var year: int = today_dict.year
	var day: int = randi_range(1, _days_in_month(month, year))

	_current_expiration_unix = Time.get_unix_time_from_datetime_dict({
		"year": year, "month": month, "day": day,
		"hour": 0, "minute": 0, "second": 0
	})
	date_label.text = _format_date(_current_expiration_unix)


func _days_in_month(month: int, year: int) -> int:
	var days_per_month: Array = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var days: int = days_per_month[month - 1]
	if month == 2 and _is_leap_year(year):
		days = 29
	return days


func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)


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
# RESOLVER ELECCIÓN
# =========================================================

func _resolve_choice(chose_save: bool) -> void:
	if _game_finished:
		return

	_busy = true
	_foods_resolved += 1

	var correct: bool = (chose_save != _is_expired())
	if correct:
		_score += 1
	else:
		_lose_life()

	_show_feedback_icon(correct)

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

	if _game_result:
		if _game_result.has_method("show_lose"):
			_game_result.show_lose()
		elif _game_result.has_method("mostrar_perdiste"):
			_game_result.mostrar_perdiste()

	emit_signal("puzzle_failed")
