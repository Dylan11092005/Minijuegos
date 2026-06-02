extends Node2D

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

		draw_rect(Rect2(0, i * 18, 720, 20), color)

	# Oscuridad superior para dar profundidad
	draw_rect(Rect2(0, 0, 720, 160), Color(0.0, 0.0, 0.035, 0.42))

	# Brillo muy suave en el centro del cielo
	draw_circle(Vector2(360, 260), 260, Color(0.15, 0.18, 0.35, 0.045))


func dibujar_luna_oculta():
	var luna_pos := Vector2(585, 105)

	# Resplandor de luna escondida
	draw_circle(luna_pos, 55, Color(0.75, 0.82, 1.0, 0.09))
	draw_circle(luna_pos, 42, Color(0.85, 0.88, 1.0, 0.16))
	draw_circle(luna_pos + Vector2(-6, -4), 30, Color(0.93, 0.95, 1.0, 0.18))

	# Sombra que la tapa parcialmente
	draw_circle(luna_pos + Vector2(-20, -8), 35, Color(0.035, 0.045, 0.11, 0.62))


# =========================================================
# MONTAÑAS
# =========================================================

func dibujar_montanas():
	# Montañas lejanas
	var montanas_lejanas = PackedVector2Array([
		Vector2(0, 680),
		Vector2(0, 550),
		Vector2(85, 500),
		Vector2(170, 565),
		Vector2(300, 465),
		Vector2(430, 565),
		Vector2(555, 480),
		Vector2(720, 570),
		Vector2(720, 680)
	])
	draw_colored_polygon(montanas_lejanas, Color(0.035, 0.045, 0.09))

	# Montañas cercanas
	var montanas_cercanas = PackedVector2Array([
		Vector2(0, 720),
		Vector2(0, 615),
		Vector2(125, 505),
		Vector2(260, 632),
		Vector2(395, 505),
		Vector2(535, 635),
		Vector2(720, 520),
		Vector2(720, 720)
	])
	draw_colored_polygon(montanas_cercanas, Color(0.022, 0.032, 0.06))

	# Sombras diagonales
	draw_line(Vector2(125, 505), Vector2(260, 632), Color(0.08, 0.10, 0.18, 0.35), 3)
	draw_line(Vector2(395, 505), Vector2(535, 635), Color(0.08, 0.10, 0.18, 0.35), 3)

	# Neblina baja sobre montañas
	draw_rect(Rect2(0, 610, 720, 35), Color(0.35, 0.42, 0.65, 0.045))


# =========================================================
# NUBES
# =========================================================

func dibujar_nubes():
	var movimiento_lento := sin(tiempo * 0.35) * 8
	var movimiento_medio := sin(tiempo * 0.55) * 12

	# Nubes superiores
	dibujar_nube(Vector2(35 + movimiento_lento, 95), 1.35, Color(0.13, 0.14, 0.23))
	dibujar_nube(Vector2(245 - movimiento_medio, 70), 1.65, Color(0.11, 0.12, 0.20))
	dibujar_nube(Vector2(500 + movimiento_lento, 115), 1.45, Color(0.14, 0.15, 0.24))

	# Nubes medias más oscuras
	dibujar_nube(Vector2(120 - movimiento_lento, 190), 1.10, Color(0.08, 0.09, 0.16))
	dibujar_nube(Vector2(430 + movimiento_medio, 210), 1.25, Color(0.075, 0.085, 0.15))


func dibujar_nube(pos: Vector2, escala: float, color_nube: Color):
	var sombra := Color(0.015, 0.02, 0.045, 0.72)

	# Sombra
	draw_circle(pos + Vector2(0, 28) * escala, 48 * escala, sombra)
	draw_circle(pos + Vector2(50, 8) * escala, 60 * escala, sombra)
	draw_circle(pos + Vector2(110, 30) * escala, 48 * escala, sombra)
	draw_rect(Rect2(pos.x - 12 * escala, pos.y + 28 * escala, 145 * escala, 48 * escala), sombra)

	# Cuerpo de nube
	draw_circle(pos + Vector2(0, 20) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(48, 0) * escala, 58 * escala, color_nube)
	draw_circle(pos + Vector2(105, 22) * escala, 45 * escala, color_nube)
	draw_circle(pos + Vector2(55, 36) * escala, 62 * escala, color_nube)
	draw_rect(Rect2(pos.x - 10 * escala, pos.y + 22 * escala, 135 * escala, 45 * escala), color_nube)

	# Brillo leve
	draw_circle(pos + Vector2(45, -8) * escala, 28 * escala, Color(0.25, 0.27, 0.36, 0.14))


# =========================================================
# LLUVIA Y NEBLINA
# =========================================================

