extends Panel

var background_color := Color("#406080")
var border_color := Color("#30C0F0")
var tick_color := Color("#C0E0FF")

func _ready():
	queue_redraw()

func _draw():
	draw_circle(
		Vector2(26, 26),
		24,
		background_color
	)
	draw_arc(
		Vector2(26, 26),
		24,
		0,
		TAU,
		64,
		border_color,
		3.0
	)
	for i in range(12):
		var angle = i * TAU / 12.0
		var start = Vector2(
			26 + cos(angle) * 18,
			26 + sin(angle) * 18
		)
		var end = Vector2(
			26 + cos(angle) * 23,
			26 + sin(angle) * 23
		)
		draw_line(
			start,
			end,
			tick_color,
			1.5
		)
	draw_circle(
		Vector2(26, 26),
		2,
		Color.WHITE
	)
