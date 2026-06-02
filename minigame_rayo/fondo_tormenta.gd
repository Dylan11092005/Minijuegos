extends Node2D

var ANCHO := 1280.0
var ALTO := 720.0

var tiempo := 0.0
var flash := 0.0
var intensidad_flash := 0.0


func _process(delta):
	tiempo += delta

	if randf() < 0.008:
		flash = 0.28
		intensidad_flash = randf_range(0.35, 0.75)

	if flash > 0:
		flash -= delta

	queue_redraw()


func _draw():
	ANCHO = get_viewport_rect().size.x
	ALTO = get_viewport_rect().size.y

	dibujar_cielo()
	dibujar_luna_oculta()
	dibujar_montanas()
	dibujar_nubes()
	dibujar_neblina()
	dibujar_lluvia()
	dibujar_suelo()
	dibujar_detalles_suelo()
	dibujar_relamapago_decorativo()
	dibujar_flash()


# =========================================================
# CIELO
# =========================================================

func dibujar_cielo():
	for i in range(45):
		var t := float(i) / 45.0
		var color_arriba := Color(0.012, 0.014, 0.045)
		var color_abajo := Color(0.055, 0.075, 0.15)
		var color := color_arriba.lerp(color_abajo, t)

		draw_rect(
			Rect2(0, i * (ALTO / 45.0), ANCHO, (ALTO / 45.0) + 2),
			color
		)

	draw_rect(Rect2(0, 0, ANCHO, ALTO * 0.22), Color(0.0, 0.0, 0.035, 0.42))
	draw_circle(Vector2(ANCHO / 2.0, ALTO * 0.35), ANCHO * 0.24, Color(0.15, 0.18, 0.35, 0.045))


func dibujar_luna_oculta():
	var luna_pos := Vector2(ANCHO * 0.84, ALTO * 0.15)

	draw_circle(luna_pos, 60, Color(0.75, 0.82, 1.0, 0.09))
	draw_circle(luna_pos, 44, Color(0.85, 0.88, 1.0, 0.16))
	draw_circle(luna_pos + Vector2(-6, -4), 31, Color(0.93, 0.95, 1.0, 0.18))
	draw_circle(luna_pos + Vector2(-22, -8), 37, Color(0.035, 0.045, 0.11, 0.62))


# =========================================================
# MONTAÑAS
# =========================================================

func dibujar_montanas():
	var suelo_y := ALTO * 0.86

	var montanas_lejanas = PackedVector2Array([
		Vector2(0, suelo_y),
		Vector2(0, ALTO * 0.70),
		Vector2(ANCHO * 0.09, ALTO * 0.63),
		Vector2(ANCHO * 0.20, ALTO * 0.74),
		Vector2(ANCHO * 0.31, ALTO * 0.61),
		Vector2(ANCHO * 0.43, ALTO * 0.75),
		Vector2(ANCHO * 0.56, ALTO * 0.63),
		Vector2(ANCHO * 0.70, ALTO * 0.75),
		Vector2(ANCHO * 0.82, ALTO * 0.64),
		Vector2(ANCHO, ALTO * 0.76),
		Vector2(ANCHO, suelo_y)
	])
	draw_colored_polygon(montanas_lejanas, Color(0.035, 0.045, 0.09))

	var montanas_cercanas = PackedVector2Array([
		Vector2(0, ALTO),
		Vector2(0, ALTO * 0.81),
		Vector2(ANCHO * 0.13, ALTO * 0.67),
		Vector2(ANCHO * 0.25, ALTO * 0.84),
		Vector2(ANCHO * 0.39, ALTO * 0.68),
		Vector2(ANCHO * 0.54, ALTO * 0.85),
		Vector2(ANCHO * 0.68, ALTO * 0.69),
		Vector2(ANCHO * 0.82, ALTO * 0.84),
		Vector2(ANCHO, ALTO * 0.70),
		Vector2(ANCHO, ALTO)
	])
	draw_colored_polygon(montanas_cercanas, Color(0.022, 0.032, 0.06))

	draw_rect(Rect2(0, ALTO * 0.79, ANCHO, 35), Color(0.35, 0.42, 0.65, 0.045))


# =========================================================
# NUBES
# =========================================================

func dibujar_nubes():
	var movimiento_lento := sin(tiempo * 0.35) * 10
	var movimiento_medio := sin(tiempo * 0.55) * 14

	dibujar_nube(Vector2(ANCHO * 0.04 + movimiento_lento, ALTO * 0.13), 1.35, Color(0.13, 0.14, 0.23))
	dibujar_nube(Vector2(ANCHO * 0.26 - movimiento_medio, ALTO * 0.10), 1.65, Color(0.11, 0.12, 0.20))
	dibujar_nube(Vector2(ANCHO * 0.54 + movimiento_lento, ALTO * 0.16), 1.45, Color(0.14, 0.15, 0.24))
	dibujar_nube(Vector2(ANCHO * 0.77 - movimiento_lento, ALTO * 0.12), 1.55, Color(0.12, 0.13, 0.22))

	dibujar_nube(Vector2(ANCHO * 0.13 - movimiento_lento, ALTO * 0.26), 1.10, Color(0.08, 0.09, 0.16))
	dibujar_nube(Vector2(ANCHO * 0.45 + movimiento_medio, ALTO * 0.29), 1.25, Color(0.075, 0.085, 0.15))
	dibujar_nube(Vector2(ANCHO * 0.73 - movimiento_medio, ALTO * 0.28), 1.15, Color(0.075, 0.085, 0.15))


