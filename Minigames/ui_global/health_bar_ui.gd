extends Node2D
class_name HealthBarUi


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

const PANEL_SIZE := Vector2(300, 95)
const PANEL_RADIUS := 22.0
const PANEL_SHADOW_OFFSET := Vector2(4, 5)

const PANEL_BACKGROUND_COLOR := C_BEIGE
const PANEL_SHINE_COLOR := Color(1.0, 0.92, 0.78, 0.32)
const PANEL_BORDER_COLOR := C_ORANGE
const PANEL_LINE_COLOR := Color(1.0, 0.95, 0.84, 0.35)
const PANEL_SHADOW_COLOR := Color(0.35, 0.20, 0.10, 0.18)

const TITLE_COLOR := C_BLUE
const TITLE_SHADOW_COLOR := Color(1.0, 0.95, 0.86, 0.55)

const BAR_BACKGROUND_COLOR := Color(0.55, 0.45, 0.35, 0.35)
const BAR_BORDER_COLOR := C_BLUE

const TITLE_TEXT := "SALUD"
const TITLE_FONT_SIZE := 22

const BAR_POSITION := Vector2(28, 55)
const BAR_SIZE := Vector2(244, 24)
const BAR_RADIUS := 10.0


@export var max_health := 100
@export var panel_corner := PanelCorner.TOP_RIGHT
@export var panel_margin := Vector2(35, 20)

var current_health := 100
var pulse := 0.0


func _ready():
	current_health = max_health
	queue_redraw()


func _process(delta):
	pulse += delta
	queue_redraw()


func update_health(new_health: int):
	current_health = clampi(new_health, 0, max_health)
	queue_redraw()


func set_max_health(new_max_health: int):
	max_health = max(1, new_max_health)
	current_health = clampi(current_health, 0, max_health)
	queue_redraw()


func set_panel_corner(new_corner: PanelCorner):
	panel_corner = new_corner
	queue_redraw()


func set_panel_margin(new_margin: Vector2):
	panel_margin = new_margin
	queue_redraw()


func _draw():
	_draw_health_panel()
	_draw_health_bar()


func _draw_health_panel():
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
		TITLE_TEXT + ": " + str(current_health),
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_SHADOW_COLOR
	)

	draw_string(
		font,
		panel_position + Vector2(0, 33),
		TITLE_TEXT + ": " + str(current_health),
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_COLOR
	)


func _draw_health_bar():
	var panel_position = _get_panel_position()
	var bar_position = panel_position + BAR_POSITION

	var health_percent := float(current_health) / float(max_health)
	health_percent = clampf(health_percent, 0.0, 1.0)

	var fill_width := BAR_SIZE.x * health_percent

	var fill_color = C_BLUE

	if current_health > 60:
		fill_color = C_RED
	elif current_health > 30:
		fill_color = C_ORANGE
	else:
		fill_color = C_RED

	_draw_rounded_rect(
		bar_position,
		BAR_SIZE,
		BAR_RADIUS,
		BAR_BACKGROUND_COLOR
	)

	_draw_rounded_border(
		bar_position,
		BAR_SIZE,
		BAR_RADIUS,
		BAR_BORDER_COLOR,
		3
	)

	if fill_width > 0:
		var animated_width = fill_width

		if current_health <= 30:
			animated_width += sin(pulse * 7.0) * 2.0

		animated_width = clampf(animated_width, 0.0, BAR_SIZE.x)

		_draw_rounded_rect(
			bar_position + Vector2(4, 4),
			Vector2(max(1.0, animated_width - 8), BAR_SIZE.y - 8),
			7,
			fill_color
		)

		draw_line(
			bar_position + Vector2(12, 8),
			bar_position + Vector2(max(12, animated_width - 12), 8),
			Color(1.0, 1.0, 1.0, 0.25),
			2
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
	if rect_size.x <= 0 or rect_size.y <= 0:
		return

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
