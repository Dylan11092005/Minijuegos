extends Node2D
class_name LivesUi


enum PanelCorner {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}


const C_BEIGE = Color("#E5C89E")
const C_ORANGE = Color("#E0B080")
const C_BLUE = Color("#3E5F8F")
const C_WHITE = Color("#FFFFFF")
const C_RED = Color("#D63A3A")

const PANEL_SIZE := Vector2(240, 108)
const PANEL_RADIUS := 22.0
const PANEL_SHADOW_OFFSET := Vector2(4, 5)

const PANEL_BACKGROUND_COLOR := C_BEIGE
const PANEL_SHINE_COLOR := Color(1.0, 0.92, 0.78, 0.32)
const PANEL_BORDER_COLOR := C_ORANGE
const PANEL_LINE_COLOR := Color(1.0, 0.95, 0.84, 0.35)
const PANEL_SHADOW_COLOR := Color(0.35, 0.20, 0.10, 0.18)

const TITLE_COLOR := C_BLUE
const TITLE_SHADOW_COLOR := Color(1.0, 0.95, 0.86, 0.55)

const HEART_ACTIVE_COLOR := C_RED
const HEART_ACTIVE_SHINE_COLOR := Color(1.0, 0.58, 0.65)
const HEART_EMPTY_COLOR := Color(0.58, 0.50, 0.44, 0.55)
const HEART_EMPTY_SHINE_COLOR := Color(0.78, 0.70, 0.60, 0.35)
const HEART_LOST_LINE_COLOR := Color(0.35, 0.25, 0.20, 0.65)

const HEART_START_OFFSET := Vector2(55, 78)
const HEART_SEPARATION := 62
const HEART_POINTS := 50

const TITLE_TEXT := "VIDAS"
const TITLE_FONT_SIZE := 22


@export var max_lives := 3
@export var panel_corner := PanelCorner.TOP_RIGHT
@export var panel_margin := Vector2(35, 20)


var current_lives := 3
var pulse := 0.0


func _ready():
	current_lives = max_lives
	queue_redraw()


func _process(delta):
	pulse += delta
	queue_redraw()


func actualizar_vidas(lives: int):
	current_lives = clampi(lives, 0, max_lives)
	queue_redraw()


func set_max_lives(new_max_lives: int):
	max_lives = max(1, new_max_lives)
	current_lives = clampi(current_lives, 0, max_lives)
	queue_redraw()


func set_panel_corner(new_corner: PanelCorner):
	panel_corner = new_corner
	queue_redraw()


func set_panel_margin(new_margin: Vector2):
	panel_margin = new_margin
	queue_redraw()


func _draw():
	_draw_lives_panel()
	_draw_hearts()


func _draw_lives_panel():
	var panel_position = _get_panel_position()
	var font := ThemeDB.fallback_font

	_draw_rounded_rect(
		panel_position + PANEL_SHADOW_OFFSET,
		PANEL_SIZE,
		PANEL_RADIUS,
		PANEL_SHADOW_COLOR
	)

	_draw_rounded_rect(
		panel_position,
		PANEL_SIZE,
		PANEL_RADIUS,
		PANEL_BACKGROUND_COLOR
	)

	_draw_rounded_rect(
		panel_position + Vector2(5, 5),
		PANEL_SIZE - Vector2(10, 10),
		16,
		PANEL_SHINE_COLOR
	)

	_draw_rounded_border(
		panel_position,
		PANEL_SIZE,
		PANEL_RADIUS,
		PANEL_BORDER_COLOR,
		4
	)

	draw_line(
		panel_position + Vector2(35, 9),
		panel_position + Vector2(PANEL_SIZE.x - 35, 9),
		PANEL_LINE_COLOR,
		2
	)

	draw_string(
		font,
		panel_position + Vector2(2, 35),
		TITLE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_SHADOW_COLOR
	)

	draw_string(
		font,
		panel_position + Vector2(0, 33),
		TITLE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_COLOR
	)


func _draw_hearts():
	var panel_position = _get_panel_position()
	var start_position = panel_position + HEART_START_OFFSET

	for index in range(max_lives):
		var heart_center = start_position + Vector2(index * HEART_SEPARATION, 0)

		if index < current_lives:
			var heart_scale = 1.15 + sin(pulse * 4.0 + index) * 0.04

			_draw_heart(
				heart_center,
				heart_scale,
				HEART_ACTIVE_COLOR,
				HEART_ACTIVE_SHINE_COLOR,
				true
			)
		else:
			_draw_heart(
				heart_center,
				1.05,
				HEART_EMPTY_COLOR,
				HEART_EMPTY_SHINE_COLOR,
				false
			)


