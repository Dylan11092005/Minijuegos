extends Node2D

var amigos_rescatados = 0
var _panel: Node2D
var pulse := 0.0



@onready var spawn_points = $SpawnPoints.get_children()

const C_BEIGE  = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE   = Color("#3E5F8F")
const C_GREEN  = Color("#4A9B5F")

const PANEL_SIZE   := Vector2(240, 108)
const PANEL_RADIUS := 22.0
var TOTAL_TIME: float = 50.0

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null


func _ready() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	_panel = Node2D.new()
	canvas.add_child(_panel)
	_panel.draw.connect(_on_panel_draw)

	_setup_damage_effect()

	$AudioMusica.play()
	_randomize_friend_positions()

	$Amigos/Amigo1.body_entered.connect(_on_amigo1_rescatado)
	$Amigos/Amigo2.body_entered.connect(_on_amigo2_rescatado)
	$ZonaSegura.body_entered.connect(_on_zona_segura_entrada)

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 50.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 50.0

	$TimerUI.iniciar(TOTAL_TIME, "Evacúa en", "segundos")
	$TimerUI.time_up.connect(_on_tiempo_agotado)


func _randomize_friend_positions() -> void:
	spawn_points.shuffle()

	$Amigos/Amigo1.global_position = spawn_points[0].global_position
	$Amigos/Amigo2.global_position = spawn_points[1].global_position



func _process(_delta):
	if _panel == null:
		return

	pulse += _delta
	_panel.queue_redraw()


func _on_amigo1_rescatado(body):
	if body.name == "Jugador":
		amigos_rescatados += 1
		$Amigos/Amigo1.queue_free()
		verificar_zona_segura()
		$AudioRescate.play()


func _on_amigo2_rescatado(body):
	if body.name == "Jugador":
		amigos_rescatados += 1
		$Amigos/Amigo2.queue_free()
		verificar_zona_segura()
		$AudioRescate.play()


func verificar_zona_segura():
	if amigos_rescatados >= 2:
		$ZonaSegura/BloqueoZona/CollisionShape2D.set_deferred("disabled", true)


func _on_zona_segura_entrada(body):
	if body.name == "Jugador":
		if amigos_rescatados >= 2:
			$AudioMusica.stop()
			$Jugador.bloquear_movimiento()
			$TimerUI.detener()
			$ResultadoJuego.mostrar_ganaste()
		else:
			print("Aún faltan amigos por rescatar")


func _on_tiempo_agotado():
	$AudioMusica.stop()
	$Jugador.bloquear_movimiento()
	$TimerUI.detener()
	_play_damage_effect()
	$ResultadoJuego.mostrar_perdiste()


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


func _on_panel_draw():
	var viewport_size = get_viewport().get_visible_rect().size
	var pos = Vector2(viewport_size.x - PANEL_SIZE.x - 35, 20)
	_panel_draw_panel(pos)
	_panel_draw_titulo(pos)
	_panel_draw_iconos_amigos(pos)


func _panel_draw_panel(pos: Vector2):
	_panel_rounded_rect(pos + Vector2(4, 5), PANEL_SIZE, PANEL_RADIUS,
		Color(0.35, 0.20, 0.10, 0.18))
	_panel_rounded_rect(pos, PANEL_SIZE, PANEL_RADIUS, C_BEIGE)
	_panel_rounded_rect(pos + Vector2(5, 5), PANEL_SIZE - Vector2(10, 10),
		16, Color(1.0, 0.92, 0.78, 0.32))
	_panel_rounded_border(pos, PANEL_SIZE, PANEL_RADIUS, C_ORANGE, 4)
	_panel.draw_line(pos + Vector2(35, 9), pos + Vector2(PANEL_SIZE.x - 35, 9),
		Color(1.0, 0.95, 0.84, 0.35), 2)


func _panel_draw_titulo(pos: Vector2):
	var font := ThemeDB.fallback_font
	_panel.draw_string(font, pos + Vector2(2, 35), "AMIGOS",
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, 22,
		Color(1.0, 0.95, 0.86, 0.55))
	_panel.draw_string(font, pos + Vector2(0, 33), "AMIGOS",
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, 22, C_BLUE)


