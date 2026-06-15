extends Node2D
class_name RoundUi


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

const PANEL_SIZE := Vector2(240, 90)
const PANEL_RADIUS := 22.0
const PANEL_SHADOW_OFFSET := Vector2(4, 5)

const PANEL_BACKGROUND_COLOR := C_BEIGE
const PANEL_SHINE_COLOR := Color(1.0, 0.92, 0.78, 0.32)
const PANEL_BORDER_COLOR := C_ORANGE
const PANEL_LINE_COLOR := Color(1.0, 0.95, 0.84, 0.35)
const PANEL_SHADOW_COLOR := Color(0.35, 0.20, 0.10, 0.18)

const TITLE_COLOR := C_BLUE
const TITLE_SHADOW_COLOR := Color(1.0, 0.95, 0.86, 0.55)

const ROUND_ACTIVE_COLOR := C_BLUE
const ROUND_INACTIVE_COLOR := Color(0.58, 0.50, 0.44, 0.55)
const ROUND_SHINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)

const TITLE_TEXT := "RONDA"
const TITLE_FONT_SIZE := 22
const NUMBER_FONT_SIZE := 25


@export var panel_corner := PanelCorner.TOP_RIGHT
@export var panel_margin := Vector2(35, 140)

var current_round := 1
var max_rounds := 3
var pulse := 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func update_round(new_current_round: int, new_max_rounds: int) -> void:
	current_round = max(1, new_current_round)
	max_rounds = max(1, new_max_rounds)
	queue_redraw()


func set_panel_corner(new_corner: PanelCorner) -> void:
	panel_corner = new_corner
	queue_redraw()


func set_panel_margin(new_margin: Vector2) -> void:
	panel_margin = new_margin
	queue_redraw()


func _draw() -> void:
	_draw_round_panel()
	_draw_round_text()
	_draw_round_marks()


func _draw_round_panel() -> void:
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
		panel_position + Vector2(2, 34),
		TITLE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_SHADOW_COLOR
	)

	draw_string(
		font,
		panel_position + Vector2(0, 32),
		TITLE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		TITLE_FONT_SIZE,
		TITLE_COLOR
	)


func _draw_round_text() -> void:
	var panel_position = _get_panel_position()
	var font := ThemeDB.fallback_font
	var round_text := str(current_round) + " / " + str(max_rounds)

	draw_string(
		font,
		panel_position + Vector2(2, 64),
		round_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		NUMBER_FONT_SIZE,
		TITLE_SHADOW_COLOR
	)

	draw_string(
		font,
		panel_position + Vector2(0, 62),
		round_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_SIZE.x,
		NUMBER_FONT_SIZE,
		TITLE_COLOR
	)


func _draw_round_marks() -> void:
	var panel_position: Vector2 = _get_panel_position()
	var start_x: float = panel_position.x + 70.0
	var y: float = panel_position.y + 75.0

	for index in range(max_rounds):
		var center: Vector2 = Vector2(start_x + float(index) * 50.0, y)

		if index < current_round:
			var mark_scale: float = 1.0 + sin(pulse * 4.0 + float(index)) * 0.05

			draw_circle(
				center + Vector2(2, 3),
				9.0 * mark_scale,
				Color(0, 0, 0, 0.22)
			)

			draw_circle(
				center,
				9.0 * mark_scale,
				ROUND_ACTIVE_COLOR
			)

			draw_circle(
				center + Vector2(-3, -3),
				3.0 * mark_scale,
				ROUND_SHINE_COLOR
			)
		else:
			draw_circle(
				center + Vector2(2, 3),
				8.0,
				Color(0, 0, 0, 0.18)
			)

			draw_circle(
				center,
				8.0,
				ROUND_INACTIVE_COLOR
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
) -> void:
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
) -> void:
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