func dibujar_lluvia():
	# Lluvia fina del fondo
	for i in range(95):
		var x = fmod(i * 71 + tiempo * 165, 780) - 40
		var y = fmod(i * 43 + tiempo * 410, 820)

		draw_line(
			Vector2(x, y),
			Vector2(x - 8, y + 24),
			Color(0.35, 0.55, 0.95, 0.28),
			1
		)

	# Lluvia principal
	for i in range(75):
		var x = fmod(i * 91 + tiempo * 260, 780) - 40
		var y = fmod(i * 59 + tiempo * 560, 830)

		draw_line(
			Vector2(x, y),
			Vector2(x - 13, y + 34),
			Color(0.55, 0.72, 1.0, 0.55),
			2
		)

	# Lluvia frontal más fuerte
	for i in range(28):
		var x = fmod(i * 127 + tiempo * 390, 800) - 50
		var y = fmod(i * 83 + tiempo * 720, 850)

		draw_line(
			Vector2(x, y),
			Vector2(x - 16, y + 42),
			Color(0.78, 0.88, 1.0, 0.65),
			2.5
		)


func dibujar_neblina():
	var offset := sin(tiempo * 0.45) * 18

	for i in range(5):
		var y := 430 + i * 45

		draw_rect(
			Rect2(-40 + offset + i * 20, y, 800, 28),
			Color(0.45, 0.55, 0.75, 0.045)
		)


# =========================================================
# SUELO PROFESIONAL
# =========================================================

func dibujar_suelo():
	# Base del terreno con varias capas
	draw_rect(Rect2(0, 688, 720, 112), Color(0.018, 0.050, 0.035))
	draw_rect(Rect2(0, 700, 720, 100), Color(0.025, 0.075, 0.045))
	draw_rect(Rect2(0, 745, 720, 55), Color(0.012, 0.032, 0.023, 0.90))

	# Línea superior de césped
	draw_rect(Rect2(0, 688, 720, 5), Color(0.16, 0.34, 0.16, 0.95))
	draw_rect(Rect2(0, 693, 720, 7), Color(0.06, 0.17, 0.08, 0.90))

	# Textura suave del suelo
	for i in range(28):
		var x := i * 30
		var y := 718 + int(abs(sin(i * 2.4)) * 36)

		draw_circle(
			Vector2(x, y),
			18,
			Color(0.04, 0.09, 0.06, 0.32)
		)

	# Sombra donde se apoya el jugador
	draw_oval(Vector2(360, 720), Vector2(95, 18), Color(0.0, 0.0, 0.0, 0.20))


func dibujar_detalles_suelo():
	# Pasto de fondo
	for i in range(58):
		var x := i * 13 + int(sin(i * 1.7) * 5)
		var alto := 10 + int(abs(sin(i * 2.3)) * 17)

		draw_line(
			Vector2(x, 700),
			Vector2(x - 3, 700 - alto),
			Color(0.08, 0.22, 0.11, 0.75),
			2
		)

		draw_line(
			Vector2(x + 4, 700),
			Vector2(x + 8, 700 - alto * 0.75),
			Color(0.06, 0.18, 0.09, 0.65),
			2
		)

	# Pasto frontal más visible
	for i in range(42):
		var x := i * 18 + int(cos(i * 1.3) * 7)
		var alto := 18 + int(abs(cos(i * 1.9)) * 22)

		draw_line(
			Vector2(x, 708),
			Vector2(x - 5, 708 - alto),
			Color(0.12, 0.34, 0.16, 0.92),
			3
		)

		draw_line(
			Vector2(x, 708),
			Vector2(x + 6, 708 - alto * 0.8),
			Color(0.08, 0.25, 0.12, 0.85),
			2
		)

	# Arbustos
	dibujar_arbusto(Vector2(45, 705), 0.9)
	dibujar_arbusto(Vector2(625, 708), 1.1)
	dibujar_arbusto(Vector2(350, 710), 0.75)

	# Charcos
	dibujar_charco(Vector2(160, 748), Vector2(60, 11), Color(0.10, 0.17, 0.25, 0.62))
	dibujar_charco(Vector2(510, 735), Vector2(72, 13), Color(0.10, 0.17, 0.25, 0.50))

	# Brillos de charcos
	draw_line(Vector2(120, 746), Vector2(200, 744), Color(0.62, 0.78, 1.0, 0.18), 2)
	draw_line(Vector2(465, 733), Vector2(555, 731), Color(0.62, 0.78, 1.0, 0.16), 2)


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
	draw_oval(center, radius, color)


func draw_oval(center: Vector2, radius: Vector2, color: Color):
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
		Vector2(565, 0),
		Vector2(535, 95),
		Vector2(575, 95),
		Vector2(510, 230),
		Vector2(595, 110),
		Vector2(555, 110),
		Vector2(610, 0)
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
		Rect2(0, 0, 720, 800),
		Color(0.85, 0.9, 1.0, flash * intensidad_flash)
	)
