extends Node2D

const ANCHO := 1280
const ALTO := 720

var tiempo_actual := 30
var vidas_actuales := 3
var mensaje := ""

var pulso := 0.0


func _process(delta):
	pulso += delta
	queue_redraw()


func actualizar_hud(tiempo: int, vidas: int, nuevo_mensaje: String = ""):
	tiempo_actual = tiempo
	vidas_actuales = clamp(vidas, 0, 3)
	mensaje = nuevo_mensaje
	queue_redraw()


func _draw():
	dibujar_panel_tiempo()
	dibujar_panel_vidas()
	dibujar_corazones()
	dibujar_mensaje()


# =========================================================
# PANEL DEL TIEMPO
# =========================================================

func dibujar_panel_tiempo():
	var size := Vector2(270, 64)
	var pos := Vector2((ANCHO - size.x) / 2, 18)

	# Sombra
	dibujar_rect_redondeado(pos + Vector2(5, 6), size, 20, Color(0, 0, 0, 0.38))

	# Fondo del panel
	dibujar_rect_redondeado(pos, size, 20, Color(0.045, 0.055, 0.13, 0.95))

	# Brillo interno
	dibujar_rect_redondeado(pos + Vector2(4, 4), size - Vector2(8, 8), 17, Color(0.12, 0.15, 0.30, 0.45))

	# Borde
	dibujar_borde_redondeado(pos, size, 20, Color(0.62, 0.78, 1.0, 0.45), 3)

	# Línea decorativa superior
	draw_line(
		pos + Vector2(28, 8),
		pos + Vector2(size.x - 28, 8),
		Color(0.85, 0.92, 1.0, 0.28),
		2
	)

	var font := ThemeDB.fallback_font
	var texto := "TIEMPO  " + str(tiempo_actual)

	# Sombra del texto
	draw_string(
		font,
		pos + Vector2(2, 43),
		texto,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		26,
		Color(0, 0, 0, 0.55)
	)

	# Texto principal
	draw_string(
		font,
		pos + Vector2(0, 41),
		texto,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		26,
		Color(0.95, 0.97, 1.0)
	)


# =========================================================
# PANEL DE VIDAS
# =========================================================

func dibujar_panel_vidas():
	var size := Vector2(230, 105)
	var pos := Vector2(ANCHO - size.x - 35, 18)

	# Sombra
	dibujar_rect_redondeado(pos + Vector2(5, 6), size, 20, Color(0, 0, 0, 0.38))

	# Fondo del panel
	dibujar_rect_redondeado(pos, size, 20, Color(0.08, 0.045, 0.10, 0.95))

	# Brillo interno
	dibujar_rect_redondeado(pos + Vector2(4, 4), size - Vector2(8, 8), 17, Color(0.22, 0.10, 0.18, 0.42))

	# Borde rosado
	dibujar_borde_redondeado(pos, size, 20, Color(1.0, 0.42, 0.55, 0.45), 3)

	# Línea decorativa
	draw_line(
		pos + Vector2(28, 8),
		pos + Vector2(size.x - 28, 8),
		Color(1.0, 0.78, 0.84, 0.25),
		2
	)

	var font := ThemeDB.fallback_font

	# Sombra texto
	draw_string(
		font,
		pos + Vector2(2, 34),
		"VIDAS",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		22,
		Color(0, 0, 0, 0.55)
	)

	# Texto principal
	draw_string(
		font,
		pos + Vector2(0, 32),
		"VIDAS",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		22,
		Color(1.0, 0.88, 0.92)
	)


# =========================================================
# CORAZONES
# =========================================================

func dibujar_corazones():
	var inicio := Vector2(ANCHO - 205, 78)
	var separacion := 58

	for i in range(3):
		var centro := inicio + Vector2(i * separacion, 0)

		if i < vidas_actuales:
			var escala := 1.15 + sin(pulso * 4.0 + i) * 0.04
			dibujar_corazon(
				centro,
				escala,
				Color(1.0, 0.10, 0.22),
				Color(1.0, 0.55, 0.62),
				true
			)
		else:
			dibujar_corazon(
				centro,
				1.05,
				Color(0.18, 0.18, 0.23, 0.55),
				Color(0.38, 0.38, 0.45, 0.35),
				false
			)


func dibujar_corazon(center: Vector2, scale: float, color_base: Color, color_brillo: Color, activo: bool):
	var puntos := PackedVector2Array()

	for i in range(48):
		var t := TAU * float(i) / 48.0

		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))

		puntos.append(center + Vector2(x, y) * scale)

	# Sombra del corazón
	var sombra := PackedVector2Array()
	for p in puntos:
		sombra.append(p + Vector2(3, 4))

	draw_colored_polygon(sombra, Color(0, 0, 0, 0.30))
	draw_colored_polygon(puntos, color_base)

	if activo:
		# Brillo superior
		draw_circle(center + Vector2(-8, -7) * scale, 5.0 * scale, color_brillo)
		draw_circle(center + Vector2(-4, -10) * scale, 2.5 * scale, Color(1, 1, 1, 0.35))

		# Borde suave
		draw_polyline(puntos, Color(1.0, 0.75, 0.78, 0.35), 2)
	else:
		# Línea diagonal para vida perdida
		draw_line(
			center + Vector2(-18, -18),
			center + Vector2(18, 18),
			Color(0.08, 0.08, 0.10, 0.75),
			4
		)


# =========================================================
# MENSAJE DE GANAR / PERDER
# =========================================================

func dibujar_mensaje():
	if mensaje == "":
		return

	var size := Vector2(500, 130)
	var pos := Vector2((ANCHO - size.x) / 2, 270)

	# Sombra
	dibujar_rect_redondeado(pos + Vector2(6, 8), size, 26, Color(0, 0, 0, 0.50))

	# Fondo
	dibujar_rect_redondeado(pos, size, 26, Color(0.04, 0.05, 0.12, 0.96))

	# Brillo interno
	dibujar_rect_redondeado(pos + Vector2(5, 5), size - Vector2(10, 10), 22, Color(0.12, 0.14, 0.28, 0.45))

	# Borde
	dibujar_borde_redondeado(pos, size, 26, Color(0.72, 0.84, 1.0, 0.50), 3)

	var font := ThemeDB.fallback_font

	var lineas := mensaje.split("\n")
	var y_base := pos.y + 54

	for i in range(lineas.size()):
		var linea := lineas[i]

		draw_string(
			font,
			Vector2(pos.x + 2, y_base + i * 34 + 2),
			linea,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			27,
			Color(0, 0, 0, 0.55)
		)

		draw_string(
			font,
			Vector2(pos.x, y_base + i * 34),
			linea,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			27,
			Color(1, 1, 1)
		)


# =========================================================
# FUNCIONES PARA DIBUJAR PANELES
# =========================================================

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

	draw_arc(pos + Vector2(radio, radio), radio, PI, PI * 1.5, 18, color, grosor)
	draw_arc(pos + Vector2(size.x - radio, radio), radio, PI * 1.5, TAU, 18, color, grosor)
	draw_arc(pos + Vector2(radio, size.y - radio), radio, PI * 0.5, PI, 18, color, grosor)
	draw_arc(pos + Vector2(size.x - radio, size.y - radio), radio, 0, PI * 0.5, 18, color, grosor)