func dibujar_nube(pos: Vector2, escala: float, color_nube: Color):
	var sombra := Color(0.015, 0.02, 0.045, 0.72)

	draw_circle(pos + Vector2(0, 28) * escala, 48 * escala, sombra)
	draw_circle(pos + Vector2(50, 8) * escala, 60 * escala, sombra)
	draw_circle(pos + Vector2(110, 30) * escala, 48 * escala, sombra)
	draw_rect(Rect2(pos.x - 12 * escala, pos.y + 28 * escala, 145 * escala, 48 * escala), sombra)

	draw_circle(pos + Vector2(0, 20) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(48, 0) * escala, 58 * escala, color_nube)
	draw_circle(pos + Vector2(105, 22) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(55, 36) * escala, 62 * escala, color_nube)
	draw_rect(Rect2(pos.x - 10 * escala, pos.y + 22 * escala, 135 * escala, 45 * escala), color_nube)

	draw_circle(pos + Vector2(45, -8) * escala, 28 * escala, Color(0.25, 0.27, 0.36, 0.14))


# =========================================================
# LLUVIA Y NEBLINA
# =========================================================

func dibujar_lluvia():
	for i in range(160):
		var x = fmod(i * 71 + tiempo * 165, ANCHO + 100) - 50
		var y = fmod(i * 43 + tiempo * 410, ALTO + 120)

		draw_line(
			Vector2(x, y),
			Vector2(x - 8, y + 24),
			Color(0.35, 0.55, 0.95, 0.28),
			1
		)

	for i in range(130):
		var x = fmod(i * 91 + tiempo * 260, ANCHO + 100) - 50
		var y = fmod(i * 59 + tiempo * 560, ALTO + 130)

		draw_line(
			Vector2(x, y),
			Vector2(x - 13, y + 34),
			Color(0.55, 0.72, 1.0, 0.55),
			2
		)

	for i in range(55):
		var x = fmod(i * 127 + tiempo * 390, ANCHO + 120) - 60
		var y = fmod(i * 83 + tiempo * 720, ALTO + 140)

		draw_line(
			Vector2(x, y),
			Vector2(x - 16, y + 42),
			Color(0.78, 0.88, 1.0, 0.65),
			2.5
		)


func dibujar_neblina():
	var offset := sin(tiempo * 0.45) * 22

	for i in range(5):
		var y := ALTO * 0.54 + i * 42

		draw_rect(
			Rect2(-60 + offset + i * 30, y, ANCHO + 120, 28),
			Color(0.45, 0.55, 0.75, 0.045)
		)


# =========================================================
# SUELO
# =========================================================

func dibujar_suelo():
	var suelo_inicio := ALTO * 0.85

	draw_rect(Rect2(0, suelo_inicio, ANCHO, ALTO - suelo_inicio), Color(0.018, 0.050, 0.035))
	draw_rect(Rect2(0, suelo_inicio + 12, ANCHO, ALTO - suelo_inicio), Color(0.025, 0.075, 0.045))
	draw_rect(Rect2(0, suelo_inicio + 55, ANCHO, ALTO - suelo_inicio), Color(0.012, 0.032, 0.023, 0.90))

	draw_rect(Rect2(0, suelo_inicio, ANCHO, 5), Color(0.16, 0.34, 0.16, 0.95))
	draw_rect(Rect2(0, suelo_inicio + 5, ANCHO, 7), Color(0.06, 0.17, 0.08, 0.90))

	for i in range(50):
		var x := i * 30
		var y := suelo_inicio + 30 + int(abs(sin(i * 2.4)) * 34)

		draw_circle(
			Vector2(x, y),
			18,
			Color(0.04, 0.09, 0.06, 0.32)
		)

	dibujar_ovalo(
		Vector2(ANCHO / 2.0, suelo_inicio + 28),
		Vector2(105, 18),
		Color(0.0, 0.0, 0.0, 0.20)
	)


