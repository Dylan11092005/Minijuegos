## MapPuzzle.gd
## Minijuego: Rompecabezas de Mapa
## Godot 4.x

extends Node2D

signal puzzle_completed
signal puzzle_failed

# =========================================================
# CONFIGURACIÓN
# =========================================================
@export var map_texture: Texture2D
@export var background_texture: Texture2D
@export var cols: int = 4
@export var rows: int = 3
@export var piece_gap: int = 6
@export var time_limit: float = 60.0

# =========================================================
# RESOLUCIÓN
# =========================================================
const SCREEN_SIZE = Vector2(1920, 1080)
const MODAL_SIZE  = Vector2(1600, 920)

# =========================================================
# VARIABLES
# =========================================================
var piece_size: Vector2
var pieces: Array = []

var selected_index: int   = -1
var game_active: bool     = false
var time_remaining: float = 0.0

# =========================================================
# UI
# =========================================================
var overlay:         ColorRect
var modal:           Panel
var board_container: Node2D
var guide_preview:   TextureRect
var timer_label:     Label
var result_overlay:  Panel

# =========================================================
# COLORES
# =========================================================
const COLOR_GOLD     = Color("#D4AF37")
const COLOR_SELECTED = Color(1.0, 0.878, 0.251, 0.35)
const COLOR_CORRECT  = Color(0.251, 1.0, 0.502, 0.2)
const COLOR_WIN      = Color("#1A3A1A")
const COLOR_LOSE     = Color("#3A1A1A")

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	_build_ui()
	if map_texture:
		start_game()

# =========================================================
# PROCESS
# =========================================================
func _process(delta: float) -> void:
	if not game_active:
		return

	time_remaining -= delta
	_update_timer_label()

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_on_time_out()

# =========================================================
# START GAME
# =========================================================
func start_game() -> void:
	_clear_pieces()

	selected_index = -1
	game_active    = true
	time_remaining = time_limit

	overlay.visible = true

	if map_texture == null:
		return

	guide_preview.texture = map_texture

	var available_width  = 1050.0
	var available_height = 620.0

	piece_size = Vector2(
		available_width  / cols,
		available_height / rows
	)

	_create_pieces()
	_shuffle_pieces()
	_animate_modal()

# =========================================================
# CREAR PIEZAS
# =========================================================
func _create_pieces() -> void:
	var image: Image = map_texture.get_image()

	var original_piece_size = Vector2(
		map_texture.get_width()  / cols,
		map_texture.get_height() / rows
	)

	for row in rows:
		for col in cols:
			var index: int = row * cols + col

			var region := Rect2i(
				col * int(original_piece_size.x),
				row * int(original_piece_size.y),
				int(original_piece_size.x),
				int(original_piece_size.y)
			)

			var piece_image := image.get_region(region)
			var piece_tex   := ImageTexture.create_from_image(piece_image)

			var sprite := Sprite2D.new()
			sprite.texture  = piece_tex
			sprite.centered = false
			sprite.scale    = Vector2(
				piece_size.x / original_piece_size.x,
				piece_size.y / original_piece_size.y
			)

			board_container.add_child(sprite)

			var highlight := ColorRect.new()
			highlight.size         = piece_size - Vector2(piece_gap * 2, piece_gap * 2)
			highlight.color        = Color.TRANSPARENT
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

			sprite.add_child(highlight)
			highlight.position = Vector2(piece_gap, piece_gap)

			pieces.append({
				"sprite":      sprite,
				"highlight":   highlight,
				"correct_pos": index,
				"current_pos": index
			})

# =========================================================
# SHUFFLE
# =========================================================
func _shuffle_pieces() -> void:
	var positions: Array = range(cols * rows)
	positions.shuffle()
	for i in pieces.size():
		pieces[i]["current_pos"] = positions[i]
	_apply_positions()

# =========================================================
# POSICIONES
# =========================================================
func _apply_positions() -> void:
	var start_x = 70
	var start_y = 240

	for piece in pieces:
		var pos_index: int = piece["current_pos"]
		var col: int = pos_index % cols
		var row: int = pos_index / cols

		var target := Vector2(
			start_x + col * (piece_size.x + piece_gap),
			start_y + row * (piece_size.y + piece_gap)
		)

		piece["sprite"].position = target

	_refresh_highlights()

# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_index = _get_piece_at(event.position)

			if clicked_index == -1:
				return

			if selected_index == -1:
				selected_index = clicked_index

			elif selected_index == clicked_index:
				selected_index = -1

			else:
				_swap_pieces(selected_index, clicked_index)
				selected_index = -1
				_check_win()

			_refresh_highlights()

# =========================================================
# DETECTAR PIEZA
# =========================================================
func _get_piece_at(pos: Vector2) -> int:
	for i in pieces.size():
		var p     = pieces[i]
		var p_pos = p["sprite"].global_position
		var rect  = Rect2(p_pos, piece_size)
		if rect.has_point(pos):
			return i
	return -1

# =========================================================
# SWAP
# =========================================================
func _swap_pieces(a: int, b: int) -> void:
	var temp_pos             = pieces[a]["current_pos"]
	pieces[a]["current_pos"] = pieces[b]["current_pos"]
	pieces[b]["current_pos"] = temp_pos
	_apply_positions()

# =========================================================
# HIGHLIGHTS
# =========================================================
func _refresh_highlights() -> void:
	for i in pieces.size():
		var p         = pieces[i]
		var highlight = p["highlight"]
		var is_sel    = (i == selected_index)
		var is_ok     = (p["current_pos"] == p["correct_pos"])

		if is_sel:
			highlight.color = COLOR_SELECTED
		elif is_ok:
			highlight.color = COLOR_CORRECT
		else:
			highlight.color = Color.TRANSPARENT

# =========================================================
# WIN CHECK
# =========================================================
func _check_win() -> void:
	for piece in pieces:
		if piece["current_pos"] != piece["correct_pos"]:
			return

	game_active = false
	_show_result(true)
	emit_signal("puzzle_completed")

# =========================================================
# TIME OUT
# =========================================================
func _on_time_out() -> void:
	game_active = false
	_show_result(false)
	emit_signal("puzzle_failed")

# =========================================================
# RESULTADO
# =========================================================
func _show_result(won: bool) -> void:
	result_overlay.visible = true

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color                       = COLOR_WIN if won else COLOR_LOSE
	bg_style.corner_radius_top_left         = 16
	bg_style.corner_radius_top_right        = 16
	bg_style.corner_radius_bottom_left      = 16
	bg_style.corner_radius_bottom_right     = 16
	bg_style.border_width_left              = 3
	bg_style.border_width_top               = 3
	bg_style.border_width_right             = 3
	bg_style.border_width_bottom            = 3
	bg_style.border_color                   = COLOR_GOLD
	result_overlay.add_theme_stylebox_override("panel", bg_style)

	var title := result_overlay.get_node("Title")
	var body  := result_overlay.get_node("Body")
	var btn   := result_overlay.get_node("CloseButton")

	if won:
		title.text = "¡Mapa completado!"
		body.text  = "Excelente trabajo. Armaste el mapa de riesgo escolar a tiempo."
	else:
		title.text = "¡Tiempo agotado!"
		body.text  = "No lograste armar el mapa a tiempo. ¡Inténtalo de nuevo!"

	btn.text = "Reiniciar"

	btn.pressed.connect(_on_result_closed, CONNECT_ONE_SHOT)

	result_overlay.scale    = Vector2(0.8, 0.8)
	result_overlay.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_overlay, "scale",    Vector2.ONE,    0.25)
	tween.tween_property(result_overlay, "modulate", Color(1,1,1,1), 0.25)

func _on_result_closed() -> void:
	result_overlay.visible = false
	start_game()

# =========================================================
# TIMER LABEL
# =========================================================
func _update_timer_label() -> void:
	var secs         = int(ceil(time_remaining))
	timer_label.text = "⏱ %d s" % secs

	if time_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color("#FF4444"))
	else:
		timer_label.add_theme_color_override("font_color", COLOR_GOLD)

