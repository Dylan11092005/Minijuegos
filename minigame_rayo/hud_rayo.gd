extends Node2D

var tiempo_actual := 30
var vidas_actuales := 3
var mensaje := ""

var pulso := 0.0

func _process(delta):
	pulso += delta
	queue_redraw()


func actualizar_hud(tiempo: int, vidas: int, nuevo_mensaje: String = ""):
	tiempo_actual = tiempo
	vidas_actuales = vidas
	mensaje = nuevo_mensaje
	queue_redraw()


func _draw():
	dibujar_panel_tiempo()
	dibujar_panel_vidas()
	dibujar_corazones()
	dibujar_mensaje()


func dibujar_panel_tiempo():
	var pos := Vector2(235, 18)
	var size := Vector2(250, 58)

	dibujar_rect_redondeado(pos + Vector2(4, 5), size, 18, Color(0, 0, 0, 0.35))
	dibujar_rect_redondeado(pos, size, 18, Color(0.06, 0.07, 0.16, 0.92))
	dibujar_rect_redondeado(pos + Vector2(3, 3), size - Vector2(6, 6), 15, Color(0.12, 0.14, 0.28, 0.55))

	# Borde
	dibujar_borde_redondeado(pos, size, 18, Color(0.65, 0.78, 1.0, 0.35), 3)

	var font := ThemeDB.fallback_font
	var texto := "TIEMPO  " + str(tiempo_actual)

	draw_string(
		font,
		pos + Vector2(0, 37),
		texto,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		24,
		Color(0.92, 0.95, 1.0)
	)


func dibujar_panel_vidas():
	var pos := Vector2(485, 18)
	var size := Vector2(205, 96)

	dibujar_rect_redondeado(pos + Vector2(4, 5), size, 18, Color(0, 0, 0, 0.35))
	dibujar_rect_redondeado(pos, size, 18, Color(0.08, 0.06, 0.13, 0.92))
	dibujar_rect_redondeado(pos + Vector2(3, 3), size - Vector2(6, 6), 15, Color(0.20, 0.11, 0.20, 0.45))

	dibujar_borde_redondeado(pos, size, 18, Color(1.0, 0.45, 0.55, 0.35), 3)

	var font := ThemeDB.fallback_font

	draw_string(
		font,
		pos + Vector2(0, 31),
		"VIDAS",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		20,
		Color(1.0, 0.86, 0.90)
	)


func dibujar_corazones():
	var inicio := Vector2(520, 68)
	var separacion := 48

	for i in range(3):
		var centro := inicio + Vector2(i * separacion, 0)

		if i < vidas_actuales:
			var escala := 1.0 + sin(pulso * 4.0 + i) * 0.04
			dibujar_corazon(centro, 1.05 * escala, Color(1.0, 0.12, 0.22), Color(1.0, 0.55, 0.62))
		else:
			dibujar_corazon(centro, 0.95, Color(0.18, 0.18, 0.23, 0.55), Color(0.35, 0.35, 0.42, 0.35))


func dibujar_mensaje():
	if mensaje == "":
		return

	var pos := Vector2(150, 295)
	var size := Vector2(420, 105)

	dibujar_rect_redondeado(pos + Vector2(5, 6), size, 24, Color(0, 0, 0, 0.45))
	dibujar_rect_redondeado(pos, size, 24, Color(0.05, 0.06, 0.13, 0.94))
	dibujar_borde_redondeado(pos, size, 24, Color(0.75, 0.85, 1.0, 0.45), 3)

	var font := ThemeDB.fallback_font

	draw_string(
		font,
		pos + Vector2(0, 43),
		mensaje,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		24,
		Color(1, 1, 1)
	)


func dibujar_corazon(center: Vector2, scale: float, color_base: Color, color_brillo: Color):
	var puntos := PackedVector2Array()

	for i in range(40):
		var t := TAU * float(i) / 40.0

		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))

		puntos.append(center + Vector2(x, y) * scale)

	# Sombra
	var sombra := PackedVector2Array()
	for p in puntos:
		sombra.append(p + Vector2(2, 3))

	draw_colored_polygon(sombra, Color(0, 0, 0, 0.28))
	draw_colored_polygon(puntos, color_base)

	# Brillo pequeño
	draw_circle(center + Vector2(-7, -6) * scale, 4.5 * scale, color_brillo)


func dibujar_rect_redondeado(pos: Vector2, size: Vector2, radio: float, color: Color):
	draw_rect(Rect2(pos.x + radio, pos.y, size.x - radio * 2, size.y), color)
	draw_rect(Rect2(pos.x, pos.y + radio, size.x, size.y - radio * 2), color)

	draw_circle(pos + Vector2(radio, radio), radio, color)
	draw_circle(pos + Vector2(size.x - radio, radio), radio, color)
	draw_circle(pos + Vector2(radio, size.y - radio), radio, color)
	draw_circle(pos + Vector2(size.x - radio, size.y - radio), radio, color)


func dibujar_borde_redondeado(pos: Vector2, size: Vector2, radio: float, color: Color, grosor: float):
	draw_line(pos + Vector2(radio, 0), pos + Vector2(size.x - radio, 0), color, grosor)
	draw_line(pos + Vector2(radio, size.y), pos + Vector2(size.x - radio, size.y), color, grosor)
	draw_line(pos + Vector2(0, radio), pos + Vector2(0, size.y - radio), color, grosor)
	draw_line(pos + Vector2(size.x, radio), pos + Vector2(size.x, size.y - radio), color, grosor)

	draw_arc(pos + Vector2(radio, radio), radio, PI, PI * 1.5, 16, color, grosor)
	draw_arc(pos + Vector2(size.x - radio, radio), radio, PI * 1.5, TAU, 16, color, grosor)
	draw_arc(pos + Vector2(radio, size.y - radio), radio, PI * 0.5, PI, 16, color, grosor)
	draw_arc(pos + Vector2(size.x - radio, size.y - radio), radio, 0, PI * 0.5, 16, color, grosor)