func dibujar_detalles_suelo():
	var suelo_inicio := ALTO * 0.85

	for i in range(110):
		var x := i * 13 + int(sin(i * 1.7) * 5)
		var alto := 10 + int(abs(sin(i * 2.3)) * 17)

		draw_line(
			Vector2(x, suelo_inicio + 12),
			Vector2(x - 3, suelo_inicio + 12 - alto),
			Color(0.08, 0.22, 0.11, 0.75),
			2
		)

		draw_line(
			Vector2(x + 4, suelo_inicio + 12),
			Vector2(x + 8, suelo_inicio + 12 - alto * 0.75),
			Color(0.06, 0.18, 0.09, 0.65),
			2
		)

	for i in range(85):
		var x := i * 18 + int(cos(i * 1.3) * 7)
		var alto := 18 + int(abs(cos(i * 1.9)) * 22)

		draw_line(
			Vector2(x, suelo_inicio + 20),
			Vector2(x - 5, suelo_inicio + 20 - alto),
			Color(0.12, 0.34, 0.16, 0.92),
			3
		)

		draw_line(
			Vector2(x, suelo_inicio + 20),
			Vector2(x + 6, suelo_inicio + 20 - alto * 0.8),
			Color(0.08, 0.25, 0.12, 0.85),
			2
		)

	dibujar_arbusto(Vector2(ANCHO * 0.06, suelo_inicio + 18), 1.0)
	dibujar_arbusto(Vector2(ANCHO * 0.86, suelo_inicio + 20), 1.15)
	dibujar_arbusto(Vector2(ANCHO * 0.30, suelo_inicio + 22), 0.8)
	dibujar_arbusto(Vector2(ANCHO * 0.64, suelo_inicio + 22), 0.75)

	dibujar_charco(Vector2(ANCHO * 0.18, suelo_inicio + 65), Vector2(70, 12), Color(0.10, 0.17, 0.25, 0.62))
	dibujar_charco(Vector2(ANCHO * 0.74, suelo_inicio + 52), Vector2(82, 14), Color(0.10, 0.17, 0.25, 0.50))

	draw_line(
		Vector2(ANCHO * 0.18 - 50, suelo_inicio + 63),
		Vector2(ANCHO * 0.18 + 45, suelo_inicio + 61),
		Color(0.62, 0.78, 1.0, 0.18),
		2
	)

	draw_line(
		Vector2(ANCHO * 0.74 - 55, suelo_inicio + 50),
		Vector2(ANCHO * 0.74 + 55, suelo_inicio + 48),
		Color(0.62, 0.78, 1.0, 0.16),
		2
	)


func dibujar_arbusto(pos: Vector2, escala: float):
	var color_base := Color(0.04, 0.14, 0.07, 0.95)
	var color_luz := Color(0.10, 0.28, 0.12, 0.85)
	var color_sombra := Color(0.01, 0.04, 0.02, 0.55)

	draw_circle(pos + Vector2(0, 4) * escala, 18 * escala, color_sombra)
	draw_circle(pos + Vector2(20, 0) * escala, 24 * escala, color_sombra)
	draw_circle(pos + Vector2(40, 5) * escala, 18 * escala, color_sombra)

	draw_circle(pos + Vector2(0, 0) * escala, 18 * escala, color_base)
	draw_circle(pos + Vector2(18, -7) * escala, 22 * escala, color_base)
	draw_circle(pos + Vector2(38, 0) * escala, 18 * escala, color_base)
	draw_rect(Rect2(pos.x - 5 * escala, pos.y, 52 * escala, 18 * escala), color_base)

	draw_circle(pos + Vector2(18, -12) * escala, 8 * escala, color_luz)
	draw_circle(pos + Vector2(36, -4) * escala, 6 * escala, color_luz)


func dibujar_charco(center: Vector2, radius: Vector2, color: Color):
	dibujar_ovalo(center, radius, color)


func dibujar_ovalo(center: Vector2, radius: Vector2, color: Color):
	var puntos := PackedVector2Array()

	for i in range(36):
		var angulo := TAU * float(i) / 36.0

		puntos.append(Vector2(
			center.x + cos(angulo) * radius.x,
			center.y + sin(angulo) * radius.y
		))

	draw_colored_polygon(puntos, color)


# =========================================================
# RELÁMPAGO Y FLASH
# =========================================================

func dibujar_relamapago_decorativo():
	if flash <= 0:
		return

	var base_x := ANCHO * 0.82

	var puntos = PackedVector2Array([
		Vector2(base_x, 0),
		Vector2(base_x - 40, ALTO * 0.13),
		Vector2(base_x + 15, ALTO * 0.13),
		Vector2(base_x - 70, ALTO * 0.31),
		Vector2(base_x + 45, ALTO * 0.15),
		Vector2(base_x - 5, ALTO * 0.15),
		Vector2(base_x + 70, 0)
	])

	draw_polyline(puntos, Color(0.55, 0.65, 1.0, 0.32), 13)
	draw_polyline(puntos, Color(1.0, 0.96, 0.45, 0.95), 6)
	draw_polyline(puntos, Color(1.0, 1.0, 0.85, 1.0), 2)


func dibujar_flash():
	if flash <= 0:
		return

	draw_rect(
		Rect2(0, 0, ANCHO, ALTO),
		Color(0.85, 0.9, 1.0, flash * intensidad_flash)
	)
