extends Node2D

const ANCHO := 1280
const ALTO := 720

var tiempo := 0.0
var flash := 0.0
var intensidad_flash := 0.0


func _process(delta):
	tiempo += delta

	# Relámpago decorativo aleatorio
	if randf() < 0.008:
		flash = 0.28
		intensidad_flash = randf_range(0.35, 0.75)

	if flash > 0:
		flash -= delta

	queue_redraw()


func _draw():
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
	# Degradado vertical oscuro
	for i in range(45):
		var t := float(i) / 45.0
		var color_arriba := Color(0.012, 0.014, 0.045)
		var color_abajo := Color(0.055, 0.075, 0.15)
		var color := color_arriba.lerp(color_abajo, t)

		draw_rect(Rect2(0, i * 16, ANCHO, 18), color)

	# Oscuridad superior
	draw_rect(Rect2(0, 0, ANCHO, 160), Color(0.0, 0.0, 0.035, 0.42))

	# Brillo suave en el centro
	draw_circle(Vector2(ANCHO / 2, 240), 310, Color(0.15, 0.18, 0.35, 0.045))


func dibujar_luna_oculta():
	var luna_pos := Vector2(1080, 105)

	draw_circle(luna_pos, 60, Color(0.75, 0.82, 1.0, 0.09))
	draw_circle(luna_pos, 44, Color(0.85, 0.88, 1.0, 0.16))
	draw_circle(luna_pos + Vector2(-6, -4), 31, Color(0.93, 0.95, 1.0, 0.18))

	# Sombra para que parezca tapada por nubes
	draw_circle(luna_pos + Vector2(-22, -8), 37, Color(0.035, 0.045, 0.11, 0.62))


# =========================================================
# MONTAÑAS
# =========================================================

func dibujar_montanas():
	# Montañas lejanas
	var montanas_lejanas = PackedVector2Array([
		Vector2(0, 640),
		Vector2(0, 510),
		Vector2(120, 455),
		Vector2(250, 535),
		Vector2(390, 440),
		Vector2(540, 545),
		Vector2(710, 455),
		Vector2(880, 540),
		Vector2(1040, 465),
		Vector2(1280, 555),
		Vector2(1280, 640)
	])
	draw_colored_polygon(montanas_lejanas, Color(0.035, 0.045, 0.09))

	# Montañas cercanas
	var montanas_cercanas = PackedVector2Array([
		Vector2(0, 690),
		Vector2(0, 585),
		Vector2(170, 485),
		Vector2(320, 610),
		Vector2(500, 490),
		Vector2(690, 615),
		Vector2(870, 500),
		Vector2(1050, 610),
		Vector2(1280, 505),
		Vector2(1280, 690)
	])
	draw_colored_polygon(montanas_cercanas, Color(0.022, 0.032, 0.06))

	# Sombras
	draw_line(Vector2(170, 485), Vector2(320, 610), Color(0.08, 0.10, 0.18, 0.35), 3)
	draw_line(Vector2(500, 490), Vector2(690, 615), Color(0.08, 0.10, 0.18, 0.35), 3)
	draw_line(Vector2(870, 500), Vector2(1050, 610), Color(0.08, 0.10, 0.18, 0.35), 3)

	# Neblina baja sobre montañas
	draw_rect(Rect2(0, 585, ANCHO, 35), Color(0.35, 0.42, 0.65, 0.045))


# =========================================================
# NUBES
# =========================================================

func dibujar_nubes():
	var movimiento_lento := sin(tiempo * 0.35) * 10
	var movimiento_medio := sin(tiempo * 0.55) * 14

	# Nubes superiores
	dibujar_nube(Vector2(60 + movimiento_lento, 95), 1.35, Color(0.13, 0.14, 0.23))
	dibujar_nube(Vector2(335 - movimiento_medio, 70), 1.65, Color(0.11, 0.12, 0.20))
	dibujar_nube(Vector2(690 + movimiento_lento, 115), 1.45, Color(0.14, 0.15, 0.24))
	dibujar_nube(Vector2(980 - movimiento_lento, 85), 1.55, Color(0.12, 0.13, 0.22))

	# Nubes medias oscuras
	dibujar_nube(Vector2(170 - movimiento_lento, 190), 1.10, Color(0.08, 0.09, 0.16))
	dibujar_nube(Vector2(570 + movimiento_medio, 210), 1.25, Color(0.075, 0.085, 0.15))
	dibujar_nube(Vector2(930 - movimiento_medio, 200), 1.15, Color(0.075, 0.085, 0.15))


func dibujar_nube(pos: Vector2, escala: float, color_nube: Color):
	var sombra := Color(0.015, 0.02, 0.045, 0.72)

	# Sombra
	draw_circle(pos + Vector2(0, 28) * escala, 48 * escala, sombra)
	draw_circle(pos + Vector2(50, 8) * escala, 60 * escala, sombra)
	draw_circle(pos + Vector2(110, 30) * escala, 48 * escala, sombra)
	draw_rect(Rect2(pos.x - 12 * escala, pos.y + 28 * escala, 145 * escala, 48 * escala), sombra)

	# Cuerpo principal
	draw_circle(pos + Vector2(0, 20) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(48, 0) * escala, 58 * escala, color_nube)
	draw_circle(pos + Vector2(105, 22) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(55, 36) * escala, 62 * escala, color_nube)
	draw_rect(Rect2(pos.x - 10 * escala, pos.y + 22 * escala, 135 * escala, 45 * escala), color_nube)

	# Brillo superior leve
	draw_circle(pos + Vector2(45, -8) * escala, 28 * escala, Color(0.25, 0.27, 0.36, 0.14))


# =========================================================
# LLUVIA Y NEBLINA
# =========================================================