# =========================================================
# BUILD UI
# =========================================================
func _build_ui() -> void:

	# =====================================================
	# FONDO
	# =====================================================
	if background_texture:
		var bg := TextureRect.new()
		bg.texture      = background_texture
		bg.size         = SCREEN_SIZE
		bg.position     = Vector2.ZERO
		bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)

	# =====================================================
	# OVERLAY
	# =====================================================
	overlay         = ColorRect.new()
	overlay.color   = Color(0, 0, 0, 0.0)
	overlay.size    = SCREEN_SIZE
	overlay.visible = false
	add_child(overlay)

	# =====================================================
	# MODAL
	# =====================================================
	modal          = Panel.new()
	modal.size     = MODAL_SIZE
	modal.position = (SCREEN_SIZE - MODAL_SIZE) / 2
	add_child(modal)

	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0, 0, 0, 0.0)
	style.border_width_left          = 0
	style.border_width_top           = 0
	style.border_width_right         = 0
	style.border_width_bottom        = 0
	modal.add_theme_stylebox_override("panel", style)

	board_container = Node2D.new()
	modal.add_child(board_container)

	# =====================================================
	# TEXTO EDUCATIVO
	# =====================================================
	var instruction_label := Label.new()
	instruction_label.text          = "Participaste en la elaboración del mapa de riesgo escolar."
	instruction_label.position      = Vector2(70, 40)
	instruction_label.size          = Vector2(820, 100)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 30)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	modal.add_child(instruction_label)

	# =====================================================
	# TIMER
	# =====================================================
	timer_label          = Label.new()
	timer_label.text     = "⏱ 60 s"
	timer_label.position = Vector2(70, 155)
	timer_label.size     = Vector2(300, 60)
	timer_label.add_theme_font_size_override("font_size", 36)
	timer_label.add_theme_color_override("font_color", COLOR_GOLD)
	modal.add_child(timer_label)

	# =====================================================
	# MINI MAPA
	# =====================================================
	var preview_border      := Panel.new()
	preview_border.position  = Vector2(1260, 40)
	preview_border.size      = Vector2(280, 200)

	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color                   = Color(0, 0, 0, 0.2)
	preview_style.border_width_left          = 3
	preview_style.border_width_top           = 3
	preview_style.border_width_right         = 3
	preview_style.border_width_bottom        = 3
	preview_style.border_color               = COLOR_GOLD
	preview_style.corner_radius_top_left     = 10
	preview_style.corner_radius_top_right    = 10
	preview_style.corner_radius_bottom_left  = 10
	preview_style.corner_radius_bottom_right = 10
	preview_border.add_theme_stylebox_override("panel", preview_style)
	modal.add_child(preview_border)

	guide_preview              = TextureRect.new()
	guide_preview.position     = Vector2(1275, 55)
	guide_preview.size         = Vector2(250, 170)
	guide_preview.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	guide_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modal.add_child(guide_preview)
	guide_preview.move_to_front()

	# =====================================================
	# PANEL DE RESULTADO
	# =====================================================
	result_overlay          = Panel.new()
	result_overlay.size     = Vector2(700, 340)
	result_overlay.position = (MODAL_SIZE - Vector2(700, 340)) / 2
	result_overlay.visible  = false
	modal.add_child(result_overlay)

	var r_title := Label.new()
	r_title.name                 = "Title"
	r_title.position             = Vector2(40, 50)
	r_title.size                 = Vector2(620, 80)
	r_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_title.add_theme_font_size_override("font_size", 48)
	r_title.add_theme_color_override("font_color", COLOR_GOLD)
	result_overlay.add_child(r_title)

	var r_body := Label.new()
	r_body.name                 = "Body"
	r_body.position             = Vector2(40, 150)
	r_body.size                 = Vector2(620, 80)
	r_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_body.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	r_body.add_theme_font_size_override("font_size", 24)
	r_body.add_theme_color_override("font_color", Color.WHITE)
	result_overlay.add_child(r_body)

	var r_btn := Button.new()
	r_btn.name     = "CloseButton"
	r_btn.position = Vector2(200, 260)
	r_btn.size     = Vector2(300, 60)
	r_btn.add_theme_font_size_override("font_size", 26)
	result_overlay.add_child(r_btn)

# =========================================================
# ANIMACIÓN MODAL
# =========================================================
func _animate_modal() -> void:
	modal.scale = Vector2(0.8, 0.8)
	var tween   = create_tween()
	tween.tween_property(modal, "scale", Vector2.ONE, 0.2)

# =========================================================
# CLEAR
# =========================================================
func _clear_pieces() -> void:
	for piece in pieces:
		piece["sprite"].queue_free()
	pieces.clear()