func _panel_draw_iconos_amigos(pos: Vector2):
	var start = pos + Vector2(70, 76)

	for i in range(2):
		var centro = start + Vector2(i * 62, 0)

		if i < amigos_rescatados:
			var s = 1.1 + sin(pulse * 4.0 + i) * 0.04
			_panel_figura_amigo(centro, s, C_GREEN, Color(0.6, 1.0, 0.7), true)
		else:
			_panel_figura_amigo(
				centro,
				1.0,
				Color(0.55, 0.48, 0.42, 0.55),
				Color(0.78, 0.70, 0.60, 0.35),
				false
			)


func _panel_figura_amigo(centro: Vector2, escala: float, color: Color, shine: Color, activo: bool):
	var r_cabeza = 10.0 * escala

	_panel.draw_circle(centro + Vector2(2, 3 - 22 * escala), r_cabeza, Color(0, 0, 0, 0.22))
	_panel.draw_circle(centro + Vector2(0, -22 * escala), r_cabeza, color)

	if activo:
		_panel.draw_circle(centro + Vector2(-4, -26 * escala), 3.5 * escala, shine)

	var cuerpo_top  = centro + Vector2(-10 * escala, -10 * escala)
	var cuerpo_size = Vector2(20 * escala, 22 * escala)

	_panel_rounded_rect(cuerpo_top + Vector2(2, 4), cuerpo_size, 6, Color(0, 0, 0, 0.22))
	_panel_rounded_rect(cuerpo_top, cuerpo_size, 6, color)

	if not activo:
		_panel.draw_line(
			centro + Vector2(-14, -34) * escala,
			centro + Vector2(14, 2) * escala,
			Color(0.35, 0.25, 0.20, 0.65),
			3
		)
		_panel.draw_line(
			centro + Vector2(14, -34) * escala,
			centro + Vector2(-14, 2) * escala,
			Color(0.35, 0.25, 0.20, 0.65),
			3
		)


func _panel_rounded_rect(rpos: Vector2, rsize: Vector2, radius: float, color: Color):
	_panel.draw_rect(Rect2(rpos.x + radius, rpos.y, rsize.x - radius * 2, rsize.y), color)
	_panel.draw_rect(Rect2(rpos.x, rpos.y + radius, rsize.x, rsize.y - radius * 2), color)
	_panel.draw_circle(rpos + Vector2(radius, radius), radius, color)
	_panel.draw_circle(rpos + Vector2(rsize.x - radius, radius), radius, color)
	_panel.draw_circle(rpos + Vector2(radius, rsize.y - radius), radius, color)
	_panel.draw_circle(rpos + Vector2(rsize.x - radius, rsize.y - radius), radius, color)


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


func _panel_rounded_border(rpos: Vector2, rsize: Vector2, radius: float, color: Color, width: float):
	_panel.draw_line(rpos + Vector2(radius, 0), rpos + Vector2(rsize.x - radius, 0), color, width)
	_panel.draw_line(rpos + Vector2(radius, rsize.y), rpos + Vector2(rsize.x - radius, rsize.y), color, width)
	_panel.draw_line(rpos + Vector2(0, radius), rpos + Vector2(0, rsize.y - radius), color, width)
	_panel.draw_line(rpos + Vector2(rsize.x, radius), rpos + Vector2(rsize.x, rsize.y - radius), color, width)
	_panel.draw_arc(rpos + Vector2(radius, radius), radius, PI, PI * 1.5, 18, color, width)
	_panel.draw_arc(rpos + Vector2(rsize.x - radius, radius), radius, PI * 1.5, TAU, 18, color, width)
	_panel.draw_arc(rpos + Vector2(radius, rsize.y - radius), radius, PI * 0.5, PI, 18, color, width)
	_panel.draw_arc(rpos + Vector2(rsize.x - radius, rsize.y - radius), radius, 0, PI * 0.5, 18, color, width)
