extends Panel

var color_fondo := Color("#406080")
var color_borde := Color("#30C0F0")
var color_marcas := Color("#C0E0FF")

func _ready():
	queue_redraw()

func _draw():

	draw_circle(
		Vector2(26,26),
		24,
		color_fondo
	)

	draw_arc(
		Vector2(26,26),
		24,
		0,
		TAU,
		64,
		color_borde,
		3.0
	)

	for i in range(12):

		var angulo = i * TAU / 12.0

		var inicio = Vector2(
			26 + cos(angulo) * 18,
			26 + sin(angulo) * 18
		)

		var fin = Vector2(
			26 + cos(angulo) * 23,
			26 + sin(angulo) * 23
		)

		draw_line(
			inicio,
			fin,
			color_marcas,
			1.5
		)

	draw_circle(
		Vector2(26,26),
		2,
		Color.WHITE
	)