func _draw_heart(
	center: Vector2,
	heart_scale: float,
	base_color: Color,
	shine_color: Color,
	active: bool
):
	var points := PackedVector2Array()

	for index in range(HEART_POINTS):
		var time = TAU * float(index) / float(HEART_POINTS)

		var x = 16.0 * pow(sin(time), 3)
		var y = -(13.0 * cos(time) - 5.0 * cos(2.0 * time) - 2.0 * cos(3.0 * time) - cos(4.0 * time))

		points.append(center + Vector2(x, y) * heart_scale)

	var shadow_points := PackedVector2Array()

	for point in points:
		shadow_points.append(point + Vector2(3, 4))

	draw_colored_polygon(shadow_points, Color(0, 0, 0, 0.28))
	draw_colored_polygon(points, base_color)

	if active:
		draw_circle(
			center + Vector2(-8, -7) * heart_scale,
			5.0 * heart_scale,
			shine_color
		)

		draw_circle(
			center + Vector2(-4, -10) * heart_scale,
			2.5 * heart_scale,
			Color(1, 1, 1, 0.35)
		)

		draw_polyline(points, Color(1.0, 0.75, 0.78, 0.35), 2)
	else:
		draw_line(
			center + Vector2(-18, -18),
			center + Vector2(18, 18),
			HEART_LOST_LINE_COLOR,
			4
		)


func _get_panel_position() -> Vector2:
	var viewport_size = get_viewport_rect().size

	match panel_corner:
		PanelCorner.TOP_LEFT:
			return panel_margin

		PanelCorner.TOP_RIGHT:
			return Vector2(
				viewport_size.x - PANEL_SIZE.x - panel_margin.x,
				panel_margin.y
			)

		PanelCorner.BOTTOM_LEFT:
			return Vector2(
				panel_margin.x,
				viewport_size.y - PANEL_SIZE.y - panel_margin.y
			)

		PanelCorner.BOTTOM_RIGHT:
			return Vector2(
				viewport_size.x - PANEL_SIZE.x - panel_margin.x,
				viewport_size.y - PANEL_SIZE.y - panel_margin.y
			)

	return panel_margin


func _draw_rounded_rect(
	rect_position: Vector2,
	rect_size: Vector2,
	radius: float,
	color: Color
):
	draw_rect(
		Rect2(rect_position.x + radius, rect_position.y, rect_size.x - radius * 2, rect_size.y),
		color
	)

	draw_rect(
		Rect2(rect_position.x, rect_position.y + radius, rect_size.x, rect_size.y - radius * 2),
		color
	)

	draw_circle(rect_position + Vector2(radius, radius), radius, color)
	draw_circle(rect_position + Vector2(rect_size.x - radius, radius), radius, color)
	draw_circle(rect_position + Vector2(radius, rect_size.y - radius), radius, color)
	draw_circle(rect_position + Vector2(rect_size.x - radius, rect_size.y - radius), radius, color)


func _draw_rounded_border(
	rect_position: Vector2,
	rect_size: Vector2,
	radius: float,
	color: Color,
	border_width: float
):
	draw_line(
		rect_position + Vector2(radius, 0),
		rect_position + Vector2(rect_size.x - radius, 0),
		color,
		border_width
	)

	draw_line(
		rect_position + Vector2(radius, rect_size.y),
		rect_position + Vector2(rect_size.x - radius, rect_size.y),
		color,
		border_width
	)

	draw_line(
		rect_position + Vector2(0, radius),
		rect_position + Vector2(0, rect_size.y - radius),
		color,
		border_width
	)

	draw_line(
		rect_position + Vector2(rect_size.x, radius),
		rect_position + Vector2(rect_size.x, rect_size.y - radius),
		color,
		border_width
	)

	draw_arc(
		rect_position + Vector2(radius, radius),
		radius,
		PI,
		PI * 1.5,
		18,
		color,
		border_width
	)

	draw_arc(
		rect_position + Vector2(rect_size.x - radius, radius),
		radius,
		PI * 1.5,
		TAU,
		18,
		color,
		border_width
	)

	draw_arc(
		rect_position + Vector2(radius, rect_size.y - radius),
		radius,
		PI * 0.5,
		PI,
		18,
		color,
		border_width
	)

	draw_arc(
		rect_position + Vector2(rect_size.x - radius, rect_size.y - radius),
		radius,
		0,
		PI * 0.5,
		18,
		color,
		border_width
	)