func dibujar_lluvia():
	# Lluvia fina de fondo
	for i in range(140):
		var x = fmod(i * 71 + tiempo * 165, ANCHO + 80) - 40
		var y = fmod(i * 43 + tiempo * 410, ALTO + 100)

		draw_line(
			Vector2(x, y),
			Vector2(x - 8, y + 24),
			Color(0.35, 0.55, 0.95, 0.28),
			1
		)

	# Lluvia principal
	for i in range(115):
		var x = fmod(i * 91 + tiempo * 260, ANCHO + 80) - 40
		var y = fmod(i * 59 + tiempo * 560, ALTO + 110)

		draw_line(
			Vector2(x, y),
			Vector2(x - 13, y + 34),
			Color(0.55, 0.72, 1.0, 0.55),
			2
		)

	# Lluvia frontal
	for i in range(45):
		var x = fmod(i * 127 + tiempo * 390, ANCHO + 100) - 50
		var y = fmod(i * 83 + tiempo * 720, ALTO + 130)

		draw_line(
			Vector2(x, y),
			Vector2(x - 16, y + 42),
			Color(0.78, 0.88, 1.0, 0.65),
			2.5
		)


func dibujar_neblina():
	var offset := sin(tiempo * 0.45) * 22

	for i in range(5):
		var y := 390 + i * 42

		draw_rect(
			Rect2(-60 + offset + i * 30, y, ANCHO + 120, 28),
			Color(0.45, 0.55, 0.75, 0.045)
		)


# =========================================================
# SUELO PROFESIONAL
# =========================================================

func dibujar_suelo():
	# Base del terreno con capas
	draw_rect(Rect2(0, 610, ANCHO, 110), Color(0.018, 0.050, 0.035))
	draw_rect(Rect2(0, 622, ANCHO, 98), Color(0.025, 0.075, 0.045))
	draw_rect(Rect2(0, 665, ANCHO, 55), Color(0.012, 0.032, 0.023, 0.90))

	# Línea superior de césped
	draw_rect(Rect2(0, 610, ANCHO, 5), Color(0.16, 0.34, 0.16, 0.95))
	draw_rect(Rect2(0, 615, ANCHO, 7), Color(0.06, 0.17, 0.08, 0.90))

	# Textura suave
	for i in range(46):
		var x := i * 30
		var y := 640 + int(abs(sin(i * 2.4)) * 34)

		draw_circle(
			Vector2(x, y),
			18,
			Color(0.04, 0.09, 0.06, 0.32)
		)

	# Sombra donde se apoya el jugador
	dibujar_ovalo(Vector2(640, 638), Vector2(105, 18), Color(0.0, 0.0, 0.0, 0.20))


func dibujar_detalles_suelo():
	# Pasto de fondo
	for i in range(95):
		var x := i * 13 + int(sin(i * 1.7) * 5)
		var alto := 10 + int(abs(sin(i * 2.3)) * 17)

		draw_line(
			Vector2(x, 622),
			Vector2(x - 3, 622 - alto),
			Color(0.08, 0.22, 0.11, 0.75),
			2
		)

		draw_line(
			Vector2(x + 4, 622),
			Vector2(x + 8, 622 - alto * 0.75),
			Color(0.06, 0.18, 0.09, 0.65),
			2
		)

	# Pasto frontal más definido
	for i in range(72):
		var x := i * 18 + int(cos(i * 1.3) * 7)
		var alto := 18 + int(abs(cos(i * 1.9)) * 22)

		draw_line(
			Vector2(x, 630),
			Vector2(x - 5, 630 - alto),
			Color(0.12, 0.34, 0.16, 0.92),
			3
		)

		draw_line(
			Vector2(x, 630),
			Vector2(x + 6, 630 - alto * 0.8),
			Color(0.08, 0.25, 0.12, 0.85),
			2
		)

	# Arbustos
	dibujar_arbusto(Vector2(70, 628), 1.0)
	dibujar_arbusto(Vector2(1120, 630), 1.15)
	dibujar_arbusto(Vector2(370, 632), 0.8)
	dibujar_arbusto(Vector2(820, 632), 0.75)

	# Charcos
	dibujar_charco(Vector2(220, 675), Vector2(70, 12), Color(0.10, 0.17, 0.25, 0.62))
	dibujar_charco(Vector2(950, 662), Vector2(82, 14), Color(0.10, 0.17, 0.25, 0.50))

	# Brillos de charcos
	draw_line(Vector2(170, 673), Vector2(265, 671), Color(0.62, 0.78, 1.0, 0.18), 2)
	draw_line(Vector2(895, 660), Vector2(1005, 658), Color(0.62, 0.78, 1.0, 0.16), 2)


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
# RELÁMPAGOS DECORATIVOS
# =========================================================

func dibujar_relamapago_decorativo():
	if flash <= 0:
		return

	var puntos = PackedVector2Array([
		Vector2(1040, 0),
		Vector2(1000, 90),
		Vector2(1055, 90),
		Vector2(970, 225),
		Vector2(1085, 105),
		Vector2(1035, 105),
		Vector2(1110, 0)
	])

	# Resplandor azul
	draw_polyline(puntos, Color(0.55, 0.65, 1.0, 0.32), 13)

	# Rayo amarillo
	draw_polyline(puntos, Color(1.0, 0.96, 0.45, 0.95), 6)

	# Centro claro
	draw_polyline(puntos, Color(1.0, 1.0, 0.85, 1.0), 2)


func dibujar_flash():
	if flash <= 0:
		return

	draw_rect(
		Rect2(0, 0, ANCHO, ALTO),
		Color(0.85, 0.9, 1.0, flash * intensidad_flash)
	)
