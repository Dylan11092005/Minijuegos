extends Node2D

var tiempo := 0.0
var nivel_agua := 0.0

func _process(delta):
	tiempo += delta
	# El agua sube lentamente
	nivel_agua = 0.55 + sin(tiempo * 0.4) * 0.03
	queue_redraw()

func _draw():
	var ANCHO = get_viewport_rect().size.x
	var ALTO = get_viewport_rect().size.y

	dibujar_cielo(ANCHO, ALTO)
	dibujar_nubes(ANCHO, ALTO)
	dibujar_ciudad(ANCHO, ALTO)
	dibujar_agua(ANCHO, ALTO)
	dibujar_gotas(ANCHO, ALTO)

func dibujar_cielo(ANCHO, ALTO):
	for i in range(40):
		var t = float(i) / 40.0
		var color_arriba = Color(0.08, 0.10, 0.22)
		var color_abajo = Color(0.15, 0.20, 0.40)
		var color = color_arriba.lerp(color_abajo, t)
		draw_rect(Rect2(0, i * (ALTO / 40.0), ANCHO, (ALTO / 40.0) + 2), color)

func dibujar_nubes(ANCHO, ALTO):
	var mov1 = sin(tiempo * 0.2) * 10
	var mov2 = sin(tiempo * 0.3) * 14

	dibujar_nube(Vector2(ANCHO * 0.05 + mov1, ALTO * 0.08), 1.4)
	dibujar_nube(Vector2(ANCHO * 0.32 - mov2, ALTO * 0.05), 1.8)
	dibujar_nube(Vector2(ANCHO * 0.60 + mov1, ALTO * 0.10), 1.5)
	dibujar_nube(Vector2(ANCHO * 0.80 - mov1, ALTO * 0.06), 1.6)

func dibujar_nube(pos, escala):
	var color = Color(0.10, 0.12, 0.25)
	var sombra = Color(0.04, 0.05, 0.15, 0.7)

	draw_circle(pos + Vector2(0, 25) * escala, 46 * escala, sombra)
	draw_circle(pos + Vector2(50, 8) * escala, 58 * escala, sombra)
	draw_circle(pos + Vector2(108, 28) * escala, 46 * escala, sombra)

	draw_circle(pos + Vector2(0, 18) * escala, 44 * escala, color)
	draw_circle(pos + Vector2(48, 0) * escala, 56 * escala, color)
	draw_circle(pos + Vector2(105, 20) * escala, 44 * escala, color)
	draw_rect(Rect2(pos.x - 8 * escala, pos.y + 18 * escala, 132 * escala, 44 * escala), color)

func dibujar_ciudad(ANCHO, ALTO):
	# Edificios de fondo (silueta)
	var edificios = [
		[0.05, 0.45, 0.08, 0.30],
		[0.14, 0.40, 0.07, 0.35],
		[0.22, 0.50, 0.09, 0.25],
		[0.32, 0.38, 0.06, 0.37],
		[0.40, 0.44, 0.10, 0.31],
		[0.52, 0.36, 0.07, 0.39],
		[0.61, 0.48, 0.08, 0.27],
		[0.71, 0.42, 0.09, 0.33],
		[0.82, 0.46, 0.07, 0.29],
		[0.90, 0.39, 0.08, 0.36],
	]

	for e in edificios:
		var ex = ANCHO * e[0]
		var ey = ALTO * e[1]
		var ew = ANCHO * e[2]
		var eh = ALTO * e[3]
		draw_rect(Rect2(ex, ey, ew, eh), Color(0.05, 0.07, 0.18))

		# Ventanas de los edificios
		for fila in range(3):
			for col in range(2):
				var wx = ex + col * (ew/2) + 4
				var wy = ey + fila * 28 + 8
				draw_rect(Rect2(wx, wy, 10, 14), Color(0.8, 0.75, 0.3, 0.4))

func dibujar_agua(ANCHO, ALTO):
	var agua_y = ALTO * nivel_agua

	# Agua principal
	draw_rect(Rect2(0, agua_y, ANCHO, ALTO - agua_y), Color(0.05, 0.18, 0.45, 0.95))

	# Ondas animadas
	for i in range(10):
		var y = agua_y + i * 18
		var offset = sin(tiempo * 1.5 + i * 0.7) * 20
		draw_line(
			Vector2(0 + offset, y),
			Vector2(ANCHO + offset, y),
			Color(0.2, 0.45, 0.75, 0.3),
			3
		)

	# Reflejos de los edificios en el agua
	for i in range(6):
		var x = ANCHO * (float(i) / 6.0) + 30
		var y = agua_y + 20 + sin(tiempo * 0.9 + i) * 10
		draw_line(
			Vector2(x, y),
			Vector2(x + 35, y + 10),
			Color(0.6, 0.75, 1.0, 0.15),
			2
		)

	# Línea de espuma del agua
	draw_line(
		Vector2(0, agua_y),
		Vector2(ANCHO, agua_y),
		Color(0.7, 0.85, 1.0, 0.5),
		3
	)

func dibujar_gotas(ANCHO, ALTO):
	# Gotas cayendo suavemente
	for i in range(80):
		var x = fmod(i * 83 + tiempo * 120, ANCHO + 80) - 40
		var y = fmod(i * 51 + tiempo * 300, ALTO + 100)
		draw_line(
			Vector2(x, y),
			Vector2(x - 5, y + 18),
			Color(0.4, 0.6, 1.0, 0.25),
			1
		)
