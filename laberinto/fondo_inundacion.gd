extends Node2D

var tiempo := 0.0
var flash := 0.0
var intensidad_flash := 0.0

func _process(delta):
	tiempo += delta

	if randf() < 0.006:
		flash = 0.25
		intensidad_flash = randf_range(0.2, 0.5)

	if flash > 0:
		flash -= delta

	queue_redraw()

func _draw():
	var ANCHO = get_viewport_rect().size.x
	var ALTO = get_viewport_rect().size.y

	dibujar_cielo(ANCHO, ALTO)
	dibujar_nubes(ANCHO, ALTO)
	dibujar_agua(ANCHO, ALTO)
	dibujar_lluvia(ANCHO, ALTO)
	dibujar_flash(ANCHO, ALTO)

func dibujar_cielo(ANCHO, ALTO):
	for i in range(40):
		var t = float(i) / 40.0
		var color_arriba = Color(0.05, 0.10, 0.25)
		var color_abajo = Color(0.10, 0.20, 0.45)
		var color = color_arriba.lerp(color_abajo, t)
		draw_rect(Rect2(0, i * (ALTO / 40.0), ANCHO, (ALTO / 40.0) + 2), color)

func dibujar_nubes(ANCHO, ALTO):
	var mov1 = sin(tiempo * 0.3) * 12
	var mov2 = sin(tiempo * 0.5) * 15

	dibujar_nube(ANCHO, ALTO, Vector2(ANCHO * 0.05 + mov1, ALTO * 0.08), 1.4)
	dibujar_nube(ANCHO, ALTO, Vector2(ANCHO * 0.30 - mov2, ALTO * 0.06), 1.7)
	dibujar_nube(ANCHO, ALTO, Vector2(ANCHO * 0.58 + mov1, ALTO * 0.10), 1.5)
	dibujar_nube(ANCHO, ALTO, Vector2(ANCHO * 0.78 - mov1, ALTO * 0.07), 1.6)

func dibujar_nube(ANCHO, ALTO, pos, escala):
	var color = Color(0.12, 0.15, 0.28)
	var sombra = Color(0.05, 0.07, 0.18, 0.7)

	draw_circle(pos + Vector2(0, 25) * escala, 46 * escala, sombra)
	draw_circle(pos + Vector2(50, 8) * escala, 58 * escala, sombra)
	draw_circle(pos + Vector2(108, 28) * escala, 46 * escala, sombra)

	draw_circle(pos + Vector2(0, 18) * escala, 44 * escala, color)
	draw_circle(pos + Vector2(48, 0) * escala, 56 * escala, color)
	draw_circle(pos + Vector2(105, 20) * escala, 44 * escala, color)
	draw_rect(Rect2(pos.x - 8 * escala, pos.y + 18 * escala, 132 * escala, 44 * escala), color)

func dibujar_agua(ANCHO, ALTO):
	# Fondo de agua azul oscuro
	draw_rect(Rect2(0, ALTO * 0.35, ANCHO, ALTO), Color(0.05, 0.15, 0.35, 0.95))

	# Ondas animadas del agua
	for i in range(12):
		var y = ALTO * 0.35 + i * 32
		var offset = sin(tiempo * 1.2 + i * 0.8) * 18

		draw_line(
			Vector2(0 + offset, y),
			Vector2(ANCHO + offset, y),
			Color(0.15, 0.35, 0.65, 0.25),
			3
		)

	# Reflejos en el agua
	for i in range(8):
		var x = ANCHO * (float(i) / 8.0)
		var y = ALTO * 0.5 + sin(tiempo * 0.8 + i) * 15

		draw_line(
			Vector2(x, y),
			Vector2(x + 40, y + 8),
			Color(0.5, 0.7, 1.0, 0.15),
			2
		)

func dibujar_lluvia(ANCHO, ALTO):
	# Lluvia fina
	for i in range(150):
		var x = fmod(i * 73 + tiempo * 180, ANCHO + 100) - 50
		var y = fmod(i * 47 + tiempo * 420, ALTO + 120)
		draw_line(
			Vector2(x, y),
			Vector2(x - 7, y + 22),
			Color(0.4, 0.6, 1.0, 0.3),
			1
		)

	# Lluvia media
	for i in range(100):
		var x = fmod(i * 97 + tiempo * 280, ANCHO + 100) - 50
		var y = fmod(i * 61 + tiempo * 580, ALTO + 130)
		draw_line(
			Vector2(x, y),
			Vector2(x - 12, y + 35),
			Color(0.55, 0.75, 1.0, 0.5),
			2
		)

	# Lluvia gruesa
	for i in range(45):
		var x = fmod(i * 131 + tiempo * 400, ANCHO + 120) - 60
		var y = fmod(i * 89 + tiempo * 740, ALTO + 140)
		draw_line(
			Vector2(x, y),
			Vector2(x - 15, y + 44),
			Color(0.75, 0.88, 1.0, 0.65),
			2.5
		)

func dibujar_flash(ANCHO, ALTO):
	if flash <= 0:
		return
	draw_rect(
		Rect2(0, 0, ANCHO, ALTO),
		Color(0.7, 0.85, 1.0, flash * intensidad_flash)
	)
